import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';

/// 컴포넌트 테마의 글자 스타일이 번들 글꼴을 잃지 않는지 본다.
///
/// `styleFrom(textStyle:)` 은 테마 라벨 스타일을 **대체**한다. fontFamily 를
/// 빼면 그 컴포넌트의 글자만 기본 글꼴로 떨어지고, 웹(CanvasKit)은 그 대체
/// 글꼴 조각을 네트워크에서 받아 오다가 늦게 온 글자를 네모로 그린다 —
/// "새 링크"의 링, "참여"의 참이 그렇게 뚫렸다. Android 는 시스템 글꼴이
/// 대신 그려 줘서 눈치채지 못했다.
void main() {
  for (final (name, theme) in [
    ('light', buildGyeoteTheme()),
    ('dark', buildGyeoteDarkTheme()),
  ]) {
    group('$name 테마', () {
      test('테마 기본 글꼴은 Pretendard', () {
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Pretendard');
      });

      test('버튼 라벨이 글꼴을 잃지 않는다', () {
        for (final style in [
          theme.filledButtonTheme.style,
          theme.outlinedButtonTheme.style,
          theme.textButtonTheme.style,
        ]) {
          final text = style?.textStyle?.resolve(const {});
          expect(text?.fontFamily, 'Pretendard', reason: '$style');
        }
      });

      test('칩과 내비게이션 라벨이 글꼴을 잃지 않는다', () {
        expect(theme.chipTheme.labelStyle?.fontFamily, 'Pretendard');
        final nav = theme.navigationBarTheme.labelTextStyle?.resolve(const {});
        expect(nav?.fontFamily, 'Pretendard');
        final navSelected = theme.navigationBarTheme.labelTextStyle
            ?.resolve(const {WidgetState.selected});
        expect(navSelected?.fontFamily, 'Pretendard');
      });
    });
  }
}
