import 'package:flutter_map/flutter_map.dart';

/// 지도 타일 출처.
///
/// 개발 기본값은 OpenStreetMap 공용 타일 서버다. 그건 **출시용이 아니다** —
/// OSM 재단의 타일 사용 정책은 앱 규모 트래픽을 막고, 타일 요청마다 기기의 IP
/// 와 보고 있는 영역이 그 서버에 실린다(처리방침 §3 에 그렇게 적었다). 출시
/// 빌드는 `--dart-define` 으로 유료 타일을 넣는다:
///
///     --dart-define=MAP_TILE_URL=https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=KEY
///     --dart-define=MAP_TILE_ATTRIBUTION="© MapTiler © OpenStreetMap contributors"
///
/// 저작자 표시는 ODbL 상 빼면 안 된다. 공급자를 바꾸면 표시 문구도 함께 바꾼다.
class MapTileConfig {
  const MapTileConfig({
    required this.urlTemplate,
    required this.attribution,
    this.maxNativeZoom = 19,
  });

  static const String osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution = '© OpenStreetMap';

  static const MapTileConfig osm = MapTileConfig(
    urlTemplate: osmUrl,
    attribution: osmAttribution,
  );

  /// 빌드 시점의 `--dart-define` 값. 비어 있으면 OSM.
  factory MapTileConfig.fromEnvironment() {
    const url = String.fromEnvironment('MAP_TILE_URL');
    const attribution = String.fromEnvironment('MAP_TILE_ATTRIBUTION');
    const maxZoom = int.fromEnvironment('MAP_TILE_MAX_ZOOM', defaultValue: 19);
    return MapTileConfig.resolve(
      url: url,
      attribution: attribution,
      maxNativeZoom: maxZoom,
    );
  }

  /// [fromEnvironment] 의 규칙을 테스트에서도 쓰려고 따로 둔다.
  ///
  /// URL 만 바꾸고 표시 문구를 안 넣으면 OSM 표기가 그대로 남는다 — 그게 틀린
  /// 표기가 될 수 있으므로, URL 이 있는데 표기가 없으면 URL 의 호스트를 적는다.
  /// 없는 것보다 낫고, 정확한 문구는 공급자가 정해 준다.
  static MapTileConfig resolve({
    required String url,
    required String attribution,
    int maxNativeZoom = 19,
  }) {
    if (url.isEmpty) return osm;
    final label = attribution.isNotEmpty
        ? attribution
        : '© ${Uri.tryParse(url)?.host ?? url}';
    return MapTileConfig(
      urlTemplate: url,
      attribution: label,
      maxNativeZoom: maxNativeZoom,
    );
  }

  final String urlTemplate;
  final String attribution;
  final int maxNativeZoom;

  /// 출시 빌드가 이 값이면 안 된다. 스토어 가이드 §5 참조.
  bool get isPublicOsm => urlTemplate.contains('tile.openstreetmap.org');

  /// 두 지도(메인, 경로 재생)가 같은 출처와 같은 UA 를 쓴다. OSM 정책은 앱을
  /// 식별할 수 있는 UA 를 요구하고, 그 값은 앱 ID 와 같아야 추적이 된다.
  static const String userAgentPackageName = 'app.gyeote.gyeote';

  TileLayer layer() => TileLayer(
        urlTemplate: urlTemplate,
        userAgentPackageName: userAgentPackageName,
        maxNativeZoom: maxNativeZoom,
      );
}

/// 앱 전체가 쓰는 타일 설정. 빌드 시점에 고정된다.
final MapTileConfig gyeoteTiles = MapTileConfig.fromEnvironment();
