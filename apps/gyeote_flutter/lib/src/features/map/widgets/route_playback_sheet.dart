import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/backend/backend_contract.dart';
import '../../../core/i18n/region_settings.dart';
import '../../../core/map/map_tile_config.dart';
import '../../../theme/gyeote_theme.dart';
import '../map_models.dart';
import '../route_playback.dart';
import 'night_tiles.dart';

/// 하루치 이동 다시 보기.
///
/// 이 화면은 이 제품에서 감시에 가장 가까운 자리다. 그래서 세 가지를 지킨다.
///
/// - 남의 이동을 보면 **그 사람의 열람 기록에 남는다.** 화면에도 그렇게 적는다.
/// - 저장된 지점만 잇는다. 표본 사이가 벌어진 구간은 이동으로 그리지 않고
///   "기록 없음"이라고 말한다.
/// - 좌표는 이미 공유 정확도와 민감 장소 가림을 거친 값이다. 재생이 원래보다
///   정밀한 무언가를 복원하지 않는다.
///
/// 광고는 들어가지 않는다 — 지도 표면이자 프라이버시 흐름이다 (스킬 §5).
Future<void> showRoutePlaybackSheet(
  BuildContext context, {
  required CircleRepository repository,
  required String circleId,
  required String profileId,
  required String memberName,
  required bool isSelf,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => RoutePlaybackView(
        repository: repository,
        circleId: circleId,
        profileId: profileId,
        memberName: memberName,
        isSelf: isSelf,
        scrollController: controller,
      ),
    ),
  );
}

class RoutePlaybackView extends StatefulWidget {
  const RoutePlaybackView({
    super.key,
    required this.repository,
    required this.circleId,
    required this.profileId,
    required this.memberName,
    required this.isSelf,
    this.scrollController,
    this.window = const Duration(hours: 24),
  });

  final CircleRepository repository;
  final String circleId;
  final String profileId;
  final String memberName;

  /// 내 이동인지. 남의 것이면 열람 기록에 남는다는 사실을 화면에 적는다.
  final bool isSelf;
  final ScrollController? scrollController;
  final Duration window;

  @override
  State<RoutePlaybackView> createState() => _RoutePlaybackViewState();
}

class _RoutePlaybackViewState extends State<RoutePlaybackView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..addListener(() {
      if (mounted) setState(() {});
    });

  RoutePlaybackTimeline? _timeline;
  bool _failed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final points = await widget.repository.getMemberRouteTail(
        circleId: widget.circleId,
        profileId: widget.profileId,
        // RPC 상한이 100이다. 하루를 100점으로 보는 셈이라 촘촘하지는 않지만,
        // 더 받겠다고 상한을 올리는 것은 보관 정책을 건드리는 일이다.
        limit: 100,
        since: widget.window,
      );
      if (!mounted) return;

      setState(() {
        _timeline = RoutePlaybackTimeline([
          for (final point in points)
            MapRoutePoint(
              point: LatLng(
                point.sharedCoordinate.latitude,
                point.sharedCoordinate.longitude,
              ),
              recordedAt: point.recordedAt,
            ),
        ]);
        _isLoading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _failed = true;
      });
    }
  }

  void _togglePlay() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _controller.forward(
        from: _controller.value >= 1 ? 0 : _controller.value,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final unit = RegionSettings.of(Localizations.localeOf(context)).distanceUnit;
    final timeline = _timeline;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          l10n.playbackTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.memberName,
          style: TextStyle(fontSize: 13, color: palette.inkMuted),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.playbackSubtitle,
          style: TextStyle(fontSize: 12, color: palette.muted),
        ),
        if (!widget.isSelf) ...[
          const SizedBox(height: 4),
          Text(
            // 이 문장이 이 화면을 관제가 아닌 것으로 만든다. 보는 쪽도 그걸
            // 알고 봐야 한다.
            l10n.playbackViewerLogNote,
            style: TextStyle(fontSize: 12, color: palette.warm),
          ),
        ],
        const SizedBox(height: 16),
        if (_isLoading)
          _Notice(text: l10n.playbackLoading)
        else if (_failed)
          _Notice(text: l10n.playbackLoadFailed, isError: true)
        else if (timeline == null || timeline.isEmpty)
          _Notice(text: l10n.playbackEmpty, body: l10n.playbackEmptyHint)
        else
          ..._player(context, timeline, l10n, palette, unit),
      ],
    );
  }

  List<Widget> _player(
    BuildContext context,
    RoutePlaybackTimeline timeline,
    AppL10n l10n,
    GyeotePalette palette,
    DistanceUnit unit,
  ) {
    final frame = timeline.frameAt(_controller.value);
    final clock = RegionSettings.of(Localizations.localeOf(context));

    return [
      SizedBox(
        height: 300,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GyeoteRadius.card),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: frame.point,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
            ),
            children: [
              NightTiles(child: gyeoteTiles.layer()),
              PolylineLayer(
                polylines: [
                  // 전체 경로는 흐리게 깔고, 지나온 만큼만 진하게 덮는다.
                  Polyline(
                    points: [for (final p in timeline.points) p.point],
                    color: palette.line,
                    strokeWidth: 4,
                  ),
                  if (frame.travelled.length > 1)
                    Polyline(
                      points: frame.travelled,
                      color: palette.move,
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: frame.point,
                    width: 22,
                    height: 22,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: frame.isInGap ? palette.muted : palette.brand,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          IconButton.filledTonal(
            onPressed: _togglePlay,
            tooltip: _controller.isAnimating
                ? l10n.playbackPause
                : l10n.playbackPlay,
            icon: Icon(
              _controller.isAnimating ? Icons.pause : Icons.play_arrow,
            ),
          ),
          Expanded(
            child: Slider(
              value: _controller.value,
              onChanged: (value) {
                _controller.stop();
                setState(() => _controller.value = value);
              },
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: Text(
              _clockLabel(frame.at, clock.uses24HourClock),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            l10n.playbackTravelled(
              unit.formatDistance(timeline.travelledMeters),
            ),
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        l10n.playbackWindow(
          _clockLabel(timeline.startsAt, clock.uses24HourClock),
          _clockLabel(timeline.endsAt, clock.uses24HourClock),
        ),
        style: TextStyle(fontSize: 12, color: palette.muted),
      ),
      if (frame.isInGap) ...[
        const SizedBox(height: 8),
        _Notice(text: l10n.playbackGapNotice, tone: GyeoteTone.warm),
      ],
    ];
  }
}

/// 24시간제/12시간제는 지역 설정값이다. 문자열로 번역하면 어긋난다.
String _clockLabel(DateTime at, bool uses24Hour) {
  final minute = at.minute.toString().padLeft(2, '0');
  if (uses24Hour) {
    return '${at.hour.toString().padLeft(2, '0')}:$minute';
  }
  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  return '$hour:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    this.body,
    this.isError = false,
    this.tone,
  });

  final String text;
  final String? body;
  final bool isError;
  final GyeoteTone? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isError
        ? palette.alert
        : tone?.resolve(palette) ?? palette.inkMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(GyeoteRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (body case final detail?) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}
