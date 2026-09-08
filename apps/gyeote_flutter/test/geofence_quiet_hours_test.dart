import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/core/location/location_bridge.dart';
import 'package:gyeote/src/core/location/location_models.dart';

/// 조용한 시간이 지오펜스 등록 페이로드까지 내려가는지 본다.
///
/// 지오펜스 전환은 앱이 죽어 있어도 네이티브 리시버가 처리한다. 창이 여기까지
/// 내려가지 않으면 앱은 조용한 시간을 저장하고 보여 주고 순환시키면서, 알림은
/// 시각과 무관하게 같은 소리로 울린다 — 지금까지 실제로 그랬다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app.gyeote/location');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('창이 있는 지오펜스는 quietStart·quietEnd 를 싣는다', () async {
    await LocationBridge().registerGeofences(const [
      GeofenceSpec(
        id: 'home',
        center: Coordinate(latitude: 37.5, longitude: 127.0),
        radiusM: 200,
        notifyOnArrival: true,
        notifyOnDeparture: true,
        quietStart: '22:00',
        quietEnd: '07:00',
      ),
      GeofenceSpec(
        id: 'school',
        center: Coordinate(latitude: 37.5, longitude: 127.0),
        radiusM: 200,
        notifyOnArrival: true,
        notifyOnDeparture: false,
      ),
    ]);

    final call = calls.singleWhere((c) => c.method == 'registerGeofences');
    final geofences =
        (call.arguments as Map)['geofences'] as List<dynamic>;
    final home = geofences.firstWhere((g) => g['id'] == 'home') as Map;
    final school = geofences.firstWhere((g) => g['id'] == 'school') as Map;

    expect(home['quietStart'], '22:00');
    expect(home['quietEnd'], '07:00');
    expect(school['quietStart'], isNull);
    expect(school['quietEnd'], isNull);
  });
}
