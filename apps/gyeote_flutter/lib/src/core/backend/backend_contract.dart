import '../../../l10n/app_localizations.dart';

import '../location/location_models.dart';

enum CompanionSessionStatus {
  pending,
  active,
  ended,
  expired,
  cancelled,
}

enum PlaceAlertEventType {
  arrived,
  departed,
  late,
  longStay,
}

enum DataRequestType {
  export,
  deleteHistory,
  deleteAccount,
}

enum CheckInStatus {
  /// 도착했어. 동행 세션을 끝내는 유일한 값이다.
  safeArrived,

  /// 시스템이 판단한다. 사용자가 누르는 값이 아니다.
  needsCheck,
  signalWeak,

  /// 정형 반응. 한 번 눌러 서클에 보내는 짧은 말이다.
  onTheWay,
  imOk,
  callMe;

  /// 사용자가 직접 보낼 수 있는 값인지.
  bool get isQuickReply => switch (this) {
        CheckInStatus.safeArrived ||
        CheckInStatus.onTheWay ||
        CheckInStatus.imOk ||
        CheckInStatus.callMe =>
          true,
        CheckInStatus.needsCheck || CheckInStatus.signalWeak => false,
      };

  /// 동행 세션을 끝내는 값인지. 마이그레이션 016 의 가드와 같은 규칙이다.
  bool get endsCompanionSession => this == CheckInStatus.safeArrived;

  /// 사용자가 고를 수 있는 정형 반응 네 가지. 화면에 이 순서로 놓는다.
  static const quickReplies = [
    CheckInStatus.safeArrived,
    CheckInStatus.onTheWay,
    CheckInStatus.imOk,
    CheckInStatus.callMe,
  ];

  /// 표시 문구. 화면마다 복사하면 곧 서로 어긋난다.
  String label(AppL10n l10n) => switch (this) {
        CheckInStatus.safeArrived => l10n.checkInSafeArrived,
        CheckInStatus.needsCheck => l10n.checkInNeedsCheck,
        CheckInStatus.signalWeak => l10n.checkInWeakSignal,
        CheckInStatus.onTheWay => l10n.checkInOnTheWay,
        CheckInStatus.imOk => l10n.checkInImOk,
        CheckInStatus.callMe => l10n.checkInCallMe,
      };
}

enum DevicePlatform {
  ios,
  android,
}

class CircleSummary {
  const CircleSummary({
    required this.id,
    required this.name,
    required this.memberCount,
  });

  final String id;
  final String name;
  final int memberCount;
}

class CircleInvite {
  const CircleInvite({
    required this.id,
    required this.circleId,
    required this.codeHint,
    required this.expiresAt,
    required this.maxUses,
    required this.useCount,
  });

  final String id;
  final String circleId;
  final String codeHint;
  final DateTime expiresAt;
  final int maxUses;
  final int useCount;
}

class InviteCreationResult {
  const InviteCreationResult({
    required this.invite,
    required this.rawInviteUrl,
  });

  final CircleInvite invite;
  final Uri rawInviteUrl;
}

class MemberLocationSnapshot {
  const MemberLocationSnapshot({
    required this.profileId,
    required this.displayName,
    required this.sharedCoordinate,
    required this.sharingMode,
    required this.recordedAt,
    this.accuracyM,
    this.batteryPercent,
  });

  final String profileId;
  final String displayName;
  final Coordinate? sharedCoordinate;
  final SharingMode sharingMode;
  final DateTime recordedAt;
  final double? accuracyM;
  final int? batteryPercent;
}

class MemberRoutePoint {
  const MemberRoutePoint({
    required this.profileId,
    required this.sharedCoordinate,
    required this.sharingMode,
    required this.recordedAt,
  });

  final String profileId;
  final Coordinate sharedCoordinate;
  final SharingMode sharingMode;
  final DateTime recordedAt;
}

class LocationUpload {
  const LocationUpload({
    required this.deviceId,
    required this.sample,
    required this.idempotencyKey,
    this.companionSessionId,
    this.sharingMode = SharingMode.balanced,
  });

  final String deviceId;
  final LocationSample sample;
  final String idempotencyKey;
  final String? companionSessionId;
  final SharingMode sharingMode;
}

class RegisteredDevice {
  const RegisteredDevice({
    required this.id,
    required this.platform,
    this.pushToken,
    this.appVersion,
    this.lastSeenAt,
  });

  final String id;
  final DevicePlatform platform;
  final String? pushToken;
  final String? appVersion;
  final DateTime? lastSeenAt;
}

