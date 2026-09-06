import '../geo/geo_math.dart';

/// 정확한 위치를 내보내지 않을 장소.
///
/// 집·학교·병원·상담소처럼, 거기 있다는 사실보다 **어디의 몇 번째 건물인지**가
/// 훨씬 많은 것을 말해 주는 자리들이다. 위치 기록으로 생활 패턴이 드러나는
/// 문제(`docs/qa.md` 의 고위험 이슈)의 직접적인 완화책이다.
///
/// 이 객체는 **기기 밖으로 나가지 않는다.** 서버에 테이블이 없고, 채널로도
/// 네이티브 쪽 공유 정책에만 실린다. 서버에 두면 "이 사람이 숨기고 싶어 하는
/// 장소 목록"이라는, 원래 감추려던 것보다 더 압축된 정보가 한곳에 쌓인다.
///
/// 좌표를 `Coordinate` 가 아니라 double 로 들고 있는 것은 의도다. 이 파일이
/// 위치 모델을 참조하면 두 파일이 서로를 물게 되고, 무엇보다 이 계산은 위치
/// 파이프라인의 타입을 몰라도 성립한다.
class PrivatePlace {
  const PrivatePlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
  });

  final String id;

  /// 사용자가 붙인 이름. 화면에만 쓰고, 공유되는 좌표에도 채널에도 싣지 않는다.
  final String name;
  final double latitude;
  final double longitude;
  final int radiusM;

  /// 반경 하한. 이보다 작으면 가려도 건물 한 채가 특정된다.
  static const int minRadiusM = 100;

  /// 반경 상한. 이보다 크면 "동네 어딘가"조차 아니게 되어, 보는 사람이 위치
  /// 공유가 고장 났다고 생각한다.
  static const int maxRadiusM = 2000;

  static const List<int> radiusPresetsM = [150, 300, 600, 1000];

  double distanceTo(double lat, double lng) =>
      distanceMetersBetween(latitude, longitude, lat, lng);

  bool contains(double lat, double lng) => distanceTo(lat, lng) <= radiusM;

  PrivatePlace copyWith({String? name, int? radiusM}) => PrivatePlace(
        id: id,
        name: name ?? this.name,
        latitude: latitude,
        longitude: longitude,
        radiusM: radiusM ?? this.radiusM,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'lat': latitude,
        'lng': longitude,
        'radiusM': radiusM,
      };

  /// 네이티브로 보내는 형태. **이름을 싣지 않는다.**
  ///
  /// 네이티브는 좌표를 가리는 데 이름이 필요 없고, 이름 자체가 민감하다
  /// ("정신과", "쉼터"). 네이티브 로그나 크래시 리포트에 실릴 이유를 만들지
  /// 않는다.
  Map<String, Object?> toChannel() => {
        'lat': latitude,
        'lng': longitude,
        'radiusM': radiusM,
      };

  static PrivatePlace? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final lat = json['lat'];
    final lng = json['lng'];
    final radius = json['radiusM'];
    if (id is! String || lat is! num || lng is! num || radius is! num) {
      return null;
    }

    return PrivatePlace(
      id: id,
      name: json['name'] is String ? json['name']! as String : '',
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      radiusM: radius.toInt().clamp(minRadiusM, maxRadiusM),
    );
  }
}

/// 이 좌표를 감싸는 민감 장소. 여러 개가 겹치면 중심이 가장 가까운 것을 쓴다.
PrivatePlace? privatePlaceCovering(
  List<PrivatePlace> places,
  double lat,
  double lng,
) {
  PrivatePlace? best;
  var bestDistance = double.infinity;

  for (final place in places) {
    final distance = place.distanceTo(lat, lng);
    if (distance <= place.radiusM && distance < bestDistance) {
      best = place;
      bestDistance = distance;
    }
  }
  return best;
}

/// 공유될 좌표를 민감 장소 중심으로 밀어 넣는다.
///
/// 반올림이 아니라 **중심으로 스냅**한다. 반올림은 격자를 만들 뿐이라 같은 집
/// 안에서도 값이 몇 가지로 갈리고, 그 분포에서 원래 위치가 복원된다. 중심
/// 스냅은 반경 안의 모든 지점이 정확히 같은 값이 되어 되돌릴 수 없다.
///
/// 감싸는 장소가 없으면 받은 좌표를 그대로 돌려준다. 두 번 적용해도 결과가
/// 같다 — 중심은 언제나 자기 반경 안에 있다.
({double latitude, double longitude}) maskWithPrivatePlaces(
  List<PrivatePlace> places,
  double lat,
  double lng,
) {
  final place = privatePlaceCovering(places, lat, lng);
  if (place == null) return (latitude: lat, longitude: lng);
  return (latitude: place.latitude, longitude: place.longitude);
}
