import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_bridge.dart';
import '../../core/location/location_models.dart';
import '../../core/privacy/private_place.dart';
import '../../core/privacy/private_place_store.dart';
import 'viewer_log_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/gyeote_theme.dart';

enum _BatteryMode {
  live,
  balanced,
  saver,
}

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({
    super.key,
    this.circleRepository,
    this.privacyRepository,
    this.locationBridge,
    this.onSignOut,
  });

  final CircleRepository? circleRepository;
  final PrivacyRepository? privacyRepository;
  final LocationBridge? locationBridge;
  final Future<void> Function()? onSignOut;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  String? _statusMessage;

  /// 오류 색을 문구 내용으로 추측하지 않기 위한 플래그.
  /// 예전에는 '못했습니다' 부분 문자열로 판별해서, 번역하는 순간 조용히 깨졌다.
  bool _statusIsError = false;

  AppL10n get _l10n => AppL10n.of(context);
  bool _isPausing = false;
  bool _isRequestingData = false;
  bool _isSavingAds = false;
  bool _isLoadingPermissions = false;
  bool _personalizedAdsEnabled = false;
  bool _sensitiveCategoriesBlocked = true;
  _BatteryMode _batteryMode = _BatteryMode.balanced;
  PermissionSnapshot? _permissionSnapshot;
  String? _permissionStatusMessage;
  List<PrivatePlace> _privatePlaces = const [];
  bool _isAddingPrivatePlace = false;
  List<ViewerLogEntry>? _viewerLog;
  bool _viewerLogFailed = false;

  bool get _hasBackend =>
      widget.circleRepository != null && widget.privacyRepository != null;

  bool get _supportsNativeLocation {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void initState() {
    super.initState();
    _loadAdPreferences();
    _loadPermissionSnapshot();
    _loadPrivatePlaces();
    _loadViewerLog();
  }

  @override
  void didUpdateWidget(covariant PrivacyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.privacyRepository != widget.privacyRepository) {
      _loadAdPreferences();
    }
    if (oldWidget.locationBridge != widget.locationBridge) {
      _permissionSnapshot = null;
      _loadPermissionSnapshot();
    }
  }

  Future<void> _loadAdPreferences() async {
    final repository = widget.privacyRepository;
    if (repository == null) {
      return;
    }

    try {
      final preferences = await repository.getAdPreferences();
      if (!mounted) {
        return;
      }
      setState(() {
        _personalizedAdsEnabled = preferences.personalizedAdsEnabled;
        _sensitiveCategoriesBlocked = preferences.sensitiveCategoriesBlocked;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
        _statusMessage = _l10n.privacyAdsLoadFailed;
        _statusIsError = true;
      });
      }
    }
  }

  Future<void> _loadPermissionSnapshot() async {
    final bridge = widget.locationBridge;
    if (!_supportsNativeLocation || bridge == null) {
      setState(
          () => _permissionStatusMessage = _l10n.privacyPermissionBuildOnly);
      return;
    }

    setState(() {
      _isLoadingPermissions = true;
      _permissionStatusMessage = null;
    });

    try {
      final snapshot = await bridge.getPermissionSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionSnapshot = snapshot;
        _isLoadingPermissions = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPermissions = false;
          _permissionStatusMessage = _l10n.privacyPermissionFailed;
        });
      }
    }
  }

  Future<CircleSummary> _activeCircle() async {
    final repository = widget.circleRepository;
    if (repository == null) {
      throw StateError('Circle repository is not configured.');
    }

    final circles = await repository.listCircles();
    if (circles.isEmpty) {
      throw StateError('No circle exists.');
    }
    return circles.first;
  }

  Future<void> _pauseSharing() async {
    if (!_hasBackend) {
      setState(() {
        _statusMessage = _l10n.privacyPauseNeedsBackend;
        _statusIsError = true;
      });
      return;
    }

    setState(() {
      _isPausing = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
      final circle = await _activeCircle();
      await widget.privacyRepository!.updateSharingPolicy(
        circleId: circle.id,
        policy: SharingPolicy(
          enabled: false,
          mode: SharingMode.hidden,
          pausedUntil: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      if (mounted) {
        setState(() {
        _statusMessage = _l10n.privacyPausedNotice;
        _statusIsError = false;
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _statusMessage = _l10n.privacyPauseFailed;
        _statusIsError = true;
      });
      }
    } finally {
      if (mounted) {
        setState(() => _isPausing = false);
      }
    }
  }

  Future<void> _requestData(DataRequestType type) async {
    final repository = widget.privacyRepository;
    if (repository == null) {
      setState(() {
        _statusMessage = _l10n.privacyDataNeedsBackend;
        _statusIsError = true;
      });
      return;
    }

    setState(() {
      _isRequestingData = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
      await repository.requestData(type);
      if (mounted) {
        setState(() => _statusMessage = type == DataRequestType.export
            ? _l10n.privacyDataExportSent
            : _l10n.privacyDataDeleteSent);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _statusMessage = _l10n.privacyDataRequestFailed;
        _statusIsError = true;
      });
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingData = false);
      }
    }
  }

  Future<void> _updateAdPreferences({
    bool? personalizedAdsEnabled,
    bool? sensitiveCategoriesBlocked,
  }) async {
    final repository = widget.privacyRepository;
    if (repository == null) {
      setState(() {
        _statusMessage = _l10n.privacyAdsNeedsBackend;
        _statusIsError = true;
      });
      return;
    }

    final nextPreferences = AdPreferences(
      personalizedAdsEnabled: personalizedAdsEnabled ?? _personalizedAdsEnabled,
      sensitiveCategoriesBlocked:
          sensitiveCategoriesBlocked ?? _sensitiveCategoriesBlocked,
    );

    setState(() {
      _isSavingAds = true;
      _statusMessage = null;
      _statusIsError = false;
      _personalizedAdsEnabled = nextPreferences.personalizedAdsEnabled;
      _sensitiveCategoriesBlocked = nextPreferences.sensitiveCategoriesBlocked;
    });

    try {
      await repository.updateAdPreferences(nextPreferences);
      if (mounted) {
        setState(() {
        _statusMessage = _l10n.privacyAdsSaved;
        _statusIsError = false;
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _statusMessage = _l10n.privacyAdsSaveFailed;
        _statusIsError = true;
      });
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingAds = false);
      }
    }
  }

  Future<void> _loadViewerLog() async {
    final repository = widget.circleRepository;
    if (repository == null) return;

    try {
      final entries = await repository.listViewerLog(limit: 20);
      if (!mounted) return;
      setState(() {
        _viewerLog = entries;
        _viewerLogFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _viewerLog = const [];
        _viewerLogFailed = true;
      });
    }
  }

  Future<void> _loadPrivatePlaces() async {
    final places = await const PrivatePlaceStore().load();
    if (!mounted) return;
    setState(() => _privatePlaces = places);
  }

  /// 지금 있는 곳을 민감 장소로 등록한다.
  ///
  /// 지도에서 점을 찍게 하지 않는 이유는, 이걸 설정하는 사람은 대개 그 장소에
  /// 서 있기 때문이다. 지도 피커를 붙이면 단계가 늘고, 늘어난 단계만큼 안 쓰게
  /// 된다.
  Future<void> _addPrivatePlaceHere() async {
    final bridge = widget.locationBridge;
    if (bridge == null) return;

    if (_privatePlaces.length >= PrivatePlaceStore.maxPlaces) {
      _setStatus(_l10n.privatePlacesFull(PrivatePlaceStore.maxPlaces),
          isError: true);
      return;
    }

    setState(() => _isAddingPrivatePlace = true);
    try {
      final sample = await bridge.getLastKnownLocation();
      if (!mounted) return;
      if (sample == null) {
        _setStatus(_l10n.privatePlacesNoFix, isError: true);
        return;
      }

      // 등록에는 **원시 좌표**를 쓴다. 이미 가려진 좌표로 중심을 잡으면 반경이
      // 실제 위치에서 밀려나 정작 집이 반경 밖에 남는다.
      final draft = await _askPrivatePlaceDetails();
      if (!mounted || draft == null) return;

      final place = PrivatePlace(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: draft.name,
        latitude: sample.rawCoordinate.latitude,
        longitude: sample.rawCoordinate.longitude,
        radiusM: draft.radiusM,
      );

      await _savePrivatePlaces([..._privatePlaces, place]);
      if (mounted) _setStatus(_l10n.privatePlacesSaved, isError: false);
    } catch (_) {
      if (mounted) _setStatus(_l10n.privatePlacesNoFix, isError: true);
    } finally {
      if (mounted) setState(() => _isAddingPrivatePlace = false);
    }
  }

  Future<void> _removePrivatePlace(String id) async {
    await _savePrivatePlaces(
      _privatePlaces.where((place) => place.id != id).toList(),
    );
    if (mounted) _setStatus(_l10n.privatePlacesRemoved, isError: false);
  }

  Future<void> _savePrivatePlaces(List<PrivatePlace> places) async {
    await const PrivatePlaceStore().save(places);
    // 저장과 적용이 갈리면 화면은 등록됐다고 하는데 좌표는 계속 정확하게
    // 나간다. 그래서 저장 직후에 곧바로 밀어 넣는다.
    await widget.locationBridge?.setPrivatePlaces(places);
    if (mounted) setState(() => _privatePlaces = places);
  }

  Future<({String name, int radiusM})?> _askPrivatePlaceDetails() {
    return showModalBottomSheet<({String name, int radiusM})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _PrivatePlaceComposer(),
    );
  }

  void _setStatus(String message, {required bool isError}) {
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final statusColor = _statusIsError ? palette.alert : palette.brand;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.privacyTitle,
                      style:
                          const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l10n.privacySubtitle,
                      style: TextStyle(color: palette.muted)),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(_statusMessage!,
                        style: TextStyle(color: statusColor, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.alertSoft,
                    foregroundColor: palette.alert,
                  ),
                  onPressed: _isPausing
                      ? null
                      : () async {
                          await _pauseSharing();
                        },
                  child: Text(_isPausing ? l10n.privacySaving : l10n.privacyPauseSharing),
                ),
                if (widget.onSignOut != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () async {
                      await widget.onSignOut!();
                    },
                    icon: const Icon(Icons.logout_outlined, size: 18),
                    label: Text(l10n.signOut),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SharingModeCard(),
        const SizedBox(height: 12),
        _BatteryModeCard(
          mode: _batteryMode,
          onChanged: (mode) => setState(() => _batteryMode = mode),
        ),
        const SizedBox(height: 12),
        _PermissionHealthCard(
          snapshot: _permissionSnapshot,
          isLoading: _isLoadingPermissions,
          message: _permissionStatusMessage,
          onRefresh: _loadPermissionSnapshot,
        ),
        const SizedBox(height: 12),
        _PrivatePlacesCard(
          places: _privatePlaces,
          isAdding: _isAddingPrivatePlace,
          canAdd: widget.locationBridge != null,
          onAdd: _addPrivatePlaceHere,
          onRemove: _removePrivatePlace,
        ),
        const SizedBox(height: 12),
        _ViewerLogCard(
          entries: _viewerLog,
          failed: _viewerLogFailed,
          repository: widget.circleRepository,
        ),
        const SizedBox(height: 12),
        _AdsCard(
          personalizedAdsEnabled: _personalizedAdsEnabled,
          sensitiveCategoriesBlocked: _sensitiveCategoriesBlocked,
          isSaving: _isSavingAds,
          onPersonalizedChanged: (value) =>
              _updateAdPreferences(personalizedAdsEnabled: value),
          onSensitiveChanged: (value) =>
              _updateAdPreferences(sensitiveCategoriesBlocked: value),
        ),
        const SizedBox(height: 12),
        _DataRequestCard(
          isLoading: _isRequestingData,
          onExport: () => _requestData(DataRequestType.export),
          onDeleteHistory: () => _requestData(DataRequestType.deleteHistory),
        ),
      ],
    );
  }
}

