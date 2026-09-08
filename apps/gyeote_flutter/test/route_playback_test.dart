import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/features/map/map_models.dart';
import 'package:gyeote/src/features/map/movement.dart';
import 'package:gyeote/src/features/map/route_playback.dart';
import 'package:latlong2/latlong.dart';

const _lat = 37.5000;
const _lng = 127.0000;
final _day = DateTime(2026, 9, 7, 9, 0);

LatLng _north(double meters) => LatLng(_lat + meters / 111320, _lng);

MapRoutePoint _at(Duration after, double meters) => MapRoutePoint(
      point: _north(meters),
      recordedAt: _day.add(after),
    );

void main() {
  group('시간축 재생', () {
    test('인덱스가 아니라 시각으로 보간한다', () {
      // 앞 두 점은 1분 간격, 마지막은 9분 뒤다. 인덱스 기준이면 절반 지점이
      // 두 번째 점이지만, 시각 기준이면 아직 두 번째 점 근처다. 하루를
      // 되감는 화면에서 이 차이는 "대부분의 시간을 어디서 보냈나"를 바꾼다.
      final timeline = RoutePlaybackTimeline([
        _at(Duration.zero, 0),
        _at(const Duration(minutes: 1), 100),
        _at(const Duration(minutes: 10), 1000),
      ]);

      final half = timeline.frameAt(0.5);
      expect(half.at, _day.add(const Duration(minutes: 5)));

      // 5분 지점은 2번째 점(1분, 100m)과 3번째 점(10분, 1000m) 사이의 4/9.
      const expected = 100 + (1000 - 100) * (4 / 9);
      expect(
        distanceMeters(half.point, _north(0)),
        closeTo(expected, 15),
      );
    });

    test('시작과 끝은 실제 표본 위에 있다', () {
      final timeline = RoutePlaybackTimeline([
        _at(Duration.zero, 0),
        _at(const Duration(minutes: 5), 400),
      ]);

      expect(timeline.frameAt(0).at, timeline.startsAt);
      expect(timeline.frameAt(1).at, timeline.endsAt);
      expect(
        distanceMeters(timeline.frameAt(1).point, _north(400)),
        lessThan(1),
      );
    });

    test('진행률이 범위를 벗어나도 끝점에서 멈춘다', () {
      final timeline = RoutePlaybackTimeline([
        _at(Duration.zero, 0),
        _at(const Duration(minutes: 5), 400),
      ]);
      expect(timeline.frameAt(-3).at, timeline.startsAt);
      expect(timeline.frameAt(9).at, timeline.endsAt);
    });

    test('순서가 섞여 들어와도 시간순으로 정렬한다', () {
      final timeline = RoutePlaybackTimeline([
        _at(const Duration(minutes: 5), 400),
        _at(Duration.zero, 0),
      ]);
      expect(timeline.startsAt, _day);
      expect(timeline.endsAt, _day.add(const Duration(minutes: 5)));
    });
  });

  group('기록이 끊긴 구간', () {
    RoutePlaybackTimeline withGap() => RoutePlaybackTimeline([
          _at(Duration.zero, 0),
          _at(const Duration(minutes: 2), 200),
          // 세 시간 비었다. 그 사이 어디 있었는지 이 앱은 모른다.
          _at(const Duration(hours: 3), 20000),
          _at(const Duration(hours: 3, minutes: 2), 20200),
        ]);

    test('끊긴 구간을 짚어 낸다', () {
      final gaps = withGap().gaps;
      expect(gaps, hasLength(1));
      expect(gaps.single.from, _day.add(const Duration(minutes: 2)));
    });

    test('끊긴 구간에서는 마지막으로 아는 자리에 머문다', () {
      // 직선으로 이어 그리면 가지 않은 길을 지나간 것으로 그리게 된다.
      final timeline = withGap();
      final frame = timeline.frameAt(0.5);

      expect(frame.isInGap, isTrue);
      expect(distanceMeters(frame.point, _north(200)), lessThan(1));
    });

    test('끊긴 구간은 이동 거리에 넣지 않는다', () {
      // 넣으면 "오늘 20km 이동"처럼 있지도 않은 숫자가 나온다.
      expect(withGap().travelledMeters, closeTo(400, 5));
    });

    test('이어진 경로에는 끊김이 없다', () {
      final timeline = RoutePlaybackTimeline([
        _at(Duration.zero, 0),
        _at(const Duration(minutes: 2), 200),
        _at(const Duration(minutes: 4), 400),
      ]);
      expect(timeline.gaps, isEmpty);
      expect(timeline.frameAt(0.5).isInGap, isFalse);
      expect(timeline.travelledMeters, closeTo(400, 5));
    });
  });

  group('경계', () {
    test('표본이 둘 미만이면 비어 있다고 답한다', () {
      expect(RoutePlaybackTimeline(const []).isEmpty, isTrue);
      expect(RoutePlaybackTimeline([_at(Duration.zero, 0)]).isEmpty, isTrue);
    });

    test('한 점짜리도 프레임을 낸다', () {
      final frame = RoutePlaybackTimeline([_at(Duration.zero, 0)]).frameAt(0.4);
      expect(frame.at, _day);
      expect(frame.isInGap, isFalse);
    });

    test('같은 시각의 표본이 여럿이어도 죽지 않는다', () {
      final timeline = RoutePlaybackTimeline([
        _at(Duration.zero, 0),
        _at(Duration.zero, 50),
        _at(const Duration(minutes: 2), 200),
      ]);
      expect(() => timeline.frameAt(0.3), returnsNormally);
    });
  });
}
