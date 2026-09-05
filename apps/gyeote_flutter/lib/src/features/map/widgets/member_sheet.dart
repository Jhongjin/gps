import 'package:flutter/material.dart';

import '../../../core/location/location_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../theme/gyeote_theme.dart';
import '../map_models.dart';
import 'map_chrome.dart';

/// 멤버 상세 시트.
///
/// 마커·아바타 레일·목록 어디서 열어도 같은 시트다. 사람에서 행동으로 가는
/// 유일한 경로이므로 전화·깨우기·길찾기가 여기 모인다.
///
/// 하단의 "오늘 이 위치를 본 사람"이 곁에의 차별점을 매 순간 보여주는 자리다.
/// 안전 화면이므로 광고는 들어가지 않는다 (스킬 §5).
Future<void> showMemberSheet(
  BuildContext context, {
  required MapMemberTrack member,
  required VoidCallback onOpenViewerLog,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _MemberSheet(
      member: member,
      onOpenViewerLog: onOpenViewerLog,
    ),
  );
}

class _MemberSheet extends StatelessWidget {
  const _MemberSheet({required this.member, required this.onOpenViewerLog});

  final MapMemberTrack member;
  final VoidCallback onOpenViewerLog;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MemberAvatar(member: member, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      Text(
                        member.status(l10n),
                        style: TextStyle(fontSize: 13, color: palette.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatRow(member: member),
            const SizedBox(height: 12),
            const _ActionRow(),
            if (member.safetyNote(l10n) != null) ...[
              const SizedBox(height: 12),
              _NoteBanner(
                text: member.safetyNote(l10n)!,
                tone: memberStateTone(member),
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: palette.line, height: 1),
            const SizedBox(height: 16),
            _PrecisionBlock(member: member),
            const SizedBox(height: 16),
            Divider(color: palette.line, height: 1),
            const SizedBox(height: 12),
            _ViewerLogRow(onOpen: onOpenViewerLog),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.member});

  final MapMemberTrack member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final battery = member.batteryPercent;
    final accuracy = member.accuracyM;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: l10n.memberBattery,
            value: battery == null ? l10n.valueUnknown : '$battery%',
            tone: member.hasLowBattery ? GyeoteTone.alert : GyeoteTone.muted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: l10n.memberAccuracy,
            value: accuracy == null
                ? l10n.valueUnknown
                : '${accuracy.round()}m',
            tone: GyeoteTone.muted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: l10n.memberUpdated,
            value: _relativeLabel(l10n, member.recordedAt),
            tone: member.isStale ? GyeoteTone.warm : GyeoteTone.muted,
          ),
        ),
      ],
    );
  }
}

String _relativeLabel(AppL10n l10n, DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return l10n.relativeJustNow;
  if (diff.inMinutes < 60) return l10n.relativeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.relativeHours(diff.inHours);
  return l10n.relativeDays(diff.inDays);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final GyeoteTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(GyeoteRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: palette.muted)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: tone == GyeoteTone.muted
                  ? palette.ink
                  : tone.resolve(palette),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    // 실제 연결은 후속 작업이다. 지금은 경로만 만들어 둔다.
    return Row(
      children: [
        Expanded(
          child: _Action(icon: Icons.call_outlined, label: l10n.memberCall),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Action(
            icon: Icons.notifications_active_outlined,
            label: l10n.memberNudge,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Action(
            icon: Icons.directions_outlined,
            label: l10n.memberDirections,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.text, required this.tone});

  final String text;
  final GyeoteTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.resolveSoft(palette),
        borderRadius: BorderRadius.circular(GyeoteRadius.small),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: tone.resolve(palette)),
      ),
    );
  }
}

class _PrecisionBlock extends StatelessWidget {
  const _PrecisionBlock({required this.member});

  final MapMemberTrack member;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final labels = {
      SharingMode.precise: l10n.precisionPrecise,
      SharingMode.balanced: l10n.precisionBalanced,
      SharingMode.area: l10n.precisionArea,
      SharingMode.hidden: l10n.precisionHidden,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.memberPrecisionTitle(member.name),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in labels.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: member.sharingMode == entry.key,
                // 일방적으로 올릴 수 없다. 동의 우선 원칙의 UI 증거다.
                onSelected: null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.memberPrecisionConsent(member.name),
          style: TextStyle(fontSize: 11, color: palette.muted),
        ),
      ],
    );
  }
}

class _ViewerLogRow extends StatelessWidget {
  const _ViewerLogRow({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.viewerLogTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              Text(
                l10n.viewerLogSubtitle,
                style: TextStyle(fontSize: 11, color: palette.muted),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onOpen, child: Text(l10n.viewerLogOpen)),
      ],
    );
  }
}
