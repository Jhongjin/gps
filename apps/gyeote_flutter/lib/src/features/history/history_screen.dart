import 'package:flutter/material.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_models.dart';
import '../../theme/gyeote_theme.dart';

enum _HistoryFilter {
  all,
  checkIn,
  place,
  companion,
  data,
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    this.circleRepository,
    this.checkInRepository,
  });

  final CircleRepository? circleRepository;
  final CheckInRepository? checkInRepository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _demoEvents = [
    _HistoryEvent(
        time: '08:10',
        type: '장소',
        title: '준 학교 도착',
        detail: '예상보다 4분 빠름',
        color: GyeoteColors.primary),
    _HistoryEvent(
        time: '12:42',
        type: '조회',
        title: '미라가 내 위치 확인',
        detail: '가족 서클 · 균형 위치',
        color: GyeoteColors.info),
    _HistoryEvent(
        time: '17:18',
        type: '동행',
        title: '할아버지 산책 시작',
        detail: '15분 동행 세션 · 상호 동의',
        color: GyeoteColors.amber),
    _HistoryEvent(
        time: '18:02',
        type: '확인',
        title: '준 무사 도착',
        detail: '동행 공유 종료 · 균형 위치로 알림',
        color: GyeoteColors.primary),
    _HistoryEvent(
        time: '18:03',
        type: '데이터',
        title: '위치 기록 삭제 요청',
        detail: '처리 대기 중',
        color: GyeoteColors.danger),
  ];

  List<CheckInEvent> _checkIns = const [];
  _HistoryFilter _filter = _HistoryFilter.all;
  bool _isLoading = false;
  String? _message;

  bool get _hasBackend =>
      widget.circleRepository != null && widget.checkInRepository != null;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circleRepository != widget.circleRepository ||
        oldWidget.checkInRepository != widget.checkInRepository) {
      _checkIns = const [];
      _message = null;
      _loadCheckIns();
    }
  }

  Future<void> _loadCheckIns() async {
    if (!_hasBackend) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final circles = await widget.circleRepository!.listCircles();
      if (circles.isEmpty) {
        if (mounted) {
          setState(() {
            _checkIns = const [];
            _isLoading = false;
          });
        }
        return;
      }

      final events = await widget.checkInRepository!.listRecentCheckIns(
        circleId: circles.first.id,
        limit: 12,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _checkIns = events;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _message = '활동 기록을 불러오지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _hasBackend
        ? _checkIns.map(_historyEventFromCheckIn).toList(growable: false)
        : _demoEvents;
    final visibleEvents =
        events.where((event) => _matchesFilter(event, _filter)).toList();
    final checkInCount = _hasBackend ? _checkIns.length : 1;
    final checkInEvents = events.where((event) => event.type == '확인').toList();
    final latestCheckIn = checkInEvents.isEmpty ? null : checkInEvents.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('오늘 활동',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('장소 알림, 조회 로그, 동행 세션, 안전 확인',
            style: TextStyle(color: GyeoteColors.muted)),
        if (_message != null) ...[
          const SizedBox(height: 4),
          Text(_message!,
              style: const TextStyle(color: GyeoteColors.danger, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        _SummaryBand(checkInCount: checkInCount),
        const SizedBox(height: 12),
        _SafetySummaryCard(
          checkInCount: checkInCount,
          latestCheckIn: latestCheckIn,
        ),
        const SizedBox(height: 12),
        _HistoryFilterBar(
          selected: _filter,
          onChanged: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const _HistoryEmptyState(
            icon: Icons.sync_outlined,
            title: '활동 기록 동기화 중',
            body: '안전 확인과 동행 종료 기록을 불러오고 있습니다.',
          )
        else if (_hasBackend && events.isEmpty)
          const _HistoryEmptyState(
            icon: Icons.check_circle_outline,
            title: '오늘 안전 확인이 없습니다',
            body: '동행 중 도착 확인을 보내면 이곳에 무사 도착 기록이 남습니다.',
          )
        else if (visibleEvents.isEmpty)
          const _HistoryEmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: '이 필터의 활동이 없습니다',
            body: '다른 활동 필터를 선택하면 오늘 기록을 다시 볼 수 있습니다.',
          )
        else
          for (final event in visibleEvents) _HistoryRow(event: event),
      ],
    );
  }
}

class _HistoryEvent {
  const _HistoryEvent({
    required this.time,
    required this.type,
    required this.title,
    required this.detail,
    required this.color,
  });

  final String time;
  final String type;
  final String title;
  final String detail;
  final Color color;
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.checkInCount});

  final int checkInCount;

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
          const _SummaryCell(label: '조회', value: '3'),
          const _Divider(),
          const _SummaryCell(label: '장소', value: '5'),
          const _Divider(),
          _SummaryCell(label: '확인', value: '$checkInCount'),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: GyeoteColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SafetySummaryCard extends StatelessWidget {
  const _SafetySummaryCard({
    required this.checkInCount,
    required this.latestCheckIn,
  });

  final int checkInCount;
  final _HistoryEvent? latestCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.primarySoft,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: GyeoteColors.surface,
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: GyeoteColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkInCount == 0 ? '안전 확인 대기' : '안전 확인 $checkInCount개',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  latestCheckIn == null
                      ? '최근 도착 확인이 아직 없습니다.'
                      : latestCheckIn!.title,
                  style:
                      const TextStyle(color: GyeoteColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const _HistoryPill(text: '광고 없음'),
        ],
      ),
    );
  }
}

