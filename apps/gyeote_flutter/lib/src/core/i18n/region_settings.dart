import 'dart:ui';

/// 지역마다 값 자체가 달라지는 항목.
///
/// 이것들을 번역 문자열로 다루면 안전 기능이 오작동한다. 한국의 `112`를
/// 독일어로 "번역"해도 독일에서는 틀린 번호다. 그래서 ARB가 아니라 여기 둔다.
///
/// 한·일·독이 `110`/`112`/`119`를 부분적으로 공유해서 오히려 더 위험하다 —
/// 그럴듯해 보이는 값이 조용히 틀리는 쪽이 명백히 틀린 값보다 나쁘다.
class RegionSettings {
  const RegionSettings({
    required this.emergencyNumber,
    required this.policeNumber,
    required this.distanceUnit,
    required this.uses24HourClock,
  });

  /// 구급·소방.
  final String emergencyNumber;

  /// 경찰.
  final String policeNumber;

  final DistanceUnit distanceUnit;
  final bool uses24HourClock;

  static const _korea = RegionSettings(
    emergencyNumber: '119',
    policeNumber: '112',
    distanceUnit: DistanceUnit.metric,
    uses24HourClock: true,
  );

  static const _japan = RegionSettings(
    emergencyNumber: '119',
    policeNumber: '110',
    distanceUnit: DistanceUnit.metric,
    uses24HourClock: true,
  );

  static const _germany = RegionSettings(
    emergencyNumber: '112',
    policeNumber: '110',
    distanceUnit: DistanceUnit.metric,
    uses24HourClock: true,
  );

  /// 미국만 야드파운드법을 쓴다. 반경 프리셋도 함께 달라져야 한다.
  static const _unitedStates = RegionSettings(
    emergencyNumber: '911',
    policeNumber: '911',
    distanceUnit: DistanceUnit.imperial,
    uses24HourClock: false,
  );

  /// EU 공통 긴급번호.
  static const _europe = RegionSettings(
    emergencyNumber: '112',
    policeNumber: '112',
    distanceUnit: DistanceUnit.metric,
    uses24HourClock: true,
  );

  /// 알 수 없는 지역에서는 국제 표준인 `112`로 떨어뜨린다.
  /// 대부분의 GSM 단말이 이 번호를 지역 긴급번호로 라우팅한다.
  static const fallback = _europe;

  /// 사용자 기기의 지역을 우선한다. 언어가 아니라 **지역**이 기준이다 —
  /// 독일에 사는 한국어 사용자에게 필요한 번호는 `112`다.
  static RegionSettings of(Locale locale) {
    return switch (locale.countryCode) {
      'KR' => _korea,
      'JP' => _japan,
      'DE' || 'AT' || 'CH' => _germany,
      'US' => _unitedStates,
      'ES' || 'FR' || 'IT' || 'NL' || 'BE' || 'PL' || 'SE' => _europe,
      _ => switch (locale.languageCode) {
          'ko' => _korea,
          'ja' => _japan,
          'de' => _germany,
          _ => fallback,
        },
    };
  }
}

enum DistanceUnit {
  metric,
  imperial;

  /// 장소 알림 반경 프리셋. 미터를 그대로 마일로 환산하면
  /// `0.06mi` 같은 값이 나오므로, 단위계마다 값을 새로 고른다.
  List<int> get radiusPresetsM => switch (this) {
        DistanceUnit.metric => const [100, 300, 500],
        // 대략 1/16 · 1/8 · 1/4 마일.
        DistanceUnit.imperial => const [100, 200, 400],
      };

  String formatDistance(double meters) => switch (this) {
        DistanceUnit.metric => meters >= 1000
            ? '${(meters / 1000).toStringAsFixed(1)}km'
            : '${meters.round()}m',
        DistanceUnit.imperial => meters >= 402
            ? '${(meters / 1609.344).toStringAsFixed(1)}mi'
            : '${(meters * 3.28084).round()}ft',
      };
}
