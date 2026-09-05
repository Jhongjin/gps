import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gyeote/src/app/gyeote_app.dart';
import 'package:gyeote/src/core/backend/backend_config.dart';
import 'package:gyeote/src/features/map/widgets/night_tiles.dart';

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

  /// 로케일을 고정한 뒤 앱을 띄운다.
  ///
  /// 고정하지 않으면 테스트 호스트의 로케일을 따라가서, 한국어 문자열을 찾는
  /// 검증이 환경에 따라 통과하기도 하고 실패하기도 한다.
  Future<void> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('ko'),
  }) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));
    // 온보딩 확인이 비동기다. 한 프레임 더 돌려야 셸이 그려진다.
    await tester.pump();
  }

  _darkModeTests();

  testWidgets('renders the Gyeote shell in demo mode', (tester) async {
    await pumpApp(tester);

    expect(find.text('지도'), findsWidgets);
    expect(find.text('서클'), findsWidgets);
    expect(find.text('기록'), findsWidgets);
    expect(find.text('안심'), findsWidgets);
  });

  testWidgets('shell follows the device locale', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));

    expect(find.text('Map'), findsWidgets);
    expect(find.text('Safety'), findsWidgets);
    expect(find.text('지도'), findsNothing);
  });

  testWidgets('history screen exposes safety filters', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('기록'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('안전 확인 1개'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('확인'), findsWidgets);
    expect(find.text('장소'), findsWidgets);
    expect(find.text('동행'), findsWidgets);
    expect(find.text('데이터'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('스폰서'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('스폰서'), findsOneWidget);
  });

  testWidgets('map place alert draft exposes quiet hour presets',
      (tester) async {
    await pumpApp(tester);

    // 장소 알림은 지도를 가리지 않도록 드래그 시트 안으로 들어갔다.
    await tester.scrollUntilVisible(
      find.text('장소 알림 저장'),
      300,
      scrollable: _mapSheet(),
    );

    expect(find.text('장소 알림 저장'), findsOneWidget);
    expect(find.text('없음'), findsWidgets);
    expect(find.text('야간'), findsOneWidget);
    expect(find.text('수업'), findsOneWidget);
  });

  testWidgets('map keeps the map full-bleed under a draggable sheet',
      (tester) async {
    await pumpApp(tester);

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.textContaining('명이 위치 공유 중'), findsOneWidget);
  });

  testWidgets('tapping a member opens the member sheet', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('준').first);
    await tester.pumpAndSettle();

    expect(find.text('배터리'), findsOneWidget);
    expect(find.text('정확도'), findsOneWidget);
    expect(find.text('이 위치를 본 사람'), findsOneWidget);
  });

  testWidgets('SOS never fires on a single tap', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('SOS'));
    await tester.pump(const Duration(milliseconds: 300));

    // 카운트다운은 길게 눌러야만 나타난다.
    expect(find.text('긴급 공유 준비'), findsNothing);
  });

  testWidgets('privacy screen exposes permission and battery controls',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('안심'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('배터리 모드'), findsOneWidget);
    expect(find.text('권한 상태'), findsOneWidget);
    expect(find.text('실시간'), findsOneWidget);
    expect(find.text('균형'), findsWidgets);
    expect(find.text('절전'), findsOneWidget);
  });
}

/// 지도 화면의 드래그 시트 스크롤러.
Finder _mapSheet() => find.ancestor(
      of: find.textContaining('명이 위치 공유 중'),
      matching: find.byType(Scrollable),
    );

/// 다크 모드 회귀 방지.
///
/// 테마만 어두워지고 지도 타일이 밝게 남으면 화면 절반이 눈을 때린다.
/// 실제로 그 상태로 한 번 배포될 뻔했다.
void _darkModeTests() {
  const testConfig = BackendConfig(
    supabaseUrl: '',
    supabaseAnonKey: '',
    inviteBaseUrl: 'https://gyeote.app/invite',
  );

  Future<void> pumpDark(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'gyeote.onboarding.seen.v1': true});
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));
    // 온보딩 확인이 비동기다. 한 프레임 더 돌려야 셸이 그려진다.
    await tester.pump();
  }

  testWidgets('dark mode darkens the map tiles too', (tester) async {
    await pumpDark(tester);

    expect(Theme.of(tester.element(find.byType(NightTiles))).brightness,
        Brightness.dark);
    // NightTiles 는 다크에서만 필터를 건다.
    expect(
      find.descendant(
        of: find.byType(NightTiles),
        matching: find.byType(ColorFiltered),
      ),
      findsWidgets,
    );
  });

  testWidgets('light mode leaves the tiles untouched', (tester) async {
    SharedPreferences.setMockInitialValues({'gyeote.onboarding.seen.v1': true});
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));
    // 온보딩 확인이 비동기다. 한 프레임 더 돌려야 셸이 그려진다.
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(NightTiles),
        matching: find.byType(ColorFiltered),
      ),
      findsNothing,
    );
  });
}