class _SharingModeCard extends StatelessWidget {
  const _SharingModeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return _PrivacyCard(
      title: l10n.privacySharingScopeTitle,
      child: Column(
        children: [
          _ModeRow(label: l10n.privacyCircleFamily, value: l10n.privacyModeBalancedTitle, detail: l10n.privacyModeAdjusted),
          _ModeRow(label: l10n.privacyCompanionMode, value: l10n.privacyCompanion15MinLeft, detail: l10n.privacyCompanionConsentNote),
          _ModeRow(label: l10n.privacyCircleFriends, value: l10n.precisionArea, detail: l10n.privacyModeHidesExact),
        ],
      ),
    );
  }
}

class _BatteryModeCard extends StatelessWidget {
  const _BatteryModeCard({
    required this.mode,
    required this.onChanged,
  });

  final _BatteryMode mode;
  final ValueChanged<_BatteryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return _PrivacyCard(
      title: l10n.privacyBatteryTitle,
      trailing: _Badge(text: _batteryModeBadge(l10n, mode)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_BatteryMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _BatteryMode.live,
                  icon: const Icon(Icons.speed_outlined),
                  label: Text(l10n.privacyBatteryRealtime),
                ),
                ButtonSegment(
                  value: _BatteryMode.balanced,
                  icon: const Icon(Icons.tune_outlined),
                  label: Text(l10n.precisionBalanced),
                ),
                ButtonSegment(
                  value: _BatteryMode.saver,
                  icon: const Icon(Icons.battery_saver_outlined),
                  label: Text(l10n.privacyBatterySaver),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) {
                  onChanged(values.first);
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          _ModeRow(
            label: _batteryModeTitle(l10n, mode),
            value: _batteryModeInterval(l10n, mode),
            detail: _batteryModeDetail(l10n, mode),
          ),
        ],
      ),
    );
  }
}

