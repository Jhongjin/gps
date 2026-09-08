import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/app/gyeote_app.dart';
import 'package:gyeote/src/core/backend/backend_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 마커 링이 그리는 것을 스크린리더도 듣는지 본다.
///
/// 링은 배터리를 채움 정도로, 오래됨을 색으로 그린다. 그 두 가지를 위한
/// 문구(`a11yBatteryLevel`, `a11yStaleLocation`, `a11yAttentionBadge`)는 ARB 에
/// 있었지만 어디서도 쓰이지 않았다. 이 테스트는 그 문구가 실제 의미 트리에
/// 도달하는지를 고정한다 — 문구가 존재하는 것과 읽히는 것은 다르다.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
        {'gyeote.onboarding.seen.v1': true},
      ));

  const testConfig = BackendConfig(
    supabaseUrl: '',
    supabaseAnonKey: '',
    inviteBaseUrl: 'https://gyeote.app/invite',
  );

  Future<SemanticsHandle> pumpDemo(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return handle;
  }

  testWidgets('배터리 잔량이 읽힌다', (tester) async {
    final handle = await pumpDemo(tester);
    // 데모의 준은 46%다. 링에만 있던 숫자가 라벨에 있어야 한다.
    expect(
      find.bySemanticsLabel(RegExp('배터리 46퍼센트')),
      findsWidgets,
    );
    handle.dispose();
  });

  testWidgets('오래된 위치가 읽힌다', (tester) async {
    final handle = await pumpDemo(tester);
    // 데모의 할아버지는 22분 전 위치다.
    expect(
      find.bySemanticsLabel(RegExp('위치가 오래됐습니다')),
      findsWidgets,
    );
    handle.dispose();
  });

  testWidgets('확인 필요 배지가 숫자만이 아니라 문장으로 읽힌다', (tester) async {
    final handle = await pumpDemo(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'확인이 필요한 멤버 \d+명')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
