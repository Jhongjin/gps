import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/gyeote_theme.dart';

/// 길게 눌러 무장하는 SOS 버튼.
///
/// 탭 한 번으로는 절대 발동하지 않는다. 누르고 있는 동안 링이 차오르고,
/// 다 차면 [onArmed]가 호출돼 취소 가능한 카운트다운으로 넘어간다.
/// 이 화면 계열에는 광고가 들어가지 않는다 (스킬 §5).
class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.onArmed,
    this.holdDuration = const Duration(milliseconds: 600),
  });

  final Future<void> Function() onArmed;
  final Duration holdDuration;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fire();
      }
    });

  bool _isBusy = false;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _fire() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    unawaited(HapticFeedback.heavyImpact());
    _hold.reset();
    try {
      await widget.onArmed();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Semantics(
      button: true,
      label: l10n.sosButtonSemantics,
      child: GestureDetector(
        onTapDown: (_) => _hold.forward(),
        onTapUp: (_) => _hold.reverse(),
        onTapCancel: () => _hold.reverse(),
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) {
            return SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(62),
                    painter: _HoldRingPainter(
                      progress: _hold.value,
                      color: palette.alert,
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.alert,
                      boxShadow: [
                        BoxShadow(
                          color: palette.alert.withValues(alpha: 0.42),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.sosLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  const _HoldRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.shortestSide / 2 - 2,
      ),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_HoldRingPainter old) =>
      old.progress != progress || old.color != color;
}

/// 발송 전 취소 유예. 손을 떼도 되돌릴 수 있어야 한다.
///
/// `true`를 반환하면 사용자가 전송을 확정한 것이다.
Future<bool> showSosCountdown(
  BuildContext context, {
  required String audienceLabel,
  int seconds = 3,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (context) => _SosCountdownSheet(
      audienceLabel: audienceLabel,
      seconds: seconds,
    ),
  );
  return result ?? false;
}

class _SosCountdownSheet extends StatefulWidget {
  const _SosCountdownSheet({
    required this.audienceLabel,
    required this.seconds,
  });

  final String audienceLabel;
  final int seconds;

  @override
  State<_SosCountdownSheet> createState() => _SosCountdownSheetState();
}

class _SosCountdownSheetState extends State<_SosCountdownSheet> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining -= 1);
      unawaited(HapticFeedback.heavyImpact());
      if (_remaining <= 0) {
        timer.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.sosArming,
              style: TextStyle(
                color: palette.alert,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 132,
              height: 132,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.alert,
                boxShadow: [
                  BoxShadow(
                    color: palette.alertSoft,
                    blurRadius: 0,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    l10n.sosSecondsRemaining,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.sosAudience(widget.audienceLabel),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sosNoAds,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.sosCancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.alert,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.sosSendNow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
