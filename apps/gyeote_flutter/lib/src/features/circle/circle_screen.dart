import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_bridge.dart';
import '../../core/location/location_models.dart';
import '../../core/location/place_alert_geofence_sync.dart';
import '../../theme/gyeote_theme.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({
    super.key,
    this.circleRepository,
    this.invitationRepository,
    this.placeAlertRepository,
    this.checkInRepository,
    this.locationBridge,
  });

  final CircleRepository? circleRepository;
  final InvitationRepository? invitationRepository;
  final PlaceAlertRepository? placeAlertRepository;
  final CheckInRepository? checkInRepository;
  final LocationBridge? locationBridge;

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  static const _demoMembers = [
    _CircleMember(
        name: '미라', role: '보호자', status: '정확 공유', tone: GyeoteTone.brand),
    _CircleMember(
        name: '준', role: '자녀', status: '동행 대기', tone: GyeoteTone.move),
    _CircleMember(
        name: '하나', role: '친구', status: '균형 공유', tone: GyeoteTone.warm),
    _CircleMember(
        name: '할아버지', role: '케어', status: '동네만', tone: GyeoteTone.alert),
  ];

  List<CircleSummary> _circles = const [];
  List<PlaceAlertRule> _placeAlerts = const [];
  List<CheckInEvent> _checkIns = const [];
  final Set<String> _busyPlaceAlertIds = {};
  final _inviteInputController = TextEditingController();
  InviteCreationResult? _inviteResult;
  String? _statusMessage;
  String? _placeAlertMessage;
  String? _checkInMessage;
  bool _isLoadingCircles = false;
  bool _isLoadingPlaceAlerts = false;
  bool _isLoadingCheckIns = false;
  bool _isCreatingInvite = false;
  bool _isAcceptingInvite = false;

  bool get _hasBackend =>
      widget.circleRepository != null && widget.invitationRepository != null;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  @override
  void dispose() {
    _inviteInputController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CircleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circleRepository != widget.circleRepository ||
        oldWidget.invitationRepository != widget.invitationRepository ||
        oldWidget.placeAlertRepository != widget.placeAlertRepository ||
        oldWidget.checkInRepository != widget.checkInRepository ||
        oldWidget.locationBridge != widget.locationBridge) {
      _circles = const [];
      _placeAlerts = const [];
      _checkIns = const [];
      _busyPlaceAlertIds.clear();
      _inviteResult = null;
      _statusMessage = null;
      _placeAlertMessage = null;
      _checkInMessage = null;
      _loadCircles();
    }
  }

  Future<void> _loadCircles() async {
    final repository = widget.circleRepository;
    if (repository == null) {
      return;
    }

    setState(() {
      _isLoadingCircles = true;
      _isLoadingPlaceAlerts = false;
      _isLoadingCheckIns = false;
      _statusMessage = null;
      _placeAlertMessage = null;
      _checkInMessage = null;
    });

    try {
      final circles = await repository.listCircles();
      if (!mounted) {
        return;
      }
      setState(() {
        _circles = circles;
        _isLoadingCircles = false;
      });
      if (circles.isNotEmpty) {
        await _loadPlaceAlerts(circles.first.id);
        await _loadCheckIns(circles.first.id);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCircles = false;
        _statusMessage = '서클을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _loadPlaceAlerts(String circleId) async {
    final repository = widget.placeAlertRepository;
    if (repository == null) {
      if (mounted) {
        setState(() => _placeAlerts = const []);
      }
      return;
    }

    setState(() {
      _isLoadingPlaceAlerts = true;
      _placeAlertMessage = null;
    });

    try {
      final alerts = await repository.listPlaceAlerts(circleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _placeAlerts = alerts;
        _isLoadingPlaceAlerts = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _placeAlerts = const [];
        _isLoadingPlaceAlerts = false;
        _placeAlertMessage = '장소 알림을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _loadCheckIns(String circleId) async {
    final repository = widget.checkInRepository;
    if (repository == null) {
      if (mounted) {
        setState(() => _checkIns = const []);
      }
      return;
    }

    setState(() {
      _isLoadingCheckIns = true;
      _checkInMessage = null;
    });

    try {
      final events = await repository.listRecentCheckIns(
        circleId: circleId,
        limit: 5,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _checkIns = events;
        _isLoadingCheckIns = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _checkIns = const [];
        _isLoadingCheckIns = false;
        _checkInMessage = '안전 확인 기록을 불러오지 못했습니다.';
      });
    }
  }

  Future<CircleSummary> _ensureCircle() async {
    if (_circles.isNotEmpty) {
      return _circles.first;
    }

    final repository = widget.circleRepository;
    if (repository == null) {
      throw StateError('Circle repository is not configured.');
    }

    final circle = await repository.createCircle(name: '가족 서클');
    if (mounted) {
      setState(() => _circles = [circle]);
      await _loadPlaceAlerts(circle.id);
      await _loadCheckIns(circle.id);
    }
    return circle;
  }

  Future<void> _createInvite() async {
    if (!_hasBackend) {
      setState(() => _statusMessage = 'Supabase 연결 후 실제 초대 링크를 만들 수 있습니다.');
      return;
    }

    setState(() {
      _isCreatingInvite = true;
      _statusMessage = null;
    });

    try {
      final circle = await _ensureCircle();
      final invite = await widget.invitationRepository!.createInvite(
        circleId: circle.id,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _inviteResult = invite;
        _statusMessage = '24시간 초대 링크를 만들었습니다.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _statusMessage = '초대 링크를 만들지 못했습니다. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) {
        setState(() => _isCreatingInvite = false);
      }
    }
  }

  Future<void> _copyInviteLink() async {
    final invite = _inviteResult;
    if (invite == null) {
      return;
    }

    await Clipboard.setData(
        ClipboardData(text: invite.rawInviteUrl.toString()));
    if (mounted) {
      setState(() => _statusMessage = '초대 링크를 복사했습니다.');
    }
  }

  Future<void> _acceptInvite() async {
    final repository = widget.invitationRepository;
    final rawInput = _inviteInputController.text.trim();

    if (repository == null) {
      setState(() => _statusMessage = 'Supabase 연결 후 초대를 수락할 수 있습니다.');
      return;
    }

    final token = _inviteTokenFromInput(rawInput);
    if (token == null) {
      setState(() => _statusMessage = '초대 링크나 토큰을 입력해 주세요.');
      return;
    }

    setState(() {
      _isAcceptingInvite = true;
      _statusMessage = null;
    });

    try {
      await repository.acceptInvite(rawInviteToken: token);
      _inviteInputController.clear();
      await _loadCircles();
      if (!mounted) {
        return;
      }
      setState(() => _statusMessage = '초대를 수락했습니다.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _statusMessage = '초대를 수락하지 못했습니다. 만료 여부를 확인해 주세요.');
    } finally {
      if (mounted) {
        setState(() => _isAcceptingInvite = false);
      }
    }
  }

  Future<void> _setPlaceAlertEnabled(PlaceAlertRule alert) async {
    final repository = widget.placeAlertRepository;
    if (repository == null) {
      setState(() => _placeAlertMessage = 'Supabase 연결 후 장소 알림을 변경할 수 있습니다.');
      return;
    }

    final nextEnabled = !alert.enabled;
    setState(() {
      _busyPlaceAlertIds.add(alert.id);
      _placeAlertMessage = null;
    });

    try {
      await repository.setPlaceAlertEnabled(
        alertId: alert.id,
        enabled: nextEnabled,
      );
      await _loadPlaceAlerts(alert.circleId);
      final synced = await _syncPlaceAlertGeofences(alert.circleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _placeAlertMessage = synced
            ? (nextEnabled ? '장소 알림을 다시 켰습니다.' : '장소 알림을 일시정지했습니다.')
            : '서버 변경은 완료됐고, 기기 반경 동기화는 대기 중입니다.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _placeAlertMessage = '장소 알림 상태를 변경하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() => _busyPlaceAlertIds.remove(alert.id));
      }
    }
  }

  Future<void> _cyclePlaceAlertQuietHours(PlaceAlertRule alert) async {
    final repository = widget.placeAlertRepository;
    if (repository == null) {
      setState(() => _placeAlertMessage = 'Supabase 연결 후 조용한 시간을 변경할 수 있습니다.');
      return;
    }

    final nextQuietHours = _nextPlaceAlertQuietHours(alert.quietHours);
    setState(() {
      _busyPlaceAlertIds.add(alert.id);
      _placeAlertMessage = null;
    });

    try {
      await repository.setPlaceAlertQuietHours(
        alertId: alert.id,
        quietHours: nextQuietHours,
      );
      await _loadPlaceAlerts(alert.circleId);
      if (!mounted) {
        return;
      }
      setState(() =>
          _placeAlertMessage = '조용한 시간을 ${nextQuietHours.summary}(으)로 변경했습니다.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _placeAlertMessage = '조용한 시간을 변경하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() => _busyPlaceAlertIds.remove(alert.id));
      }
    }
  }

  Future<void> _confirmDeletePlaceAlert(PlaceAlertRule alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('장소 알림 삭제'),
        content:
            Text('${alert.name} 알림을 삭제할까요? 대상 멤버에게 더 이상 도착/이탈 알림이 가지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePlaceAlert(alert);
    }
  }

  Future<void> _deletePlaceAlert(PlaceAlertRule alert) async {
    final repository = widget.placeAlertRepository;
    if (repository == null) {
      setState(() => _placeAlertMessage = 'Supabase 연결 후 장소 알림을 삭제할 수 있습니다.');
      return;
    }

    setState(() {
      _busyPlaceAlertIds.add(alert.id);
      _placeAlertMessage = null;
    });

    try {
      await repository.deletePlaceAlert(alert.id);
      await _loadPlaceAlerts(alert.circleId);
      final synced = await _syncPlaceAlertGeofences(alert.circleId);
      if (!mounted) {
        return;
      }
      setState(() => _placeAlertMessage =
          synced ? '장소 알림을 삭제했습니다.' : '서버 삭제는 완료됐고, 기기 반경 동기화는 대기 중입니다.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _placeAlertMessage = '장소 알림을 삭제하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() => _busyPlaceAlertIds.remove(alert.id));
      }
    }
  }

  Future<bool> _syncPlaceAlertGeofences(String circleId) async {
    final repository = widget.placeAlertRepository;
    final bridge = widget.locationBridge;
    if (repository == null || bridge == null) {
      return true;
    }

    try {
      await syncPlaceAlertGeofences(
        repository: repository,
        locationBridge: bridge,
        circleId: circleId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _inviteTokenFromInput(String value) {
    if (value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    final token = uri?.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      return token;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final activeCircle = _circles.isEmpty ? null : _circles.first;
    final memberCount = activeCircle == null || activeCircle.memberCount == 0
        ? 1
        : activeCircle.memberCount;
    final title = activeCircle?.name ?? '가족 서클';
    final subtitle = _isLoadingCircles
        ? '서클 동기화 중'
        : activeCircle == null
            ? '첫 서클을 만들고 가까운 사람을 초대하세요'
            : '$memberCount명 · 장소 3개 · 동행 세션 1개 대기';
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(color: palette.muted)),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(_statusMessage!,
                        style: TextStyle(color: statusColor, fontSize: 12)),
                  ],
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _isCreatingInvite
                  ? null
                  : () async {
                      await _createInvite();
                    },
              icon: _isCreatingInvite
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_add_alt_1_outlined),
              label: Text(activeCircle == null ? '서클 만들기' : '초대하기'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InviteCard(
          inviteResult: _inviteResult,
          onCreateInvite: _isCreatingInvite ? null : _createInvite,
          onCopyInvite: _inviteResult == null ? null : _copyInviteLink,
        ),
        const SizedBox(height: 12),
        _InviteAcceptCard(
          controller: _inviteInputController,
          isLoading: _isAcceptingInvite,
          onAccept: _acceptInvite,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '멤버',
          trailing: TextButton(
            onPressed: activeCircle == null && _hasBackend ? null : () {},
            child: const Text('멤버 관리'),
          ),
          child: activeCircle == null && _hasBackend
              ? const _EmptyMembersState()
              : Column(
                  children: [
                    for (final member in _demoMembers)
                      _MemberRow(member: member),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        const _CompanionRequestCard(),
        const SizedBox(height: 12),
        _CheckInStatusCard(
          events: _hasBackend ? _checkIns : null,
          hasCircle: activeCircle != null,
          isLoading: _isLoadingCheckIns,
          message: _checkInMessage,
        ),
        const SizedBox(height: 12),
        _PlaceAlertCard(
          alerts: _hasBackend ? _placeAlerts : null,
          hasCircle: activeCircle != null,
          isLoading: _isLoadingPlaceAlerts,
          message: _placeAlertMessage,
          busyAlertIds: _busyPlaceAlertIds,
          onToggleEnabled: _setPlaceAlertEnabled,
          onCycleQuietHours: _cyclePlaceAlertQuietHours,
          onDelete: _confirmDeletePlaceAlert,
        ),
      ],
    );
  }
}

class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.brandSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('아직 멤버가 없습니다', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('초대 링크를 만들면 이곳에 수락한 멤버가 표시됩니다.',
              style: TextStyle(color: palette.muted)),
        ],
      ),
    );
  }
}

