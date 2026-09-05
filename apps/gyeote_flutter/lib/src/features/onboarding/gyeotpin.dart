import 'package:flutter/material.dart';

import '../../theme/gyeote_theme.dart';

/// 마스코트 `곁핀`. 지도 핀과 방패를 겹친 형태다.
///
/// 스킬이 허용한 자리에만 쓴다 — 온보딩, 권한 사전 안내, 빈 서클, 경로 공유
/// 확인, 배터리·오래된 위치 힌트. SOS·긴급 카운트다운·권한 거부 오류·법적
/// 동의·데이터 삭제에는 **넣지 않는다.** 그 순간에 마스코트는 상황을 가볍게
/// 만든다.
///
/// 표정은 눈 두 점뿐이다. 웃기거나 놀란 얼굴을 주면 안전 제품이 장난감이 된다.
class Gyeotpin extends StatelessWidget {
  const Gyeotpin({super.key, this.size = 96, this.showSignal = false});

  final double size;

  /// 배터리·신호 힌트에서만 켠다. 평소에는 조용히 둔다.
  final bool showSignal;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GyeotpinPainter(
          body: palette.brand,
          bodyTop: palette.brandVivid,
          eye: palette.canvas,
          signal: showSignal ? palette.warm : null,
        ),
      ),
    );
  }
}

class _GyeotpinPainter extends CustomPainter {
  const _GyeotpinPainter({
    required this.body,
    required this.bodyTop,
    required this.eye,
    required this.signal,
  });

  final Color body;
  final Color bodyTop;
  final Color eye;
  final Color? signal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 핀 머리의 중심과 반지름. 아래 꼬리가 이 원에 접하도록 잡는다.
    final headR = w * 0.30;
    final headC = Offset(cx, h * 0.38);

    if (signal != null) {
      canvas.drawCircle(
        headC,
        headR * 1.42,
        Paint()..color = signal!.withValues(alpha: 0.22),
      );
    }

    // 핀 실루엣: 원 + 아래로 뾰족한 꼬리.
    final tail = Offset(cx, h * 0.92);
    final tangent = headR * 0.62;
    final path = Path()
      ..moveTo(cx - tangent, headC.dy + tangent)
      ..quadraticBezierTo(cx - headR * 0.30, h * 0.78, tail.dx, tail.dy)
      ..quadraticBezierTo(
          cx + headR * 0.30, h * 0.78, cx + tangent, headC.dy + tangent)
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bodyTop, body],
      ).createShader(Rect.fromCircle(center: headC, radius: headR * 1.6));

    canvas.drawPath(path, fill);
    canvas.drawCircle(headC, headR, fill);

    // 방패 노치. 핀 아래쪽을 살짝 깎아 방패 어깨처럼 보이게 한다.
    final notch = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawPath(path, fill);
    canvas.drawCircle(headC, headR, fill);
    canvas.drawCircle(Offset(cx, h * 0.995), headR * 0.42, notch);
    canvas.restore();

    // 눈 두 점. 이게 표정의 전부다.
    final eyePaint = Paint()..color = eye;
    final eyeR = headR * 0.115;
    final eyeY = headC.dy - headR * 0.04;
    canvas.drawCircle(Offset(cx - headR * 0.34, eyeY), eyeR, eyePaint);
    canvas.drawCircle(Offset(cx + headR * 0.34, eyeY), eyeR, eyePaint);

    // 체크 디테일. 얼굴 한가운데 두면 입처럼 읽혀 표정이 생긴다 — 스킬이
    // 금지한 것이다. 오른쪽 아래 배지 자리로 내리고 크기도 줄인다.
    final badgeC = Offset(cx + headR * 0.66, headC.dy + headR * 0.66);
    canvas.drawCircle(badgeC, headR * 0.30, Paint()..color = body);
    canvas.drawCircle(
      badgeC,
      headR * 0.30,
      Paint()
        ..color = eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = headR * 0.07,
    );
    final check = Paint()
      ..color = eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final ck = headR * 0.15;
    canvas.drawPath(
      Path()
        ..moveTo(badgeC.dx - ck, badgeC.dy)
        ..lineTo(badgeC.dx - ck * 0.2, badgeC.dy + ck * 0.8)
        ..lineTo(badgeC.dx + ck, badgeC.dy - ck * 0.8),
      check,
    );
  }

  @override
  bool shouldRepaint(_GyeotpinPainter old) =>
      old.body != body || old.eye != eye || old.signal != signal;
}
