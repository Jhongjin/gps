import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/l10n/app_localizations.dart';
import 'package:gyeote/src/core/backend/backend_contract.dart';
import 'package:gyeote/src/features/map/widgets/meetup_card.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';

Meetup _meetup({
  Duration fromNow = const Duration(minutes: 30),
  int graceMinutes = 30,
  MeetupResponse mine = MeetupResponse.invited,
  String createdBy = 'someone-else',
  int going = 1,
  int total = 3,
}) {
  return Meetup(
    id: 'm1',
    circleId: 'c1',
    createdBy: createdBy,
    name: '저녁 약속',
    placeName: '강남역 11번 출구',
    placeLat: 37.4979,
    placeLng: 127.0276,
    meetAt: DateTime.now().add(fromNow),
    graceMinutes: graceMinutes,
    myResponse: mine,
    goingCount: going,
    attendeeCount: total,
  );
}

void main() {
  group('스스로 끝나는 성질', () {
    test('약속 시각이 지나도 유예 동안은 살아 있다', () {
      // 시각이 지나자마자 사라지면 늦는 사람이 목적지를 잃는다.
      final justLate = _meetup(
        fromNow: const Duration(minutes: -10),
        graceMinutes: 30,
      );
      expect(justLate.isOver, isFalse);
      expect(justLate.timeUntil.isNegative, isTrue);
    });

    test('유예까지 지나면 끝난다', () {
      final done = _meetup(
        fromNow: const Duration(minutes: -40),
        graceMinutes: 30,
      );
      expect(done.isOver, isTrue);
    });

    test('만료 시각은 약속 시각 + 유예다', () {
      // SQL 의 is_meetup_over 와 같은 규칙이어야 한다. 두 곳이 어긋나면
      // 서버는 끝났다고 보는데 화면에는 남아 있는 상태가 된다.
      final m = _meetup(
        fromNow: const Duration(hours: 1),
        graceMinutes: 45,
      );
      expect(
        m.endsAt.difference(m.meetAt),
        const Duration(minutes: 45),
      );
    });
  });

  group('약속 카드', () {
    Widget host(Meetup meetup, {
      void Function(MeetupResponse)? onRespond,
      VoidCallback? onEnd,
      bool isCreator = false,
    }) {
      return MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('ko'),
        theme: buildGyeoteTheme(),
        home: Scaffold(
          body: MeetupCard(
            meetup: meetup,
            isCreator: isCreator,
            onRespond: onRespond ?? (_) {},
            onEnd: onEnd ?? () {},
          ),
        ),
      );
    }

    testWidgets('스스로 사라진다는 사실을 카드에 적는다', (tester) async {
      await tester.pumpWidget(host(_meetup(graceMinutes: 30)));

      // 이게 이 기능의 전부다. 안 보이면 사람들은 여전히 끄는 걸 걱정한다.
      expect(find.textContaining('자동으로 사라집니다'), findsOneWidget);
    });

    testWidgets('참석 인원이 보인다', (tester) async {
      await tester.pumpWidget(host(_meetup(going: 2, total: 4)));
      expect(find.text('참석 2/4'), findsOneWidget);
    });

    testWidgets('응답을 고르면 올라온다', (tester) async {
      MeetupResponse? picked;
      await tester.pumpWidget(
        host(_meetup(), onRespond: (r) => picked = r),
      );

      await tester.tap(find.text('미정'));
      expect(picked, MeetupResponse.maybe);
    });

    testWidgets('만든 사람만 끝낼 수 있다', (tester) async {
      await tester.pumpWidget(host(_meetup(createdBy: 'someone-else')));
      expect(find.text('약속 끝내기'), findsNothing);

      await tester.pumpWidget(host(_meetup(createdBy: 'me'), isCreator: true));
      expect(find.text('약속 끝내기'), findsOneWidget);
    });

    testWidgets('약속 시각이 지나면 남은 시간 대신 지난 시간을 보여 준다',
        (tester) async {
      await tester.pumpWidget(
        host(_meetup(fromNow: const Duration(minutes: -10))),
      );
      expect(find.textContaining('지남'), findsOneWidget);
    });

    testWidgets('탭 타깃이 44px 아래로 내려가지 않는다', (tester) async {
      await tester.pumpWidget(host(_meetup()));

      for (final label in ['참석', '미정', '불참']) {
        final box = tester.getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first,
        );
        expect(box.height, greaterThanOrEqualTo(44), reason: label);
      }
    });
  });
}
