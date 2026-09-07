import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';

/// 글자색 × 바닥색 대비를 잰다. WCAG 본문 기준 4.5:1.
///
/// 디자인 스킬 §6 은 "muted on surfaceAlt 는 반드시 측정"이라고 적어 두었는데,
/// 적어 두기만 했다. 재 보니 라이트 모드의 `muted`·`warm`·`brand`·`alert` 가
/// 자기 바닥 위에서 3.2~4.1 이었다. 63곳의 캡션이 기준 미달로 그려지고 있었다.
/// 토큰을 바꾸면 이 파일이 먼저 말한다.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, palette) in [
    ('light', GyeotePalette.light),
    ('dark', GyeotePalette.dark),
  ]) {
    group('$name 대비', () {
      final grounds = {
        'canvas': palette.canvas,
        'surface': palette.surface,
        'surfaceAlt': palette.surfaceAlt,
      };
      final texts = {
        'ink': palette.ink,
        'inkMuted': palette.inkMuted,
        'muted': palette.muted,
        'brand': palette.brand,
        'warm': palette.warm,
        'move': palette.move,
        'alert': palette.alert,
      };
      // 배지·칩: 상태색 글자가 자기 soft 바닥 위에 놓인다.
      final softPairs = {
        'brand on brandSoft': (palette.brand, palette.brandSoft),
        'warm on warmSoft': (palette.warm, palette.warmSoft),
        'move on moveSoft': (palette.move, palette.moveSoft),
        'alert on alertSoft': (palette.alert, palette.alertSoft),
      };

      for (final text in texts.entries) {
        for (final ground in grounds.entries) {
          test('${text.key} on ${ground.key} ≥ 4.5', () {
            expect(
              _contrast(text.value, ground.value),
              greaterThanOrEqualTo(4.5),
            );
          });
        }
      }
      for (final pair in softPairs.entries) {
        test('${pair.key} ≥ 4.5', () {
          expect(
            _contrast(pair.value.$1, pair.value.$2),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    });
  }
}
