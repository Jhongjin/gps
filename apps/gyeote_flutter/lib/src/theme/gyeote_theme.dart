import 'package:flutter/material.dart';

/// 곁에 디자인 시스템 "귀갓길".
///
/// 기준 모드는 다크다. 이 앱의 피크 사용 시간은 밤이고, 지도는 어두운 배경에서
/// 마커와 경로가 더 잘 읽힌다. 라이트도 동등하게 완성한다.
///
/// 규칙은 `.claude/skills/gyeote-design/SKILL.md`에 있다.
@immutable
class GyeotePalette extends ThemeExtension<GyeotePalette> {
  const GyeotePalette({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkMuted,
    required this.muted,
    required this.line,
    required this.brand,
    required this.brandVivid,
    required this.brandSoft,
    required this.warm,
    required this.warmSoft,
    required this.move,
    required this.moveSoft,
    required this.alert,
    required this.alertSoft,
    required this.mapLand,
    required this.mapRoad,
    required this.mapWater,
    required this.mapPark,
  });

  /// 화면 바닥.
  final Color canvas;

  /// 카드·시트.
  final Color surface;

  /// 눌린 면, 보조 칩, 광고 슬롯.
  final Color surfaceAlt;

  /// 본문.
  final Color ink;

  /// 보조 본문.
  final Color inkMuted;

  /// 메타·캡션.
  final Color muted;

  /// 구분선. 계층을 만드는 데 쓰지 않는다.
  final Color line;

  /// 주 액션, 정상 상태.
  final Color brand;

  /// 마커 그라디언트 상단.
  final Color brandVivid;

  /// 선택된 배경.
  final Color brandSoft;

  /// 도착·온기·배터리 주의. 경고 전용이 아니다.
  final Color warm;
  final Color warmSoft;

  /// 이동 중, 경로 꼬리.
  final Color move;
  final Color moveSoft;

  /// SOS, 확인 필요, 파괴적 행동.
  final Color alert;
  final Color alertSoft;

  final Color mapLand;
  final Color mapRoad;
  final Color mapWater;
  final Color mapPark;

  static const light = GyeotePalette(
    canvas: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2EDE4),
    ink: Color(0xFF191512),
    inkMuted: Color(0xFF4C443B),
    muted: Color(0xFF877D71),
    line: Color(0x1A191512),
    brand: Color(0xFF00825C),
    brandVivid: Color(0xFF00A374),
    brandSoft: Color(0xFFDDF2EA),
    warm: Color(0xFFBE7411),
    warmSoft: Color(0xFFFCEFD5),
    move: Color(0xFF2C6BA4),
    moveSoft: Color(0xFFE2EDF7),
    alert: Color(0xFFC03D2C),
    alertSoft: Color(0xFFFBE7E2),
    mapLand: Color(0xFFEAE4D8),
    mapRoad: Color(0xFFFFFFFF),
    mapWater: Color(0xFFD7E4EA),
    mapPark: Color(0xFFDCE7D3),
  );

  static const dark = GyeotePalette(
    canvas: Color(0xFF141210),
    surface: Color(0xFF1D1A16),
    surfaceAlt: Color(0xFF29251F),
    ink: Color(0xFFF6F1E9),
    inkMuted: Color(0xFFC7BEB2),
    muted: Color(0xFF968C80),
    line: Color(0x1CF6F1E9),
    brand: Color(0xFF3ED9A4),
    brandVivid: Color(0xFF4FE7B2),
    brandSoft: Color(0xFF113429),
    warm: Color(0xFFEFB055),
    warmSoft: Color(0xFF362810),
    move: Color(0xFF7FB4E6),
    moveSoft: Color(0xFF16283A),
    alert: Color(0xFFF08574),
    alertSoft: Color(0xFF3B2019),
    mapLand: Color(0xFF201D18),
    mapRoad: Color(0xFF2E2922),
    mapWater: Color(0xFF17242C),
    mapPark: Color(0xFF1E2A1E),
  );

  @override
  GyeotePalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? inkMuted,
    Color? muted,
    Color? line,
    Color? brand,
    Color? brandVivid,
    Color? brandSoft,
    Color? warm,
    Color? warmSoft,
    Color? move,
    Color? moveSoft,
    Color? alert,
    Color? alertSoft,
    Color? mapLand,
    Color? mapRoad,
    Color? mapWater,
    Color? mapPark,
  }) {
    return GyeotePalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      brand: brand ?? this.brand,
      brandVivid: brandVivid ?? this.brandVivid,
      brandSoft: brandSoft ?? this.brandSoft,
      warm: warm ?? this.warm,
      warmSoft: warmSoft ?? this.warmSoft,
      move: move ?? this.move,
      moveSoft: moveSoft ?? this.moveSoft,
      alert: alert ?? this.alert,
      alertSoft: alertSoft ?? this.alertSoft,
      mapLand: mapLand ?? this.mapLand,
      mapRoad: mapRoad ?? this.mapRoad,
      mapWater: mapWater ?? this.mapWater,
      mapPark: mapPark ?? this.mapPark,
    );
  }

  @override
  GyeotePalette lerp(ThemeExtension<GyeotePalette>? other, double t) {
    if (other is! GyeotePalette) {
      return this;
    }

    return GyeotePalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandVivid: Color.lerp(brandVivid, other.brandVivid, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      warm: Color.lerp(warm, other.warm, t)!,
      warmSoft: Color.lerp(warmSoft, other.warmSoft, t)!,
      move: Color.lerp(move, other.move, t)!,
      moveSoft: Color.lerp(moveSoft, other.moveSoft, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      alertSoft: Color.lerp(alertSoft, other.alertSoft, t)!,
      mapLand: Color.lerp(mapLand, other.mapLand, t)!,
      mapRoad: Color.lerp(mapRoad, other.mapRoad, t)!,
      mapWater: Color.lerp(mapWater, other.mapWater, t)!,
      mapPark: Color.lerp(mapPark, other.mapPark, t)!,
    );
  }
}

