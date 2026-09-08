import '../../theme/gyeote_theme.dart';

/// 홈 화면 위젯이 그릴 최소한의 상태.
///
/// 좌표 필드가 없다. 위젯은 잠금화면에서 누구에게나 보이므로 "누가 괜찮은지"
/// 까지만 보여 주고, 어디 있는지는 앱을 열어야 보인다. 필드를 두지 않는 것으로
/// 실수를 구조적으로 막는다.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.circleName,
    required this.sharingCount,
    required this.attentionCount,
    required this.members,
    required this.hasCircle,
    required this.updatedAt,
  });

  const HomeWidgetSnapshot.empty()
      : circleName = '',
        sharingCount = 0,
        attentionCount = 0,
        members = const [],
        hasCircle = false,
        updatedAt = null;

  final String circleName;
  final int sharingCount;
  final int attentionCount;
  final List<HomeWidgetMember> members;
  final bool hasCircle;

  /// 스냅샷을 만든 시각. 위젯이 "몇 분 전"을 그리는 데 쓴다. 없으면 네이티브가
  /// 받은 시각을 쓴다.
  final DateTime? updatedAt;

  /// 위젯에 세 줄만 들어간다. 더 보내도 그릴 자리가 없다.
  static const maxMembers = 3;

  Map<String, Object?> toChannel() => {
        'circleName': circleName,
        'sharingCount': sharingCount,
        'attentionCount': attentionCount,
        'hasCircle': hasCircle,
        'updatedAtMillis':
            (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'members': members
            .take(maxMembers)
            .map((member) => member.toChannel())
            .toList(growable: false),
      };
}

class HomeWidgetMember {
  const HomeWidgetMember({
    required this.name,
    required this.status,
    required this.tone,
  });

  final String name;

  /// 사람이 읽을 수 있는 상태 한 줄. 주소나 장소 이름은 넣지 않는다.
  final String status;
  final GyeoteTone tone;

  Map<String, Object?> toChannel() => {
        'name': name,
        'status': status,
        'tone': switch (tone) {
          GyeoteTone.alert => 'alert',
          GyeoteTone.warm => 'warm',
          _ => 'brand',
        },
      };
}

/// 체크인 상태를 위젯 톤으로 옮긴다.
GyeoteTone homeWidgetToneFor({
  required bool isStale,
  required bool hasLowBattery,
}) {
  if (isStale) return GyeoteTone.warm;
  if (hasLowBattery) return GyeoteTone.alert;
  return GyeoteTone.brand;
}
