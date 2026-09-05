import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend/backend_config.dart';
import '../../core/backend/backend_contract.dart';
import '../../core/location/location_bridge.dart';
import '../../core/location/location_models.dart';
import '../../core/location/place_alert_geofence_sync.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/i18n/region_settings.dart';
import '../../theme/gyeote_theme.dart';
import '../onboarding/permission_primer.dart';
import 'widgets/animated_tracks.dart';
import 'widgets/map_chrome.dart';
import 'widgets/night_tiles.dart';
import 'widgets/quick_reply_bar.dart';
import 'widgets/member_sheet.dart';
import 'widgets/sos_control.dart';
import 'map_models.dart';

enum _PlaceQuietHoursPreset {
  none,
  night,
  schoolOrWork,
}

class MapScreen extends StatefulWidget {
  MapScreen({
    super.key,
    this.circleRepository,
    this.deviceRepository,
    this.companionRepository,
    this.checkInRepository,
    this.placeAlertRepository,
    this.backendConfig,
    this.onOpenCircle,
    LocationBridge? locationBridge,
  }) : locationBridge = locationBridge ?? LocationBridge();

  final CircleRepository? circleRepository;
  final DeviceRepository? deviceRepository;
  final CompanionRepository? companionRepository;
  final CheckInRepository? checkInRepository;
  final PlaceAlertRepository? placeAlertRepository;
  final BackendConfig? backendConfig;
  final VoidCallback? onOpenCircle;
  final LocationBridge locationBridge;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  StreamSubscription<List<MemberLocationSnapshot>>? _locationSubscription;
  StreamSubscription<Map<Object?, Object?>>? _deviceLocationSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  List<MapMemberTrack> _serverTracks = const [];
  List<LatLng> _deviceRoute = const [];
  MapMemberTrack? _deviceTrack;
  String? _circleName;
  String? _loadError;
  String? _bridgeStatus;
  String? _uploadStatus;
  String? _checkInStatusMessage;
  String? _placeAlertStatusMessage;

  /// 오류 색을 문구 내용으로 추측하지 않기 위한 플래그.
  /// 예전에는 '못했습니다'/'선택'/'입력' 부분 문자열로 판별해서, 번역하는 순간
  /// 실패가 성공 색으로 표시됐다.
  bool _placeAlertStatusIsError = false;
  int? _uploadPendingCount;
  bool? _hasServerCircle;
  String? _activeCircleId;
  String? _activeCompanionSessionId;
  CheckInEvent? _lastCheckInEvent;
  bool _isLoading = false;
  bool _isCompanionActive = false;
  bool _isUploadFlushRunning = false;
  bool _isCheckingIn = false;
  bool _isSavingPlaceAlert = false;
  bool _isPlaceDraftVisible = false;
  String? _selectedMemberId;

  /// 지금 보내는 중인 정형 반응. 하나가 나가는 동안 나머지를 잠근다.
  CheckInStatus? _sendingQuickReply;

