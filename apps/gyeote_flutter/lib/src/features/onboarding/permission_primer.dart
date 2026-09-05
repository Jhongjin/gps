import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/gyeote_theme.dart';
import 'gyeotpin.dart';

/// 어떤 권한을 왜 묻는지.
enum PermissionPurpose {
  /// 동행 모드에서 지도에 내 위치를 그리기 위해.
  whileUsing,

  /// 앱이 꺼져 있어도 장소 알림을 확인하기 위해.
  background,
}

/// OS 권한 대화상자를 띄우기 전에 이유를 먼저 말한다.
///
/// 권한 대화상자는 대부분의 플랫폼에서 **한 번뿐**이다. 아무 설명 없이 띄웠다가
/// 거절당하면 그 기능은 설정 앱에 들어가야만 되살아나고, 대부분은 들어가지
/// 않는다. 특히 백그라운드 위치는 냉정하게 물으면 거의 거절당한다.
///
/// 그래서 사용자가 [PermissionPurpose] 에 해당하는 행동을 한 직후에만, 그
/// 행동과 이어서 설명한다. `false` 를 받으면 OS API 를 아예 호출하지 않는다.
/// 물어보지 않으면 기회가 남는다.
///
/// SOS 에는 쓰지 않는다. 긴급한 사람에게 시트를 읽히면 안 된다 — 그래서 위치
/// 권한을 온보딩에서 미리 받아 두는 것이 중요하다.
Future<bool> showPermissionPrimer(
  BuildContext context, {
  required PermissionPurpose purpose,
}) async {
  final granted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _PermissionPrimerSheet(purpose: purpose),
  );
  return granted ?? false;
}

class _PermissionPrimerSheet extends StatelessWidget {
  const _PermissionPrimerSheet({required this.purpose});

  final PermissionPurpose purpose;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    final (String title, String body) = switch (purpose) {
      PermissionPurpose.whileUsing => (
          l10n.primerWhenInUseTitle,
          l10n.primerWhenInUseBody,
        ),
      PermissionPurpose.background => (
          l10n.primerAlwaysTitle,
          l10n.primerAlwaysBody,
        ),
    };

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Gyeotpin(size: 72)),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(fontSize: 14, color: palette.inkMuted),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.brandSoft,
                borderRadius: BorderRadius.circular(GyeoteRadius.small),
              ),
              child: Text(
                l10n.primerPromise,
                style: TextStyle(fontSize: 12.5, color: palette.brand),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    // 거절도 값싸야 한다. 여기서 물러나면 OS 대화상자는
                    // 뜨지 않으므로 나중에 다시 물어볼 수 있다.
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.primerLater),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.primerContinue),
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