class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({
    required this.selected,
    required this.onChanged,
  });

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _HistoryFilter.values) ...[
            ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: selected == filter,
              onSelected: (_) => onChanged(filter),
              avatar: Icon(_filterIcon(filter), size: 16),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(6),
        color: GyeoteColors.surface,
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: GyeoteColors.border);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.event});

  final _HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(event.time,
                style: const TextStyle(
                    color: GyeoteColors.primary, fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: GyeoteColors.border),
                borderRadius: BorderRadius.circular(8),
                color: GyeoteColors.surface,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: event.color.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      event.type,
                      style: TextStyle(
                          color: event.color,
                          fontWeight: FontWeight.w900,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(event.detail,
                            style: const TextStyle(color: GyeoteColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GyeoteColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(color: GyeoteColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_HistoryEvent _historyEventFromCheckIn(CheckInEvent event) {
  return _HistoryEvent(
    time: _timeLabel(event.createdAt),
    type: '확인',
    title: '${event.displayName} ${_checkInStatusLabel(event.status)}',
    detail: '동행 공유 종료 · ${_sharingModeLabel(event.sharingMode)} 위치로 알림',
    color: GyeoteColors.primary,
  );
}

bool _matchesFilter(_HistoryEvent event, _HistoryFilter filter) {
  switch (filter) {
    case _HistoryFilter.all:
      return true;
    case _HistoryFilter.checkIn:
      return event.type == '확인';
    case _HistoryFilter.place:
      return event.type == '장소';
    case _HistoryFilter.companion:
      return event.type == '동행';
    case _HistoryFilter.data:
      return event.type == '데이터';
  }
}

String _filterLabel(_HistoryFilter filter) {
  switch (filter) {
    case _HistoryFilter.all:
      return '전체';
    case _HistoryFilter.checkIn:
      return '확인';
    case _HistoryFilter.place:
      return '장소';
    case _HistoryFilter.companion:
      return '동행';
    case _HistoryFilter.data:
      return '데이터';
  }
}

IconData _filterIcon(_HistoryFilter filter) {
  switch (filter) {
    case _HistoryFilter.all:
      return Icons.history_outlined;
    case _HistoryFilter.checkIn:
      return Icons.verified_user_outlined;
    case _HistoryFilter.place:
      return Icons.location_on_outlined;
    case _HistoryFilter.companion:
      return Icons.route_outlined;
    case _HistoryFilter.data:
      return Icons.folder_delete_outlined;
  }
}

String _timeLabel(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