  AppL10n get _l10n => AppL10n.of(context);
  bool _placeNotifyArrival = true;
  bool _placeNotifyDeparture = true;
  bool _placeNotifyLate = false;
  bool _placeNotifyLongStay = false;
  _PlaceQuietHoursPreset _placeQuietHoursPreset = _PlaceQuietHoursPreset.none;
  int _placeDraftRadiusM = 300;
  int _routeTailRequestSerial = 0;
  Set<String> _placeDraftTargetIds = const {};
  final _placeAlertNameController = TextEditingController();
  bool _didSeedPlaceName = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 기본 장소 이름은 로케일이 정해진 뒤에야 만들 수 있다.
    if (!_didSeedPlaceName) {
      _didSeedPlaceName = true;
      _placeAlertNameController.text = _l10n.placeDraftNameHint;
    }
  }

  @override
  void initState() {
    super.initState();
    _connectRepository();
    _connectDeviceLocation();
    _connectAuthRefresh();
    _configureNativeUpload();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circleRepository != widget.circleRepository) {
      _locationSubscription?.cancel();
      _routeTailRequestSerial += 1;
      _serverTracks = const [];
      _circleName = null;
      _loadError = null;
      _hasServerCircle = null;
      _activeCircleId = null;
      _lastCheckInEvent = null;
      _checkInStatusMessage = null;
      _connectRepository();
    }
    if (oldWidget.deviceRepository != widget.deviceRepository ||
        oldWidget.backendConfig != widget.backendConfig) {
      _authSubscription?.cancel();
      _authSubscription = null;
      _connectAuthRefresh();
      _configureNativeUpload();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _deviceLocationSubscription?.cancel();
    _authSubscription?.cancel();
    _placeAlertNameController.dispose();
    super.dispose();
  }

  bool get _supportsNativeLocation {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<void> _connectRepository() async {
    final repository = widget.circleRepository;
    if (repository == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final circles = await repository.listCircles();
      if (!mounted) {
        return;
      }

      if (circles.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasServerCircle = false;
        });
        return;
      }

      final activeCircle = circles.first;
      setState(() {
        _circleName = activeCircle.name;
        _hasServerCircle = true;
        _activeCircleId = activeCircle.id;
      });
      await _loadRecentCheckIns(activeCircle.id);

      _locationSubscription =
          repository.watchLatestLocations(activeCircle.id).listen(
        (snapshots) async {
          final requestSerial = ++_routeTailRequestSerial;
          final tracks = await _tracksWithRouteTails(
            repository: repository,
            circleId: activeCircle.id,
            snapshots: snapshots,
          );
          if (!mounted) {
            return;
          }
          if (requestSerial != _routeTailRequestSerial) {
            return;
          }
          setState(() {
            _serverTracks = tracks;
            _placeDraftTargetIds =
                _reconciledPlaceTargetIds(_placeDraftTargetIds, tracks);
            _isLoading = false;
            _loadError = null;
          });
        },
        onError: (_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isLoading = false;
            _loadError = _l10n.locationLoadFailed;
          });
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = _l10n.circleLoadFailed;
      });
    }
  }

  Future<void> _loadRecentCheckIns(String circleId) async {
    final repository = widget.checkInRepository;
    if (repository == null) {
      return;
    }

    try {
      final events = await repository.listRecentCheckIns(
        circleId: circleId,
        limit: 1,
      );
      if (!mounted || events.isEmpty) {
        return;
      }
      setState(() => _lastCheckInEvent = events.first);
    } catch (_) {
      if (mounted) {
        setState(() => _checkInStatusMessage = _l10n.checkInSyncPending);
      }
    }
  }

  Future<List<MapMemberTrack>> _tracksWithRouteTails({
    required CircleRepository repository,
    required String circleId,
    required List<MemberLocationSnapshot> snapshots,
  }) async {
    final tracks = mapTracksFromSnapshots(_l10n, snapshots);
    if (tracks.isEmpty) {
      return tracks;
    }

    final companionSessionId =
        _isCompanionActive ? _activeCompanionSessionId : null;

    return Future.wait(
      tracks.map((track) async {
        if (track.isStale) {
          return track;
        }
        try {
          final routePoints = companionSessionId == null
              ? await repository.getMemberRouteTail(
                  circleId: circleId,
                  profileId: track.id,
                  limit: 24,
                  since: const Duration(hours: 2),
                )
              : await repository.getActiveCompanionRouteTail(
                  companionSessionId: companionSessionId,
                  profileId: track.id,
                  limit: 60,
                  since: const Duration(minutes: 45),
                );
          final routeTail = routePoints
              .map(
                (point) => LatLng(
                  point.sharedCoordinate.latitude,
                  point.sharedCoordinate.longitude,
                ),
              )
              .toList(growable: false);

          if (routeTail.length < 2) {
            return track;
          }
          return track.copyWith(routeTail: routeTail);
        } catch (_) {
          return track;
        }
      }),
    );
  }

  void _connectAuthRefresh() {
    if (!_supportsNativeLocation || widget.backendConfig?.hasSupabase != true) {
      return;
    }

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.session == null) {
        widget.locationBridge.clearUploadConfig();
        if (mounted) {
          setState(() {
            _bridgeStatus = _l10n.uploadDeviceDisconnected;
            _uploadStatus = _l10n.uploadNeedsSignIn;
            _uploadPendingCount = null;
          });
        }
        return;
      }
      _configureNativeUpload();
    });
  }

  Future<void> _configureNativeUpload() async {
    final deviceRepository = widget.deviceRepository;
    final backendConfig = widget.backendConfig;
    if (!_supportsNativeLocation ||
        deviceRepository == null ||
        backendConfig == null ||
        !backendConfig.hasSupabase) {
      return;
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final profileId = client.auth.currentUser?.id;
    if (session == null || profileId == null) {
      await widget.locationBridge.clearUploadConfig();
      if (mounted) {
        setState(() => _uploadStatus = _l10n.uploadNeedsSignIn);
      }
      return;
    }

    try {
      final registeredDevice = await deviceRepository.registerDevice(
        platform: defaultTargetPlatform == TargetPlatform.android
            ? DevicePlatform.android
            : DevicePlatform.ios,
        appVersion: '0.1.0+1',
      );
      await widget.locationBridge.configureUpload(
        NativeUploadConfig(
          supabaseUrl: backendConfig.supabaseUrl,
          publishableKey: backendConfig.supabaseAnonKey,
          accessToken: session.accessToken,
          profileId: profileId,
          deviceId: registeredDevice.id,
        ),
      );
      if (mounted) {
        setState(() {
          _bridgeStatus = _l10n.uploadDeviceReady;
          _uploadStatus = _l10n.uploadQueueReady;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bridgeStatus = _l10n.uploadDeviceConfigPending;
          _uploadStatus = _l10n.uploadQueueConfigPending;
        });
      }
    }
  }

  void _connectDeviceLocation() {
    if (!_supportsNativeLocation) {
      _bridgeStatus = _l10n.deviceLocationBridgeNote;
      return;
    }

    _deviceLocationSubscription = widget.locationBridge.events.listen(
      (event) {
        if (!mounted) {
          return;
        }

        final type = '${event['type'] ?? ''}';
        if (type == 'location.updated') {
          final track = _deviceTrackFromEvent(event);
          if (track == null) {
            return;
          }
          setState(() {
            _deviceTrack = track;
            _deviceRoute = track.routeTail;
            _bridgeStatus = _l10n.deviceReceiving;
          });
        } else if (type == 'permission.changed') {
          setState(() => _bridgeStatus = _l10n.devicePermissionChecked);
        } else if (type == 'geofence.entered' ||
            type == 'geofence.exited' ||
            type == 'geofence.transition') {
          final message = _geofenceStatusText(_l10n, type);
          setState(() {
            _bridgeStatus = message;
            _placeAlertStatusMessage = message;
          });
          unawaited(_recordPlaceAlertTransition(event, type));
        } else if (type == 'service.statusChanged') {
          final status = '${event['status'] ?? ''}';
          final statusText = _serviceStatusText(event);
          final pendingCount = _intFromEvent(event['pendingCount']);
          setState(() {
            _bridgeStatus = statusText;
            if (status.startsWith('upload_')) {
              _uploadStatus = statusText;
              _uploadPendingCount = pendingCount ?? _uploadPendingCount;
            }
          });
        } else if (type == 'location.error') {
          final code = '${event['code'] ?? ''}';
          final message = '${event['message'] ?? _l10n.deviceLocationError}';
          final pendingCount = _intFromEvent(event['pendingCount']);
          setState(() {
            _bridgeStatus = message;
            if (code.startsWith('upload_')) {
              _uploadStatus = message;
              _uploadPendingCount = pendingCount ?? _uploadPendingCount;
            }
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() => _bridgeStatus = _l10n.deviceBridgeFailed);
        }
      },
    );
  }

  Future<void> _recordPlaceAlertTransition(
    Map<Object?, Object?> event,
    String type,
  ) async {
    final repository = widget.placeAlertRepository;
    final eventType = _placeAlertEventTypeFromGeofenceType(type);
    if (repository == null ||
        eventType == null ||
        widget.backendConfig?.hasSupabase != true ||
        Supabase.instance.client.auth.currentSession == null) {
      return;
    }

    final occurredAt =
        DateTime.tryParse('${event['recordedAt']}') ?? DateTime.now();
    final geofenceIds = _geofenceIdsFromEvent(event);
    for (final alertId in geofenceIds) {
      try {
        await repository.recordPlaceAlertEvent(
          alertId: alertId,
          eventType: eventType,
          occurredAt: occurredAt,
          dedupeKey:
              '$alertId:${eventType.name}:${occurredAt.toUtc().toIso8601String().substring(0, 16)}',
        );
      } catch (_) {
        // Native transition UX should not be blocked by best-effort audit upload.
      }
    }
  }

  Future<void> _startCompanionSession(Duration duration) async {
    if (!_supportsNativeLocation) {
      setState(() => _bridgeStatus = _l10n.deviceLocationBuildOnly);
      return;
    }

    final expiresAt = DateTime.now().add(duration);
    try {
      final companionSessionId =
          await _createBackendCompanionSession(expiresAt);
      final config = _companionConfig(
        duration,
        companionSessionId: companionSessionId,
      );
      // 물러나면 OS 대화상자를 띄우지 않는다. 물어보지 않으면 기회가 남는다.
      if (!mounted) return;
      final allowed = await showPermissionPrimer(
        context,
        purpose: PermissionPurpose.whileUsing,
      );
      if (!allowed) return;

      await widget.locationBridge.requestWhenInUse();
      await widget.locationBridge.startLocationSession(config);
      if (!mounted) {
        return;
      }
      setState(() {
        _isCompanionActive = true;
        _activeCompanionSessionId = companionSessionId;
        _bridgeStatus = companionSessionId == null
            ? _l10n.companionStarted
            : _l10n.companionStartedWithSession;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _bridgeStatus = _l10n.companionStartFailed);
      }
    }
  }

  Future<void> _stopCompanionSession() async {
    try {
      await widget.locationBridge
          .stopLocationSession(reason: 'user_stopped_companion_mode');
    } catch (_) {
      // Preview runtimes may not have a native location bridge.
    }
    await _endBackendCompanionSession(reason: 'user_stopped_companion_mode');
    if (mounted) {
      setState(() {
        _isCompanionActive = false;
        _activeCompanionSessionId = null;
        _bridgeStatus = _l10n.companionStopped;
      });
    }
  }

  /// 정형 반응을 서클에 보낸다.
  ///
  /// 도착 확인은 동행 세션을 끝내는 부수 효과가 있어 기존 경로를 그대로 탄다.
  /// 나머지 셋은 이벤트만 남긴다 — '가는 중'으로 공유가 꺼지면 마침 필요한
  /// 순간에 위치가 사라진다. 같은 규칙이 마이그레이션 016 에도 있다.
  Future<void> _sendQuickReply(CheckInStatus status) async {
    if (status.endsCompanionSession) {
      await _sendArrivalCheckIn();
      return;
    }

    final circleId = _activeCircleId;
    final repository = widget.checkInRepository;
    if (repository == null || circleId == null) {
      setState(() => _checkInStatusMessage = _l10n.quickReplyNeedsCircle);
      return;
    }

    setState(() => _sendingQuickReply = status);
    try {
      final saved = await repository.performCheckIn(
        circleId: circleId,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _lastCheckInEvent = saved;
        _checkInStatusMessage = _l10n.quickReplySent(status.label(_l10n));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkInStatusMessage = _l10n.quickReplyFailed);
    } finally {
      if (mounted) setState(() => _sendingQuickReply = null);
    }
  }

  Future<void> _sendArrivalCheckIn() async {
    final circleId = _activeCircleId;
    setState(() {
      _isCheckingIn = true;
      _checkInStatusMessage = _l10n.companionCheckInSending;
    });

    CheckInEvent? savedEvent;
    try {
      if (widget.checkInRepository != null && circleId != null) {
        savedEvent = await widget.checkInRepository!.performCheckIn(
          circleId: circleId,
          companionSessionId: _activeCompanionSessionId,
        );
      } else {
        await _endBackendCompanionSession(reason: 'manual_check_in');
      }

      try {
        await widget.locationBridge
            .stopLocationSession(reason: 'manual_check_in');
      } catch (_) {
        // Preview runtimes may not have a native location bridge.
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isCompanionActive = false;
        _activeCompanionSessionId = null;
        _lastCheckInEvent = savedEvent ??
            CheckInEvent(
              id: 'local-${DateTime.now().microsecondsSinceEpoch}',
              circleId: circleId ?? 'local',
              actorProfileId: 'device-me',
              subjectProfileId: 'device-me',
              displayName: _l10n.mapMeShort,
              status: CheckInStatus.safeArrived,
              sharingMode: SharingMode.balanced,
              createdAt: DateTime.now(),
            );
        _deviceRoute = const [];
        _deviceTrack = _deviceTrack?.copyWith(
          statusOverride: _l10n.deviceArrivedStatus,
          metaOverride: _l10n.deviceArrivedMeta,
          routeTail: const [],
          isStale: false,
          hasLowBattery: false,
        );
        _bridgeStatus = _l10n.companionArrivedSent;
        _checkInStatusMessage = _bridgeStatus;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _checkInStatusMessage = _l10n.companionCheckInFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingIn = false);
      }
    }
  }

  void _openMemberSheet(MapMemberTrack member) {
    setState(() => _selectedMemberId = member.id);
    showMemberSheet(
      context,
      member: member,
      onOpenViewerLog: () {
        Navigator.of(context).pop();
        widget.onOpenCircle?.call();
      },
    ).whenComplete(() {
      if (mounted) setState(() => _selectedMemberId = null);
    });
  }

  /// 길게 누르기로 무장한 뒤 취소 유예를 준다. 탭 한 번으로는 나가지 않는다.
  Future<void> _armSos() async {
    final audience = _circleName ?? _l10n.mapDefaultCircleName;
    final confirmed = await showSosCountdown(context, audienceLabel: audience);
    if (!confirmed || !mounted) return;
    await _requestSosFix();
  }

  Future<void> _requestSosFix() async {
    if (!_supportsNativeLocation) {
      setState(() => _bridgeStatus = _l10n.sosBuildOnly);
      return;
    }

    try {
      // 여기에는 사전 안내를 넣지 않는다. 긴급한 사람에게 설명 시트를 읽힐 수
      // 없다. 그래서 온보딩에서 미리 받아 두는 것이 중요하다.
      await widget.locationBridge.requestWhenInUse();
      await widget.locationBridge.requestSosFix();
      if (mounted) {
        setState(() => _bridgeStatus = _l10n.sosRequesting);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _bridgeStatus = _l10n.sosRequestFailed);
      }
    }
  }

  Future<void> _flushPendingLocations() async {
    if (!_supportsNativeLocation) {
      setState(() => _uploadStatus = _l10n.uploadBuildOnly);
      return;
    }

    setState(() {
      _isUploadFlushRunning = true;
      _uploadStatus = _l10n.uploadQueueRequesting;
    });

    try {
      await widget.locationBridge.flushPendingLocations();
      if (mounted) {
        setState(() => _uploadStatus = _l10n.uploadQueueRequested);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploadStatus = _l10n.uploadQueueRequestFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadFlushRunning = false);
      }
    }
  }

  Future<String?> _createBackendCompanionSession(DateTime expiresAt) async {
    final companionRepository = widget.companionRepository;
    final circleId = _activeCircleId;
    final profileId = Supabase.instance.client.auth.currentUser?.id;
    if (companionRepository == null || circleId == null || profileId == null) {
      return null;
    }

    final sessionId = await companionRepository.createSession(
      circleId: circleId,
      subjectProfileId: profileId,
      expiresAt: expiresAt,
    );
    await companionRepository.consentToSession(sessionId);
    await companionRepository.activateSession(sessionId);
    return sessionId;
  }

  Future<void> _endBackendCompanionSession({required String reason}) async {
    final companionRepository = widget.companionRepository;
    final sessionId = _activeCompanionSessionId;
    if (companionRepository == null || sessionId == null) {
      return;
    }

    try {
      await companionRepository.endSession(
          sessionId: sessionId, reason: reason);
    } catch (_) {
      if (mounted) {
        setState(() => _bridgeStatus = _l10n.companionEndSyncPending);
      }
    }
  }

  LocationSessionConfig _companionConfig(
    Duration duration, {
    String? companionSessionId,
  }) {
    return LocationSessionConfig(
      mode: LocationSessionMode.companion,
      reason: 'user_started_companion_mode',
      desiredAccuracyM: 25,
      minDistanceM: 15,
      minIntervalSeconds: 20,
      companionSessionId: companionSessionId,
      sharingPolicy: SharingPolicy(
        enabled: true,
        mode: SharingMode.balanced,
        expiresAt: DateTime.now().add(duration),
      ),
    );
  }

  Set<String> _reconciledPlaceTargetIds(
    Set<String> current,
    List<MapMemberTrack> candidates,
  ) {
    final candidateIds = candidates.map((member) => member.id).toSet();
    final kept = current.where(candidateIds.contains).toSet();
    if (kept.isNotEmpty) {
      return kept;
    }

    for (final member in candidates) {
      if (member.isCurrentUser) {
        return {member.id};
      }
    }

    if (candidates.isNotEmpty) {
      return {candidates.first.id};
    }
    return const {};
  }

  void _togglePlaceTarget(String profileId, bool selected) {
    setState(() {
      final next = {..._placeDraftTargetIds};
      if (selected) {
        next.add(profileId);
      } else {
        next.remove(profileId);
      }
      _placeDraftTargetIds = next;
    });
  }

  void _setPlaceNotification({
    bool? arrival,
    bool? departure,
    bool? late,
    bool? longStay,
  }) {
    setState(() {
      final nextArrival = arrival ?? _placeNotifyArrival;
      final nextDeparture = departure ?? _placeNotifyDeparture;
      final nextLate = late ?? _placeNotifyLate;
      final nextLongStay = longStay ?? _placeNotifyLongStay;
      if (!(nextArrival || nextDeparture || nextLate || nextLongStay)) {
        _placeAlertStatusMessage = _l10n.placeAlertNeedsRule;
        _placeAlertStatusIsError = true;
        return;
      }
      _placeNotifyArrival = nextArrival;
      _placeNotifyDeparture = nextDeparture;
      _placeNotifyLate = nextLate;
      _placeNotifyLongStay = nextLongStay;
      _placeAlertStatusMessage = null;
      _placeAlertStatusIsError = false;
    });
  }

  Future<void> _savePlaceAlert({
    required LatLng center,
    required List<MapMemberTrack> candidates,
  }) async {
    final repository = widget.placeAlertRepository;
    final circleId = _activeCircleId;
    final targetIds = _reconciledPlaceTargetIds(
      _placeDraftTargetIds,
      candidates,
    ).toList(growable: false);
    final name = _placeAlertNameController.text.trim();

    if (repository == null || circleId == null) {
      setState(() {
        _placeAlertStatusMessage = _l10n.placeAlertNeedsBackend;
        _placeAlertStatusIsError = true;
      });
      return;
    }
    if (targetIds.isEmpty) {
      setState(() {
        _placeAlertStatusMessage = _l10n.placeAlertPickTarget;
        _placeAlertStatusIsError = true;
      });
      return;
    }
    if (name.isEmpty) {
      setState(() {
        _placeAlertStatusMessage = _l10n.placeAlertNeedsName;
        _placeAlertStatusIsError = true;
      });
      return;
    }

    setState(() {
      _isSavingPlaceAlert = true;
      _placeAlertStatusMessage = _l10n.placeDraftSaving;
      _placeAlertStatusIsError = false;
    });

    try {
      final alert = await repository.createPlaceAlert(
        PlaceAlertDraft(
          circleId: circleId,
          name: name,
          center: Coordinate(
            latitude: center.latitude,
            longitude: center.longitude,
          ),
          radiusM: _placeDraftRadiusM,
          targetProfileIds: targetIds,
          notifyOnArrival: _placeNotifyArrival,
          notifyOnDeparture: _placeNotifyDeparture,
          notifyOnLate: _placeNotifyLate,
          notifyOnLongStay: _placeNotifyLongStay,
          quietHours: _quietHoursFromPreset(_l10n, _placeQuietHoursPreset),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _placeAlertStatusMessage =
            _l10n.placeAlertSaved(alert.name, alert.targetCount);
        _isPlaceDraftVisible = true;
      });
      await _syncPlaceAlertGeofences(circleId, askForBackground: true);
    } catch (_) {
      if (mounted) {
        setState(() => _placeAlertStatusMessage = _l10n.placeAlertSaveFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPlaceAlert = false);
      }
    }
  }

  /// 장소 알림을 막 저장한 직후에만 백그라운드 위치를 묻는다. 방금 한 행동과
  /// 이어져야 왜 필요한지가 납득된다.
  Future<void> _syncPlaceAlertGeofences(
    String circleId, {
    bool askForBackground = false,
  }) async {
    final repository = widget.placeAlertRepository;
    if (!_supportsNativeLocation || repository == null) {
      return;
    }

    try {
      var allowBackground = false;
      if (askForBackground && mounted) {
        allowBackground = await showPermissionPrimer(
          context,
          purpose: PermissionPurpose.background,
        );
      }

      final registeredCount = await syncPlaceAlertGeofences(
        repository: repository,
        locationBridge: widget.locationBridge,
        circleId: circleId,
        requestBackgroundPermission: allowBackground,
      );
      if (mounted) {
        setState(() => _bridgeStatus = registeredCount == 0
            ? _l10n.placeAlertUnregistered
            : _l10n.placeAlertRegistered(registeredCount ?? 0));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _bridgeStatus = _l10n.placeAlertSavedPendingDevice);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final demoTracks = demoMapTracks(_l10n);
    final hasNoCircle =
        widget.circleRepository != null && _hasServerCircle == false;
    final isLive = _serverTracks.isNotEmpty;
    final baseTracks = hasNoCircle
        ? const <MapMemberTrack>[]
        : isLive
            ? _serverTracks
            : demoTracks;
    final tracks = _mergeDeviceTrack(baseTracks);
    final placeTargetCandidates =
        isLive ? baseTracks : const <MapMemberTrack>[];
    final effectivePlaceTargetIds =
        _reconciledPlaceTargetIds(_placeDraftTargetIds, placeTargetCandidates);
    final canSavePlaceAlert = widget.placeAlertRepository != null &&
        _activeCircleId != null &&
        placeTargetCandidates.isNotEmpty &&
        effectivePlaceTargetIds.isNotEmpty &&
        !_isSavingPlaceAlert;
    final circleTitle = _circleName ?? l10n.mapDefaultCircleName;
    final companionConfig = _companionConfig(const Duration(minutes: 15));
    final draftPlacePoint = tracks.isEmpty
        ? const LatLng(37.50768, 127.04382)
        : tracks
            .firstWhere((member) => member.isCurrentUser,
                orElse: () => tracks.first)
            .point;

    final otherMembers =
        tracks.where((member) => !member.isCurrentUser).toList();
    final sheetPeek = MediaQuery.sizeOf(context).height * 0.30;

    // 지도가 화면 그 자체다. 예전처럼 스크롤 문서 안의 카드가 아니다.
    return Stack(
      children: [
        Positioned.fill(
          // 마커만 보간한다. 시트의 멤버 목록은 원래 좌표를 그대로 읽는다.
          child: AnimatedMemberTracks(
            members: tracks,
            builder: (context, animated) => _MapSurface(
              members: animated,
              selectedId: _selectedMemberId,
              placeDraftPoint: _isPlaceDraftVisible ? draftPlacePoint : null,
              placeDraftRadiusM: _placeDraftRadiusM,
              onSelectMember: _openMemberSheet,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 8,
          child: Row(
            // Flexible 과 Spacer 를 함께 두면 남은 폭을 반씩 나눠 가져
            // 버튼이 화면 가운데로 밀린다.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: MapCircleChip(
                  label: circleTitle,
                  onTap: widget.onOpenCircle,
                ),
              ),
              MapIconButton(
                icon: Icons.layers_outlined,
                tooltip: l10n.mapLayersTooltip,
                onPressed: null,
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 64,
          child: MemberAvatarRail(
            members: tracks,
            selectedId: _selectedMemberId,
            onSelect: _openMemberSheet,
            onInvite: () => widget.onOpenCircle?.call(),
          ),
        ),
        Positioned(
          right: 16,
          bottom: sheetPeek + 16,
          child: SosButton(onArmed: _armSos),
        ),
        DraggableScrollableSheet(
          // 시작 크기는 snapSizes 안에 있어야 한다. 밖에 두면 첫 드래그가
          // 가장 가까운 지점으로 튀어, 시트가 손에 안 잡히는 느낌이 된다.
          initialChildSize: 0.30,
          minChildSize: 0.16,
          maxChildSize: 0.92,
          snap: true,
          snapSizes: const [0.16, 0.30, 0.62, 0.92],
          builder: (context, controller) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(GyeoteRadius.sheet),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: palette.line,
                        borderRadius: BorderRadius.circular(GyeoteRadius.pill),
                      ),
                    ),
                  ),
                  _SheetStatusLine(
                    memberCount: tracks.length,
                    attentionCount: tracks
                        .where((m) => m.isStale || m.hasLowBattery)
                        .length,
                    isLoading: _isLoading,
                    loadError: _loadError,
                    hasNoCircle: hasNoCircle,
                    isDemo: !isLive && widget.circleRepository != null,
                    bridgeStatus: _bridgeStatus,
                  ),
                  const SizedBox(height: 10),
                  for (final member in otherMembers)
                    _MemberTile(
                      member: member,
                      onTap: () => _openMemberSheet(member),
                    ),
                  const SizedBox(height: 4),
                  QuickReplyBar(
                    onSend: _sendQuickReply,
                    isEnabled: !hasNoCircle && !_isCheckingIn,
                    sending: _sendingQuickReply,
                  ),
                  if (hasNoCircle) ...[
                    const SizedBox(height: 12),
                    _MapOnboardingPanel(onOpenCircle: widget.onOpenCircle),
                  ],
                  const SizedBox(height: 4),
                  _CompanionPanel(
                    config: companionConfig,
                    isActive: _isCompanionActive,
                    uploadStatus: _uploadStatus ?? _bridgeStatus,
                    uploadPendingCount: _uploadPendingCount,
                    checkInStatus: _checkInStatusMessage,
                    lastCheckInText: _lastCheckInEvent == null
                        ? null
                        : _checkInEventText(l10n, _lastCheckInEvent!),
                    isFlushAvailable: _supportsNativeLocation,
                    isFlushing: _isUploadFlushRunning,
                    isCheckingIn: _isCheckingIn,
                    onStart15: () =>
                        _startCompanionSession(const Duration(minutes: 15)),
                    onStartUntilArrival: () =>
                        _startCompanionSession(const Duration(minutes: 45)),
                    onStop: _stopCompanionSession,
                    onCheckIn: _sendArrivalCheckIn,
                    onFlush: () => _flushPendingLocations(),
                  ),
                  const SizedBox(height: 12),
                  _PlaceDraftPanel(
                    nameController: _placeAlertNameController,
                    radiusM: _placeDraftRadiusM,
                    isVisible: _isPlaceDraftVisible,
                    targetCandidates: placeTargetCandidates,
                    selectedTargetIds: effectivePlaceTargetIds,
                    notifyArrival: _placeNotifyArrival,
                    notifyDeparture: _placeNotifyDeparture,
                    notifyLate: _placeNotifyLate,
                    notifyLongStay: _placeNotifyLongStay,
                    quietHoursPreset: _placeQuietHoursPreset,
                    statusMessage: _placeAlertStatusMessage,
                    statusIsError: _placeAlertStatusIsError,
                    canSave: canSavePlaceAlert,
                    isSaving: _isSavingPlaceAlert,
                    onVisibilityChanged: (visible) =>
                        setState(() => _isPlaceDraftVisible = visible),
                    onRadiusChanged: (radius) =>
                        setState(() => _placeDraftRadiusM = radius),
                    onTargetChanged: _togglePlaceTarget,
                    onNotifyArrivalChanged: (value) =>
                        _setPlaceNotification(arrival: value),
                    onNotifyDepartureChanged: (value) =>
                        _setPlaceNotification(departure: value),
                    onNotifyLateChanged: (value) =>
                        _setPlaceNotification(late: value),
                    onNotifyLongStayChanged: (value) =>
                        _setPlaceNotification(longStay: value),
                    onQuietHoursPresetChanged: (value) =>
                        setState(() => _placeQuietHoursPreset = value),
                    onSave: () => _savePlaceAlert(
                      center: draftPlacePoint,
                      candidates: placeTargetCandidates,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  List<MapMemberTrack> _mergeDeviceTrack(List<MapMemberTrack> baseTracks) {
    final deviceTrack = _deviceTrack;
    if (deviceTrack == null) {
      return baseTracks;
    }

    return [
      deviceTrack,
      ...baseTracks.where(
          (member) => member.id != deviceTrack.id && !member.isCurrentUser),
    ];
  }

  MapMemberTrack? _deviceTrackFromEvent(Map<Object?, Object?> event) {
    final point = _pointFromMap(event['sharedCoordinate']);
    if (point == null) {
      return null;
    }

    final route = [..._deviceRoute, point];
    final trimmedRoute =
        route.length > 30 ? route.sublist(route.length - 30) : route;
    final recordedAt =
        DateTime.tryParse('${event['recordedAt'] ?? ''}') ?? DateTime.now();
    final age = DateTime.now().difference(recordedAt);
    final isStale = age > const Duration(minutes: 5);
    final accuracy =
        event['accuracyM'] is num ? (event['accuracyM'] as num).round() : null;
    final battery = event['batteryPercent'] is num
        ? (event['batteryPercent'] as num).round()
        : null;
    final hasLowBattery = battery != null && battery <= 15;

    return MapMemberTrack(
      id: 'device-me',
      name: _l10n.mapMeShort,
      point: point,
      tone: GyeoteTone.brand,
      recordedAt: recordedAt,
      sharingMode: SharingMode.balanced,
      routeTail: isStale ? const [] : trimmedRoute,
      isCurrentUser: true,
      isStale: isStale,
      hasLowBattery: hasLowBattery,
      batteryPercent: battery,
      accuracyM: accuracy?.toDouble(),
    );
  }

  LatLng? _pointFromMap(Object? value) {
    if (value is! Map) {
      return null;
    }

    final latitude = value['latitude'];
    final longitude = value['longitude'];
    if (latitude is! num || longitude is! num) {
      return null;
    }
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }

  String _serviceStatusText(Map<Object?, Object?> event) {
    final status = '${event['status'] ?? _l10n.checkInStatusChanged}';
    final uploadedCount = _intFromEvent(event['uploadedCount']);
    final retryInSeconds = _intFromEvent(event['retryInSeconds']);

    switch (status) {
      case 'started':
        return _l10n.deviceSharingRunning;
      case 'stopped':
        return _l10n.deviceSharingStopped;
      case 'policy_paused':
        return _l10n.sharingPausedByPolicy;
      case 'provider_enabled':
        return _l10n.deviceLocationServiceAvailable;
      case 'sos_requested':
        return _l10n.sosRequesting;
      case 'geofences_registered':
        return _l10n.placeAlertReady;
      case 'upload_not_configured':
        return _l10n.uploadQueueConfigPending;
      case 'upload_configured':
        return _l10n.uploadQueueReady;
      case 'upload_queue_empty':
        return _l10n.uploadNothingPending;
      case 'upload_already_running':
        return _l10n.uploadQueueSyncing;
      case 'upload_flushed':
        return _l10n.uploadCompleted(uploadedCount ?? 0);
      case 'upload_retry_wait':
        return _l10n.uploadRetryIn(retryInSeconds ?? 0);
      case 'upload_retry_scheduled':
        return _l10n.uploadFailedRetryScheduled;
      case 'upload_ios_queue_pending':
        return _l10n.uploadIosPending;
      default:
        return _l10n.deviceLocationService(status);
    }
  }

  int? _intFromEvent(Object? value) {
    if (value is num) {
      return value.round();
    }
    return int.tryParse('$value');
  }
}

String _relativeTimeLabel(AppL10n l10n, DateTime recordedAt) {
  final diff = DateTime.now().difference(recordedAt);
  if (diff.inSeconds < 60) {
    return l10n.agoJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.agoMinutes(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.agoHours(diff.inHours);
  }
  return l10n.agoDays(diff.inDays);
}

String _checkInEventText(AppL10n l10n, CheckInEvent event) {
  final status = event.status.label(l10n);
  return l10n.checkInEventLine(
    event.displayName.isEmpty ? l10n.memberFallbackName : event.displayName,
    status,
    _relativeTimeLabel(l10n, event.createdAt),
  );
}

String _precisionText(AppL10n l10n, MapMemberTrack member) {
  final radiusLabel = _radiusLabel(member);
  final modeLabel = switch (member.sharingMode) {
    SharingMode.precise => l10n.precisionExactLocation,
    SharingMode.balanced => l10n.precisionBalancedLocation,
    SharingMode.area => l10n.sharingModeArea,
    SharingMode.hidden => l10n.sharingHidden,
    SharingMode.sosOnly => l10n.sharingModeSosOnly,
  };

  if (member.isStale) {
    return l10n.precisionRangeStale(modeLabel, radiusLabel);
  }
  return l10n.precisionRange(modeLabel, radiusLabel);
}

String _radiusLabel(MapMemberTrack member) {
  final radius =
      member.accuracyM ?? _defaultRadiusForSharingMode(member.sharingMode);
  if (radius >= 1000) {
    return '${(radius / 1000).toStringAsFixed(1)}km';
  }
  return '${radius.round()}m';
}

double _defaultRadiusForSharingMode(SharingMode mode) {
  switch (mode) {
    case SharingMode.precise:
      return 45;
    case SharingMode.balanced:
      return 180;
    case SharingMode.area:
      return 500;
    case SharingMode.hidden:
      return 900;
    case SharingMode.sosOnly:
      return 120;
  }
}

class _MapSurface extends StatelessWidget {
  const _MapSurface({
    required this.members,
    required this.selectedId,
    required this.placeDraftPoint,
    required this.placeDraftRadiusM,
    required this.onSelectMember,
  });

  final List<MapMemberTrack> members;
  final String? selectedId;
  final LatLng? placeDraftPoint;
  final int placeDraftRadiusM;
  final ValueChanged<MapMemberTrack> onSelectMember;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final routeMembers = members
        .where((member) => !member.isStale && member.routeTail.length > 1)
        .toList();
    // 선택된 멤버는 아바타 아래 이름 라벨이 붙는다. 마커 상자를 고정하면
    // OS 글자 크기를 키웠을 때 그 라벨이 잘린다.
    final markerExtent =
        (52 + 12 + MediaQuery.textScalerOf(context).scale(11) * 1.45)
            .clamp(88.0, 160.0);
    final initialCenter = members.isEmpty
        ? const LatLng(37.50768, 127.04382)
        : members
            .firstWhere((member) => member.isCurrentUser,
                orElse: () => members.first)
            .point;

    return ColoredBox(
      color: palette.mapLand,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.7,
              minZoom: 5,
              maxZoom: 18,
              keepAlive: true,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              // 타일만 야간 처리한다. 마커·경로·반경은 팔레트 색 그대로 위에 얹힌다.
              NightTiles(
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gyeote.app',
                  maxNativeZoom: 19,
                ),
              ),
              CircleLayer(
                circles: [
                  if (placeDraftPoint != null)
                    CircleMarker(
                      point: placeDraftPoint!,
                      radius: placeDraftRadiusM.toDouble(),
                      useRadiusInMeter: true,
                      color: palette.brand.withValues(alpha: 0.10),
                      borderColor: palette.brand.withValues(alpha: 0.72),
                      borderStrokeWidth: 2,
                    ),
                  for (final member in members)
                    CircleMarker(
                      point: member.point,
                      radius: _precisionRadiusM(member),
                      useRadiusInMeter: true,
                      color: _precisionFillColor(member, palette),
                      borderColor: _precisionBorderColor(member, palette),
                      borderStrokeWidth: member.isStale ? 2 : 1.5,
                    ),
                ],
              ),
              if (routeMembers.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    for (final member in routeMembers)
                      Polyline(
                        points: member.routeTail,
                        color: member.tone.resolve(palette),
                        strokeWidth: member.isCurrentUser ? 6 : 5,
                        borderColor: Colors.white,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final member in members)
                    Marker(
                      point: member.point,
                      width: markerExtent,
                      height: markerExtent,
                      child: MemberMarker(
                        member: member,
                        isSelected: member.id == selectedId,
                        onTap: () => onSelectMember(member),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // ODbL 상 출처 표기는 뺄 수 없다. 시트에 가리지 않는 자리에 둔다.
          const Positioned(
            left: 14,
            bottom: 10,
            child: MapAttribution(),
          ),
        ],
      ),
    );
  }

  double _precisionRadiusM(MapMemberTrack member) {
    if (member.isStale) {
      return _radiusForSharingMode(member.sharingMode)
          .clamp(160, 800)
          .toDouble();
    }

    final accuracy = member.accuracyM;
    if (accuracy != null && accuracy > 0) {
      return accuracy.clamp(35, 1200).toDouble();
    }

    return _radiusForSharingMode(member.sharingMode);
  }

  double _radiusForSharingMode(SharingMode mode) {
    return _defaultRadiusForSharingMode(mode);
  }

  Color _precisionFillColor(MapMemberTrack member, GyeotePalette palette) {
    return memberStateTone(member).resolve(palette).withValues(
          alpha: member.isStale ? 0.08 : 0.11,
        );
  }

  Color _precisionBorderColor(MapMemberTrack member, GyeotePalette palette) {
    return memberStateTone(member).resolve(palette).withValues(
          alpha: member.isStale ? 0.65 : 0.42,
        );
  }
}

class _MapOnboardingPanel extends StatelessWidget {
  const _MapOnboardingPanel({required this.onOpenCircle});

  final VoidCallback? onOpenCircle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: palette.brandSoft,
            ),
            child: Icon(Icons.group_add_outlined, color: palette.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.mapOnboardTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(l10n.mapOnboardBody,
                    style: TextStyle(color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onOpenCircle,
            icon: const Icon(Icons.arrow_forward_outlined),
            label: Text(l10n.mapOpenCircle),
          ),
        ],
      ),
    );
  }
}

class _PlaceDraftPanel extends StatelessWidget {
  const _PlaceDraftPanel({
    required this.nameController,
    required this.radiusM,
    required this.isVisible,
    required this.targetCandidates,
    required this.selectedTargetIds,
    required this.notifyArrival,
    required this.notifyDeparture,
    required this.notifyLate,
    required this.notifyLongStay,
    required this.quietHoursPreset,
    required this.statusMessage,
    required this.statusIsError,
    required this.canSave,
    required this.isSaving,
    required this.onVisibilityChanged,
    required this.onRadiusChanged,
    required this.onTargetChanged,
    required this.onNotifyArrivalChanged,
    required this.onNotifyDepartureChanged,
    required this.onNotifyLateChanged,
    required this.onNotifyLongStayChanged,
    required this.onQuietHoursPresetChanged,
    required this.onSave,
  });

  final TextEditingController nameController;
  final int radiusM;
  final bool isVisible;
  final List<MapMemberTrack> targetCandidates;
  final Set<String> selectedTargetIds;
  final bool notifyArrival;
  final bool notifyDeparture;
  final bool notifyLate;
  final bool notifyLongStay;
  final _PlaceQuietHoursPreset quietHoursPreset;
  final String? statusMessage;
  final bool statusIsError;
  final bool canSave;
  final bool isSaving;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<int> onRadiusChanged;
  final void Function(String profileId, bool selected) onTargetChanged;
  final ValueChanged<bool> onNotifyArrivalChanged;
  final ValueChanged<bool> onNotifyDepartureChanged;
  final ValueChanged<bool> onNotifyLateChanged;
  final ValueChanged<bool> onNotifyLongStayChanged;
  final ValueChanged<_PlaceQuietHoursPreset> onQuietHoursPresetChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final hasTargets = targetCandidates.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: palette.brandSoft,
                ),
                child:
                    Icon(Icons.add_location_alt_outlined, color: palette.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.placeDraftTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(l10n.placeDraftSubtitle,
                        style: TextStyle(color: palette.muted, fontSize: 12)),
                  ],
                ),
              ),
              Switch(value: isVisible, onChanged: onVisibilityChanged),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.placeDraftNameLabel,
              prefixIcon: const Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: 100,
                  icon: Icon(Icons.trip_origin_outlined),
                  label: Text('100m'),
                ),
                ButtonSegment(
                  value: 300,
                  icon: Icon(Icons.radio_button_checked_outlined),
                  label: Text('300m'),
                ),
                ButtonSegment(
                  value: 500,
                  icon: Icon(Icons.adjust_outlined),
                  label: Text('500m'),
                ),
              ],
              selected: {radiusM},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) {
                  onRadiusChanged(values.first);
                  onVisibilityChanged(true);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!hasTargets)
                _PlaceDraftHint(text: l10n.placeAlertNeedsLiveCircle),
              for (final member in targetCandidates)
                FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: member.tone.resolveSoft(palette),
                    child: Text(
                      member.name.characters.first,
                      style: TextStyle(
                        color: member.tone.resolve(palette),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  label: Text(
                      member.isCurrentUser ? l10n.mapMeShort : member.name),
                  selected: selectedTargetIds.contains(member.id),
                  onSelected: (selected) =>
                      onTargetChanged(member.id, selected),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                avatar: const Icon(Icons.login_outlined, size: 18),
                label: Text(l10n.placeRuleArrival),
                selected: notifyArrival,
                onSelected: onNotifyArrivalChanged,
              ),
              FilterChip(
                avatar: const Icon(Icons.logout_outlined, size: 18),
                label: Text(l10n.placeRuleDeparture),
                selected: notifyDeparture,
                onSelected: onNotifyDepartureChanged,
              ),
              FilterChip(
                avatar: const Icon(Icons.schedule_outlined, size: 18),
                label: Text(l10n.placeRuleLate),
                selected: notifyLate,
                onSelected: onNotifyLateChanged,
              ),
              FilterChip(
                avatar: const Icon(Icons.timelapse_outlined, size: 18),
                label: Text(l10n.placeRuleLongStay),
                selected: notifyLongStay,
                onSelected: onNotifyLongStayChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_PlaceQuietHoursPreset>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _PlaceQuietHoursPreset.none,
                  icon: const Icon(Icons.notifications_none_outlined),
                  label: Text(l10n.quietHoursNone),
                ),
                ButtonSegment(
                  value: _PlaceQuietHoursPreset.night,
                  icon: const Icon(Icons.bedtime_outlined),
                  label: Text(l10n.quietHoursNight),
                ),
                ButtonSegment(
                  value: _PlaceQuietHoursPreset.schoolOrWork,
                  icon: const Icon(Icons.work_history_outlined),
                  label: Text(l10n.quietHoursClass),
                ),
              ],
              selected: {quietHoursPreset},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) {
                  onQuietHoursPresetChanged(values.first);
                }
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _quietHoursPresetCopy(l10n, quietHoursPreset),
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              statusMessage!,
              style: TextStyle(
                color: statusIsError ? palette.alert : palette.brand,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canSave
                  ? () async {
                      await onSave();
                    }
                  : null,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              label: Text(isSaving ? l10n.privacySaving : l10n.placeDraftSave),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceDraftHint extends StatelessWidget {
  const _PlaceDraftHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: palette.muted, fontSize: 12),
      ),
    );
  }
}

