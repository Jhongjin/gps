import 'dart:async';

import 'package:flutter/services.dart';

import '../privacy/private_place.dart';
import 'home_widget_snapshot.dart';
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

  /// 네이티브가 이미 가려서 보내지만, 여기서 한 번 더 적용한다. 스냅은 여러 번
  /// 걸어도 결과가 같고, 네이티브 가림이 없는 플랫폼에서는 이쪽이 유일한
  /// 방어선이 된다. 정확한 좌표가 새는 실패는 조용하기 때문에 두 겹으로 둔다.
  List<PrivatePlace> _privatePlaces = const [];

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
    _privatePlaces = config.sharingPolicy.privatePlaces;
    return _invokeVoid('startLocationSession', _sessionConfigToJson(config));
  }

  Future<void> stopLocationSession({required String reason}) {
    return _invokeVoid('stopLocationSession', {'reason': reason});
  }

  Future<void> setSharingPolicy(SharingPolicy policy) {
    _privatePlaces = policy.privatePlaces;
    return _invokeVoid('setSharingPolicy', _sharingPolicyToJson(policy));
  }

  /// 민감 장소만 갈아 끼운다.
  ///
  /// 전체 정책을 다시 밀지 않는 이유는, 안심 화면이 공유 모드나 일시정지처럼
  /// 자기가 모르는 값까지 덮어쓰게 되기 때문이다.
  Future<void> setPrivatePlaces(List<PrivatePlace> places) {
    _privatePlaces = places;
    return _invokeVoid('setPrivatePlaces', {
      'privatePlaces': places.map((place) => place.toChannel()).toList(),
    });
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

  /// 홈 화면 위젯에 보여 줄 스냅샷을 넘긴다.
  ///
  /// **좌표를 담지 않는다.** 위젯은 잠금화면에서 주머니에서 꺼낸 사람 누구에게나
  /// 보인다. 이름과 대략의 상태까지가 한계이고, 어디 있는지는 앱을 열어야
  /// 보인다. 네이티브 쪽도 좌표 키를 아예 읽지 않는다.
  Future<void> updateHomeWidget(HomeWidgetSnapshot snapshot) {
    return _invokeVoid('updateHomeWidget', snapshot.toChannel());
  }

  /// 로그아웃이나 서클 이탈에서 부른다. 남겨 두면 잠금화면에 옛 이름이 남는다.
  Future<void> clearHomeWidget() {
    return _invokeVoid('clearHomeWidget');
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
        // 이름은 빼고 좌표와 반경만 내려보낸다. 네이티브는 가리는 데 이름이
        // 필요 없고, 이름 자체가 민감하다.
        'privatePlaces':
            policy.privatePlaces.map((place) => place.toChannel()).toList(),
      };

  Map<String, Object?> _geofenceToJson(GeofenceSpec geofence) => {
        'id': geofence.id,
        'center': geofence.center.toJson(),
        'radiusM': geofence.radiusM,
        'notifyOnArrival': geofence.notifyOnArrival,
        'notifyOnDeparture': geofence.notifyOnDeparture,
        'quietStart': geofence.quietStart,
        'quietEnd': geofence.quietEnd,
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
      sharedCoordinate:
          _maskedCoordinate(_coordinateFromJson(json['sharedCoordinate'])),
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

  /// 민감 장소 안이면 중심으로 스냅한다.
  Coordinate _maskedCoordinate(Coordinate coordinate) {
    final masked = maskWithPrivatePlaces(
      _privatePlaces,
      coordinate.latitude,
      coordinate.longitude,
    );
    return Coordinate(
      latitude: masked.latitude,
      longitude: masked.longitude,
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