extension GyeotePaletteX on BuildContext {
  /// 테마를 따르는 색 팔레트. 위젯의 모든 색은 여기서 온다.
  ///
  /// `const` 생성자 안에서는 쓸 수 없으므로, 이 값을 참조하는 위젯은 `const`를
  /// 걷어내야 한다. 모델에 `Color`를 담아 우회하지 말 것 — 그러면 그 화면이
  /// 한 테마에 묶인다. 모델은 [GyeoteTone]을 담는다.
  ///
  /// 테마에 확장이 없는 경우(테스트의 맨 Theme 등)에는 현재 밝기를 따른다.
  GyeotePalette get palette {
    final theme = Theme.of(this);
    return theme.extension<GyeotePalette>() ??
        (theme.brightness == Brightness.dark
            ? GyeotePalette.dark
            : GyeotePalette.light);
  }
}

/// 모델이 [Color]를 들지 않게 하는 의미 토큰.
///
/// 색은 테마에 따라 달라져야 하므로 모델은 역할만 들고, 실제 [Color]는 그릴 때
/// [resolve]로 푼다. 모델에 `Color`를 박으면 그 화면은 영원히 한 테마에 묶인다.
enum GyeoteTone {
  /// 주 액션, 정상 상태.
  brand,

  /// 이동 중.
  move,

  /// 도착·온기·주의.
  warm,

  /// 확인 필요, 파괴적 행동.
  alert,

  /// 중립.
  muted;

  Color resolve(GyeotePalette palette) => switch (this) {
        GyeoteTone.brand => palette.brand,
        GyeoteTone.move => palette.move,
        GyeoteTone.warm => palette.warm,
        GyeoteTone.alert => palette.alert,
        GyeoteTone.muted => palette.muted,
      };

  /// 같은 역할의 배경용 약한 면.
  Color resolveSoft(GyeotePalette palette) => switch (this) {
        GyeoteTone.brand => palette.brandSoft,
        GyeoteTone.move => palette.moveSoft,
        GyeoteTone.warm => palette.warmSoft,
        GyeoteTone.alert => palette.alertSoft,
        GyeoteTone.muted => palette.surfaceAlt,
      };
}

/// 형태 토큰. 라디우스 8px 상한은 폐기됐다.
abstract final class GyeoteRadius {
  /// 시트.
  static const sheet = 28.0;

  /// 카드.
  static const card = 16.0;

  /// 작은 면.
  static const small = 10.0;

  /// 칩·버튼·아바타.
  static const pill = 999.0;
}

/// 최소 탭 타깃.
const kGyeoteMinTapTarget = Size(44, 44);

ThemeData _buildTheme(GyeotePalette palette, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.brand,
    brightness: brightness,
    surface: palette.surface,
    onSurface: palette.ink,
    error: palette.alert,
  );

  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: palette.canvas,
    canvasColor: palette.canvas,
    dividerColor: palette.line,
    // 한글과 라틴을 한 패밀리로 그린다. 두 패밀리를 섞으면 `배터리 46%` 처럼
    // 한 줄에서 문자가 섞일 때 x-height 와 베이스라인이 어긋난다.
    // ja/hi/ar 을 열 때는 해당 문자용 Noto 서브셋을 담아 fallback 에 잇는다.
    fontFamily: 'Pretendard',
    useMaterial3: true,
    extensions: [palette],
    dividerTheme: DividerThemeData(color: palette.line, space: 1, thickness: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.brandSoft,
      // 보더 대신 면으로 계층을 만든다.
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? palette.brand
              : palette.muted,
          fontSize: 12,
          // 굵기는 700까지만.
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.brand,
        foregroundColor: palette.surface,
        minimumSize: kGyeoteMinTapTarget,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        backgroundColor: palette.surfaceAlt,
        minimumSize: kGyeoteMinTapTarget,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.brand,
        minimumSize: kGyeoteMinTapTarget,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    // cardTheme은 두지 않는다. Material Card 위젯을 쓰는 곳이 없고,
    // CardTheme/CardThemeData 타입이 Flutter 버전에 따라 달라 위험하다.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GyeoteRadius.sheet),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceAlt,
      selectedColor: palette.brandSoft,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: palette.ink,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
  );
}

/// 라이트 테마.
ThemeData buildGyeoteTheme() => _buildTheme(GyeotePalette.light, Brightness.light);

/// 다크 테마. 귀갓길의 기준 모드다.
ThemeData buildGyeoteDarkTheme() =>
    _buildTheme(GyeotePalette.dark, Brightness.dark);