class _CompanionPanel extends StatelessWidget {
  const _CompanionPanel({
    required this.config,
    required this.isActive,
    required this.uploadStatus,
    required this.uploadPendingCount,
    required this.checkInStatus,
    required this.lastCheckInText,
    required this.isFlushAvailable,
    required this.isFlushing,
    required this.isCheckingIn,
    required this.onStart15,
    required this.onStartUntilArrival,
    required this.onStop,
    required this.onCheckIn,
    required this.onFlush,
  });

  final LocationSessionConfig config;
  final bool isActive;
  final String? uploadStatus;
  final int? uploadPendingCount;
  final String? checkInStatus;
  final String? lastCheckInText;
  final bool isFlushAvailable;
  final bool isFlushing;
  final bool isCheckingIn;
  final VoidCallback onStart15;
  final VoidCallback onStartUntilArrival;
  final VoidCallback onStop;
  final VoidCallback onCheckIn;
  final VoidCallback onFlush;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final expiresAt = config.sharingPolicy.expiresAt;
    final minutes = expiresAt == null
        ? 15
        : expiresAt.difference(DateTime.now()).inMinutes.clamp(1, 60);
    final uploadText = [
      uploadStatus ?? l10n.uploadQueueWaiting,
      if (uploadPendingCount != null)
        l10n.uploadPendingCount(uploadPendingCount!),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.brandSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.privacyCompanionMode,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              _StatusBadge(text: l10n.companionMinutesLeft(minutes)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.companionConfigNote(
              config.minIntervalSeconds,
              config.sharingPolicy.mode.name,
            ),
            style: TextStyle(color: palette.muted),
          ),
          const SizedBox(height: 12),
          if (isActive)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: isCheckingIn ? null : onCheckIn,
                    icon: isCheckingIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(l10n.companionCheckIn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isCheckingIn ? null : onStop,
                    child: Text(l10n.privacyPauseSharing),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: onStart15,
                        child: Text(l10n.companionFifteenMinutes))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: onStartUntilArrival,
                        child: Text(l10n.companionUntilArrival))),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onStart15,
                    child: Text(l10n.companionStart),
                  ),
                ),
              ],
            ),
          if (checkInStatus != null || lastCheckInText != null) ...[
            const SizedBox(height: 10),
            _SafetyStatusStrip(
              text: checkInStatus ?? lastCheckInText!,
              icon: Icons.verified_user_outlined,
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: palette.line),
              borderRadius: BorderRadius.circular(8),
              color: palette.surface,
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_sync_outlined, color: palette.move),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.uploadSyncTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(uploadText,
                          style: TextStyle(color: palette.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Tooltip(
                  message: l10n.uploadFlush,
                  child: IconButton.filledTonal(
                    onPressed: isFlushAvailable && !isFlushing ? onFlush : null,
                    icon: isFlushing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_outlined),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyStatusStrip extends StatelessWidget {
  const _SafetyStatusStrip({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.surface,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style:
                  TextStyle(color: palette.brand, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final MapMemberTrack member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final unit =
        RegionSettings.of(Localizations.localeOf(context)).distanceUnit;

    return Semantics(
      button: true,
      label: l10n.a11yMemberRow(member.name, member.status(l10n)),
      // 아래 시각 요소는 위 라벨이 이미 읽어 준다. 두 번 읽지 않게 묶는다.
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GyeoteRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MemberAvatar(member: member, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.status(l10n),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.meta(l10n, unit),
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    _MemberPrecisionLine(member: member),
                    if (member.safetyNote(l10n) != null) ...[
                      const SizedBox(height: 8),
                      _MemberSafetyNote(
                        text: member.safetyNote(l10n)!,
                        icon: member.isStale
                            ? Icons.wifi_off_outlined
                            : Icons.battery_alert_outlined,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberPrecisionLine extends StatelessWidget {
  const _MemberPrecisionLine({required this.member});

  final MapMemberTrack member;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    final text = _precisionText(l10n, member);
    return Row(
      children: [
        Icon(
          member.isStale
              ? Icons.history_outlined
              : Icons.radio_button_checked_outlined,
          size: 15,
          color: member.isStale ? palette.warm : palette.brand,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _MemberSafetyNote extends StatelessWidget {
  const _MemberSafetyNote({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: palette.warm),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// 방해 금지 프리셋.
///
/// `label` 은 DB 에 저장돼 다른 멤버에게도 보인다. 만든 사람의 언어로 굳는다는
/// 뜻이므로, 장기적으로는 라벨 대신 프리셋 키를 저장하고 읽는 쪽에서 번역해야
/// 한다. `timeZone` 도 지금 서울로 고정돼 있어 다른 지역에서는 조용한 시간대가
/// 어긋난다 — IANA 존을 구해 오도록 고쳐야 한다.
PlaceAlertQuietHours _quietHoursFromPreset(
  AppL10n l10n,
  _PlaceQuietHoursPreset preset,
) {
  switch (preset) {
    case _PlaceQuietHoursPreset.none:
      return const PlaceAlertQuietHours.none();
    case _PlaceQuietHoursPreset.night:
      return PlaceAlertQuietHours(
        enabled: true,
        start: '22:00',
        end: '07:00',
        timeZone: 'Asia/Seoul',
        label: l10n.quietHoursNight,
      );
    case _PlaceQuietHoursPreset.schoolOrWork:
      return PlaceAlertQuietHours(
        enabled: true,
        start: '09:00',
        end: '17:00',
        timeZone: 'Asia/Seoul',
        label: l10n.quietHoursClassOrWork,
      );
  }
}

String _quietHoursPresetCopy(AppL10n l10n, _PlaceQuietHoursPreset preset) {
  switch (preset) {
    case _PlaceQuietHoursPreset.none:
      return l10n.quietHoursNoneCopy;
    case _PlaceQuietHoursPreset.night:
      return l10n.quietHoursNightCopy;
    case _PlaceQuietHoursPreset.schoolOrWork:
      return l10n.quietHoursClassCopy;
  }
}

String _geofenceStatusText(AppL10n l10n, String type) {
  switch (type) {
    case 'geofence.entered':
      return l10n.placeAlertEnter;
    case 'geofence.exited':
      return l10n.placeAlertExit;
    default:
      return l10n.placeAlertTransition;
  }
}

PlaceAlertEventType? _placeAlertEventTypeFromGeofenceType(String type) {
  switch (type) {
    case 'geofence.entered':
      return PlaceAlertEventType.arrived;
    case 'geofence.exited':
      return PlaceAlertEventType.departed;
    default:
      return null;
  }
}

List<String> _geofenceIdsFromEvent(Map<Object?, Object?> event) {
  final ids = event['geofenceIds'];
  if (ids is List) {
    final parsed = ids
        .map((id) => id?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }

  final id = event['geofenceId']?.toString();
  if (id == null || id.isEmpty) {
    return const [];
  }
  return [id];
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: palette.surface,
      ),
      child: Text(text,
          style: TextStyle(
              color: palette.brand, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

/// 시트 상단의 상태 줄.
///
/// 예전에는 지도 위 헤더에 텍스트 네 줄이 쌓여 있었다. 지도를 가리지 않도록
/// 시트 안으로 들여왔다.
class _SheetStatusLine extends StatelessWidget {
  const _SheetStatusLine({
    required this.memberCount,
    required this.attentionCount,
    required this.isLoading,
    required this.loadError,
    required this.hasNoCircle,
    required this.isDemo,
    required this.bridgeStatus,
  });

  final int memberCount;
  final int attentionCount;
  final bool isLoading;
  final String? loadError;
  final bool hasNoCircle;
  final bool isDemo;
  final String? bridgeStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final (String? note, GyeoteTone tone) =
        switch ((loadError, isLoading, hasNoCircle, isDemo)) {
      (final String error, _, _, _) => (error, GyeoteTone.alert),
      (_, true, _, _) => (l10n.mapConnecting, GyeoteTone.muted),
      (_, _, true, _) => (l10n.mapNoCircle, GyeoteTone.muted),
      (_, _, _, true) => (l10n.mapDemoNotice, GyeoteTone.warm),
      _ => (bridgeStatus, GyeoteTone.muted),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.mapSharingCount(memberCount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ),
            if (attentionCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.warmSoft,
                  borderRadius: BorderRadius.circular(GyeoteRadius.pill),
                ),
                child: Text(
                  l10n.mapAttentionCount(attentionCount),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.warm,
                  ),
                ),
              ),
          ],
        ),
        if (note != null && note.isNotEmpty)
          Text(
            note,
            style: TextStyle(fontSize: 12, color: tone.resolve(palette)),
          ),
      ],
    );
  }
}
