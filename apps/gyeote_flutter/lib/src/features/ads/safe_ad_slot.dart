import 'package:flutter/material.dart';

import '../../theme/gyeote_theme.dart';

class SafeAdSlot extends StatelessWidget {
  const SafeAdSlot({
    super.key,
    required this.placement,
  });

  final String placement;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '스폰서 영역',
      child: Container(
        key: ValueKey('safe_ad_slot_$placement'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: GyeoteColors.border),
          borderRadius: BorderRadius.circular(8),
          color: GyeoteColors.surfaceAlt,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: GyeoteColors.surface,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: GyeoteColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('스폰서', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text(
                    '위치 데이터와 분리된 광고 영역',
                    style: TextStyle(color: GyeoteColors.muted, fontSize: 12),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(6),
        color: GyeoteColors.surface,
      ),
      child: const Text(
        '테스트',
        style: TextStyle(
          color: GyeoteColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
