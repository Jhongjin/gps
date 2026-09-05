import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/gyeote_theme.dart';

/// 광고 슬롯.
///
/// 안전 액션보다 조용해야 한다. 브랜드색을 쓰지 않고 중성 면(`surfaceAlt`)과
/// `muted` 텍스트로만 그린다.
///
/// SOS, 권한, 동의, 프라이버시 저장, 지도, 온보딩에는 **절대** 배치하지 않는다.
/// 규칙은 `.claude/skills/gyeote-design/SKILL.md` §5.
class SafeAdSlot extends StatelessWidget {
  const SafeAdSlot({
    super.key,
    required this.placement,
  });

  final String placement;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Semantics(
      label: l10n.adSlotSemantics,
      child: Container(
        key: ValueKey('safe_ad_slot_$placement'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GyeoteRadius.card),
          color: palette.surfaceAlt,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GyeoteRadius.small),
                color: palette.surface,
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 20,
                // 광고에는 브랜드색을 쓰지 않는다.
                color: palette.muted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adSlotTitle,
                    style: TextStyle(
                      color: palette.inkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.adSlotBody,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const _AdPlacementBadge(),
          ],
        ),
      ),
    );
  }
}

class _AdPlacementBadge extends StatelessWidget {
  const _AdPlacementBadge();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GyeoteRadius.pill),
        color: palette.surface,
      ),
      child: Text(
        l10n.adSlotBadge,
        style: TextStyle(
          color: palette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
