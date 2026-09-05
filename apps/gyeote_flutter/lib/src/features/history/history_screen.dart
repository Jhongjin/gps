import 'package:flutter/material.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/gyeote_theme.dart';
import '../ads/safe_ad_slot.dart';

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
  List<_HistoryEvent> _demoEvents(AppL10n l10n) => [
    _HistoryEvent(
        time: '08:10',
        type: HistoryEventType.place,
        title: l10n.demoEventPlaceArrival,
        detail: l10n.demoEventPlaceArrivalDetail,
        tone: GyeoteTone.brand),
    _HistoryEvent(
        time: '12:42',
        type: HistoryEventType.viewed,
        title: l10n.demoEventViewed,
        detail: l10n.demoEventViewedDetail,
        tone: GyeoteTone.move),
    _HistoryEvent(
        time: '17:18',
        type: HistoryEventType.companion,
        title: l10n.demoEventCompanion,
        detail: l10n.demoEventCompanionDetail,
        tone: GyeoteTone.warm),
    _HistoryEvent(
        time: '18:02',
        type: HistoryEventType.checkIn,
        title: l10n.demoEventCheckIn,
        detail: l10n.demoEventCheckInDetail,
        tone: GyeoteTone.brand),
    _HistoryEvent(
        time: '18:03',
        type: HistoryEventType.data,
        title: l10n.demoEventDataRequest,
        detail: l10n.demoEventDataRequestDetail,
        tone: GyeoteTone.alert),
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
        _message = AppL10n.of(context).historyLoadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    final events = _hasBackend
        ? _checkIns
            .map((event) => _historyEventFromCheckIn(l10n, event))
            .toList(growable: false)
        : _demoEvents(l10n);
    final visibleEvents =
        events.where((event) => _matchesFilter(event, _filter)).toList();
    final checkInCount = _hasBackend ? _checkIns.length : 1;
    final checkInEvents = events.where((event) => event.type == HistoryEventType.checkIn).toList();
    final latestCheckIn = checkInEvents.isEmpty ? null : checkInEvents.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.historyTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(l10n.historySubtitle,
            style: TextStyle(color: palette.muted)),
        if (_message != null) ...[
          const SizedBox(height: 4),
          Text(_message!,
              style: TextStyle(color: palette.alert, fontSize: 12)),
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
          _HistoryEmptyState(
            icon: Icons.sync_outlined,
            title: l10n.historySyncing,
            body: l10n.historySafetyLoading,
          )
        else if (_hasBackend && events.isEmpty)
          _HistoryEmptyState(
            icon: Icons.check_circle_outline,
            title: l10n.historySafetyEmpty,
            body: l10n.historySafetyEmptyHint,
          )
        else if (visibleEvents.isEmpty)
          _HistoryEmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: l10n.historyFilterEmpty,
            body: l10n.historyFilterEmptyHint,
          )
        else
          for (final event in visibleEvents) _HistoryRow(event: event),
        const SizedBox(height: 12),
        const SafeAdSlot(placement: 'history_after_activity'),
      ],
    );
  }
}

/// 활동 종류.
///
/// 예전에는 이 자리에 표시용 한국어 문자열이 들어가 있었고 필터가
/// `event.type == '확인'` 으로 비교했다. 라벨을 번역하는 순간 필터가 조용히
/// 깨지는 구조였다. 판별과 표시를 분리한다.
enum HistoryEventType {
  checkIn,
  place,
  companion,
  data,
  viewed;

  String label(AppL10n l10n) => switch (this) {
        HistoryEventType.checkIn => l10n.historyFilterCheckIn,
        HistoryEventType.place => l10n.historyFilterPlace,
        HistoryEventType.companion => l10n.historyFilterCompanion,
        HistoryEventType.data => l10n.historyFilterData,
        HistoryEventType.viewed => l10n.historyTypeViewed,
      };
}

class _HistoryEvent {
  const _HistoryEvent({
    required this.time,
    required this.type,
    required this.title,
    required this.detail,
    required this.tone,
  });

