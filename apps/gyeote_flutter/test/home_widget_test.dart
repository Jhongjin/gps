import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/core/location/home_widget_snapshot.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';

void main() {
  group('위젯 스냅샷은 위치를 담지 않는다', () {
    test('채널로 나가는 키에 좌표가 없다', () {
      // 위젯은 잠금화면에서 주머니에서 꺼낸 사람 누구에게나 보인다. 이 단언이
      // 깨지면 그 사람에게 가족의 위치가 보인다는 뜻이다.
      const snapshot = HomeWidgetSnapshot(
        circleName: '우리 가족',
        sharingCount: 4,
        attentionCount: 1,
        hasCircle: true,
        updatedAt: null,
        members: [
          HomeWidgetMember(
            name: '준',
            status: '균형 공유 중',
            tone: GyeoteTone.brand,
          ),
        ],
      );

      final payload = snapshot.toChannel();
      final flat = payload.toString();

      for (final forbidden in [
        'lat', 'lng', 'latitude', 'longitude', 'accuracy', 'point', 'coord',
      ]) {
        expect(
          flat.toLowerCase().contains(forbidden),
          isFalse,
          reason: '위젯 페이로드에 "$forbidden" 이 들어갔다',
        );
      }
    });

    test('멤버는 이름·상태·톤 세 가지만 보낸다', () {
      const member = HomeWidgetMember(
        name: '하나',
        status: '동네만 공유',
        tone: GyeoteTone.warm,
      );

      expect(member.toChannel().keys.toSet(), {'name', 'status', 'tone'});
    });
  });

  group('위젯 스냅샷', () {
    test('세 명까지만 보낸다', () {
      final snapshot = HomeWidgetSnapshot(
        circleName: 'c',
        sharingCount: 6,
        attentionCount: 0,
        hasCircle: true,
        updatedAt: null,
        members: List.generate(
          6,
          (i) => HomeWidgetMember(
            name: '멤버$i',
            status: 's',
            tone: GyeoteTone.brand,
          ),
        ),
      );

      final members = snapshot.toChannel()['members'] as List;
      expect(members, hasLength(HomeWidgetSnapshot.maxMembers));
    });

    test('갱신 시각을 함께 보낸다', () {
      // 위젯이 "몇 분 전"을 그리려면 이 값이 필요하다. 없으면 앱이 꺼진 채로
      // 시간이 흘러도 위젯이 계속 현재처럼 보인다.
      final at = DateTime(2026, 9, 6, 12, 0);
      final snapshot = HomeWidgetSnapshot(
        circleName: 'c',
        sharingCount: 1,
        attentionCount: 0,
        hasCircle: true,
        updatedAt: at,
        members: const [],
      );
      expect(
        snapshot.toChannel()['updatedAtMillis'],
        at.millisecondsSinceEpoch,
      );
    });

    test('갱신 시각을 안 주면 지금으로 채운다', () {
      const snapshot = HomeWidgetSnapshot(
        circleName: 'c',
        sharingCount: 1,
        attentionCount: 0,
        hasCircle: true,
        updatedAt: null,
        members: [],
      );
      final sent = snapshot.toChannel()['updatedAtMillis']! as int;
      expect(
        (DateTime.now().millisecondsSinceEpoch - sent).abs(),
        lessThan(5000),
      );
    });

    test('빈 스냅샷은 서클 없음을 뜻한다', () {
      const empty = HomeWidgetSnapshot.empty();
      expect(empty.hasCircle, isFalse);
      expect(empty.toChannel()['members'], isEmpty);
    });

    test('톤은 네이티브가 아는 세 값으로만 나간다', () {
      for (final tone in GyeoteTone.values) {
        final sent = HomeWidgetMember(name: 'n', status: 's', tone: tone)
            .toChannel()['tone'];
        expect(['brand', 'warm', 'alert'], contains(sent), reason: '$tone');
      }
    });
  });

  group('상태 톤', () {
    test('오래된 위치가 배터리보다 우선한다', () {
      // 둘 다 해당하면 더 근본적인 문제를 보여 준다. 배터리가 낮아서 갱신이
      // 늦는 것일 수도 있으므로, 늦다는 사실이 먼저다.
      expect(
        homeWidgetToneFor(isStale: true, hasLowBattery: true),
        GyeoteTone.warm,
      );
    });

    test('배터리 부족은 alert', () {
      expect(
        homeWidgetToneFor(isStale: false, hasLowBattery: true),
        GyeoteTone.alert,
      );
    });

    test('정상은 brand', () {
      expect(
        homeWidgetToneFor(isStale: false, hasLowBattery: false),
        GyeoteTone.brand,
      );
    });
  });
}
