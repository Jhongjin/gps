import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_models.dart';
import '../../theme/gyeote_theme.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({
    super.key,
    this.circleRepository,
    this.invitationRepository,
    this.placeAlertRepository,
    this.checkInRepository,
  });

  final CircleRepository? circleRepository;
  final InvitationRepository? invitationRepository;
  final PlaceAlertRepository? placeAlertRepository;
  final CheckInRepository? checkInRepository;

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  static const _demoMembers = [
    _CircleMember(
        name: '미라', role: '보호자', status: '정확 공유', tone: GyeoteColors.primary),
    _CircleMember(
        name: '준', role: '자녀', status: '동행 대기', tone: GyeoteColors.info),
    _CircleMember(
        name: '하나', role: '친구', status: '균형 공유', tone: GyeoteColors.amber),
    _CircleMember(
        name: '할아버지', role: '케어', status: '동네만', tone: GyeoteColors.danger),
  ];

  List<CircleSummary> _circles = const [];
  List<PlaceAlertRule> _placeAlerts = const [];
  List<CheckInEvent> _checkIns = const [];
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
        oldWidget.checkInRepository != widget.checkInRepository) {
      _circles = const [];
      _placeAlerts = const [];
      _checkIns = const [];
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
        ? GyeoteColors.danger
        : GyeoteColors.primary;

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
                      style: const TextStyle(color: GyeoteColors.muted)),
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
        ),
      ],
    );
  }
}

class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.primarySoft,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('아직 멤버가 없습니다', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('초대 링크를 만들면 이곳에 수락한 멤버가 표시됩니다.',
              style: TextStyle(color: GyeoteColors.muted)),
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
  final Color tone;
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
            style: const TextStyle(color: GyeoteColors.muted),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: member.tone.withValues(alpha: 0.14),
            child: Text(
              member.name.substring(0, 1),
              style: TextStyle(color: member.tone, fontWeight: FontWeight.w900),
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
                    style: const TextStyle(
                        color: GyeoteColors.muted, fontSize: 12)),
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
    return _SectionCard(
      title: '동행 요청',
      trailing: const _StatusChip(text: '상호 동의'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('준 · 학교에서 집까지',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('15분 동안 균형 위치와 경로 꼬리만 공유됩니다.',
              style: TextStyle(color: GyeoteColors.muted)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 20, color: GyeoteColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name · $status',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        color: GyeoteColors.muted, fontSize: 12)),
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
  });

  final List<PlaceAlertRule>? alerts;
  final bool hasCircle;
  final bool isLoading;
  final String? message;

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
  });

  final List<PlaceAlertRule>? alerts;
  final bool hasCircle;
  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _InlineLoadingState(text: '장소 알림을 불러오는 중입니다.');
    }

    if (message != null) {
      return _InlineEmptyState(
        icon: Icons.sync_problem_outlined,
        title: '장소 알림 동기화 실패',
        body: message!,
      );
    }

    final rules = alerts;
    if (rules == null) {
      return const Column(
        children: [
          _AlertRule(title: '학교', body: '평일 08:00-17:00 · 도착/이탈 · 10분 지연'),
          _AlertRule(title: '집', body: '가족 전체 · 도착 확인'),
          _AlertRule(title: '병원', body: '할아버지 · 오래 머무름 확인'),
        ],
      );
    }

    if (!hasCircle) {
      return const _InlineEmptyState(
        icon: Icons.add_location_alt_outlined,
        title: '서클을 먼저 만들어 주세요',
        body: '장소 알림은 서클 멤버와 공유 범위를 정한 뒤 사용할 수 있습니다.',
      );
    }

    if (rules.isEmpty) {
      return const _InlineEmptyState(
        icon: Icons.notifications_none_outlined,
        title: '저장된 장소 알림이 없습니다',
        body: '지도에서 반경을 미리 보고 대상 멤버를 고른 뒤 안전한 알림 규칙으로 추가할 예정입니다.',
      );
    }

    return Column(
      children: [
        for (final alert in rules)
          _AlertRule(
            title: alert.name,
            body: _placeAlertBody(alert),
            enabled: alert.enabled,
          ),
      ],
    );
  }
}

class _AlertRule extends StatelessWidget {
  const _AlertRule({
    required this.title,
    required this.body,
    this.enabled = true,
  });

  final String title;
  final String body;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? GyeoteColors.amber : GyeoteColors.muted;
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
                    if (!enabled) const _StatusChip(text: '일시정지'),
                  ],
                ),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        color: GyeoteColors.muted, fontSize: 12)),
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
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: GyeoteColors.muted)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.surfaceAlt,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GyeoteColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(body,
                    style: const TextStyle(
                        color: GyeoteColors.muted, fontSize: 12)),
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
  final targetLabel =
      alert.targetCount == 0 ? '대상 미지정' : '${alert.targetCount}명';
  final eventLabel = events.isEmpty ? '알림 조건 없음' : events.join('/');
  return '$targetLabel · 반경 ${alert.radiusM}m · $eventLabel';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(6),
        color: GyeoteColors.surfaceAlt,
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: GyeoteColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800),
      ),
    );
  }
}
