import 'dart:async';

import 'package:flutter/services.dart';

import 'location_models.dart';

class LocationBridge {
  LocationBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel('app.gyeote/location'),
        _eventChannel =
            eventChannel ?? const EventChannel('app.gyeote/location_events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<Map<Object?, Object?>> get events {
    return _eventChannel.receiveBroadcastStream().map(_mapFromJson);
  }

  Future<PermissionSnapshot> getPermissionSnapshot() async {
    final result = await _invokeMap('getPermissionSnapshot');
    return _permissionSnapshotFromJson(result);
  }

  Future<void> requestWhenInUse() {
    return _invokeVoid('requestWhenInUse');
  }

  Future<void> requestAlways() {
    return _invokeVoid('requestAlways');
  }

  Future<void> startLocationSession(LocationSessionConfig config) {
    return _invokeVoid('startLocationSession', _sessionConfigToJson(config));
  }

  Future<void> stopLocationSession({required String reason}) {
    return _invokeVoid('stopLocationSession', {'reason': reason});
  }

  Future<void> setSharingPolicy(SharingPolicy policy) {
    return _invokeVoid('setSharingPolicy', _sharingPolicyToJson(policy));
  }

  Future<void> configureUpload(NativeUploadConfig config) {
    return _invokeVoid('configureUpload', config.toJson());
  }

  Future<void> clearUploadConfig() {
    return _invokeVoid('clearUploadConfig');
  }

  Future<LocationSample?> getLastKnownLocation() async {
    final result = await _invokeNullableMap('getLastKnownLocation');
    if (result == null) {
      return null;
    }
    return _locationSampleFromJson(result);
  }

  Future<void> registerGeofences(List<GeofenceSpec> geofences) {
    return _invokeVoid(
      'registerGeofences',
      {'geofences': geofences.map(_geofenceToJson).toList(growable: false)},
    );
  }

  Future<void> flushPendingLocations() {
    return _invokeVoid('flushPendingLocations');
  }

  Future<void> requestSosFix() {
    return _invokeVoid('requestSosFix');
  }

  Future<void> _invokeVoid(String method, [Map<String, Object?>? args]) async {
    try {
      await _methodChannel.invokeMethod<void>(method, args);
    } on PlatformException catch (error) {
      throw BridgeError(
        code: error.code,
        message: error.message ?? 'Native location bridge failed.',
        platformDetails: error.details,
      );
    }
  }

  Future<Map<Object?, Object?>> _invokeMap(String method,
      [Map<String, Object?>? args]) async {
    final result = await _invokeNullableMap(method, args);
    if (result == null) {
      throw const BridgeError(
        code: 'invalid_payload',
        message: 'Native bridge returned an empty payload.',
      );
    }
    return result;
  }

  Future<Map<Object?, Object?>?> _invokeNullableMap(String method,
      [Map<String, Object?>? args]) async {
    try {
      final result = await _methodChannel.invokeMethod<Object?>(method, args);
      if (result == null) {
        return null;
      }
      if (result is Map<Object?, Object?>) {
        return result;
      }
      if (result is Map) {
        return result.cast<Object?, Object?>();
      }
      throw BridgeError(
        code: 'invalid_payload',
        message: 'Native bridge returned ${result.runtimeType}, expected Map.',
      );
    } on PlatformException catch (error) {
      throw BridgeError(
        code: error.code,
        message: error.message ?? 'Native location bridge failed.',
        platformDetails: error.details,
      );
    }
  }

  Map<String, Object?> _sessionConfigToJson(LocationSessionConfig config) => {
        'mode': config.mode.name,
        'reason': config.reason,
        'desiredAccuracyM': config.desiredAccuracyM,
        'minDistanceM': config.minDistanceM,
        'minIntervalSeconds': config.minIntervalSeconds,
        'companionSessionId': config.companionSessionId,
        'sharingPolicy': _sharingPolicyToJson(config.sharingPolicy),
      };

  Map<String, Object?> _sharingPolicyToJson(SharingPolicy policy) => {
        'enabled': policy.enabled,
        'mode': policy.mode.name,
        'pausedUntil': policy.pausedUntil?.toUtc().toIso8601String(),
        'expiresAt': policy.expiresAt?.toUtc().toIso8601String(),
        'consentVersion': policy.consentVersion,
      };

  Map<String, Object?> _geofenceToJson(GeofenceSpec geofence) => {
        'id': geofence.id,
        'center': geofence.center.toJson(),
        'radiusM': geofence.radiusM,
        'notifyOnArrival': geofence.notifyOnArrival,
        'notifyOnDeparture': geofence.notifyOnDeparture,
      };

  PermissionSnapshot _permissionSnapshotFromJson(Map<Object?, Object?> json) {
    return PermissionSnapshot(
      foregroundGranted: json['foregroundGranted'] == true,
      backgroundGranted: json['backgroundGranted'] == true,
      preciseGranted: json['preciseGranted'] == true,
      notificationsGranted: json['notificationsGranted'] == true,
      serviceEnabled: json['serviceEnabled'] == true,
    );
  }

  LocationSample _locationSampleFromJson(Map<Object?, Object?> json) {
    return LocationSample(
      rawCoordinate: _coordinateFromJson(json['rawCoordinate']),
      sharedCoordinate: _coordinateFromJson(json['sharedCoordinate']),
      accuracyM: _doubleFromJson(json['accuracyM']),
      sequence: _nullableIntFromJson(json['sequence']) ?? 0,
      altitudeM: _nullableDoubleFromJson(json['altitudeM']),
      speedMps: _nullableDoubleFromJson(json['speedMps']),
      headingDeg: _nullableDoubleFromJson(json['headingDeg']),
      recordedAt: DateTime.parse('${json['recordedAt']}'),
      source: _sourceFromJson(json['source']),
      isMocked: json['isMocked'] == true,
      batteryPercent: _nullableIntFromJson(json['batteryPercent']),
      permissionSnapshot:
          _permissionSnapshotFromJson(_mapFromJson(json['permissionSnapshot'])),
      consentVersion: '${json['consentVersion'] ?? '2026-05-30'}',
    );
  }

  Coordinate _coordinateFromJson(Object? value) {
    final map = _mapFromJson(value);
    return Coordinate(
      latitude: _doubleFromJson(map['latitude']),
      longitude: _doubleFromJson(map['longitude']),
    );
  }

  Map<Object?, Object?> _mapFromJson(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<Object?, Object?>();
    }
    throw BridgeError(
      code: 'invalid_payload',
      message: 'Native bridge returned ${value.runtimeType}, expected Map.',
    );
  }

  LocationSource _sourceFromJson(Object? value) {
    switch ('$value') {
      case 'gps':
        return LocationSource.gps;
      case 'network':
        return LocationSource.network;
      case 'significantChange':
      case 'significant_change':
        return LocationSource.significantChange;
      case 'geofence':
        return LocationSource.geofence;
      case 'sos':
        return LocationSource.sos;
      default:
        return LocationSource.unknown;
    }
  }

  double _doubleFromJson(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    throw BridgeError(
      code: 'invalid_payload',
      message: 'Native bridge returned ${value.runtimeType}, expected number.',
    );
  }

  double? _nullableDoubleFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    return _doubleFromJson(value);
  }

  int? _nullableIntFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    throw BridgeError(
      code: 'invalid_payload',
      message: 'Native bridge returned ${value.runtimeType}, expected integer.',
    );
  }
}
