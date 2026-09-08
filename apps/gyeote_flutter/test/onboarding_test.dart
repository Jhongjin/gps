import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/l10n/app_localizations.dart';
import 'package:gyeote/src/app/gyeote_app.dart';
import 'package:gyeote/src/core/backend/backend_config.dart';
import 'package:gyeote/src/features/onboarding/onboarding_screen.dart';
import 'package:gyeote/src/features/onboarding/permission_primer.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const testConfig = BackendConfig(
    supabaseUrl: '',
    supabaseAnonKey: '',
    inviteBaseUrl: 'https://gyeote.app/invite',
  );

  Future<void> pumpApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));
    await tester.pump();
  }

  testWidgets('first run explains before anything else', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('가까운 사람과, 필요한 만큼만'), findsOneWidget);
    // 지도는 아직 나오면 안 된다.
    expect(find.byType(DraggableScrollableSheet), findsNothing);
  });

  testWidgets('onboarding can be skipped and does not come back',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('지도'), findsWidgets);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('gyeote.onboarding.seen.v1'), isTrue);
  });

  testWidgets('a returning user goes straight to the map', (tester) async {
    SharedPreferences.setMockInitialValues(
      {'gyeote.onboarding.seen.v1': true},
    );
    await pumpApp(tester);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });

  testWidgets('the permission primer explains before the system asks',
      (tester) async {
    bool? answer;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('ko'),
        theme: buildGyeoteTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  answer = await showPermissionPrimer(
                    context,
                    purpose: PermissionPurpose.background,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 왜 필요한지와, 쓰지 않겠다는 약속이 함께 보여야 한다.
    expect(find.text('장소 알림에는 백그라운드 위치가 필요합니다'), findsOneWidget);
    expect(find.textContaining('광고에 쓰지 않고'), findsOneWidget);

    // 물러나면 false 다. 호출자는 이때 OS API 를 부르지 않는다 —
    // 물어보지 않아야 다음 기회가 남는다.
    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });

  testWidgets('시작하기는 네이티브 브리지가 없어도 온보딩을 끝낸다', (tester) async {
    // 웹에서 "시작하기"를 누르면 권한 요청이 MissingPluginException 으로 죽었고,
    // 그게 완료 setState 를 막아 화면이 넘어가지 않았다. 본 것은 이미 저장된
    // 뒤라 새로고침하면 지도가 뜨는, 설명할 수 없는 상태였다. 권한 요청 실패는
    // 온보딩 완료를 막을 이유가 못 된다.
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('app.gyeote/location');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException('no native bridge in this test');
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // 테스트 로케일은 en 이라 버튼 글자를 찾지 않는다. 주 버튼 하나뿐이다.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    }

    expect(find.byType(OnboardingScreen), findsNothing);
  });
}