class _PermissionHealthCard extends StatelessWidget {
  const _PermissionHealthCard({
    required this.snapshot,
    required this.isLoading,
    required this.message,
    required this.onRefresh,
  });

  final PermissionSnapshot? snapshot;
  final bool isLoading;
  final String? message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final current = snapshot;

    return _PrivacyCard(
      title: l10n.privacyPermissionTitle,
      trailing: IconButton.filledTonal(
        tooltip: l10n.privacyPermissionRefresh,
        onPressed: isLoading
            ? null
            : () async {
                await onRefresh();
              },
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync_outlined),
      ),
      child: Column(
        children: [
          if (message != null) ...[
            _PermissionNotice(message: message!),
            const SizedBox(height: 10),
          ],
          _ModeRow(
            label: l10n.privacyPermissionLocation,
            value: current == null
                ? l10n.privacyPermissionDeviceBuild
                : current.foregroundGranted
                    ? l10n.privacyPermissionWhileInUse
                    : l10n.privacyPending,
            detail: current == null
                ? l10n.privacyPermissionBuildOnlyShort
                : current.foregroundGranted
                    ? l10n.privacySharingScopeBody
                    : l10n.privacyPermissionEducationNote,
          ),
          _ModeRow(
            label: l10n.privacyPermissionBackground,
            value: current == null
                ? l10n.privacyPermissionWhenNeeded
                : current.backgroundGranted
                    ? l10n.privacyPermissionGranted
                    : l10n.privacyPermissionWhenNeeded,
            detail: l10n.privacyPermissionStagedNote,
          ),
          _ModeRow(
            label: l10n.privacyModePreciseTitle,
            value: current == null
                ? l10n.privacyPermissionUnknown
                : current.preciseGranted
                    ? l10n.precisionPrecise
                    : l10n.privacyModeApprox,
            detail: current?.preciseGranted == false
                ? l10n.privacyModeApproxBody
                : l10n.privacyModePreciseBody,
          ),
          _ModeRow(
            label: l10n.privacyPermissionNotifications,
            value: current == null
                ? l10n.privacyNotificationsTitle
                : current.notificationsGranted
                    ? l10n.privacyPermissionGranted
                    : l10n.privacyPending,
            detail: l10n.privacyNotificationsBody,
          ),
        ],
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.surfaceAlt,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: palette.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerLogCard extends StatelessWidget {
  const _ViewerLogCard({
    required this.entries,
    required this.failed,
    required this.repository,
  });

  /// null 이면 아직 읽는 중. 빈 목록과 다르다.
  final List<ViewerLogEntry>? entries;
  final bool failed;
  final CircleRepository? repository;

  /// 카드에는 세 줄까지만. 나머지는 시트에서 본다.
  static const int _preview = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final repo = repository;
    final rows = entries;

    return _PrivacyCard(
      title: l10n.privacyViewerLogTitle,
      trailing: repo == null || rows == null || rows.isEmpty
          ? null
          : TextButton(
              onPressed: () => showViewerLogSheet(context, repository: repo),
              child: Text(l10n.viewerLogSeeAll),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (repo == null)
            Text(
              // 데모에서는 가짜 이름을 그리지 않는다. 예전에는 여기에 데모
              // 이름 세 개가 진짜 열람 기록인 것처럼 박혀 있었다.
              l10n.viewerLogNeedsBackend,
              style: TextStyle(fontSize: 12, color: palette.muted),
            )
          else if (failed)
            Text(
              l10n.viewerLogLoadFailed,
              style: TextStyle(fontSize: 12, color: palette.alert),
            )
          else if (rows == null)
            Text(
              l10n.privacySaving,
              style: TextStyle(fontSize: 12, color: palette.muted),
            )
          else if (rows.isEmpty)
            Text(
              l10n.viewerLogEmpty,
              style: TextStyle(fontSize: 12, color: palette.inkMuted),
            )
          else
            for (final entry in rows.take(_preview))
              ViewerLogRow(entry: entry),
        ],
      ),
    );
  }
}

