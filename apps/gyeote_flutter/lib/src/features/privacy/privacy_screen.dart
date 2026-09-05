import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_bridge.dart';
import '../../core/location/location_models.dart';
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
        const _ViewerLogCard(),
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
  const _ViewerLogCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return _PrivacyCard(
      title: l10n.privacyViewerLogTitle,
      trailing: TextButton(onPressed: () {}, child: Text(l10n.historyFilterAll)),
      child: Column(
        children: [
          _ModeRow(label: l10n.demoNameGuardian, value: l10n.agoJustNow, detail: l10n.privacyViewerFamilyBalanced),
          _ModeRow(label: l10n.demoNameChild, value: l10n.privacyViewer12MinAgo, detail: l10n.privacyDataCompanionRoutesBody),
          _ModeRow(label: l10n.demoNameFriend, value: l10n.privacyViewerYesterday, detail: l10n.privacyViewerFriendsArea),
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
