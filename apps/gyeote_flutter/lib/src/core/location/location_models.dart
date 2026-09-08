import '../privacy/private_place.dart';

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
    this.privatePlaces = const [],
  });

  final bool enabled;
  final SharingMode mode;
  final DateTime? pausedUntil;
  final DateTime? expiresAt;
  final String consentVersion;

  /// 정확한 좌표를 내보내지 않을 장소들. 기기에만 사는 값이라 서버 스키마에
  /// 대응하는 자리가 없다. 정책의 일부인 이유는, 좌표를 만들어 내는 쪽이
  /// 네이티브라서 거기까지 내려가야 실제로 가려지기 때문이다.
  final List<PrivatePlace> privatePlaces;
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
    this.quietStart,
    this.quietEnd,
  });

  final String id;
  final Coordinate center;
  final double radiusM;
  final bool notifyOnArrival;
  final bool notifyOnDeparture;

  /// "HH:mm" 기기 현지 시각. 둘 다 있어야 창이 된다. 지오펜스 전환은 앱이 죽어
  /// 있어도 네이티브 리시버가 처리하므로, 조용한 시간은 여기까지 내려가야
  /// 실제로 조용해진다.
  final String? quietStart;
  final String? quietEnd;
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
