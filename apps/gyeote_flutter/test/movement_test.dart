import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/l10n/app_localizations.dart';
import 'package:gyeote/src/core/i18n/region_settings.dart';
import 'package:gyeote/src/core/location/location_models.dart';
import 'package:gyeote/src/features/map/map_models.dart';
import 'package:gyeote/src/features/map/movement.dart';
import 'package:gyeote/src/features/map/widgets/movement_line.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';
import 'package:latlong2/latlong.dart';

/// 강남역 근처. 위도 1도는 어디서나 약 111km 라, 경도 대신 위도로 움직여
/// 거리를 손으로 검산할 수 있게 둔다.
const _start = LatLng(37.5000, 127.0000);

LatLng _northOf(LatLng from, double meters) =>
    LatLng(from.latitude + meters / 111320, from.longitude);

List<MovementSample> _walk({
  required DateTime now,
  required double metersPerStep,
  required int steps,
  required Duration stepInterval,
}) {
  var point = _start;
  final samples = <MovementSample>[];
  for (var i = steps; i >= 0; i--) {
    samples.add(
      MovementSample(point: point, recordedAt: now.subtract(stepInterval * i)),
    );
    point = _northOf(point, metersPerStep);
  }
  return samples;
}

MapMemberTrack _track({
  required LatLng point,
  List<MapRoutePoint> routeTail = const [],
  bool isStale = false,
  DateTime? recordedAt,
}) {
  return MapMemberTrack(
    id: 'm',
    name: '준',
    point: point,
    tone: GyeoteTone.brand,
    recordedAt: recordedAt ?? DateTime.now(),
    sharingMode: SharingMode.balanced,
    routeTail: routeTail,
    isStale: isStale,
  );
}

