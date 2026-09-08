import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/core/privacy/private_place.dart';
import 'package:gyeote/src/core/privacy/private_place_store.dart';

/// 강남역 근처. 위도 1도 ≈ 111.32km 라, 위도로만 움직이면 거리를 손으로
/// 검산할 수 있다.
const double _lat = 37.5000;
const double _lng = 127.0000;

double _latNorthOf(double meters) => _lat + meters / 111320;

PrivatePlace _home({int radiusM = 300, String name = '집'}) => PrivatePlace(
      id: 'home',
      name: name,
      latitude: _lat,
      longitude: _lng,
      radiusM: radiusM,
    );

void main() {
  group('민감 장소 판정', () {
    test('반경 안이면 감싼다', () {
      expect(_home().contains(_latNorthOf(200), _lng), isTrue);
    });

    test('반경 밖이면 감싸지 않는다', () {
      expect(_home().contains(_latNorthOf(400), _lng), isFalse);
    });

    test('겹치면 중심이 가까운 쪽을 고른다', () {
      final wide = PrivatePlace(
        id: 'wide',
        name: '동네',
        latitude: _latNorthOf(500),
        longitude: _lng,
        radiusM: 1000,
      );
      final place = privatePlaceCovering(
        [wide, _home()],
        _latNorthOf(100),
        _lng,
      );
      expect(place?.id, 'home');
    });
  });

  group('가리기', () {
    test('반경 안의 서로 다른 지점이 같은 값이 된다', () {
      // 이 단언이 이 기능의 전부다. 반올림이면 같은 집 안에서도 값이 몇 가지로
      // 갈리고, 그 분포에서 원래 위치가 복원된다. 중심 스냅은 되돌릴 수 없다.
      final a = maskWithPrivatePlaces([_home()], _latNorthOf(10), _lng);
      final b = maskWithPrivatePlaces([_home()], _latNorthOf(250), _lng);

      expect(a.latitude, b.latitude);
      expect(a.longitude, b.longitude);
      expect(a.latitude, _lat);
    });

    test('두 번 걸어도 결과가 같다', () {
      // 네이티브가 이미 가린 값을 Dart 가 한 번 더 가린다. 멱등하지 않으면
      // 두 겹 방어가 값을 망가뜨린다.
      final once = maskWithPrivatePlaces([_home()], _latNorthOf(120), _lng);
      final twice =
          maskWithPrivatePlaces([_home()], once.latitude, once.longitude);
      expect(twice.latitude, once.latitude);
      expect(twice.longitude, once.longitude);
    });

    test('반경 밖이면 좌표를 건드리지 않는다', () {
      final outside = _latNorthOf(900);
      final masked = maskWithPrivatePlaces([_home()], outside, _lng);
      expect(masked.latitude, outside);
    });

    test('등록된 곳이 없으면 좌표를 건드리지 않는다', () {
      final masked = maskWithPrivatePlaces(const [], _lat, _lng);
      expect(masked.latitude, _lat);
      expect(masked.longitude, _lng);
    });
  });

  group('채널 페이로드', () {
    test('이름을 네이티브로 보내지 않는다', () {
      // 이름 자체가 민감하다("정신과", "쉼터"). 네이티브는 가리는 데 이름이
      // 필요 없으므로, 로그나 크래시 리포트에 실릴 이유를 만들지 않는다.
      final payload = _home(name: '정신건강의학과').toChannel();
      expect(payload.keys.toSet(), {'lat', 'lng', 'radiusM'});
      expect(jsonEncode(payload).contains('정신'), isFalse);
    });
  });

  group('저장', () {
    test('왕복해도 값이 같다', () {
      final restored = PrivatePlaceStore.decode(
        PrivatePlaceStore.encode([_home(radiusM: 600)]),
      );
      expect(restored, hasLength(1));
      expect(restored.single.id, 'home');
      expect(restored.single.radiusM, 600);
      expect(restored.single.latitude, _lat);
    });

    test('깨진 JSON 에서 예외를 던지지 않는다', () {
      // 여기서 던지면 위치 공유 자체가 멈춘다. 저장된 문자열 하나 때문에
      // 안전 기능이 죽으면 안 된다.
      expect(PrivatePlaceStore.decode('{not json'), isEmpty);
      expect(PrivatePlaceStore.decode('{"a":1}'), isEmpty);
      expect(PrivatePlaceStore.decode(''), isEmpty);
      expect(PrivatePlaceStore.decode(null), isEmpty);
    });

    test('항목이 망가져 있으면 그 항목만 버린다', () {
      final raw = jsonEncode([
        {'id': 'ok', 'name': 'n', 'lat': 37.5, 'lng': 127.0, 'radiusM': 300},
        {'id': 'broken', 'lat': 'not a number'},
      ]);
      expect(PrivatePlaceStore.decode(raw).map((p) => p.id), ['ok']);
    });

    test('반경은 허용 범위로 조인다', () {
      final raw = jsonEncode([
        {'id': 'tiny', 'lat': 37.5, 'lng': 127.0, 'radiusM': 5},
        {'id': 'huge', 'lat': 37.5, 'lng': 127.0, 'radiusM': 999999},
      ]);
      final restored = PrivatePlaceStore.decode(raw);
      expect(restored[0].radiusM, PrivatePlace.minRadiusM);
      expect(restored[1].radiusM, PrivatePlace.maxRadiusM);
    });

    test('상한을 넘는 목록은 잘라서 저장한다', () {
      final many = [
        for (var i = 0; i < PrivatePlaceStore.maxPlaces + 5; i++)
          PrivatePlace(
            id: '$i',
            name: '$i',
            latitude: _lat,
            longitude: _lng,
            radiusM: 300,
          ),
      ];
      final restored =
          PrivatePlaceStore.decode(PrivatePlaceStore.encode(many));
      expect(restored, hasLength(PrivatePlaceStore.maxPlaces));
    });
  });
}
