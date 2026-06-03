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
import '../../theme/gyeote_theme.dart';
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
  bool _placeNotifyArrival = true;
  bool _placeNotifyDeparture = true;
  bool _placeNotifyLate = false;
  bool _placeNotifyLongStay = false;
  _PlaceQuietHoursPreset _placeQuietHoursPreset = _PlaceQuietHoursPreset.none;
  int _placeDraftRadiusM = 300;
  int _routeTailRequestSerial = 0;
  Set<String> _placeDraftTargetIds = const {};
  final _placeAlertNameController = TextEditingController(text: '새 장소');

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
            _loadError = '위치를 불러오지 못했습니다.';
          });
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = '서클을 불러오지 못했습니다.';
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
        setState(() => _checkInStatusMessage = '안전 확인 기록 동기화 대기 중');
      }
    }
  }

  Future<List<MapMemberTrack>> _tracksWithRouteTails({
    required CircleRepository repository,
    required String circleId,
    required List<MemberLocationSnapshot> snapshots,
  }) async {
    final tracks = mapTracksFromSnapshots(snapshots);
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
          return track.copyWith(
            routeTail: routeTail,
            meta:
                '${track.meta} · ${companionSessionId == null ? '경로' : '동행 경로'} ${routeTail.length}개 샘플',
          );
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
            _bridgeStatus = '기기 업로드 큐 연결 해제';
            _uploadStatus = '로그인 후 업로드 큐 연결';
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
        setState(() => _uploadStatus = '로그인 후 업로드 큐 연결');
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
          _bridgeStatus = '기기 업로드 큐 준비됨';
          _uploadStatus = '업로드 큐 준비됨';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bridgeStatus = '기기 업로드 큐 설정 대기 중';
          _uploadStatus = '업로드 큐 설정 대기 중';
        });
      }
    }
  }

  void _connectDeviceLocation() {
    if (!_supportsNativeLocation) {
      _bridgeStatus = '기기 위치는 Android/iOS 빌드에서 연결됩니다.';
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
            _bridgeStatus = '내 위치 수신 중';
          });
        } else if (type == 'permission.changed') {
          setState(() => _bridgeStatus = '위치 권한 상태 확인됨');
        } else if (type == 'geofence.entered' ||
            type == 'geofence.exited' ||
            type == 'geofence.transition') {
          final message = _geofenceStatusText(type);
          setState(() {
            _bridgeStatus = message;
            _placeAlertStatusMessage = message;
          });
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
          final message = '${event['message'] ?? '위치 연결 오류'}';
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
          setState(() => _bridgeStatus = '기기 위치 브리지를 연결하지 못했습니다.');
        }
      },
    );
  }

  Future<void> _startCompanionSession(Duration duration) async {
    if (!_supportsNativeLocation) {
      setState(() => _bridgeStatus = 'Android/iOS 빌드에서 기기 위치를 사용할 수 있습니다.');
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
      await widget.locationBridge.requestWhenInUse();
      await widget.locationBridge.startLocationSession(config);
      if (!mounted) {
        return;
      }
      setState(() {
        _isCompanionActive = true;
        _activeCompanionSessionId = companionSessionId;
        _bridgeStatus = companionSessionId == null
            ? '동행 모드 위치 공유 시작'
            : '동행 모드 위치 공유 시작 · 세션 연결됨';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _bridgeStatus = '동행 모드를 시작하지 못했습니다.');
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
        _bridgeStatus = '동행 모드 위치 공유 중지';
      });
    }
  }

  Future<void> _sendArrivalCheckIn() async {
    final circleId = _activeCircleId;
    setState(() {
      _isCheckingIn = true;
      _checkInStatusMessage = '도착 확인을 보내는 중';
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
              displayName: '나',
              status: CheckInStatus.safeArrived,
              sharingMode: SharingMode.balanced,
              createdAt: DateTime.now(),
            );
        _deviceRoute = const [];
        _deviceTrack = _deviceTrack?.copyWith(
          status: '무사 도착 · 방금 확인',
          meta: '동행 공유 종료 · 균형 위치로 알림',
          routeTail: const [],
          isStale: false,
          hasLowBattery: false,
          clearSafetyNote: true,
        );
        _bridgeStatus = '무사 도착을 보냈어요. 동행 공유는 종료됐습니다.';
        _checkInStatusMessage = _bridgeStatus;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _checkInStatusMessage = '도착 확인을 보내지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingIn = false);
      }
    }
  }

  Future<void> _requestSosFix() async {
    if (!_supportsNativeLocation) {
      setState(() => _bridgeStatus = 'Android/iOS 빌드에서 긴급 위치를 보낼 수 있습니다.');
      return;
    }

    try {
      await widget.locationBridge.requestWhenInUse();
      await widget.locationBridge.requestSosFix();
      if (mounted) {
        setState(() => _bridgeStatus = '긴급 위치 요청 중');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _bridgeStatus = '긴급 위치를 요청하지 못했습니다.');
      }
    }
  }

  Future<void> _flushPendingLocations() async {
    if (!_supportsNativeLocation) {
      setState(() => _uploadStatus = 'Android/iOS 빌드에서 업로드 큐를 사용할 수 있습니다.');
      return;
    }

    setState(() {
      _isUploadFlushRunning = true;
      _uploadStatus = '업로드 큐 동기화 요청 중';
    });

    try {
      await widget.locationBridge.flushPendingLocations();
      if (mounted) {
        setState(() => _uploadStatus = '업로드 큐 동기화 요청됨');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploadStatus = '업로드 큐 동기화를 요청하지 못했습니다.');
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
        setState(() => _bridgeStatus = '동행 세션 종료 동기화 대기 중');
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
        _placeAlertStatusMessage = '알림 조건을 하나 이상 선택해 주세요.';
        return;
      }
      _placeNotifyArrival = nextArrival;
      _placeNotifyDeparture = nextDeparture;
      _placeNotifyLate = nextLate;
      _placeNotifyLongStay = nextLongStay;
      _placeAlertStatusMessage = null;
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
      setState(() => _placeAlertStatusMessage = 'Supabase 연결 후 저장할 수 있습니다.');
      return;
    }
    if (targetIds.isEmpty) {
      setState(() => _placeAlertStatusMessage = '대상 멤버를 선택해 주세요.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _placeAlertStatusMessage = '장소 이름을 입력해 주세요.');
      return;
    }

    setState(() {
      _isSavingPlaceAlert = true;
      _placeAlertStatusMessage = '장소 알림 저장 중';
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
          quietHours: _quietHoursFromPreset(_placeQuietHoursPreset),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _placeAlertStatusMessage =
            '${alert.name} 저장됨 · 대상 ${alert.targetCount}명';
        _isPlaceDraftVisible = true;
      });
      await _syncPlaceAlertGeofences(circleId);
    } catch (_) {
      if (mounted) {
        setState(() => _placeAlertStatusMessage =
            '장소 알림을 저장하지 못했습니다. 대상과 공유 범위를 확인해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPlaceAlert = false);
      }
    }
  }

  Future<void> _syncPlaceAlertGeofences(String circleId) async {
    final repository = widget.placeAlertRepository;
    if (!_supportsNativeLocation || repository == null) {
      return;
    }

    try {
      final registeredCount = await syncPlaceAlertGeofences(
        repository: repository,
        locationBridge: widget.locationBridge,
        circleId: circleId,
      );
      if (mounted) {
        setState(() => _bridgeStatus = registeredCount == 0
            ? '장소 알림 반경이 기기에서 해제됨'
            : '장소 알림 반경 $registeredCount개 기기 등록됨');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _bridgeStatus = '장소 알림은 저장됨 · 기기 반경 등록 대기 중');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final demoTracks = demoMapTracks();
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
    final circleTitle = _circleName ?? '우리 서클';
    final companionConfig = _companionConfig(const Duration(minutes: 15));
    final draftPlacePoint = tracks.isEmpty
        ? const LatLng(37.50768, 127.04382)
        : tracks
            .firstWhere((member) => member.isCurrentUser,
                orElse: () => tracks.first)
            .point;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('우리 서클',
                      style: TextStyle(
                          color: GyeoteColors.primary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(circleTitle,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${tracks.length}명이 위치 공유 중',
                    style: const TextStyle(color: GyeoteColors.muted),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 3),
                    const Text('서클 위치 연결 중',
                        style:
                            TextStyle(color: GyeoteColors.muted, fontSize: 12)),
                  ] else if (_loadError != null) ...[
                    const SizedBox(height: 3),
                    Text(_loadError!,
                        style: const TextStyle(
                            color: GyeoteColors.danger, fontSize: 12)),
                  ] else if (hasNoCircle) ...[
                    const SizedBox(height: 3),
                    const Text('아직 연결된 서클 없음',
                        style:
                            TextStyle(color: GyeoteColors.muted, fontSize: 12)),
                  ] else if (!isLive && widget.circleRepository != null) ...[
                    const SizedBox(height: 3),
                    const Text('아직 서버 위치가 없어 데모 위치 표시 중',
                        style:
                            TextStyle(color: GyeoteColors.muted, fontSize: 12)),
                  ],
                  if (_bridgeStatus != null) ...[
                    const SizedBox(height: 3),
                    Text(_bridgeStatus!,
                        style: const TextStyle(
                            color: GyeoteColors.muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            FilledButton.icon(
              style:
                  FilledButton.styleFrom(backgroundColor: GyeoteColors.danger),
              onPressed: _requestSosFix,
              icon: const Icon(Icons.sos_outlined),
              label: const Text('긴급 공유'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MapSurface(
          members: tracks,
          placeDraftPoint: _isPlaceDraftVisible ? draftPlacePoint : null,
          placeDraftRadiusM: _placeDraftRadiusM,
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
          onNotifyLateChanged: (value) => _setPlaceNotification(late: value),
          onNotifyLongStayChanged: (value) =>
              _setPlaceNotification(longStay: value),
          onQuietHoursPresetChanged: (value) =>
              setState(() => _placeQuietHoursPreset = value),
          onSave: () => _savePlaceAlert(
            center: draftPlacePoint,
            candidates: placeTargetCandidates,
          ),
        ),
        if (hasNoCircle) ...[
          const SizedBox(height: 12),
          _MapOnboardingPanel(onOpenCircle: widget.onOpenCircle),
        ],
        const SizedBox(height: 12),
        _CompanionPanel(
          config: companionConfig,
          isActive: _isCompanionActive,
          uploadStatus: _uploadStatus ?? _bridgeStatus,
          uploadPendingCount: _uploadPendingCount,
          checkInStatus: _checkInStatusMessage,
          lastCheckInText: _lastCheckInEvent == null
              ? null
              : _checkInEventText(_lastCheckInEvent!),
          isFlushAvailable: _supportsNativeLocation,
          isFlushing: _isUploadFlushRunning,
          isCheckingIn: _isCheckingIn,
          onStart15: () => _startCompanionSession(const Duration(minutes: 15)),
          onStartUntilArrival: () =>
              _startCompanionSession(const Duration(minutes: 45)),
          onStop: _stopCompanionSession,
          onCheckIn: _sendArrivalCheckIn,
          onFlush: () => _flushPendingLocations(),
        ),
        const SizedBox(height: 12),
        ...tracks
            .where((member) => !member.isCurrentUser)
            .map((member) => _MemberTile(member: member)),
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
    final isVeryStale = age >= const Duration(minutes: 30);
    final accuracy =
        event['accuracyM'] is num ? (event['accuracyM'] as num).round() : null;
    final battery = event['batteryPercent'] is num
        ? (event['batteryPercent'] as num).round()
        : null;
    final hasLowBattery = battery != null && battery <= 15;

    return MapMemberTrack(
      id: 'device-me',
      name: '나',
      status: isVeryStale
          ? '마지막 위치만 표시 중'
          : isStale
              ? '위치 업데이트 대기 중'
              : hasLowBattery
                  ? '배터리가 낮아 업데이트가 느릴 수 있어요'
                  : '내 기기 위치 · ${_relativeTimeLabel(recordedAt)}',
      meta: [
        if (isVeryStale)
          '오래된 위치 · ${_relativeTimeLabel(recordedAt)}'
        else if (isStale)
          '마지막 위치 · ${_relativeTimeLabel(recordedAt)}',
        if (battery != null && battery >= 0) '배터리 $battery%',
        if (accuracy != null) '정확도 ${accuracy}m',
        '실시간 브리지',
      ].join(' · '),
      point: point,
      tone: isStale
          ? GyeoteColors.amber
          : hasLowBattery
              ? GyeoteColors.danger
              : GyeoteColors.primary,
      recordedAt: recordedAt,
      sharingMode: SharingMode.balanced,
      routeTail: isStale ? const [] : trimmedRoute,
      isCurrentUser: true,
      isStale: isStale,
      hasLowBattery: hasLowBattery,
      accuracyM: accuracy?.toDouble(),
      safetyNote: isVeryStale
          ? '현재 위치가 아닐 수 있어요. 연결이 돌아오면 다시 업데이트돼요.'
          : isStale
              ? '배터리, 신호, 권한 상태 때문에 늦을 수 있어요.'
              : hasLowBattery
                  ? '배터리가 낮아 업데이트가 느릴 수 있어요.'
                  : null,
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
    final status = '${event['status'] ?? '상태 변경'}';
    final uploadedCount = _intFromEvent(event['uploadedCount']);
    final retryInSeconds = _intFromEvent(event['retryInSeconds']);

    switch (status) {
      case 'started':
        return '위치 공유 실행 중';
      case 'stopped':
        return '위치 공유 중지됨';
      case 'policy_paused':
        return '공유 정책에 따라 위치 수집 일시정지';
      case 'provider_enabled':
        return '위치 서비스 사용 가능';
      case 'sos_requested':
        return '긴급 위치 요청 중';
      case 'geofences_registered':
        return '장소 알림 준비됨';
      case 'upload_not_configured':
        return '업로드 큐 설정 대기 중';
      case 'upload_configured':
        return '업로드 큐 준비됨';
      case 'upload_queue_empty':
        return '업로드할 대기 위치 없음';
      case 'upload_already_running':
        return '업로드 큐 동기화 중';
      case 'upload_flushed':
        return '위치 업로드 완료 · ${uploadedCount ?? 0}건';
      case 'upload_retry_wait':
        return '업로드 재시도 대기 · ${retryInSeconds ?? 0}초 후';
      case 'upload_retry_scheduled':
        return '업로드 실패 · 자동 재시도 예약';
      case 'upload_ios_queue_pending':
        return 'iOS 업로드 큐 구현 대기 중';
      default:
        return '위치 서비스 $status';
    }
  }

  int? _intFromEvent(Object? value) {
    if (value is num) {
      return value.round();
    }
    return int.tryParse('$value');
  }
}

String _relativeTimeLabel(DateTime recordedAt) {
  final diff = DateTime.now().difference(recordedAt);
  if (diff.inSeconds < 60) {
    return '방금';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}분 전';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}시간 전';
  }
  return '${diff.inDays}일 전';
}

String _checkInEventText(CheckInEvent event) {
  final status = switch (event.status) {
    CheckInStatus.safeArrived => '무사 도착',
    CheckInStatus.needsCheck => '확인 필요',
    CheckInStatus.signalWeak => '신호가 잠시 약해요',
  };
  return '${event.displayName} · $status · ${_relativeTimeLabel(event.createdAt)}';
}

String _precisionText(MapMemberTrack member) {
  final radiusLabel = _radiusLabel(member);
  final modeLabel = switch (member.sharingMode) {
    SharingMode.precise => '정확 위치',
    SharingMode.balanced => '균형 위치',
    SharingMode.area => '동네 범위',
    SharingMode.hidden => '공유 숨김',
    SharingMode.sosOnly => '긴급 전용',
  };

  if (member.isStale) {
    return '마지막 위치 · $modeLabel · 약 $radiusLabel 범위';
  }
  return '$modeLabel · 약 $radiusLabel 범위';
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
    required this.placeDraftPoint,
    required this.placeDraftRadiusM,
  });

  final List<MapMemberTrack> members;
  final LatLng? placeDraftPoint;
  final int placeDraftRadiusM;

  @override
  Widget build(BuildContext context) {
    final routeMembers = members
        .where((member) => !member.isStale && member.routeTail.length > 1)
        .toList();
    final attentionCount = members
        .where((member) => member.isStale || member.hasLowBattery)
        .length;
    final routeCaption = _routeCaption(routeMembers);
    final initialCenter = members.isEmpty
        ? const LatLng(37.50768, 127.04382)
        : members
            .firstWhere((member) => member.isCurrentUser,
                orElse: () => members.first)
            .point;

    return Container(
      height: 360,
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
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
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gyeote.app',
                maxNativeZoom: 19,
              ),
              CircleLayer(
                circles: [
                  if (placeDraftPoint != null)
                    CircleMarker(
                      point: placeDraftPoint!,
                      radius: placeDraftRadiusM.toDouble(),
                      useRadiusInMeter: true,
                      color: GyeoteColors.primary.withValues(alpha: 0.10),
                      borderColor: GyeoteColors.primary.withValues(alpha: 0.72),
                      borderStrokeWidth: 2,
                    ),
                  for (final member in members)
                    CircleMarker(
                      point: member.point,
                      radius: _precisionRadiusM(member),
                      useRadiusInMeter: true,
                      color: _precisionFillColor(member),
                      borderColor: _precisionBorderColor(member),
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
                        color: member.tone,
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
                      width: 72,
                      height: 72,
                      child: _LiveMarker(member: member),
                    ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
          const Positioned(
            left: 14,
            top: 14,
            child: _MapChip(icon: Icons.layers_outlined, text: '표준 지도'),
          ),
          if (attentionCount > 0)
            Positioned(
              left: 14,
              top: 52,
              child: _MapChip(
                icon: Icons.wifi_off_outlined,
                text: '신호 확인 $attentionCount',
              ),
            ),
          const Positioned(
            left: 14,
            bottom: 14,
            child: _MapChip(
              icon: Icons.radio_button_checked_outlined,
              text: '반경=공유 정밀도',
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: _MapChip(
              icon: Icons.route_outlined,
              text:
                  routeMembers.isEmpty ? '경로 대기' : '경로 ${routeMembers.length}',
            ),
          ),
          if (placeDraftPoint != null)
            Positioned(
              right: 14,
              top: 52,
              child: _MapChip(
                icon: Icons.add_location_alt_outlined,
                text: '장소 반경 ${placeDraftRadiusM}m',
              ),
            ),
          if (routeCaption != null)
            Positioned(
              left: 48,
              right: 48,
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: GyeoteColors.border),
                  borderRadius: BorderRadius.circular(8),
                  color: GyeoteColors.surface,
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1F151C19),
                        blurRadius: 18,
                        offset: Offset(0, 8))
                  ],
                ),
                child: Text(
                  routeCaption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: GyeoteColors.muted, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _routeCaption(List<MapMemberTrack> routeMembers) {
    if (routeMembers.isEmpty) {
      return null;
    }
    if (routeMembers.length == 1) {
      final member = routeMembers.first;
      return '${member.name} · 이동 경로 ${member.routeTail.length}개 샘플';
    }
    return '${routeMembers.length}명 이동 경로 표시 중';
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

  Color _precisionFillColor(MapMemberTrack member) {
    final base = member.isStale
        ? GyeoteColors.amber
        : member.hasLowBattery
            ? GyeoteColors.danger
            : member.tone;
    return base.withValues(alpha: member.isStale ? 0.08 : 0.11);
  }

  Color _precisionBorderColor(MapMemberTrack member) {
    if (member.isStale) {
      return GyeoteColors.amber.withValues(alpha: 0.65);
    }
    return member.tone.withValues(alpha: 0.42);
  }
}

class _LiveMarker extends StatelessWidget {
  const _LiveMarker({required this.member});

  final MapMemberTrack member;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapPin(
          label: member.name.substring(0, 1),
          color: member.isStale ? GyeoteColors.amber : member.tone,
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: GyeoteColors.border),
            borderRadius: BorderRadius.circular(6),
            color: GyeoteColors.surface,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (member.isStale) ...[
                const Icon(Icons.wifi_off_outlined,
                    size: 11, color: GyeoteColors.amber),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapOnboardingPanel extends StatelessWidget {
  const _MapOnboardingPanel({required this.onOpenCircle});

  final VoidCallback? onOpenCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: GyeoteColors.primarySoft,
            ),
            child: const Icon(Icons.group_add_outlined,
                color: GyeoteColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('첫 서클을 시작하세요',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 3),
                Text('초대가 완료되면 지도에 공유 위치가 표시됩니다.',
                    style: TextStyle(color: GyeoteColors.muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onOpenCircle,
            icon: const Icon(Icons.arrow_forward_outlined),
            label: const Text('서클'),
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
    final hasTargets = targetCandidates.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.surface,
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
                  color: GyeoteColors.primarySoft,
                ),
                child: const Icon(Icons.add_location_alt_outlined,
                    color: GyeoteColors.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('장소 반경',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text('도착/이탈 규칙 저장',
                        style:
                            TextStyle(color: GyeoteColors.muted, fontSize: 12)),
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
            decoration: const InputDecoration(
              labelText: '장소 이름',
              prefixIcon: Icon(Icons.place_outlined),
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
                const _PlaceDraftHint(text: '실제 서클 위치가 연결되면 저장할 수 있습니다.'),
              for (final member in targetCandidates)
                FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: member.tone.withValues(alpha: 0.16),
                    child: Text(
                      member.name.substring(0, 1),
                      style: TextStyle(
                        color: member.tone,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  label: Text(member.isCurrentUser ? '나' : member.name),
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
                label: const Text('도착'),
                selected: notifyArrival,
                onSelected: onNotifyArrivalChanged,
              ),
              FilterChip(
                avatar: const Icon(Icons.logout_outlined, size: 18),
                label: const Text('이탈'),
                selected: notifyDeparture,
                onSelected: onNotifyDepartureChanged,
              ),
              FilterChip(
                avatar: const Icon(Icons.schedule_outlined, size: 18),
                label: const Text('늦음'),
                selected: notifyLate,
                onSelected: onNotifyLateChanged,
              ),
              FilterChip(
                avatar: const Icon(Icons.timelapse_outlined, size: 18),
                label: const Text('오래 머무름'),
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
              segments: const [
                ButtonSegment(
                  value: _PlaceQuietHoursPreset.none,
                  icon: Icon(Icons.notifications_none_outlined),
                  label: Text('없음'),
                ),
                ButtonSegment(
                  value: _PlaceQuietHoursPreset.night,
                  icon: Icon(Icons.bedtime_outlined),
                  label: Text('야간'),
                ),
                ButtonSegment(
                  value: _PlaceQuietHoursPreset.schoolOrWork,
                  icon: Icon(Icons.work_history_outlined),
                  label: Text('수업'),
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
            _quietHoursPresetCopy(quietHoursPreset),
            style: const TextStyle(color: GyeoteColors.muted, fontSize: 12),
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              statusMessage!,
              style: TextStyle(
                color: statusMessage!.contains('못했습니다') ||
                        statusMessage!.contains('선택') ||
                        statusMessage!.contains('입력')
                    ? GyeoteColors.danger
                    : GyeoteColors.primary,
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
              label: Text(isSaving ? '저장 중' : '장소 알림 저장'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GyeoteColors.surfaceAlt,
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: GyeoteColors.muted, fontSize: 12),
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
    final expiresAt = config.sharingPolicy.expiresAt;
    final minutes = expiresAt == null
        ? 15
        : expiresAt.difference(DateTime.now()).inMinutes.clamp(1, 60);
    final uploadText = [
      uploadStatus ?? '업로드 큐 대기',
      if (uploadPendingCount != null) '대기 ${uploadPendingCount!}건',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.primarySoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('동행 모드',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              _StatusBadge(text: '$minutes분 남음'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '최소 ${config.minIntervalSeconds}초 간격 · ${config.sharingPolicy.mode.name} 공유 · 상호 동의 후 시작',
            style: const TextStyle(color: GyeoteColors.muted),
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
                    label: const Text('도착 확인'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isCheckingIn ? null : onStop,
                    child: const Text('공유 멈춤'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: onStart15, child: const Text('15분'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: onStartUntilArrival,
                        child: const Text('도착까지'))),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onStart15,
                    child: const Text('시작'),
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
              border: Border.all(color: GyeoteColors.border),
              borderRadius: BorderRadius.circular(8),
              color: GyeoteColors.surface,
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_sync_outlined, color: GyeoteColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('위치 동기화',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(uploadText,
                          style: const TextStyle(
                              color: GyeoteColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Tooltip(
                  message: '대기 위치 동기화',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.surface,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: GyeoteColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: GyeoteColors.primary, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final MapMemberTrack member;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.surface,
      ),
      child: Row(
        children: [
          _MapPin(
              label: member.name.substring(0, 1),
              color: member.tone,
              compact: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.status,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(member.meta,
                    style: const TextStyle(
                        color: GyeoteColors.muted, fontSize: 12)),
                const SizedBox(height: 6),
                _MemberPrecisionLine(member: member),
                if (member.safetyNote != null) ...[
                  const SizedBox(height: 8),
                  _MemberSafetyNote(
                    text: member.safetyNote!,
                    icon: member.isStale
                        ? Icons.wifi_off_outlined
                        : Icons.battery_alert_outlined,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPrecisionLine extends StatelessWidget {
  const _MemberPrecisionLine({required this.member});

  final MapMemberTrack member;

  @override
  Widget build(BuildContext context) {
    final text = _precisionText(member);
    return Row(
      children: [
        Icon(
          member.isStale
              ? Icons.history_outlined
              : Icons.radio_button_checked_outlined,
          size: 15,
          color: member.isStale ? GyeoteColors.amber : GyeoteColors.primary,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: GyeoteColors.muted, fontSize: 12),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: GyeoteColors.amber),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: GyeoteColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

PlaceAlertQuietHours _quietHoursFromPreset(_PlaceQuietHoursPreset preset) {
  switch (preset) {
    case _PlaceQuietHoursPreset.none:
      return const PlaceAlertQuietHours.none();
    case _PlaceQuietHoursPreset.night:
      return const PlaceAlertQuietHours(
        enabled: true,
        start: '22:00',
        end: '07:00',
        timeZone: 'Asia/Seoul',
        label: '야간',
      );
    case _PlaceQuietHoursPreset.schoolOrWork:
      return const PlaceAlertQuietHours(
        enabled: true,
        start: '09:00',
        end: '17:00',
        timeZone: 'Asia/Seoul',
        label: '수업/근무',
      );
  }
}

String _quietHoursPresetCopy(_PlaceQuietHoursPreset preset) {
  switch (preset) {
    case _PlaceQuietHoursPreset.none:
      return '중요한 도착/이탈 알림을 항상 받을 수 있습니다.';
    case _PlaceQuietHoursPreset.night:
      return '22:00-07:00에는 긴급하지 않은 장소 알림을 조용히 처리합니다.';
    case _PlaceQuietHoursPreset.schoolOrWork:
      return '09:00-17:00에는 반복적인 장소 알림을 줄이는 preset입니다.';
  }
}

String _geofenceStatusText(String type) {
  switch (type) {
    case 'geofence.entered':
      return '저장한 장소 반경에 도착했습니다.';
    case 'geofence.exited':
      return '저장한 장소 반경을 벗어났습니다.';
    default:
      return '저장한 장소 반경 변화가 감지됐습니다.';
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 42.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: GyeoteColors.surface, width: 3),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
              color: Color(0x24151C19), blurRadius: 14, offset: Offset(0, 8))
        ],
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(6),
        color: GyeoteColors.surface,
        boxShadow: const [
          BoxShadow(
              color: Color(0x17151C19), blurRadius: 14, offset: Offset(0, 6))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: GyeoteColors.primary),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  color: GyeoteColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: GyeoteColors.surface,
      ),
      child: Text(text,
          style: const TextStyle(
              color: GyeoteColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12)),
    );
  }
}