void main() {
  group('거리와 방위', () {
    test('위도 1도는 약 111km', () {
      final metres = distanceMeters(
        const LatLng(37, 127),
        const LatLng(38, 127),
      );
      expect(metres, closeTo(111195, 500));
    });

    test('북쪽은 0도, 동쪽은 90도', () {
      expect(
        bearingDegrees(_start, _northOf(_start, 500)),
        closeTo(0, 0.5),
      );
      expect(
        bearingDegrees(_start, LatLng(_start.latitude, 127.01)),
        closeTo(90, 0.5),
      );
    });

    test('방위 차는 0도를 넘어 돌아간다', () {
      // 350도와 10도는 340도 차이가 아니라 20도 차이다. 이걸 틀리면 북쪽으로
      // 가는 사람이 반대로 가는 것으로 읽힌다.
      expect(bearingDeltaDegrees(350, 10), closeTo(20, 0.001));
      expect(bearingDeltaDegrees(10, 350), closeTo(20, 0.001));
    });
  });

  group('이동 추정', () {
    final now = DateTime(2026, 9, 6, 19, 0);

    test('표본이 하나면 모른다고 답한다', () {
      final estimate = estimateMovement(
        [MovementSample(point: _start, recordedAt: now)],
        now: now,
      );
      expect(estimate.state, MovementState.unknown);
      expect(estimate.bearingDeg, isNull);
    });

    test('제자리 지터는 걷는 것으로 읽지 않는다', () {
      // GPS 는 가만히 있어도 몇 미터씩 튄다. 경로 길이만 보면 "걷는 중"이
      // 되지만 실제 변위는 없다. 멈춘 사람을 움직인다고 말하면, 마중 나간
      // 사람이 헛걸음한다.
      final jitter = [
        MovementSample(
            point: _start, recordedAt: now.subtract(const Duration(minutes: 6))),
        MovementSample(
            point: _northOf(_start, 8),
            recordedAt: now.subtract(const Duration(minutes: 4))),
        MovementSample(
            point: _start, recordedAt: now.subtract(const Duration(minutes: 2))),
        MovementSample(point: _northOf(_start, 6), recordedAt: now),
      ];

      final estimate = estimateMovement(jitter, now: now);
      expect(estimate.state, MovementState.stopped);
      expect(estimate.speedMps, 0);
    });

    test('걷는 속도는 걷는 중으로 나온다', () {
      // 분당 80m ≈ 시속 4.8km.
      final estimate = estimateMovement(
        _walk(
          now: now,
          metersPerStep: 80,
          steps: 5,
          stepInterval: const Duration(minutes: 1),
        ),
        now: now,
      );
      expect(estimate.state, MovementState.walking);
      expect(estimate.bearingDeg, closeTo(0, 1));
    });

    test('차 속도는 빠른 이동으로 나온다', () {
      // 분당 800m ≈ 시속 48km.
      final estimate = estimateMovement(
        _walk(
          now: now,
          metersPerStep: 800,
          steps: 4,
          stepInterval: const Duration(minutes: 1),
        ),
        now: now,
      );
      expect(estimate.state, MovementState.driving);
    });

    test('창 밖의 오래된 표본은 현재 이동으로 치지 않는다', () {
      // 한 시간 전에 걷던 사실은 지금 걷는다는 뜻이 아니다.
      final old = _walk(
        now: now.subtract(const Duration(hours: 1)),
        metersPerStep: 80,
        steps: 5,
        stepInterval: const Duration(minutes: 1),
      );
      expect(estimateMovement(old, now: now).state, MovementState.unknown);
    });

    test('순서가 섞여 들어와도 같은 답을 낸다', () {
      final samples = _walk(
        now: now,
        metersPerStep: 80,
        steps: 5,
        stepInterval: const Duration(minutes: 1),
      );
      final shuffled = samples.reversed.toList();
      expect(
        estimateMovement(shuffled, now: now).speedMps,
        closeTo(estimateMovement(samples, now: now).speedMps, 0.001),
      );
    });
  });

  group('도착 예상', () {
    final now = DateTime(2026, 9, 6, 19, 0);

    MovementEstimate walking() => estimateMovement(
          _walk(
            now: now,
            metersPerStep: 80,
            steps: 5,
            stepInterval: const Duration(minutes: 1),
          ),
          now: now,
        );

    test('멈춰 있으면 남은 시간을 내지 않는다', () {
      // 속도가 0 이면 남은 시간은 무한이다. 숫자를 지어내느니 비워 둔다.
      const stopped = MovementEstimate(
        speedMps: 0,
        state: MovementState.stopped,
        bearingDeg: null,
        span: Duration(minutes: 5),
        sampleCount: 4,
      );
      expect(
        estimateEta(
          from: _start,
          to: _northOf(_start, 1000),
          movement: stopped,
        ),
        isNull,
      );
    });

    test('다가가는 중이면 방향이 approaching 이다', () {
      final eta = estimateEta(
        from: _northOf(_start, 400),
        to: _northOf(_start, 1400),
        movement: walking(),
      );
      expect(eta, isNotNull);
      expect(eta!.direction, ApproachDirection.approaching);
    });

    test('반대로 가면 leaving 이다', () {
      final eta = estimateEta(
        from: _northOf(_start, 400),
        to: _start,
        movement: walking(),
      );
      expect(eta!.direction, ApproachDirection.leaving);
    });

    test('우회 계수만큼 직선거리보다 멀게 잡는다', () {
      // 직선으로 계산하면 항상 실제보다 이르게 약속하게 되고, 기다리는
      // 사람에게 그건 나쁜 방향의 오차다.
      final eta = estimateEta(
        from: _start,
        to: _northOf(_start, 1000),
        movement: walking(),
      )!;
      expect(eta.travelDistanceM, closeTo(1000 * detourFactor, 5));
    });

    test('세 시간을 넘으면 내지 않는다', () {
      final eta = estimateEta(
        from: _start,
        to: _northOf(_start, 60000),
        movement: walking(),
      );
      expect(eta, isNull);
    });

    test('분 표시는 10분 넘어가면 5분 단위로만 말한다', () {
      Duration seconds(int value) => Duration(seconds: value);
      EtaEstimate at(Duration eta) => EtaEstimate(
            eta: eta,
            travelDistanceM: 0,
            direction: ApproachDirection.approaching,
          );

      expect(at(seconds(20)).roundedMinutes, 1);
      expect(at(seconds(200)).roundedMinutes, 4);
      expect(at(seconds(13 * 60)).roundedMinutes, 15);
      expect(at(seconds(31 * 60)).roundedMinutes, 30);
    });
  });

  group('이동 문구', () {
    late AppL10n l10n;

    setUp(() async {
      l10n = await AppL10n.delegate.load(const Locale('ko'));
    });

    test('오래된 위치에는 아무것도 쓰지 않는다', () {
      // 20분 전 좌표로 "걷는 중"이라고 적으면 없는 현재를 만들어 내는 것이다.
      final text = describeMovement(
        l10n: l10n,
        unit: DistanceUnit.metric,
        member: _track(point: _start, isStale: true),
        destination: MapDestination(point: _northOf(_start, 500), name: '집'),
      );
      expect(text, isNull);
    });

    test('표본이 없으면 이동 상태를 지어내지 않는다', () {
      final text = describeMovement(
        l10n: l10n,
        unit: DistanceUnit.metric,
        member: _track(point: _start),
      );
      expect(text, isNull);
    });

    test('걷는 중이면서 다가가면 남은 분을 적는다', () {
      final now = DateTime.now();
      final tail = [
        for (var i = 5; i >= 0; i--)
          MapRoutePoint(
            point: _northOf(_start, (5 - i) * 80),
            recordedAt: now.subtract(Duration(minutes: i)),
          ),
      ];
      final text = describeMovement(
        l10n: l10n,
        unit: DistanceUnit.metric,
        member: _track(point: tail.last.point, routeTail: tail),
        destination:
            MapDestination(point: _northOf(_start, 1200), name: '집결 장소'),
      )!;

      expect(text, contains('걷는 중'));
      expect(text, contains('집결 장소'));
      expect(text, contains('분'));
    });

    test('목적지가 없으면 이동 상태만 적는다', () {
      final now = DateTime.now();
      final tail = [
        for (var i = 5; i >= 0; i--)
          MapRoutePoint(
            point: _northOf(_start, (5 - i) * 80),
            recordedAt: now.subtract(Duration(minutes: i)),
          ),
      ];
      final text = describeMovement(
        l10n: l10n,
        unit: DistanceUnit.metric,
        member: _track(point: tail.last.point, routeTail: tail),
      );
      expect(text, '걷는 중');
    });

    testWidgets('그릴 것이 없으면 줄 자체를 만들지 않는다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppL10n.supportedLocales,
          theme: buildGyeoteTheme(),
          home: Scaffold(body: MovementLine(member: _track(point: _start))),
        ),
      );

      expect(find.byType(Text), findsNothing);
    });
  });
}
