import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/backend/backend_contract.dart';
import '../../../theme/gyeote_theme.dart';
import '../map_models.dart';
import '../movement.dart';

/// 시트 안의 약속 카드.
///
/// 약속은 사람이 끄는 물건이 아니라 시각이 지나면 스스로 끝나는 물건이다.
/// 그래서 "언제 사라지는지"를 카드에 적어 둔다 — 끄는 걸 잊어도 된다는 사실이
/// 보여야 안심하고 쓴다.
class MeetupCard extends StatelessWidget {
  const MeetupCard({
    super.key,
    required this.meetup,
    required this.onRespond,
    required this.onEnd,
    required this.isCreator,
    this.isBusy = false,
    this.me,
  });

  final Meetup meetup;
  final ValueChanged<MeetupResponse> onRespond;
  final VoidCallback onEnd;
  final bool isCreator;
  final bool isBusy;

  /// 내 위치. 있으면 내 도착 예상을 적는다. 다른 사람 것은 여기 적지 않는다 —
  /// 카드 한 장에 서너 명의 남은 시간을 늘어놓으면 그건 관제 화면이 된다.
  final MapMemberTrack? me;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(GyeoteRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag_outlined, size: 18, color: palette.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meetup.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    if (meetup.placeName case final place?
                        when place.isNotEmpty)
                      Text(
                        place,
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                  ],
                ),
              ),
              _CountdownChip(meetup: meetup),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.meetupGoingCount(meetup.goingCount, meetup.attendeeCount),
            style: TextStyle(fontSize: 12, color: palette.inkMuted),
          ),
          if (_myEtaMinutes() case final minutes?) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.schedule, size: 13, color: palette.brand),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    l10n.etaMineMinutes(minutes),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              // 라우팅이 아니라 직선거리 추정이다. 그 사실을 숨기면 사용자는
              // 이 숫자를 내비게이션처럼 믿게 된다.
              l10n.etaEstimateNote,
              style: TextStyle(fontSize: 10, color: palette.muted),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            // 스스로 끝난다는 사실이 이 기능의 전부다. 눈에 보이게 적는다.
            l10n.meetupAutoEnds(meetup.graceMinutes),
            style: TextStyle(fontSize: 11, color: palette.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in const {
                MeetupResponse.going: GyeoteTone.brand,
                MeetupResponse.maybe: GyeoteTone.muted,
                MeetupResponse.declined: GyeoteTone.muted,
              }.entries)
                _ResponseChip(
                  label: _responseLabel(l10n, entry.key),
                  tone: entry.value,
                  isSelected: meetup.myResponse == entry.key,
                  onTap: isBusy ? null : () => onRespond(entry.key),
                ),
              if (isCreator)
                _ResponseChip(
                  label: l10n.meetupEnd,
                  tone: GyeoteTone.alert,
                  isSelected: false,
                  onTap: isBusy ? null : onEnd,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 내 도착까지 남은 분. 추정할 수 없으면 null 이고, 그러면 줄 자체가 없다.
  int? _myEtaMinutes() {
    final track = me;
    if (track == null || track.isStale || track.isVeryStale) return null;

    return estimateEta(
      from: track.point,
      to: LatLng(meetup.placeLat, meetup.placeLng),
      movement: track.movement,
    )?.roundedMinutes;
  }
}

String _responseLabel(AppL10n l10n, MeetupResponse response) =>
    switch (response) {
      MeetupResponse.going => l10n.meetupGoing,
      MeetupResponse.maybe => l10n.meetupMaybe,
      MeetupResponse.declined => l10n.meetupDeclined,
      MeetupResponse.invited => l10n.meetupGoing,
    };

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final until = meetup.timeUntil;
    final isPast = until.isNegative;
    final span = until.abs();

    final label = span.inHours >= 1
        ? l10n.relativeHours(span.inHours)
        : l10n.relativeMinutes(span.inMinutes);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPast ? palette.warmSoft : palette.brandSoft,
        borderRadius: BorderRadius.circular(GyeoteRadius.pill),
      ),
      child: Text(
        isPast ? l10n.meetupStartedAgo(label) : l10n.meetupStartsIn(label),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPast ? palette.warm : palette.brand,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ResponseChip extends StatelessWidget {
  const _ResponseChip({
    required this.label,
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final GyeoteTone tone;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = tone.resolve(palette);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isSelected ? tone.resolveSoft(palette) : palette.surface,
        borderRadius: BorderRadius.circular(GyeoteRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GyeoteRadius.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(Icons.check, size: 14, color: accent),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: onTap == null
                          ? palette.muted
                          : (isSelected ? accent : palette.ink),
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
