import 'package:flutter/material.dart';
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
}
