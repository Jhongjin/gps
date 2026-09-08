import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/core/i18n/region_settings.dart';

void main() {
  group('긴급번호는 번역 대상이 아니라 지역 설정값이다', () {
    test('나라마다 다른 번호를 낸다', () {
      expect(RegionSettings.of(const Locale('ko', 'KR')).policeNumber, '112');
      expect(RegionSettings.of(const Locale('ja', 'JP')).policeNumber, '110');
      expect(RegionSettings.of(const Locale('de', 'DE')).policeNumber, '110');
      expect(RegionSettings.of(const Locale('en', 'US')).policeNumber, '911');
      expect(RegionSettings.of(const Locale('es', 'ES')).policeNumber, '112');
    });

    test('언어가 아니라 지역을 따른다', () {
      // 독일에 사는 한국어 사용자에게 필요한 번호는 112 이지 119 가 아니다.
      final koreanInGermany = RegionSettings.of(const Locale('ko', 'DE'));
      expect(koreanInGermany.emergencyNumber, '112');
      expect(koreanInGermany.policeNumber, '110');
    });

    test('알 수 없는 지역은 국제 표준 112 로 떨어진다', () {
      expect(RegionSettings.of(const Locale('pt', 'BR')).emergencyNumber, '112');
    });

    test('한국과 일본은 구급 번호를 공유하지만 경찰 번호가 다르다', () {
      final kr = RegionSettings.of(const Locale('ko', 'KR'));
      final jp = RegionSettings.of(const Locale('ja', 'JP'));
      expect(kr.emergencyNumber, jp.emergencyNumber);
      expect(kr.policeNumber, isNot(jp.policeNumber));
    });
  });

  group('거리 단위', () {
    test('미국만 야드파운드법을 쓴다', () {
      expect(
        RegionSettings.of(const Locale('en', 'US')).distanceUnit,
        DistanceUnit.imperial,
      );
      expect(
        RegionSettings.of(const Locale('en', 'GB')).distanceUnit,
        DistanceUnit.metric,
      );
    });

    test('반경 프리셋은 단위계마다 따로 고른다', () {
      expect(DistanceUnit.metric.radiusPresetsM, [100, 300, 500]);
      // 미터 값을 그대로 환산하면 0.06mi 같은 값이 나오므로 다시 고른다.
      expect(DistanceUnit.imperial.radiusPresetsM, isNot([100, 300, 500]));
    });

    test('거리 표기', () {
      expect(DistanceUnit.metric.formatDistance(85), '85m');
      expect(DistanceUnit.metric.formatDistance(1500), '1.5km');
      expect(DistanceUnit.imperial.formatDistance(85), '279ft');
      expect(DistanceUnit.imperial.formatDistance(1609.344), '1.0mi');
    });
  });
}