class PlaceAlertRule {
  const PlaceAlertRule({
    required this.id,
    required this.circleId,
    required this.name,
    required this.center,
    required this.radiusM,
    required this.notifyOnArrival,
    required this.notifyOnDeparture,
    required this.notifyOnLate,
    required this.notifyOnLongStay,
    required this.quietHours,
    required this.enabled,
    required this.targetCount,
  });

  final String id;
  final String circleId;
  final String name;
  final Coordinate center;
  final int radiusM;
  final bool notifyOnArrival;
  final bool notifyOnDeparture;
  final bool notifyOnLate;
  final bool notifyOnLongStay;
  final PlaceAlertQuietHours quietHours;
  final bool enabled;
  final int targetCount;
}

/// 조용한 시간 프리셋.
///
/// DB 에는 이 키가 간다. 예전에는 렌더된 라벨("야간")이 갔고, 순환할 때 그
/// 라벨을 현재 로케일의 번역과 비교했다. 만든 사람이 한국어면 영어 멤버에게는
/// 어떤 프리셋과도 일치하지 않아 항상 첫 프리셋으로 되돌아갔다 — 이 저장소에서
/// 다섯 번째로 나온 "보여주는 값을 판단에 쓴" 버그다.
enum QuietHoursPreset {
  night('night', '22:00', '07:00'),
  classOrWork('classOrWork', '09:00', '17:00');

  const QuietHoursPreset(this.key, this.start, this.end);

  final String key;
  final String start;
  final String end;

  String label(AppL10n l10n) => switch (this) {
        QuietHoursPreset.night => l10n.quietHoursNight,
        QuietHoursPreset.classOrWork => l10n.quietHoursClassOrWork,
      };

  static QuietHoursPreset? fromKey(String? key) {
    for (final preset in values) {
      if (preset.key == key) return preset;
    }
    return null;
  }

  /// 프리셋 키가 없는 옛 행을 위한 추론. 라벨이 아니라 **시각**으로 맞춘다 —
  /// 시각은 로케일과 무관한 사실이다.
  static QuietHoursPreset? fromTimes(String? start, String? end) {
    for (final preset in values) {
      if (preset.start == start && preset.end == end) return preset;
    }
    return null;
  }
}

class PlaceAlertQuietHours {
  const PlaceAlertQuietHours({
    required this.enabled,
    this.start,
    this.end,
    this.preset,
  });

  const PlaceAlertQuietHours.none()
      : enabled = false,
        start = null,
        end = null,
        preset = null;

  PlaceAlertQuietHours.preset(QuietHoursPreset preset)
      : this(
          enabled: true,
          start: preset.start,
          end: preset.end,
          preset: preset,
        );

  final bool enabled;

  /// "HH:mm". 기기 현지 시각이다. 예전에는 `timeZone: 'Asia/Seoul'` 을 함께
  /// 저장했는데, 기기가 어디 있든 서울로 적히는 값이라 사실이 아니었다. IANA
  /// 이름을 알려 주는 출처가 생기기 전까지는 적지 않는다. 지금은 어느 쪽도
  /// 이 값을 **집행하지 않는다** — 네이티브도 SQL 도 읽지 않는다.
  final String? start;
  final String? end;
  final QuietHoursPreset? preset;

  /// 표시용 요약. 라벨은 저장된 것이 아니라 프리셋에서 현재 로케일로 만든다.
  String summary(AppL10n l10n) {
    if (!enabled) {
      return l10n.quietHoursOff;
    }
    final timeLabel =
        start != null && end != null ? '$start-$end' : l10n.quietHoursOn;
    final labelText = preset?.label(l10n);
    if (labelText == null) {
      return timeLabel;
    }
    return '$labelText $timeLabel';
  }

  Map<String, Object?> toJson() {
    if (!enabled) {
      return {};
    }
    return {
      'enabled': enabled,
      'start': start,
      'end': end,
      'preset': preset?.key,
    };
  }
}

class PlaceAlertDraft {
  const PlaceAlertDraft({
    required this.circleId,
    required this.name,
    required this.center,
    required this.radiusM,
    required this.targetProfileIds,
    this.notifyOnArrival = true,
    this.notifyOnDeparture = true,
    this.notifyOnLate = false,
    this.notifyOnLongStay = false,
    this.quietHours = const PlaceAlertQuietHours.none(),
  });

  final String circleId;
  final String name;
  final Coordinate center;
  final int radiusM;
  final List<String> targetProfileIds;
  final bool notifyOnArrival;
  final bool notifyOnDeparture;
  final bool notifyOnLate;
  final bool notifyOnLongStay;
  final PlaceAlertQuietHours quietHours;
}

