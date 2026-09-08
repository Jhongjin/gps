import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/i18n/region_settings.dart';
import '../../../theme/gyeote_theme.dart';
import '../map_models.dart';
import '../movement.dart';

/// 도착 예상을 붙일 목적지. 지금은 약속 장소가 유일한 출처다.
class MapDestination {
  const MapDestination({required this.point, required this.name});

  final LatLng point;
  final String name;
}

/// "걷는 중 · 집결 장소까지 약 12분" 한 줄.
///
/// 오래된 위치에는 그리지 않는다. 20분 전 좌표로 "걷는 중"이라고 적으면 그건
/// 없는 현재를 만들어 내는 것이고, 이 앱에서 가장 하면 안 되는 종류의 거짓말이다.
class MovementLine extends StatelessWidget {
  const MovementLine({
    super.key,
    required this.member,
    this.destination,
    this.fontSize = 12,
  });

  final MapMemberTrack member;
  final MapDestination? destination;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final unit = RegionSettings.of(Localizations.localeOf(context)).distanceUnit;

    final text = describeMovement(
      l10n: l10n,
      unit: unit,
      member: member,
      destination: destination,
    );
    if (text == null) return const SizedBox.shrink();

    final movement = member.movement;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _iconFor(movement.state),
          size: fontSize + 3,
          color: palette.muted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: fontSize, color: palette.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// 그릴 것이 있는지. 호출부가 앞뒤 여백을 함께 넣거나 빼야 해서 필요하다.
bool hasMovementLine(
  BuildContext context, {
  required MapMemberTrack member,
  MapDestination? destination,
}) =>
    describeMovement(
      l10n: AppL10n.of(context),
      unit: RegionSettings.of(Localizations.localeOf(context)).distanceUnit,
      member: member,
      destination: destination,
    ) !=
    null;

/// 위젯 밖에서도 쓰고 테스트에서도 쓰려고 문구 생성을 따로 둔다.
///
/// 그릴 것이 없으면 null. 빈 문자열을 돌려주면 호출부가 빈 줄을 그린다.
String? describeMovement({
  required AppL10n l10n,
  required DistanceUnit unit,
  required MapMemberTrack member,
  MapDestination? destination,
}) {
  // 오래된 위치에서는 이동도 도착도 말하지 않는다. 그 상태는 safetyNote 가
  // 이미 "언제 것인지"로 설명하고 있다.
  if (member.isStale || member.isVeryStale) return null;

  final movement = member.movement;
  final parts = <String>[
    if (_stateLabel(l10n, movement.state) case final label?) label,
    if (destination case final target?)
      if (_destinationLabel(
        l10n: l10n,
        unit: unit,
        from: member.point,
        movement: movement,
        destination: target,
      )
          case final label?)
        label,
  ];

  return parts.isEmpty ? null : parts.join(' · ');
}

String? _stateLabel(AppL10n l10n, MovementState state) => switch (state) {
      // 표본이 모자란 것과 멈춰 있는 것은 다르다. 모르면 말하지 않는다.
      MovementState.unknown => null,
      MovementState.stopped => l10n.movementStopped,
      MovementState.walking => l10n.movementWalking,
      MovementState.riding => l10n.movementRiding,
      MovementState.driving => l10n.movementDriving,
    };

String? _destinationLabel({
  required AppL10n l10n,
  required DistanceUnit unit,
  required LatLng from,
  required MovementEstimate movement,
  required MapDestination destination,
}) {
  final straightM = distanceMeters(from, destination.point);
  if (straightM < 60) return l10n.etaNearby(destination.name);

  final eta = estimateEta(
    from: from,
    to: destination.point,
    movement: movement,
  );

  return switch (eta?.direction) {
    // 다가가는 중일 때만 분을 말한다. 멀어지거나 옆으로 가는 중에 남은 시간을
    // 적으면 그 숫자는 현재 경로와 무관한 값이 된다.
    ApproachDirection.approaching =>
      l10n.etaMinutesTo(destination.name, eta!.roundedMinutes),
    ApproachDirection.leaving => l10n.etaLeaving(destination.name),
    _ => l10n.etaDistanceTo(destination.name, unit.formatDistance(straightM)),
  };
}

IconData _iconFor(MovementState state) => switch (state) {
      MovementState.unknown => Icons.more_horiz,
      MovementState.stopped => Icons.place_outlined,
      MovementState.walking => Icons.directions_walk,
      MovementState.riding => Icons.directions_bike_outlined,
      MovementState.driving => Icons.directions_car_outlined,
    };
