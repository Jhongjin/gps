import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/backend/backend_contract.dart';
import '../../core/i18n/sharing_mode_label.dart';
import '../../theme/gyeote_theme.dart';

/// 내 위치를 본 사람 목록.
///
/// 이 화면이 이 앱의 주장을 지탱한다. 로그인 화면은 "누가 봤는지 보여 준다"는
/// 배지를 달고 있고, 멤버 시트에는 그 줄이 있다. 003 에 `record_viewer_log` 가
/// 있었는데 클라이언트가 부르지도 읽지도 않아서, 그 자리에 데모 이름 세 개가
/// 진짜인 것처럼 박혀 있었다. 없는 기록을 있는 것처럼 그리는 것은 이 앱에서
/// 가장 하면 안 되는 종류의 거짓말이다.
///
/// 광고는 들어가지 않는다 (스킬 §5, 프라이버시 흐름).
Future<void> showViewerLogSheet(
  BuildContext context, {
  required CircleRepository repository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, controller) => ViewerLogView(
        repository: repository,
        scrollController: controller,
      ),
    ),
  );
}

class ViewerLogView extends StatefulWidget {
  const ViewerLogView({
    super.key,
    required this.repository,
    this.scrollController,
    this.limit = 50,
  });

  final CircleRepository repository;
  final ScrollController? scrollController;
  final int limit;

  @override
  State<ViewerLogView> createState() => _ViewerLogViewState();
}

class _ViewerLogViewState extends State<ViewerLogView> {
  List<ViewerLogEntry>? _entries;

  /// 실패를 문구로 추측하지 않기 위한 플래그. 예전에 이 저장소에서 오류 색을
  /// 메시지 부분 문자열로 고르다가 번역하는 순간 조용히 깨진 적이 있다.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await widget.repository.listViewerLog(
        limit: widget.limit,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final entries = _entries;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          l10n.viewerLogSheetTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.viewerLogSheetBody,
          style: TextStyle(fontSize: 12, color: palette.muted),
        ),
        if (_failed) ...[
          const SizedBox(height: 8),
          Text(
            l10n.viewerLogLoadFailed,
            style: TextStyle(fontSize: 12, color: palette.alert),
          ),
        ],
        const SizedBox(height: 16),
        if (entries == null)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (entries.isEmpty && !_failed)
          Text(
            l10n.viewerLogEmpty,
            style: TextStyle(fontSize: 13, color: palette.inkMuted),
          )
        else
          for (final entry in entries) ViewerLogRow(entry: entry),
      ],
    );
  }
}

class ViewerLogRow extends StatelessWidget {
  const ViewerLogRow({super.key, required this.entry});

  final ViewerLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: palette.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.viewerName.trim().isEmpty
                      ? l10n.viewerLogUnknownViewer
                      : entry.viewerName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                Text(
                  l10n.viewerLogEntryDetail(
                    sharingModeLabel(l10n, entry.precision),
                  ),
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            viewerLogTimeLabel(l10n, entry.viewedAt),
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
        ],
      ),
    );
  }
}

/// "방금" / "12분 전" / "3시간 전" / "2일 전".
///
/// 지도 쪽 `relativeTimeLabel` 과 같은 문구를 쓰지만 그쪽은 지도 모델에 얹혀
/// 있어, 프라이버시 화면이 지도를 끌고 오지 않도록 여기서 같은 키를 쓴다.
String viewerLogTimeLabel(AppL10n l10n, DateTime at, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff.inSeconds < 60) return l10n.agoJustNow;
  if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.agoHours(diff.inHours);
  return l10n.agoDays(diff.inDays);
}
