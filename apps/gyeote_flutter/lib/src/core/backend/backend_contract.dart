import '../location/location_models.dart';

enum CompanionSessionStatus {
  pending,
  active,
  ended,
  expired,
  cancelled,
}

enum DataRequestType {
  export,
  deleteHistory,
  deleteAccount,
}

enum CheckInStatus {
  safeArrived,
  needsCheck,
  signalWeak,
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

class PlaceAlertQuietHours {
  const PlaceAlertQuietHours({
    required this.enabled,
    this.start,
    this.end,
    this.timeZone,
    this.label,
  });

  const PlaceAlertQuietHours.none()
      : enabled = false,
        start = null,
        end = null,
        timeZone = null,
        label = null;

  final bool enabled;
  final String? start;
  final String? end;
  final String? timeZone;
  final String? label;

  String get summary {
    if (!enabled) {
      return '없음';
    }
    final timeLabel = start != null && end != null ? '$start-$end' : '설정됨';
    final labelText = label;
    if (labelText == null || labelText.isEmpty) {
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
      'timeZone': timeZone,
      'label': label,
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

  Future<void> requestData(DataRequestType requestType);
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
