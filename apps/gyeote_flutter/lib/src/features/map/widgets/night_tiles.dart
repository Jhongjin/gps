import 'package:flutter/material.dart';

/// 밝은 지도 타일을 야간용으로 바꾼다.
///
/// 다크 테마를 켜 놓고 지도만 하얗게 남으면 화면 절반이 눈을 때린다. 그렇다고
/// 어두운 타일 프로바이더를 새로 붙이면 이용약관·키·출처 표기가 하나 더 늘고,
/// 나중에 Naver Maps 로 옮길 때 함께 버려진다.
///
/// 그래서 타일 자체는 그대로 두고 색만 바꾼다. 어떤 타일 소스에도 그대로
/// 적용되는 색 행렬 두 장이다 — 반전으로 밝기를 뒤집고, 채도를 눌러 지도를
/// 뒤로 물린다. 화면에서 채도를 가진 것은 마커·경로·반경뿐이어야 한다.
class NightTiles extends StatelessWidget {
  const NightTiles({super.key, required this.child});

  final Widget child;

  /// 색 반전.
  ///
  /// 밝은 배경이 어두워지고 흰 도로가 검게 된다.
  static const _invert = <double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ];

  /// 색상환 180도 회전 · 채도 22% · 감광 86% 를 하나로 합친 행렬.
  ///
  /// 반전만 하면 OSM 의 노란 간선도로가 형광 주황으로, 물이 형광 청록으로 튄다.
  /// 지도가 마커보다 시끄러워지고, 주황은 이 앱에서 배터리 주의를 뜻하는 색이라
  /// 의미까지 충돌한다.
  ///
  /// 그래서 세 단계를 거친다. 색상환을 되돌려 물은 다시 푸르게, 도로는 다시
  /// 누렇게 만들고 — 이 단계가 없으면 강이 갈색 땅처럼 보인다 — 그다음 채도를
  /// 22% 로 눌러 힌트만 남긴다. 화면에서 채도를 가진 것은 팔레트가 칠한
  /// 마커·경로·반경뿐이어야 한다.
  ///
  /// 세 행렬의 곱이라 필터는 두 장으로 끝난다. 타일 한 장마다 도는 연산이므로
  /// 한 번 곱해 두는 편이 낫다. 마지막 열의 오프셋이 캔버스의 따뜻한 먹색과
  /// 이어지도록 아주 약한 온기를 남긴다.
  static const _calm = <double>[
    0.034, 0.750, 0.076, 0, 4, //
    0.224, 0.561, 0.076, 0, 2, //
    0.224, 0.750, -0.114, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return child;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_calm),
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_invert),
        child: child,
      ),
    );
  }
}
