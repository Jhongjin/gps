enum LocationSource {
  gps,
  network,
  significantChange,
  geofence,
  sos,
  unknown,
}

enum SharingMode {
  precise,
  balanced,
  area,
  hidden,
  sosOnly,
}

enum LocationSessionMode {
  passive,
  companion,
  placeAlert,
  sos,
}

class Coordinate {
  const Coordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  Map<String, Object?> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class LocationSample {
  const LocationSample({
    required this.rawCoordinate,
    required this.sharedCoordinate,
    required this.accuracyM,
    required this.recordedAt,
    required this.source,
    required this.permissionSnapshot,
    this.sequence = 0,
    this.altitudeM,
    this.speedMps,
    this.headingDeg,
    this.isMocked = false,
    this.batteryPercent,
    this.consentVersion = '2026-05-30',
  });

  final int sequence;
  final Coordinate rawCoordinate;
  final Coordinate sharedCoordinate;
  final double accuracyM;
  final double? altitudeM;
  final double? speedMps;
  final double? headingDeg;
  final DateTime recordedAt;
  final LocationSource source;
  final bool isMocked;
  final int? batteryPercent;
  final PermissionSnapshot permissionSnapshot;
  final String consentVersion;
}

class PermissionSnapshot {
  const PermissionSnapshot({
    required this.foregroundGranted,
    required this.backgroundGranted,
    required this.preciseGranted,
    required this.notificationsGranted,
    required this.serviceEnabled,
  });

  final bool foregroundGranted;
  final bool backgroundGranted;
  final bool preciseGranted;
  final bool notificationsGranted;
  final bool serviceEnabled;
}

class SharingPolicy {
  const SharingPolicy({
    required this.enabled,
    required this.mode,
    this.pausedUntil,
    this.expiresAt,
    this.consentVersion = '2026-05-30',
  });

  final bool enabled;
  final SharingMode mode;
  final DateTime? pausedUntil;
  final DateTime? expiresAt;
  final String consentVersion;
}

class LocationSessionConfig {
  const LocationSessionConfig({
    required this.mode,
    required this.reason,
    required this.desiredAccuracyM,
    required this.minDistanceM,
    required this.minIntervalSeconds,
    required this.sharingPolicy,
    this.companionSessionId,
  });

  final LocationSessionMode mode;
  final String reason;
  final double desiredAccuracyM;
  final double minDistanceM;
  final int minIntervalSeconds;
  final SharingPolicy sharingPolicy;
  final String? companionSessionId;
}

class GeofenceSpec {
  const GeofenceSpec({
    required this.id,
    required this.center,
    required this.radiusM,
    required this.notifyOnArrival,
    required this.notifyOnDeparture,
  });

  final String id;
  final Coordinate center;
  final double radiusM;
  final bool notifyOnArrival;
  final bool notifyOnDeparture;
}

class NativeUploadConfig {
  const NativeUploadConfig({
    required this.supabaseUrl,
    required this.publishableKey,
    required this.accessToken,
    required this.profileId,
    required this.deviceId,
  });

  final String supabaseUrl;
  final String publishableKey;
  final String accessToken;
  final String profileId;
  final String deviceId;

  Map<String, Object?> toJson() => {
        'supabaseUrl': supabaseUrl,
        'publishableKey': publishableKey,
        'accessToken': accessToken,
        'profileId': profileId,
        'deviceId': deviceId,
      };
}

class BridgeError implements Exception {
  const BridgeError({
    required this.code,
    required this.message,
    this.platformDetails,
  });

  final String code;
  final String message;
  final Object? platformDetails;

  @override
  String toString() => 'BridgeError($code): $message';
}