class _AdsCard extends StatelessWidget {
  const _AdsCard({
    required this.personalizedAdsEnabled,
    required this.sensitiveCategoriesBlocked,
    required this.isSaving,
    required this.onPersonalizedChanged,
    required this.onSensitiveChanged,
  });

  final bool personalizedAdsEnabled;
  final bool sensitiveCategoriesBlocked;
  final bool isSaving;
  final Future<void> Function(bool) onPersonalizedChanged;
  final Future<void> Function(bool) onSensitiveChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return _PrivacyCard(
      title: l10n.privacyAdsTitle,
      trailing: _Badge(text: l10n.privacyAdsNoPreciseTargeting),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.privacyAdsPersonalized),
            subtitle: Text(l10n.privacyAdsPersonalizedBody,
                style: TextStyle(color: palette.muted)),
            value: personalizedAdsEnabled,
            onChanged: isSaving
                ? null
                : (value) async {
                    await onPersonalizedChanged(value);
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.privacyAdsSensitiveBlock),
            subtitle: Text(l10n.privacyAdsSensitiveBody,
                style: TextStyle(color: palette.muted)),
            value: sensitiveCategoriesBlocked,
            onChanged: isSaving
                ? null
                : (value) async {
                    await onSensitiveChanged(value);
                  },
          ),
        ],
      ),
    );
  }
}