class CheckInEvent {
  const CheckInEvent({
    required this.id,
    required this.circleId,
    required this.actorProfileId,
    required this.subjectProfileId,
    required this.displayName,
    required this.status,
    required this.sharingMode,
    required this.createdAt,
    this.companionSessionId,
  });

  final String id;
  final String circleId;
  final String actorProfileId;
  final String subjectProfileId;
  final String displayName;
  final CheckInStatus status;
  final SharingMode sharingMode;
  final DateTime createdAt;
  final String? companionSessionId;
}

class AdPreferences {
  const AdPreferences({
    required this.personalizedAdsEnabled,
    required this.sensitiveCategoriesBlocked,
    this.preciseLocationAdsEnabled = false,
  });

  final bool personalizedAdsEnabled;
  final bool sensitiveCategoriesBlocked;
  final bool preciseLocationAdsEnabled;
}

/// 누가 내 위치를 봤는지 한 줄.
///
/// 이 앱이 다른 위치 공유 앱과 갈리는 지점이다. 보는 쪽이 아니라 **보여지는
/// 쪽**이 읽는 기록이라, 본인 것만 나온다.
class ViewerLogEntry {
  const ViewerLogEntry({
    required this.id,
    required this.viewerProfileId,
    required this.viewerName,
    required this.precision,
    required this.viewedAt,
    this.circleId,
  });

  final String id;
  final String viewerProfileId;

  /// 비어 있을 수 있다. 화면이 로케일에 맞는 대체 이름을 붙인다 — 여기에
  /// 렌더된 문자열을 넣지 않는다.
  final String viewerName;
  final String? circleId;
  final SharingMode precision;
  final DateTime viewedAt;
}

abstract interface class CircleRepository {
  Future<List<CircleSummary>> listCircles();

  Future<CircleSummary> createCircle({
    required String name,
    String circleType = 'family',
  });

  Future<List<MemberLocationSnapshot>> listLatestLocations(String circleId);

  Future<List<MemberRoutePoint>> getMemberRouteTail({
    required String circleId,
    required String profileId,
    int limit = 30,
    Duration since = const Duration(hours: 2),
  });

  Future<List<MemberRoutePoint>> getActiveCompanionRouteTail({
    required String companionSessionId,
    required String profileId,
    int limit = 60,
    Duration since = const Duration(minutes: 45),
  });

  Stream<List<MemberLocationSnapshot>> watchLatestLocations(String circleId);

  /// 다른 사람의 위치를 열어 봤다는 사실을 남긴다.
  ///
  /// 본인 위치를 보는 것은 열람이 아니므로 호출부가 걸러야 한다. 실패해도
  /// 화면을 막지 않는다 — 기록이 빠지는 것은 문제지만, 그것 때문에 위치를
  /// 못 보게 하는 것은 더 큰 문제다.
  Future<void> recordViewerLog({
    required String profileId,
    required String circleId,
    required SharingMode precision,
  });

  /// 내 위치를 본 사람들. 남의 기록은 읽을 수 없다.
  Future<List<ViewerLogEntry>> listViewerLog({
    int limit = 50,
    Duration since = const Duration(days: 30),
  });
}

abstract interface class InvitationRepository {
  Future<InviteCreationResult> createInvite({
    required String circleId,
    required DateTime expiresAt,
    int maxUses = 1,
  });

  Future<void> acceptInvite({
    required String rawInviteToken,
  });

  Future<void> revokeInvite(String inviteId);
}

/// 참석 응답.
enum MeetupResponse {
  invited,
  going,
  maybe,
  declined;

  /// 아직 답하지 않은 상태인지.
  bool get isPending => this == MeetupResponse.invited;
}

/// 집결 장소와 시각.
///
/// 사람이 끄는 물건이 아니라 **시각이 지나면 스스로 끝나는** 물건이다. 이
/// 카테고리에서 사람들이 가장 불안해하는 것이 "끝났는데도 계속 공유되는 것"이라,
/// 끄는 걸 잊어도 꺼지게 만든다.
class Meetup {
  const Meetup({
    required this.id,
    required this.circleId,
    required this.createdBy,
    required this.name,
    required this.placeLat,
    required this.placeLng,
    required this.meetAt,
    required this.graceMinutes,
    required this.myResponse,
    required this.goingCount,
    required this.attendeeCount,
    this.placeName,
  });

  final String id;
  final String circleId;
  final String createdBy;
  final String name;
  final String? placeName;
  final double placeLat;
  final double placeLng;
  final DateTime meetAt;