class _InviteAcceptCard extends StatelessWidget {
  const _InviteAcceptCard({
    required this.controller,
    required this.isLoading,
    required this.onAccept,
  });

  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function() onAccept;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '초대 참여',
      trailing: const _StatusChip(text: '토큰 확인'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '초대 링크 또는 토큰',
              prefixIcon: Icon(Icons.link_outlined),
            ),
            onSubmitted: (_) async {
              if (!isLoading) {
                await onAccept();
              }
            },
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isLoading
                ? null
                : () async {
                    await onAccept();
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: const Text('참여'),
          ),
        ],
      ),
    );
  }
}

class _CircleMember {
  const _CircleMember({
    required this.name,
    required this.role,
    required this.status,
    required this.tone,
  });

  final String name;
  final String role;
  final String status;
  final GyeoteTone tone;
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.inviteResult,
    required this.onCreateInvite,
    required this.onCopyInvite,
  });

  final InviteCreationResult? inviteResult;
  final Future<void> Function()? onCreateInvite;
  final Future<void> Function()? onCopyInvite;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final invite = inviteResult?.invite;
    final rawInviteUrl = inviteResult?.rawInviteUrl.toString();

    return _SectionCard(
      title: '초대 링크',
      trailing: _StatusChip(text: invite == null ? '24시간' : invite.codeHint),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invite == null ? 'GYE-42K' : invite.codeHint,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0),
          ),
          const SizedBox(height: 6),
          Text(
            rawInviteUrl ?? '1회 사용 · 수락 전 공유 범위 확인 · 원문 토큰 저장 안 함',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.muted),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(text: '초대자 확인'),
              _StatusChip(text: '광고 안내'),
              _StatusChip(text: '위치 동의'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCreateInvite == null
                      ? null
                      : () async {
                          await onCreateInvite!();
                        },
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('새 링크'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCopyInvite == null
                      ? null
                      : () async {
                          await onCopyInvite!();
                        },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('복사'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final _CircleMember member;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: member.tone.resolveSoft(palette),
            child: Text(
              member.name.characters.first,
              style: TextStyle(
                  color: member.tone.resolve(palette),
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(member.role,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
          _StatusChip(text: member.status),
        ],
      ),
    );
  }
}

class _CompanionRequestCard extends StatelessWidget {
  const _CompanionRequestCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return _SectionCard(
      title: '동행 요청',
      trailing: const _StatusChip(text: '상호 동의'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('준 · 학교에서 집까지',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('15분 동안 균형 위치와 경로 꼬리만 공유됩니다.',
              style: TextStyle(color: palette.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {}, child: const Text('나중에'))),
              const SizedBox(width: 8),
              Expanded(
                  child: FilledButton(
                      onPressed: () {}, child: const Text('동행 허용'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckInStatusCard extends StatelessWidget {
  const _CheckInStatusCard({
    required this.events,
    required this.hasCircle,
    required this.isLoading,
    required this.message,
  });

  final List<CheckInEvent>? events;
  final bool hasCircle;
  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final items = events;
    final countLabel = items == null ? '예시' : '${items.length}개';

    return _SectionCard(
      title: '안전 확인',
      trailing: _StatusChip(text: isLoading ? '동기화' : countLabel),
      child: _CheckInStatusBody(
        events: items,
        hasCircle: hasCircle,
        isLoading: isLoading,
        message: message,
      ),
    );
  }
}

class _CheckInStatusBody extends StatelessWidget {
  const _CheckInStatusBody({
    required this.events,
    required this.hasCircle,
    required this.isLoading,
    required this.message,
  });

  final List<CheckInEvent>? events;
  final bool hasCircle;
  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _InlineLoadingState(text: '안전 확인 기록을 불러오는 중입니다.');
    }

    if (message != null) {
      return _InlineEmptyState(
        icon: Icons.sync_problem_outlined,
        title: '안전 확인 동기화 실패',
        body: message!,
      );
    }

    final items = events;
    if (items == null) {
      return const Column(
        children: [
          _CheckInRow(
            name: '준',
            status: '무사 도착',
            body: '동행 공유 종료 · 균형 위치로 알림 · 방금',
          ),
          _CheckInRow(
            name: '할아버지',
            status: '신호가 잠시 약해요',
            body: '배터리, 신호, 권한, 기기 상태를 확인해 주세요.',
          ),
        ],
      );
    }

    if (!hasCircle) {
      return const _InlineEmptyState(
        icon: Icons.verified_user_outlined,
        title: '서클을 먼저 만들어 주세요',
        body: '도착 확인은 서클 멤버에게 짧은 안심 신호로 전달됩니다.',
      );
    }

    if (items.isEmpty) {
      return const _InlineEmptyState(
        icon: Icons.check_circle_outline,
        title: '최근 안전 확인이 없습니다',
        body: '동행 중 도착 확인을 보내면 이곳에 무사 도착 기록이 표시됩니다.',
      );
    }

    return Column(
      children: [
        for (final event in items)
          _CheckInRow(
            name: event.displayName,
            status: _checkInStatusLabel(event.status),
            body:
                '${_sharingModeLabel(event.sharingMode)} 위치로 알림 · ${_relativeTimeLabel(event.createdAt)}',
          ),
      ],
    );
  }
}

class _CheckInRow extends StatelessWidget {
  const _CheckInRow({
    required this.name,
    required this.status,
    required this.body,
  });

  final String name;
  final String status;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 20, color: palette.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name · $status',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceAlertCard extends StatelessWidget {
  const _PlaceAlertCard({
    required this.alerts,
    required this.hasCircle,
    required this.isLoading,
    required this.message,
    required this.busyAlertIds,
    required this.onToggleEnabled,
    required this.onCycleQuietHours,
    required this.onDelete,
  });

  final List<PlaceAlertRule>? alerts;
  final bool hasCircle;
  final bool isLoading;
  final String? message;
  final Set<String> busyAlertIds;
  final ValueChanged<PlaceAlertRule> onToggleEnabled;
  final ValueChanged<PlaceAlertRule> onCycleQuietHours;
  final ValueChanged<PlaceAlertRule> onDelete;

  @override
  Widget build(BuildContext context) {
    final rules = alerts;
    final countLabel = rules == null ? '예시' : '${rules.length}개';

    return _SectionCard(
      title: '장소 알림',
      trailing: _StatusChip(text: isLoading ? '동기화' : countLabel),
      child: _PlaceAlertCardBody(
        alerts: rules,
        hasCircle: hasCircle,
        isLoading: isLoading,
        message: message,
        busyAlertIds: busyAlertIds,
        onToggleEnabled: onToggleEnabled,
        onCycleQuietHours: onCycleQuietHours,
        onDelete: onDelete,
      ),
    );
  }
}

class _PlaceAlertCardBody extends StatelessWidget {
  const _PlaceAlertCardBody({
    required this.alerts,
    required this.hasCircle,
    required this.isLoading,
    required this.message,
    required this.busyAlertIds,
    required this.onToggleEnabled,
    required this.onCycleQuietHours,
    required this.onDelete,
  });

  final List<PlaceAlertRule>? alerts;
  final bool hasCircle;
  final bool isLoading;
  final String? message;
  final Set<String> busyAlertIds;
  final ValueChanged<PlaceAlertRule> onToggleEnabled;
  final ValueChanged<PlaceAlertRule> onCycleQuietHours;
  final ValueChanged<PlaceAlertRule> onDelete;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _InlineLoadingState(text: '장소 알림을 불러오는 중입니다.');
    }

    final rules = alerts;
    final messageBanner = message == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InlineNoticeState(
              icon: _placeAlertMessageIcon(message!),
              title: _placeAlertMessageTitle(message!),
              body: message!,
              isError: _placeAlertMessageIsError(message!),
            ),
          );

    if (rules == null) {
      return Column(
        children: [
          if (messageBanner != null) messageBanner,
          const _AlertRule(
              title: '학교', body: '평일 08:00-17:00 · 도착/이탈 · 10분 지연'),
          const _AlertRule(title: '집', body: '가족 전체 · 도착 확인'),
          const _AlertRule(title: '병원', body: '할아버지 · 오래 머무름 확인'),
        ],
      );
    }

    if (!hasCircle) {
      return Column(
        children: [
          if (messageBanner != null) messageBanner,
          const _InlineEmptyState(
            icon: Icons.add_location_alt_outlined,
            title: '서클을 먼저 만들어 주세요',
            body: '장소 알림은 서클 멤버와 공유 범위를 정한 뒤 사용할 수 있습니다.',
          ),
        ],
      );
    }

    if (rules.isEmpty) {
      return Column(
        children: [
          if (messageBanner != null) messageBanner,
          const _InlineEmptyState(
            icon: Icons.notifications_none_outlined,
            title: '저장된 장소 알림이 없습니다',
            body: '지도에서 반경을 미리 보고 대상 멤버를 고른 뒤 안전한 알림 규칙으로 추가할 예정입니다.',
          ),
        ],
      );
    }

    return Column(
      children: [
        if (messageBanner != null) messageBanner,
        for (final alert in rules)
          _AlertRule(
            title: alert.name,
            body: _placeAlertBody(alert),
            enabled: alert.enabled,
            isBusy: busyAlertIds.contains(alert.id),
            onToggleEnabled: () => onToggleEnabled(alert),
            onCycleQuietHours: () => onCycleQuietHours(alert),
            onDelete: () => onDelete(alert),
          ),
      ],
    );
  }
}

class _InlineNoticeState extends StatelessWidget {
  const _InlineNoticeState({
    required this.icon,
    required this.title,
    required this.body,
    required this.isError,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final color = isError ? palette.alert : palette.brand;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRule extends StatelessWidget {
  const _AlertRule({
    required this.title,
    required this.body,
    this.enabled = true,
    this.isBusy = false,
    this.onToggleEnabled,
    this.onCycleQuietHours,
    this.onDelete,
  });

  final String title;
  final String body;
  final bool enabled;
  final bool isBusy;
  final VoidCallback? onToggleEnabled;
  final VoidCallback? onCycleQuietHours;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final iconColor = enabled ? palette.warm : palette.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    if (isBusy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      if (!enabled) const _StatusChip(text: '일시정지'),
                      if (onToggleEnabled != null) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: enabled ? '일시정지' : '다시 켜기',
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(enabled
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline),
                            onPressed: onToggleEnabled,
                          ),
                        ),
                      ],
                      if (onCycleQuietHours != null) ...[
                        const SizedBox(width: 2),
                        Tooltip(
                          message: '조용한 시간 변경',
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.bedtime_outlined),
                            onPressed: onCycleQuietHours,
                          ),
                        ),
                      ],
                      if (onDelete != null) ...[
                        const SizedBox(width: 2),
                        Tooltip(
                          message: '삭제',
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline),
                            color: palette.alert,
                            onPressed: onDelete,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoadingState extends StatelessWidget {
  const _InlineLoadingState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: palette.muted)),
        ),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.surfaceAlt,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.brand, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(body,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _placeAlertBody(PlaceAlertRule alert) {
  final events = [
    if (alert.notifyOnArrival) '도착',
    if (alert.notifyOnDeparture) '이탈',
    if (alert.notifyOnLate) '늦음 확인',
    if (alert.notifyOnLongStay) '오래 머무름',
  ];
  final quietHoursLabel =
      alert.quietHours.enabled ? '조용한 시간 ${alert.quietHours.summary}' : null;
  final targetLabel =
      alert.targetCount == 0 ? '대상 미지정' : '${alert.targetCount}명';
  final eventLabel = events.isEmpty ? '알림 조건 없음' : events.join('/');
  return [
    targetLabel,
    '반경 ${alert.radiusM}m',
    eventLabel,
    if (quietHoursLabel != null) quietHoursLabel,
  ].join(' · ');
}

PlaceAlertQuietHours _nextPlaceAlertQuietHours(PlaceAlertQuietHours current) {
  if (!current.enabled) {
    return const PlaceAlertQuietHours(
      enabled: true,
      start: '22:00',
      end: '07:00',
      timeZone: 'Asia/Seoul',
      label: '야간',
    );
  }

  if (current.label == '야간') {
    return const PlaceAlertQuietHours(
      enabled: true,
      start: '09:00',
      end: '17:00',
      timeZone: 'Asia/Seoul',
      label: '수업/근무',
    );
  }

  return const PlaceAlertQuietHours.none();
}

bool _placeAlertMessageIsError(String message) {
  return message.contains('못했습니다') || message.contains('대기 중');
}

IconData _placeAlertMessageIcon(String message) {
  if (message.contains('대기 중')) {
    return Icons.sync_problem_outlined;
  }
  if (_placeAlertMessageIsError(message)) {
    return Icons.error_outline;
  }
  return Icons.check_circle_outline;
}

String _placeAlertMessageTitle(String message) {
  if (message.contains('대기 중')) {
    return '기기 동기화 대기';
  }
  if (_placeAlertMessageIsError(message)) {
    return '장소 알림 변경 실패';
  }
  return '장소 알림 업데이트';
}

String _checkInStatusLabel(CheckInStatus status) {
  switch (status) {
    case CheckInStatus.safeArrived:
      return '무사 도착';
    case CheckInStatus.needsCheck:
      return '확인 필요';
    case CheckInStatus.signalWeak:
      return '신호가 잠시 약해요';
  }
}

String _sharingModeLabel(SharingMode mode) {
  switch (mode) {
    case SharingMode.precise:
      return '정확';
    case SharingMode.balanced:
      return '균형';
    case SharingMode.area:
      return '동네 범위';
    case SharingMode.hidden:
      return '숨김';
    case SharingMode.sosOnly:
      return '긴급 전용';
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

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
