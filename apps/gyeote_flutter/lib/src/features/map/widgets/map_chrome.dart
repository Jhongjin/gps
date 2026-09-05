import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/location/location_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../theme/gyeote_theme.dart';
import '../map_models.dart';

/// 마커 링이 나르는 상태. 신원은 [MapMemberTrack.tone]이 따로 담당한다.
GyeoteTone memberStateTone(MapMemberTrack member) {
  if (member.isStale) return GyeoteTone.warm;
  if (member.hasLowBattery) return GyeoteTone.alert;
  return GyeoteTone.brand;
}

/// 지도 위 요소는 구형 음영을 허용한다. 없으면 타일에 묻힌다.
BoxDecoration _avatarDecoration(GyeotePalette palette, GyeoteTone tone) {
  final base = tone.resolve(palette);
  return BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(base, Colors.white, 0.22)!, base],
    ),
    boxShadow: [
      BoxShadow(
        color: base.withValues(alpha: 0.38),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

Color _onToneText(Color tone) {
  return ThemeData.estimateBrightnessForColor(tone) == Brightness.dark
      ? Colors.white
      : const Color(0xFF10231C);
}

/// 아바타 + 상태 링.
///
/// 링 하나가 세 가지를 말한다 — 채워진 정도는 배터리, 스타일은 공유 정확도
/// (실선 = 정확·균형, 점선 = 동네만), 색은 상태.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 40,
    this.showRing = true,
    this.isSelected = false,
  });

  final MapMemberTrack member;
  final double size;
  final bool showRing;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ringSize = size + 12;

    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: _avatarDecoration(palette, member.tone),
      child: Text(
        member.name.characters.first,
        style: TextStyle(
          color: _onToneText(member.tone.resolve(palette)),
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );

    if (!showRing) return avatar;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(ringSize),
            painter: _StateRingPainter(
              trackColor: palette.line,
              ringColor: memberStateTone(member).resolve(palette),
              // 배터리를 모르면 링을 꽉 채운다. 빈 링으로 오해되면 안 된다.
              fill: (member.batteryPercent ?? 100).clamp(0, 100) / 100,
              dashed: member.sharingMode == SharingMode.area,
              emphasized: isSelected,
            ),
          ),
          avatar,
        ],
      ),
    );
  }
}

class _StateRingPainter extends CustomPainter {
  const _StateRingPainter({
    required this.trackColor,
    required this.ringColor,
    required this.fill,
    required this.dashed,
    required this.emphasized,
  });

  final Color trackColor;
  final Color ringColor;
  final double fill;
  final bool dashed;
  final bool emphasized;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = emphasized ? 3.5 : 2.6;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = ringColor;

    if (dashed) {
      // 동네만 공유는 점선. 정확한 지점이 아니라는 신호다.
      const dash = 0.20;
      const gap = 0.12;
      double start = -math.pi / 2;
      final end = start + 2 * math.pi;
      while (start < end) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          math.min(dash, end - start),
          false,
          active,
        );
        start += dash + gap;
      }
      return;
    }

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fill.clamp(0.0, 1.0),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(_StateRingPainter old) =>
      old.fill != fill ||
      old.ringColor != ringColor ||
      old.dashed != dashed ||
      old.trackColor != trackColor ||
      old.emphasized != emphasized;
}

/// 지도 위 마커. 이름 라벨은 선택된 멤버에만 띄운다.
class MemberMarker extends StatelessWidget {
  const MemberMarker({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final MapMemberTrack member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      label: '${member.name}. ${member.status(AppL10n.of(context))}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MemberAvatar(member: member, isSelected: isSelected),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(GyeoteRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 지도 위 떠 있는 원형 버튼.
class MapIconButton extends StatelessWidget {
  const MapIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.surface,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: palette.ink),
          ),
        ),
      ),
    );
  }
}

/// 좌상단 서클 칩.
class MapCircleChip extends StatelessWidget {
  const MapCircleChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(GyeoteRadius.pill),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GyeoteRadius.pill),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: palette.ink,
                  ),
                ),
              ),
              Icon(Icons.expand_more, size: 18, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// 지도 상단 아바타 레일. 탭하면 해당 멤버로 이동한다.
class MemberAvatarRail extends StatelessWidget {
  const MemberAvatarRail({
    super.key,
    required this.members,
    required this.selectedId,
    required this.onSelect,
    required this.onInvite,
  });

  final List<MapMemberTrack> members;
  final String? selectedId;
  final ValueChanged<MapMemberTrack> onSelect;
  final VoidCallback onInvite;

  /// 아바타 지름 + 상태 링.
  static const _entrySize = 50.0;
  static const _labelSize = 11.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // 높이를 고정하면 OS 글자 크기를 키웠을 때 라벨이 잘린다.
    // 아바타는 그대로 두고 라벨이 필요한 만큼만 자라게 한다.
    final labelHeight =
        MediaQuery.textScalerOf(context).scale(_labelSize) * 1.45;

    return SizedBox(
      height: _entrySize + 4 + labelHeight + 8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final member in members)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _RailEntry(
                label: member.isCurrentUser
                    ? AppL10n.of(context).mapMeShort
                    : member.name,
                isSelected: member.id == selectedId,
                onTap: () => onSelect(member),
                avatar: MemberAvatar(
                  member: member,
                  size: 38,
                  isSelected: member.id == selectedId,
                ),
              ),
            ),
          _RailEntry(
            label: AppL10n.of(context).mapInvite,
            isSelected: false,
            onTap: onInvite,
            avatar: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: palette.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  const _RailEntry({
    required this.label,
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Widget avatar;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GyeoteRadius.card),
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(GyeoteRadius.pill),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? palette.brand : palette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 지도 출처 표기.
///
/// flutter_map 의 `SimpleAttributionWidget` 은 내부 Row 가 고정 폭이라 360px
/// 기기에서 245px 넘쳐 나간다. 표기 자체는 ODbL 상 빼면 안 되므로, 좁은 화면과
/// 큰 글자에서도 버티는 형태로 직접 그린다.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(GyeoteRadius.pill),
        ),
        child: Text(
          '© OpenStreetMap',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9, color: palette.muted),
        ),
      ),
    );
  }
}
