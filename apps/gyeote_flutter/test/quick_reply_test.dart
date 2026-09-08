import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/l10n/app_localizations.dart';
import 'package:gyeote/src/app/gyeote_app.dart';
import 'package:gyeote/src/core/backend/backend_config.dart';
import 'package:gyeote/src/core/backend/backend_contract.dart';
import 'package:gyeote/src/features/map/widgets/quick_reply_bar.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
        {'gyeote.onboarding.seen.v1': true},
      ));

  group('상태 모델', () {
    test('사용자가 고를 수 있는 값은 네 가지다', () {
      expect(CheckInStatus.quickReplies, hasLength(4));
      for (final status in CheckInStatus.quickReplies) {
        expect(status.isQuickReply, isTrue, reason: '$status');
      }
    });

    test('시스템이 판단하는 상태는 고를 수 없다', () {
      expect(CheckInStatus.needsCheck.isQuickReply, isFalse);
      expect(CheckInStatus.signalWeak.isQuickReply, isFalse);
    });

    test('동행 세션을 끝내는 것은 도착 확인뿐이다', () {
      // 이 규칙이 깨지면 '가는 중'을 보낸 순간, 마침 위치 공유가 필요한
      // 사람의 공유가 꺼진다. 마이그레이션 016 에도 같은 가드가 있다.
      expect(CheckInStatus.safeArrived.endsCompanionSession, isTrue);
      for (final status in [
        CheckInStatus.onTheWay,
        CheckInStatus.imOk,
        CheckInStatus.callMe,
      ]) {
        expect(status.endsCompanionSession, isFalse, reason: '$status');
      }
    });
  });

  group('정형 반응 바', () {
    Widget host({
      required bool isEnabled,
      CheckInStatus? sending,
      ValueChanged<CheckInStatus>? onSend,
    }) {
      return MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('ko'),
        theme: buildGyeoteTheme(),
        home: Scaffold(
          body: QuickReplyBar(
            onSend: onSend ?? (_) {},
            isEnabled: isEnabled,
            sending: sending,
          ),
        ),
      );
    }

    testWidgets('네 가지가 모두 보인다', (tester) async {
      await tester.pumpWidget(host(isEnabled: true));

      expect(find.text('무사 도착'), findsOneWidget);
      expect(find.text('가는 중'), findsOneWidget);
      expect(find.text('괜찮아'), findsOneWidget);
      expect(find.text('전화해줘'), findsOneWidget);
    });

    testWidgets('누르면 해당 상태가 올라온다', (tester) async {
      CheckInStatus? sent;
      await tester.pumpWidget(host(isEnabled: true, onSend: (s) => sent = s));

      await tester.tap(find.text('괜찮아'));
      expect(sent, CheckInStatus.imOk);
    });

    testWidgets('하나가 나가는 동안 나머지도 잠긴다', (tester) async {
      CheckInStatus? sent;
      await tester.pumpWidget(host(
        isEnabled: true,
        sending: CheckInStatus.onTheWay,
        onSend: (s) => sent = s,
      ));

      await tester.tap(find.text('괜찮아'));
      expect(sent, isNull);
    });

    testWidgets('서클이 없으면 보낼 수 없다', (tester) async {
      CheckInStatus? sent;
      await tester.pumpWidget(host(isEnabled: false, onSend: (s) => sent = s));

      await tester.tap(find.text('가는 중'));
      expect(sent, isNull);
    });

    testWidgets('탭 타깃이 44px 아래로 내려가지 않는다', (tester) async {
      await tester.pumpWidget(host(isEnabled: true));

      for (final label in ['무사 도착', '가는 중', '괜찮아', '전화해줘']) {
        final box = tester.getSize(
          find.ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first,
        );
        expect(box.height, greaterThanOrEqualTo(44), reason: label);
      }
    });
  });

  testWidgets('지도 시트에 정형 반응이 있다', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const GyeoteApp(
      backendConfig: BackendConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        inviteBaseUrl: 'https://gyeote.app/invite',
      ),
    ));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(QuickReplyBar),
      200,
      scrollable: find.ancestor(
        of: find.textContaining('명이 위치 공유 중'),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byType(QuickReplyBar), findsOneWidget);
  });

  testWidgets('the sheet expands when dragged', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const GyeoteApp(
      backendConfig: BackendConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        inviteBaseUrl: 'https://gyeote.app/invite',
      ),
    ));
    await tester.pump();

    // DraggableScrollableSheet 위젯은 Stack 전체를 차지하므로 그 위치로는
    // 재지 못한다. 시트 안 콘텐츠가 얼마나 올라왔는지를 본다.
    final header = find.textContaining('명이 위치 공유 중');
    final before = tester.getTopLeft(header).dy;

    // initialChildSize 가 snapSizes 밖에 있으면 여기서 엉뚱한 지점으로 튄다.
    await tester.drag(header, const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(before - 100));
  });
}
