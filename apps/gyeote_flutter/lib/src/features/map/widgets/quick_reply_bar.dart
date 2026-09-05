import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/backend/backend_contract.dart';
import '../../../theme/gyeote_theme.dart';

/// 한 번 눌러 서클에 보내는 짧은 말 네 가지.
///
/// 이게 없으면 가족의 위치가 52분째 갱신되지 않아도 앱 안에서 할 수 있는 일이
/// 없다. 사용자는 메신저로 나가고, 나간 뒤에는 돌아오지 않는다.
///
/// 좌표를 담지 않는다. 위치를 더 보내는 기능이 아니라, 위치를 덜 물어보게
/// 만드는 기능이다.
class QuickReplyBar extends StatelessWidget {
  const QuickReplyBar({
    super.key,
    required this.onSend,
    required this.isEnabled,
    this.sending,
  });

  final ValueChanged<CheckInStatus> onSend;
  final bool isEnabled;

  /// 지금 보내는 중인 값. 하나가 나가는 동안 나머지도 잠근다.
  final CheckInStatus? sending;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final busy = sending != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickReplyTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 8),
        // 큰 글자나 긴 로케일에서 네 개가 한 줄에 안 들어가면 접힌다.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in CheckInStatus.quickReplies)
              _QuickReplyChip(
                label: status.label(l10n),
                tone: _toneFor(status),
                isSending: sending == status,
                onTap: isEnabled && !busy ? () => onSend(status) : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// 도착만 브랜드색을 쓴다. 넷을 다 물들이면 무엇이 좋은 소식인지 흐려진다.
/// '전화해줘'는 요청이지 경보가 아니므로 alert 를 쓰지 않는다.
GyeoteTone _toneFor(CheckInStatus status) => switch (status) {
      CheckInStatus.safeArrived => GyeoteTone.brand,
      CheckInStatus.onTheWay => GyeoteTone.move,
      CheckInStatus.callMe => GyeoteTone.warm,
      _ => GyeoteTone.muted,
    };

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({
    required this.label,
    required this.tone,
    required this.isSending,
    required this.onTap,
  });

  final String label;
  final GyeoteTone tone;
  final bool isSending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onTap != null;
    final accent = tone.resolve(palette);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: enabled ? tone.resolveSoft(palette) : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(GyeoteRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GyeoteRadius.pill),
          child: ConstrainedBox(
            // 탭 타깃은 44px 아래로 내려가지 않는다.
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSending) ...[
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: enabled ? accent : palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