class _DataRequestCard extends StatelessWidget {
  const _DataRequestCard({
    required this.isLoading,
    required this.onExport,
    required this.onDeleteHistory,
  });

  final bool isLoading;
  final Future<void> Function() onExport;
  final Future<void> Function() onDeleteHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return _PrivacyCard(
      title: l10n.privacyDataTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeRow(label: l10n.privacyDataLocationHistory, value: l10n.privacyRetention30Days, detail: l10n.privacyRetentionAutoDelete),
          _ModeRow(
              label: l10n.privacyDataCompanionRoutes, value: l10n.privacyRetention24Hours, detail: l10n.privacyRetentionSummaryOnly),
          _ModeRow(label: l10n.privacyViewerLogLabel, value: l10n.privacyRetention30Days, detail: l10n.privacyViewerLogNote),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          await onExport();
                        },
                  child: Text(l10n.privacyDataExport),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          await onDeleteHistory();
                        },
                  child: Text(isLoading ? l10n.privacyRequesting : l10n.privacyDataDelete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _batteryModeBadge(AppL10n l10n, _BatteryMode mode) {
  switch (mode) {
    case _BatteryMode.live:
      return l10n.privacyBatteryFast;
    case _BatteryMode.balanced:
      return l10n.privacyRecommended;
    case _BatteryMode.saver:
      return l10n.privacyBatterySlow;
  }
}

String _batteryModeTitle(AppL10n l10n, _BatteryMode mode) {
  switch (mode) {
    case _BatteryMode.live:
      return l10n.privacyBatteryRealtimeNote;
    case _BatteryMode.balanced:
      return l10n.privacyBatteryBalancedNote;
    case _BatteryMode.saver:
      return l10n.privacyBatterySaverNote;
  }
}

String _batteryModeInterval(AppL10n l10n, _BatteryMode mode) {
  switch (mode) {
    case _BatteryMode.live:
      return l10n.privacyInterval15to30;
    case _BatteryMode.balanced:
      return l10n.privacyInterval30to90;
    case _BatteryMode.saver:
      return l10n.privacyInterval2to5;
  }
}

String _batteryModeDetail(AppL10n l10n, _BatteryMode mode) {
  switch (mode) {
    case _BatteryMode.live:
      return l10n.privacyCompanionBatteryNote;
    case _BatteryMode.balanced:
      return l10n.privacyModeBalancedBody;
    case _BatteryMode.saver:
      return l10n.privacyBatteryBody;
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detail,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
          _Badge(text: value),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

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
              Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(6),
        color: palette.surfaceAlt,
      ),
      child: Text(
        text,
        style: TextStyle(
            color: palette.brand,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// 민감 장소 카드.
///
/// 광고는 여기 들어가지 않는다. 프라이버시 설정 저장 흐름은 스킬 §5 의
/// 광고 금지 화면이다.
class _PrivatePlacesCard extends StatelessWidget {
  const _PrivatePlacesCard({
    required this.places,
    required this.isAdding,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  final List<PrivatePlace> places;
  final bool isAdding;
  final bool canAdd;
  final Future<void> Function() onAdd;
  final Future<void> Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return _PrivacyCard(
      title: l10n.privatePlacesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.privatePlacesBody,
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          const SizedBox(height: 10),
          if (places.isEmpty)
            Text(
              l10n.privatePlacesEmpty,
              style: TextStyle(fontSize: 12, color: palette.inkMuted),
            )
          else
            for (final place in places)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: palette.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name.isEmpty
                                ? l10n.privatePlacesUnnamed
                                : place.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            l10n.privatePlacesRadiusValue(place.radiusM),
                            style:
                                TextStyle(fontSize: 11, color: palette.muted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => onRemove(place.id),
                      child: Text(l10n.privatePlacesRemove),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          if (canAdd)
            FilledButton.tonal(
              onPressed: isAdding ? null : onAdd,
              child: Text(
                isAdding
                    ? l10n.privatePlacesAdding
                    : l10n.privatePlacesAddHere,
              ),
            ),
        ],
      ),
    );
  }
}

/// 이름과 가릴 범위를 받는 시트.
class _PrivatePlaceComposer extends StatefulWidget {
  const _PrivatePlaceComposer();

  @override
  State<_PrivatePlaceComposer> createState() => _PrivatePlaceComposerState();
}

class _PrivatePlaceComposerState extends State<_PrivatePlaceComposer> {
  final TextEditingController _name = TextEditingController();
  int _radiusM = PrivatePlace.radiusPresetsM[1];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privatePlacesTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.privatePlacesNameLabel,
                hintText: l10n.privatePlacesNameHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privatePlacesRadius,
              style: TextStyle(fontSize: 13, color: palette.inkMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in PrivatePlace.radiusPresetsM)
                  ChoiceChip(
                    label: Text(l10n.privatePlacesRadiusValue(preset)),
                    selected: _radiusM == preset,
                    onSelected: (_) => setState(() => _radiusM = preset),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  (name: _name.text.trim(), radiusM: _radiusM),
                ),
                child: Text(l10n.privatePlacesSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
