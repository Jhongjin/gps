import 'package:flutter/material.dart';

abstract final class GyeoteColors {
  static const canvas = Color(0xFFF4F6F1);
  static const surface = Color(0xFFFFFEFA);
  static const surfaceAlt = Color(0xFFE8EFE8);
  static const ink = Color(0xFF151C19);
  static const muted = Color(0xFF66736C);
  static const border = Color(0xFFD8E1D9);
  static const primary = Color(0xFF0F6A53);
  static const primarySoft = Color(0xFFDCEFE6);
  static const danger = Color(0xFFB83A33);
  static const dangerSoft = Color(0xFFFAE7E4);
  static const info = Color(0xFF315F8C);
  static const infoSoft = Color(0xFFE4EDF6);
  static const amber = Color(0xFFB87912);
  static const amberSoft = Color(0xFFFFF1CF);
}

ThemeData buildGyeoteTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: GyeoteColors.primary,
    brightness: Brightness.light,
    surface: GyeoteColors.surface,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: GyeoteColors.canvas,
    fontFamily: 'Geist',
    fontFamilyFallback: const [
      'Pretendard',
      'Apple SD Gothic Neo',
      'Malgun Gothic',
      'sans-serif',
    ],
    useMaterial3: true,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: GyeoteColors.surface,
      indicatorColor: GyeoteColors.primarySoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected) ? GyeoteColors.primary : GyeoteColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: GyeoteColors.primary,
        foregroundColor: GyeoteColors.surface,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GyeoteColors.primary,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: GyeoteColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
