import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_bridge.dart';
import '../../core/location/location_models.dart';
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
        setState(() => _statusMessage = '광고 설정을 불러오지 못했습니다.');
      }
    }
  }

  Future<void> _loadPermissionSnapshot() async {
    final bridge = widget.locationBridge;
    if (!_supportsNativeLocation || bridge == null) {
      setState(
          () => _permissionStatusMessage = 'Android/iOS 빌드에서 기기 권한을 확인합니다.');
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
          _permissionStatusMessage = '기기 권한 상태를 확인하지 못했습니다.';
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
      setState(() => _statusMessage = 'Supabase 연결 후 공유를 멈출 수 있습니다.');
      return;
    }

    setState(() {
      _isPausing = true;
      _statusMessage = null;
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
        setState(() => _statusMessage = '1시간 동안 위치 공유를 멈췄습니다.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _statusMessage = '공유 멈춤을 저장하지 못했습니다.');
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
      setState(() => _statusMessage = 'Supabase 연결 후 데이터 요청을 보낼 수 있습니다.');
      return;
    }

    setState(() {
      _isRequestingData = true;
      _statusMessage = null;
    });

    try {
      await repository.requestData(type);
      if (mounted) {
        setState(() => _statusMessage = type == DataRequestType.export
            ? '데이터 내보내기 요청을 보냈습니다.'
            : '기록 삭제 요청을 보냈습니다.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _statusMessage = '데이터 요청을 보내지 못했습니다.');
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
      setState(() => _statusMessage = 'Supabase 연결 후 광고 설정을 저장할 수 있습니다.');
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
      _personalizedAdsEnabled = nextPreferences.personalizedAdsEnabled;
      _sensitiveCategoriesBlocked = nextPreferences.sensitiveCategoriesBlocked;
    });

    try {
      await repository.updateAdPreferences(nextPreferences);
      if (mounted) {
        setState(() => _statusMessage = '광고 설정을 저장했습니다.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _statusMessage = '광고 설정을 저장하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingAds = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final statusColor = (_statusMessage?.contains('못했습니다') ?? false)
        ? palette.alert
        : palette.brand;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('안심 설정',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('공유, 조회 기록, 광고, 삭제 요청',
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
                  child: Text(_isPausing ? '저장 중' : '공유 멈춤'),
                ),
                if (widget.onSignOut != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () async {
                      await widget.onSignOut!();
                    },
                    icon: const Icon(Icons.logout_outlined, size: 18),
                    label: const Text('로그아웃'),
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
    return const _PrivacyCard(
      title: '공유 범위',
      child: Column(
        children: [
          _ModeRow(label: '가족 서클', value: '균형 공유', detail: '현재 위치를 보정해서 표시'),
          _ModeRow(label: '동행 모드', value: '15분 남음', detail: '준과 상호 동의 완료 후 시작'),
          _ModeRow(label: '친구 서클', value: '동네만', detail: '정확 좌표 숨김'),
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
    return _PrivacyCard(
      title: '배터리 모드',
      trailing: _Badge(text: _batteryModeBadge(mode)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_BatteryMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _BatteryMode.live,
                  icon: Icon(Icons.speed_outlined),
                  label: Text('실시간'),
                ),
                ButtonSegment(
                  value: _BatteryMode.balanced,
                  icon: Icon(Icons.tune_outlined),
                  label: Text('균형'),
                ),
                ButtonSegment(
                  value: _BatteryMode.saver,
                  icon: Icon(Icons.battery_saver_outlined),
                  label: Text('절전'),
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
            label: _batteryModeTitle(mode),
            value: _batteryModeInterval(mode),
            detail: _batteryModeDetail(mode),
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
    final current = snapshot;

    return _PrivacyCard(
      title: '권한 상태',
      trailing: IconButton.filledTonal(
        tooltip: '권한 상태 새로고침',
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
            label: '위치 권한',
            value: current == null
                ? '기기 빌드'
                : current.foregroundGranted
                    ? '앱 사용 중'
                    : '대기',
            detail: current == null
                ? 'Android/iOS에서 실제 권한을 확인합니다.'
                : current.foregroundGranted
                    ? '지도와 동행 모드의 기본 위치 공유'
                    : '위치 공유 시작 전에 권한 안내가 필요합니다.',
          ),
          _ModeRow(
            label: '배경 위치',
            value: current == null
                ? '필요 시'
                : current.backgroundGranted
                    ? '허용됨'
                    : '필요 시',
            detail: '동행, 장소 알림처럼 켜진 기능에서 단계적으로 요청',
          ),
          _ModeRow(
            label: '정확한 위치',
            value: current == null
                ? '확인 전'
                : current.preciseGranted
                    ? '정확'
                    : '대략',
            detail: current?.preciseGranted == false
                ? '대략 위치에서는 반경 원으로 표시됩니다.'
                : '공유 정밀도에 맞춰 지도 반경을 표시합니다.',
          ),
          _ModeRow(
            label: '알림',
            value: current == null
                ? '안심 알림'
                : current.notificationsGranted
                    ? '허용됨'
                    : '대기',
            detail: '도착 확인, 장소 알림, SOS 수신',
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
    return _PrivacyCard(
      title: '최근 조회',
      trailing: TextButton(onPressed: () {}, child: const Text('전체')),
      child: const Column(
        children: [
          _ModeRow(label: '미라', value: '방금', detail: '가족 서클 · 균형 위치'),
          _ModeRow(label: '준', value: '12분 전', detail: '동행 세션 · 경로 꼬리'),
          _ModeRow(label: '하나', value: '어제', detail: '친구 서클 · 동네만'),
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
    final palette = context.palette;

    return _PrivacyCard(
      title: '광고와 데이터',
      trailing: const _Badge(text: '정밀 위치 광고 차단'),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('개인화 광고'),
            subtitle: Text('동의 전에는 비개인화 광고만 사용',
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
            title: const Text('민감 카테고리 차단'),
            subtitle: Text('가족, 위치, 응급 상황 문맥 보호',
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
    return _PrivacyCard(
      title: '내 데이터',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ModeRow(label: '위치 기록', value: '30일', detail: '만료 후 자동 삭제'),
          const _ModeRow(
              label: '동행 경로', value: '24시간', detail: '세션 종료 후 요약 보관'),
          const _ModeRow(label: '조회 로그', value: '30일', detail: '내가 확인 가능'),
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
                  child: const Text('내보내기'),
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
                  child: Text(isLoading ? '요청 중' : '기록 삭제'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _batteryModeBadge(_BatteryMode mode) {
  switch (mode) {
    case _BatteryMode.live:
      return '빠른 갱신';
    case _BatteryMode.balanced:
      return '추천';
    case _BatteryMode.saver:
      return '느린 갱신';
  }
}

String _batteryModeTitle(_BatteryMode mode) {
  switch (mode) {
    case _BatteryMode.live:
      return '실시간 우선';
    case _BatteryMode.balanced:
      return '균형 우선';
    case _BatteryMode.saver:
      return '절전 우선';
  }
}

String _batteryModeInterval(_BatteryMode mode) {
  switch (mode) {
    case _BatteryMode.live:
      return '15-30초';
    case _BatteryMode.balanced:
      return '30-90초';
    case _BatteryMode.saver:
      return '2-5분';
  }
}

String _batteryModeDetail(_BatteryMode mode) {
  switch (mode) {
    case _BatteryMode.live:
      return '동행 중 빠르게 업데이트하며 배터리 사용량이 높아질 수 있습니다.';
    case _BatteryMode.balanced:
      return '일상 공유에 맞춰 위치 최신성과 배터리를 함께 봅니다.';
    case _BatteryMode.saver:
      return '배터리가 낮을 때 업데이트 간격을 늘리고 주요 알림을 우선합니다.';
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
                    style: const TextStyle(fontWeight: FontWeight.w900)),
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
                      style: const TextStyle(fontWeight: FontWeight.w900))),
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
            fontWeight: FontWeight.w800),
      ),
    );
  }
}
