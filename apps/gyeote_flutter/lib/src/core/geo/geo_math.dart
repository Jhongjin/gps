import 'dart:math' as math;

/// 좌표 계산. 지도 기능과 프라이버시 기능이 함께 쓴다.
///
/// `LatLng` 를 받지 않고 double 을 받는다. `latlong2` 는 지도 패키지의 타입이고,
/// 업로드 직전에 좌표를 가리는 코드가 지도 패키지를 끌고 올 이유가 없다.

/// 지구 반지름(m).
const double earthRadiusM = 6371008.8;

/// 두 지점 사이 대권 거리(m).
double distanceMetersBetween(
  double lat1Deg,
  double lng1Deg,
  double lat2Deg,
  double lng2Deg,
) {
  final lat1 = _toRadians(lat1Deg);
  final lat2 = _toRadians(lat2Deg);
  final dLat = lat2 - lat1;
  final dLng = _toRadians(lng2Deg - lng1Deg);

  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
}

/// 첫 지점에서 두 번째 지점을 향하는 방위각. 진북 0, 시계방향 0~360.
double bearingDegreesBetween(
  double lat1Deg,
  double lng1Deg,
  double lat2Deg,
  double lng2Deg,
) {
  final lat1 = _toRadians(lat1Deg);
  final lat2 = _toRadians(lat2Deg);
  final dLng = _toRadians(lng2Deg - lng1Deg);

  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (_toDegrees(math.atan2(y, x)) + 360) % 360;
}

/// 두 방위각 사이의 최소 각도차(0~180).
///
/// 350도와 10도는 340도가 아니라 20도 차이다. 이걸 틀리면 북쪽으로 가는 사람이
/// 반대로 가는 것으로 읽힌다.
double bearingDeltaDegreesBetween(double a, double b) {
  final diff = (a - b).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}

double _toRadians(double degrees) => degrees * math.pi / 180;

double _toDegrees(double radians) => radians * 180 / math.pi;
