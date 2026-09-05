import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../map_models.dart';

/// 위치가 갱신될 때 마커를 목적지까지 이어서 움직인다.
///
/// 갱신마다 마커가 순간이동하면 지도가 살아 있다는 느낌이 사라지고, 무엇보다
/// **누가 어디서 어디로 갔는지** 읽을 수 없다. 짧은 보간 하나가 "방금 저기
/// 있었는데 이리 왔다"를 보여 준다.
///
/// 모션 축소 설정을 켠 사용자에게는 보간하지 않고 바로 옮긴다. 움직임이
/// 불편해서 끈 사람에게 부드러움을 강요하지 않는다.
class AnimatedMemberTracks extends StatefulWidget {
  const AnimatedMemberTracks({
    super.key,
    required this.members,
    required this.builder,
    this.duration = const Duration(milliseconds: 650),
  });

  final List<MapMemberTrack> members;
  final Widget Function(BuildContext context, List<MapMemberTrack> members)
      builder;
  final Duration duration;

  @override
  State<AnimatedMemberTracks> createState() => _AnimatedMemberTracksState();
}

class _AnimatedMemberTracksState extends State<AnimatedMemberTracks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  /// 보간 시작점. 이전 프레임에서 실제로 그려지던 자리다.
  Map<String, LatLng> _from = const {};

  @override
  void initState() {
    super.initState();
    _from = {for (final m in widget.members) m.id: m.point};
  }

  @override
  void didUpdateWidget(AnimatedMemberTracks oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 출발점은 **이전** 목록 기준으로 잡아야 한다. 이 시점의 widget.members 는
    // 이미 새 좌표라, 그것으로 잡으면 이동 거리가 늘 0 이 되어 보간이 죽는다.
    final drawn = {
      for (final member in _resolve(oldWidget.members, _curved))
        member.id: member.point,
    };

    final moved = widget.members.any((member) {
      final previous = drawn[member.id];
      return previous != null && previous != member.point;
    });

    _from = drawn;

    if (!moved) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  double get _curved => Curves.easeOutCubic.transform(_controller.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MapMemberTrack> _resolve(List<MapMemberTrack> members, double t) {
    if (t >= 1) return members;

    return [
      for (final member in members)
        () {
          final start = _from[member.id];
          if (start == null || start == member.point) return member;
          return member.copyWith(
            point: LatLng(
              start.latitude + (member.point.latitude - start.latitude) * t,
              start.longitude + (member.point.longitude - start.longitude) * t,
            ),
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 모션 축소를 켠 사용자에게는 보간을 걸지 않는다.
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.builder(context, widget.members);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(
        context,
        _resolve(widget.members, _curved),
      ),
    );
  }
}
