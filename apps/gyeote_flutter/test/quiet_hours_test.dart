import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/l10n/app_localizations.dart';
import 'package:gyeote/src/core/backend/backend_contract.dart';
import 'package:gyeote/src/features/circle/circle_screen.dart';

/// 조용한 시간 프리셋 순환이 언어와 무관한지 본다.
///
/// 예전에는 저장된 라벨("야간")을 현재 로케일 번역과 비교했다. 한국어 사용자가
/// 만든 알림을 영어 멤버가 순환시키면 어떤 프리셋과도 일치하지 않아 항상 첫
/// 프리셋으로 되돌아갔다. 판단은 키로, 표시는 로케일로.
void main() {
  test('없음 → 야간 → 수업/근무 → 없음 으로 돈다', () {
    var current = const PlaceAlertQuietHours.none();
    final seen = <QuietHoursPreset?>[];
    for (var i = 0; i < 3; i++) {
      current = nextPlaceAlertQuietHours(current);
      seen.add(current.enabled ? current.preset : null);
    }
    expect(seen, [
      QuietHoursPreset.night,
      QuietHoursPreset.classOrWork,
      null,
    ]);
  });

  test('저장 형식에 라벨도 시간대도 없다', () {
    // 라벨은 로케일 산물이고, 'Asia/Seoul' 은 기기가 어디 있든 적히던 거짓
    // 값이었다. 둘 다 저장하지 않는다.
    final json = PlaceAlertQuietHours.preset(QuietHoursPreset.night).toJson();
    expect(json.keys.toSet(), {'enabled', 'start', 'end', 'preset'});
    expect(json['preset'], 'night');
  });

  test('라벨만 있는 옛 행은 시각으로 프리셋을 되찾는다', () {
    // 키가 없으면 라벨이 아니라 시각을 본다. 시각은 로케일과 무관한 사실이다.
    expect(
      QuietHoursPreset.fromTimes('22:00', '07:00'),
      QuietHoursPreset.night,
    );
    expect(
      QuietHoursPreset.fromTimes('09:00', '17:00'),
      QuietHoursPreset.classOrWork,
    );
    expect(QuietHoursPreset.fromTimes('01:00', '02:00'), isNull);
  });

  test('요약 라벨은 저장값이 아니라 현재 로케일에서 나온다', () async {
    final ko = await AppL10n.delegate.load(const Locale('ko'));
    final en = await AppL10n.delegate.load(const Locale('en'));
    final night = PlaceAlertQuietHours.preset(QuietHoursPreset.night);

    expect(night.summary(ko), startsWith(ko.quietHoursNight));
    expect(night.summary(en), startsWith(en.quietHoursNight));
    expect(ko.quietHoursNight, isNot(en.quietHoursNight));
  });
}
