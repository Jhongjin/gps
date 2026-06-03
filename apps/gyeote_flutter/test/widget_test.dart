import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/app/gyeote_app.dart';
import 'package:gyeote/src/core/backend/backend_config.dart';

void main() {
  const testConfig = BackendConfig(
    supabaseUrl: '',
    supabaseAnonKey: '',
    inviteBaseUrl: 'https://gyeote.app/invite',
  );

  testWidgets('renders the Gyeote shell in demo mode', (tester) async {
    await tester.pumpWidget(
      const GyeoteApp(backendConfig: testConfig),
    );

    expect(find.text('지도'), findsWidgets);
    expect(find.text('서클'), findsWidgets);
    expect(find.text('기록'), findsWidgets);
    expect(find.text('안심'), findsWidgets);
  });

  testWidgets('history screen exposes safety filters', (tester) async {
    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));

    await tester.tap(find.text('기록'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('안전 확인 1개'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('확인'), findsWidgets);
    expect(find.text('장소'), findsWidgets);
    expect(find.text('동행'), findsWidgets);
    expect(find.text('데이터'), findsWidgets);
  });

  testWidgets('map place alert draft exposes quiet hour presets',
      (tester) async {
    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));

    expect(find.text('장소 알림 저장'), findsOneWidget);
    expect(find.text('없음'), findsWidgets);
    expect(find.text('야간'), findsOneWidget);
    expect(find.text('수업'), findsOneWidget);
  });

  testWidgets('privacy screen exposes permission and battery controls',
      (tester) async {
    await tester.pumpWidget(const GyeoteApp(backendConfig: testConfig));

    await tester.tap(find.text('안심'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('배터리 모드'), findsOneWidget);
    expect(find.text('권한 상태'), findsOneWidget);
    expect(find.text('실시간'), findsOneWidget);
    expect(find.text('균형'), findsWidgets);
    expect(find.text('절전'), findsOneWidget);
  });
}
