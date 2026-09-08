import 'package:latlong2/latlong.dart';

import 'map_models.dart';
import 'movement.dart';

/// 하루치 경로를 시간축 위에서 되감아 본다.
///
/// **시각 기준으로 보간한다.** 표본 인덱스 기준으로 재생하면 10초 간격과 3시간
/// 간격이 같은 속도로 지나가고, 그러면 "대부분의 시간을 어디서 보냈는지"가
/// 사라진다. 하루를 되감는 화면에서 그건 사실을 바꾸는 수준의 왜곡이다.
///
/// **끊긴 구간을 이은 것처럼 그리지 않는다.** 표본 사이가 [gapAfter] 보다
/// 벌어지면 그 사이는 기록이 없는 것이지 직선으로 이동한 것이 아니다. 화면이
/// 그 사실을 말할 수 있도록 [RoutePlaybackFrame.isInGap] 으로 내보낸다.
///
/// 좌표는 이미 공유 정확도와 민감 장소 가림을 거친 값이다. 재생은 저장된 것을
/// 그대로 보여 줄 뿐, 없던 정밀도를 만들지 않는다.
class RoutePlaybackTimeline {
  RoutePlaybackTimeline(List<MapRoutePoint> points, {this.gapAfter = _gap})
      : points = _sorted(points);

  /// 이보다 벌어진 표본 사이는 "이동"이 아니라 "기록 없음"으로 다룬다.
  static const Duration _gap = Duration(minutes: 20);

  final List<MapRoutePoint> points;
  final Duration gapAfter;

  bool get isEmpty => points.length < 2;

  DateTime get startsAt => points.first.recordedAt;
  DateTime get endsAt => points.last.recordedAt;
  Duration get span => endsAt.difference(startsAt);

  /// 실제로 이동한 거리(m). 끊긴 구간은 빼고 센다 — 기록이 없는 사이를 직선
  /// 거리로 더하면 "오늘 32km 이동"처럼 있지도 않은 숫자가 나온다.
  double get travelledMeters {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      if (_isGap(points[i - 1], points[i])) continue;
      total += distanceMeters(points[i - 1].point, points[i].point);
    }
    return total;
  }

  /// 재생 진행률 [progress](0~1) 에서의 한 프레임.
  RoutePlaybackFrame frameAt(double progress) {
    if (points.isEmpty) {
      // 개발자용 메시지다. 사용자에게 보이는 문구가 아니므로 번역하지 않는다.
      throw StateError('RoutePlaybackTimeline has no points to play');
    }
    if (points.length == 1) {
      return RoutePlaybackFrame(
        point: points.first.point,
        at: points.first.recordedAt,
        travelled: [points.first.point],
        isInGap: false,
      );
    }

    final clamped = progress.clamp(0.0, 1.0);
    final at = startsAt.add(
      Duration(microseconds: (span.inMicroseconds * clamped).round()),
    );

    var index = 0;
    for (var i = 1; i < points.length; i++) {
      if (!points[i].recordedAt.isAfter(at)) {
        index = i;
      } else {
        break;
      }
    }

    if (index == points.length - 1) {
      return RoutePlaybackFrame(
        point: points.last.point,
        at: at,
        travelled: _lineUpTo(points.length - 1),
        isInGap: false,
      );
    }

    final from = points[index];
    final to = points[index + 1];
    final inGap = _isGap(from, to);

    // 끊긴 구간에서는 마지막으로 **알고 있는** 자리에 머문다. 없는 이동을
    // 그리느니 멈춰 있는 편이 사실에 가깝다.
    if (inGap) {
      return RoutePlaybackFrame(
        point: from.point,
        at: at,
        travelled: _lineUpTo(index),
        isInGap: true,
      );
    }

    final segment = to.recordedAt.difference(from.recordedAt).inMicroseconds;
    final into = at.difference(from.recordedAt).inMicroseconds;
    final t = segment <= 0 ? 1.0 : (into / segment).clamp(0.0, 1.0);

    final point = LatLng(
      from.point.latitude + (to.point.latitude - from.point.latitude) * t,
      from.point.longitude + (to.point.longitude - from.point.longitude) * t,
    );

    return RoutePlaybackFrame(
      point: point,
      at: at,
      travelled: [..._lineUpTo(index), point],
      isInGap: false,
    );
  }

  /// 끊긴 구간의 목록. 화면이 "이 사이는 기록이 없다"고 적을 수 있게 낸다.
  List<({DateTime from, DateTime to})> get gaps => [
        for (var i = 1; i < points.length; i++)
          if (_isGap(points[i - 1], points[i]))
            (from: points[i - 1].recordedAt, to: points[i].recordedAt),
      ];

  bool _isGap(MapRoutePoint a, MapRoutePoint b) =>
      b.recordedAt.difference(a.recordedAt) > gapAfter;

  List<LatLng> _lineUpTo(int index) => [
        for (var i = 0; i <= index; i++) points[i].point,
      ];

  static List<MapRoutePoint> _sorted(List<MapRoutePoint> points) {
    final copy = [...points]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return List.unmodifiable(copy);
  }
}

class RoutePlaybackFrame {
  const RoutePlaybackFrame({
    required this.point,
    required this.at,
    required this.travelled,
    required this.isInGap,
  });

  final LatLng point;
  final DateTime at;

  /// 여기까지 지나온 선.
  final List<LatLng> travelled;

  /// 이 순간이 기록 없는 구간 안인지. 화면은 이때 위치를 단정하지 않는다.
  final bool isInGap;
}
