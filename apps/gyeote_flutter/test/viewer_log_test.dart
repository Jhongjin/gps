import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/l10n/app_localizations.dart';
import 'package:gyeote/src/core/backend/backend_contract.dart';
import 'package:gyeote/src/core/location/location_models.dart';
import 'package:gyeote/src/features/privacy/viewer_log_view.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';

/// 열람 기록만 대답하는 최소 저장소. 나머지는 이 테스트에서 쓰이지 않는다.
class _FakeCircleRepository implements CircleRepository {
  _FakeCircleRepository({this.entries = const [], this.fails = false});

  final List<ViewerLogEntry> entries;
  final bool fails;
  final List<({String profileId, String circleId, SharingMode precision})>
      recorded = [];

  @override
  Future<List<ViewerLogEntry>> listViewerLog({
    int limit = 50,
    Duration since = const Duration(days: 30),
  }) async {
    if (fails) throw StateError('boom');
    return entries.take(limit).toList(growable: false);
  }

  @override
  Future<void> recordViewerLog({
    required String profileId,
    required String circleId,
    required SharingMode precision,
  }) async {
    recorded.add(
      (profileId: profileId, circleId: circleId, precision: precision),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ViewerLogEntry _entry({
  String id = '1',
  String name = '보호자',
  SharingMode precision = SharingMode.balanced,
  Duration ago = const Duration(minutes: 12),
}) =>
    ViewerLogEntry(
      id: id,
      viewerProfileId: 'viewer-$id',
      viewerName: name,
      circleId: 'circle',
      precision: precision,
      viewedAt: DateTime.now().subtract(ago),
    );

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      theme: buildGyeoteTheme(),
      home: Scaffold(body: child),
    );

void main() {
  group('열람 기록 목록', () {
    testWidgets('본 사람과 정확도를 그린다', (tester) async {
      final repository = _FakeCircleRepository(
        entries: [_entry(name: '보호자', precision: SharingMode.area)],
      );
      await tester.pumpWidget(_host(ViewerLogView(repository: repository)));
      await tester.pumpAndSettle();

      expect(find.text('보호자'), findsOneWidget);
      expect(find.textContaining('동네 범위'), findsOneWidget);
    });

    testWidgets('아무도 안 봤으면 그렇다고 말한다', (tester) async {
      // 빈 목록에 아무것도 그리지 않으면, 기록 기능이 고장 난 것인지 정말
      // 아무도 안 본 것인지 구분할 수 없다.
      await tester.pumpWidget(
        _host(ViewerLogView(repository: _FakeCircleRepository())),
      );
      await tester.pumpAndSettle();

      expect(find.text('아직 아무도 열어 보지 않았습니다'), findsOneWidget);
    });

    testWidgets('실패를 조용히 빈 목록으로 보여 주지 않는다', (tester) async {
      // 이게 이 화면에서 가장 위험한 실패다. 불러오지 못한 것을 "아무도 안
      // 봤음"으로 그리면, 사용자는 감시당하지 않았다고 잘못 안심한다.
      await tester.pumpWidget(
        _host(ViewerLogView(repository: _FakeCircleRepository(fails: true))),
      );
      await tester.pumpAndSettle();

      expect(find.text('열람 기록을 불러오지 못했습니다.'), findsOneWidget);
      expect(find.text('아직 아무도 열어 보지 않았습니다'), findsNothing);
    });

    testWidgets('이름이 비어 있어도 빈 줄을 그리지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          ViewerLogView(
            repository: _FakeCircleRepository(entries: [_entry(name: '')]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('이름 없는 멤버'), findsOneWidget);
    });
  });

  group('열람 기록 쓰기', () {
    test('본 사람·서클·정확도를 함께 남긴다', () async {
      final repository = _FakeCircleRepository();
      await repository.recordViewerLog(
        profileId: 'jun',
        circleId: 'family',
        precision: SharingMode.precise,
      );

      expect(repository.recorded.single.profileId, 'jun');
      expect(repository.recorded.single.circleId, 'family');
      expect(repository.recorded.single.precision, SharingMode.precise);
    });
  });

  group('상대 시각', () {
    late AppL10n l10n;

    setUp(() async {
      l10n = await AppL10n.delegate.load(const Locale('ko'));
    });

    test('분·시간·일 단위로 끊는다', () {
      final now = DateTime(2026, 9, 7, 12, 0);
      String at(Duration ago) =>
          viewerLogTimeLabel(l10n, now.subtract(ago), now: now);

      expect(at(const Duration(seconds: 20)), '방금');
      expect(at(const Duration(minutes: 12)), contains('12'));
      expect(at(const Duration(hours: 5)), contains('5'));
      expect(at(const Duration(days: 2)), contains('2'));
    });
  });
}