  final String time;
  final HistoryEventType type;
  final String title;
  final String detail;
  final GyeoteTone tone;
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.checkInCount});

  final int checkInCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GyeoteRadius.card),
        color: palette.surfaceAlt,
      ),
      child: Row(
        children: [
          _SummaryCell(label: l10n.historyTypeViewed, value: '3'),
          const _Divider(),
          _SummaryCell(label: l10n.historyFilterPlace, value: '5'),
          const _Divider(),
          _SummaryCell(label: l10n.historyFilterCheckIn, value: '$checkInCount'),
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
    final palette = context.palette;

    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: palette.muted, fontSize: 12)),
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
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GyeoteRadius.card),
        color: palette.brandSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: palette.surface,
            ),
            child: Icon(Icons.verified_user_outlined, color: palette.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkInCount == 0
                      ? l10n.checkInPending
                      : l10n.historyCheckInCount(checkInCount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  latestCheckIn == null
                      ? l10n.historySafetyNoRecent
                      : latestCheckIn!.title,
                  style:
                      TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          _HistoryPill(text: l10n.historyNoAds),
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
              label: Text(_filterLabel(AppL10n.of(context), filter)),
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
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(6),
        color: palette.surface,
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(width: 1, height: 34, color: palette.line);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.event});

  final _HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(event.time,
                style: TextStyle(
                    color: palette.brand, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: palette.line),
                borderRadius: BorderRadius.circular(8),
                color: palette.surface,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: event.tone.resolve(palette).withValues(alpha: 0.12),
                    ),
                    child: Text(
                      event.type.label(l10n),
                      style: TextStyle(
                          color: event.tone.resolve(palette),
                          fontWeight: FontWeight.w700,
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
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(event.detail,
                            style: TextStyle(color: palette.muted)),
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
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body, style: TextStyle(color: palette.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_HistoryEvent _historyEventFromCheckIn(AppL10n l10n, CheckInEvent event) {
  return _HistoryEvent(
    time: _timeLabel(event.createdAt),
    type: HistoryEventType.checkIn,
    title: '${event.displayName.isEmpty ? l10n.memberFallbackName : event.displayName}'
        ' ${_checkInStatusLabel(l10n, event.status)}',
    detail: l10n.companionEndedNote(_sharingModeLabel(l10n, event.sharingMode)),
    tone: GyeoteTone.brand,
  );
}

bool _matchesFilter(_HistoryEvent event, _HistoryFilter filter) {
  switch (filter) {
    case _HistoryFilter.all:
      return true;
    case _HistoryFilter.checkIn:
      return event.type == HistoryEventType.checkIn;
    case _HistoryFilter.place:
      return event.type == HistoryEventType.place;
    case _HistoryFilter.companion:
      return event.type == HistoryEventType.companion;
    case _HistoryFilter.data:
      return event.type == HistoryEventType.data;
  }
}

String _filterLabel(AppL10n l10n, _HistoryFilter filter) {
  return switch (filter) {
    _HistoryFilter.all => l10n.historyFilterAll,
    _HistoryFilter.checkIn => l10n.historyFilterCheckIn,
    _HistoryFilter.place => l10n.historyFilterPlace,
    _HistoryFilter.companion => l10n.historyFilterCompanion,
    _HistoryFilter.data => l10n.historyFilterData,
  };
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

String _checkInStatusLabel(AppL10n l10n, CheckInStatus status) {
  switch (status) {
    case CheckInStatus.safeArrived:
      return l10n.checkInSafeArrived;
    case CheckInStatus.needsCheck:
      return l10n.checkInNeedsCheck;
    case CheckInStatus.signalWeak:
      return l10n.checkInWeakSignal;
  }
}

String _sharingModeLabel(AppL10n l10n, SharingMode mode) {
  switch (mode) {
    case SharingMode.precise:
      return l10n.sharingModePrecise;
    case SharingMode.balanced:
      return l10n.sharingModeBalanced;
    case SharingMode.area:
      return l10n.sharingModeArea;
    case SharingMode.hidden:
      return l10n.sharingModeHidden;
    case SharingMode.sosOnly:
      return l10n.sharingModeSosOnly;
  }
}
