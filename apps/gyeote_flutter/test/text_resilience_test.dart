import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gyeote/src/app/gyeote_app.dart';
import 'package:gyeote/src/core/backend/backend_config.dart';

/// OS 글자 크기를 키웠을 때 화면이 깨지지 않는지 본다.
///
/// 이건 접근성 항목이면서 동시에 다국어 항목이다. 고정 `fontSize` 에
/// `maxLines: 1` 을 얹고 `Expanded` 로 균등 분할한 자리는, 글자 배율을 키울
/// 때와 긴 로케일(독일어)을 넣을 때 **같은 방식으로** 깨진다. 배율은 지금
/// 당장 테스트할 수 있으니, 독일어를 열기 전에 여기서 먼저 막는다.
///
/// Flutter 는 오버플로를 디버그 빌드에서 예외로 던진다. 그래서 별도 단언 없이
/// `takeException()` 이 비어 있는지만 보면 된다.
void main() {
  // 온보딩은 첫 실행에만 뜬다. 이 파일들은 그 이후 화면을 본다.
  setUp(() => SharedPreferences.setMockInitialValues(
        {'gyeote.onboarding.seen.v1': true},
      ));

  const testConfig = BackendConfig(
    supabaseUrl: '',
    supabaseAnonKey: '',
    inviteBaseUrl: 'https://gyeote.app/invite',
  );

  /// 작은 기기 + 큰 글자. 가장 불리한 조합이다.
  Future<void> pumpScaled(WidgetTester tester, double scale) async {
    tester.view.physicalSize = const Size(1080, 2070); // 360x690 @3x
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));
    // 온보딩 확인이 비동기다. 한 프레임 더 돌려야 셸이 그려진다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Android 의 "가장 크게"가 대략 이 배율이다. iOS 접근성 크기는 더 올라간다.
  const scales = [1.0, 1.3, 2.0];

  for (final scale in scales) {
    testWidgets('map survives text scale $scale', (tester) async {
      await pumpScaled(tester, scale);
      expect(tester.takeException(), isNull);
    });

    testWidgets('circle survives text scale $scale', (tester) async {
      await pumpScaled(tester, scale);
      await tester.tap(find.text('서클'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('history survives text scale $scale', (tester) async {
      await pumpScaled(tester, scale);
      await tester.tap(find.text('기록'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('privacy survives text scale $scale', (tester) async {
      await pumpScaled(tester, scale);
      await tester.tap(find.text('안심'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('member sheet survives large text', (tester) async {
    await pumpScaled(tester, 2.0);
    await tester.tap(find.text('준').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
