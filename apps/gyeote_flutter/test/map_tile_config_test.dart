import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/core/map/map_tile_config.dart';

/// 타일 출처는 빌드 시점 값이다. 규칙만 고정한다.
void main() {
  test('아무것도 안 주면 OSM 이고, 그건 공용 서버다', () {
    final config = MapTileConfig.resolve(url: '', attribution: '');
    expect(config.urlTemplate, MapTileConfig.osmUrl);
    expect(config.attribution, MapTileConfig.osmAttribution);
    expect(config.isPublicOsm, isTrue);
  });

  test('URL 을 주면 그 출처를 쓰고 공용 서버가 아니다', () {
    final config = MapTileConfig.resolve(
      url: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=k',
      attribution: '© MapTiler © OpenStreetMap contributors',
    );
    expect(config.isPublicOsm, isFalse);
    expect(config.attribution, contains('MapTiler'));
  });

  test('URL 만 주고 표기를 빼면 OSM 표기를 그대로 두지 않는다', () {
    // 유료 타일로 옮긴 뒤에도 "© OpenStreetMap" 만 남으면 라이선스 표기가
    // 틀린다. 정확한 문구가 없을 때는 최소한 출처 호스트를 적는다.
    final config = MapTileConfig.resolve(
      url: 'https://tiles.example.com/{z}/{x}/{y}.png',
      attribution: '',
    );
    expect(config.attribution, '© tiles.example.com');
  });

  test('타일 레이어의 UA 는 앱 ID 다', () {
    // OSM 정책은 앱을 식별할 수 있는 UA 를 요구한다. 예전 값 com.gyeote.app 은
    // 어느 스토어에도 없는 이름이었다.
    expect(MapTileConfig.userAgentPackageName, 'app.gyeote.gyeote');
    expect(MapTileConfig.osm.layer().urlTemplate, MapTileConfig.osmUrl);
  });
}