  /// 약속 시각이 지나도 곧바로 사라지면 늦는 사람이 길을 잃는다.
  final int graceMinutes;

  final MeetupResponse myResponse;
  final int goingCount;
  final int attendeeCount;

  /// 만료 시각. SQL 의 `is_meetup_over` 와 같은 규칙이다.
  DateTime get endsAt => meetAt.add(Duration(minutes: graceMinutes));

  bool get isOver => DateTime.now().isAfter(endsAt);

  /// 약속 시각까지 남은 시간. 이미 지났으면 음수다.
  Duration get timeUntil => meetAt.difference(DateTime.now());
}

class MeetupDraft {
  const MeetupDraft({
    required this.circleId,
    required this.name,
    required this.placeLat,
    required this.placeLng,
    required this.meetAt,
    this.placeName,
    this.graceMinutes = 30,
    this.attendeeProfileIds,
  });

  final String circleId;
  final String name;
  final String? placeName;
  final double placeLat;
  final double placeLng;
  final DateTime meetAt;
  final int graceMinutes;

  /// null 이면 서클 전체를 부른다.
  final List<String>? attendeeProfileIds;
}

abstract interface class MeetupRepository {
  /// 끝나지 않은 약속만 돌려준다. 만료 판정은 서버가 한다 — 클라이언트 시계를
  /// 믿으면 기기마다 다른 시각에 사라진다.
  Future<List<Meetup>> listActiveMeetups(String circleId);

  Future<Meetup> createMeetup(MeetupDraft draft);

  Future<void> respondToMeetup({
    required String meetupId,
    required MeetupResponse response,
  });

  /// 만든 사람만 끝낼 수 있다.
  Future<void> endMeetup(String meetupId);
}

abstract interface class PlaceAlertRepository {
  Future<List<PlaceAlertRule>> listPlaceAlerts(String circleId);

  Future<PlaceAlertRule> createPlaceAlert(PlaceAlertDraft draft);

  Future<PlaceAlertRule> setPlaceAlertEnabled({
    required String alertId,
    required bool enabled,
  });

  Future<PlaceAlertRule> setPlaceAlertQuietHours({
    required String alertId,
    required PlaceAlertQuietHours quietHours,
  });

  Future<void> recordPlaceAlertEvent({
    required String alertId,
    required PlaceAlertEventType eventType,
    DateTime? occurredAt,
    String? dedupeKey,
  });

  Future<void> deletePlaceAlert(String alertId);
}

abstract interface class CheckInRepository {
  Future<CheckInEvent> performCheckIn({
    required String circleId,
    String? companionSessionId,
    CheckInStatus status = CheckInStatus.safeArrived,
  });

  Future<List<CheckInEvent>> listRecentCheckIns({
    required String circleId,
    int limit = 20,
  });
}

abstract interface class LocationIngestRepository {
  Future<void> uploadLatest(LocationUpload upload);

  Future<void> uploadHistoryBatch(List<LocationUpload> uploads);
}

abstract interface class DeviceRepository {
  Future<RegisteredDevice> registerDevice({
    String? deviceId,
    required DevicePlatform platform,
    String? pushToken,
    String? appVersion,
  });

  Future<void> markSeen(String deviceId);
}

abstract interface class PrivacyRepository {
  Future<AdPreferences> getAdPreferences();

  Future<void> updateAdPreferences(AdPreferences preferences);

  Future<void> updateSharingPolicy({
    required String circleId,
    required SharingPolicy policy,
  });

  /// 내보내기처럼 사람이 처리해야 하는 요청. 큐에 남는다.
  Future<void> requestData(DataRequestType requestType);

  /// 내 위치 기록을 지금 지운다. 지운 행 수를 돌려준다.
  ///
  /// 예전에는 `requestData(deleteHistory)` 로 큐에 행만 넣었고 그 행을 읽는 것은
  /// 없었다. 스토어는 "삭제 요청 접수"가 아니라 삭제를 요구한다.
  Future<int> deleteLocationHistory();

  /// 내 계정을 지금 지운다. 성공하면 호출자가 로그아웃 상태를 정리한다.
  Future<void> deleteAccount();
}

abstract interface class CompanionRepository {
  Future<String> createSession({
    required String circleId,
    required String subjectProfileId,
    required DateTime expiresAt,
  });

  Future<void> consentToSession(String sessionId);

  Future<void> activateSession(String sessionId);

  Future<void> endSession({
    required String sessionId,
    required String reason,
  });

  Stream<CompanionSessionStatus> watchSessionStatus(String sessionId);
}
