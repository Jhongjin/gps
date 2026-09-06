import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'private_place.dart';

/// 민감 장소를 기기에만 보관한다.
///
/// 서버에 두지 않는 것이 이 기능의 절반이다. "이 사람이 숨기고 싶어 하는
/// 장소 목록"은 가리려던 원래 좌표보다 더 압축된 정보라, 한곳에 모이면
/// 유출됐을 때 피해가 더 크다. 계정을 옮기면 다시 등록해야 하는데, 그 불편은
/// 여기서 감수할 값이다.
class PrivatePlaceStore {
  const PrivatePlaceStore();

  static const String storageKey = 'gyeote.private_places.v1';

  /// 한 사람이 관리할 수 있는 수를 넘기면 목록이 아니라 짐이 된다.
  static const int maxPlaces = 12;

  Future<List<PrivatePlace>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(storageKey));
  }

  Future<void> save(List<PrivatePlace> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, encode(places));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  /// 저장 형식을 테스트에서 직접 다루려고 열어 둔다.
  static String encode(List<PrivatePlace> places) => jsonEncode(
        places.take(maxPlaces).map((place) => place.toJson()).toList(),
      );

  /// 깨진 값에서 예외를 던지지 않는다. 여기서 실패하면 위치 공유 자체가
  /// 멈추는데, 저장된 JSON 하나 때문에 안전 기능이 죽으면 안 된다. 대신
  /// 비어 있는 목록으로 떨어뜨린다 — 가림이 사라지는 쪽이 아니라 **정확한
  /// 위치가 나가는 쪽**이므로, 이 실패는 조용히 두면 안 되고 화면이 목록이
  /// 비었다는 사실을 그대로 보여 준다.
  static List<PrivatePlace> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, Object?>>()
          .map(PrivatePlace.fromJson)
          .nonNulls
          .take(maxPlaces)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }
}
