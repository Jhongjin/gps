import 'package:flutter/foundation.dart';

import '../backend/backend_contract.dart';
import 'location_bridge.dart';
import 'location_models.dart';

bool get supportsNativePlaceAlertGeofences {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

Future<int?> syncPlaceAlertGeofences({
  required PlaceAlertRepository repository,
  required LocationBridge locationBridge,
  required String circleId,
  /// 기본값이 `false` 인 것은 의도다. 예전에는 `true` 여서 장소 알림을 만지는
  /// 모든 경로가 조용히 백그라운드 위치를 요청했다. 이유를 설명한 호출자만
  /// 켠다.
  bool requestBackgroundPermission = false,
}) async {
  if (!supportsNativePlaceAlertGeofences) {
    return null;
  }

  final alerts = await repository.listPlaceAlerts(circleId);
  final geofences = alerts
      .where((alert) =>
          alert.enabled && (alert.notifyOnArrival || alert.notifyOnDeparture))
      .take(20)
      .map(
        (alert) => GeofenceSpec(
          id: alert.id,
          center: alert.center,
          radiusM: alert.radiusM.toDouble(),
          notifyOnArrival: alert.notifyOnArrival,
          notifyOnDeparture: alert.notifyOnDeparture,
          quietStart: alert.quietHours.enabled ? alert.quietHours.start : null,
          quietEnd: alert.quietHours.enabled ? alert.quietHours.end : null,
        ),
      )
      .toList(growable: false);

  // 백그라운드 위치는 냉정하게 물으면 거의 거절당하고, 되돌리려면 사용자가
  // 설정 앱까지 들어가야 한다. 그래서 이 함수는 스스로 묻지 않는다 —
  // 호출자가 이유를 설명하고 동의를 받은 뒤에만 이 플래그를 켠다.
  if (requestBackgroundPermission && geofences.isNotEmpty) {
    await locationBridge.requestAlways();
  }
  await locationBridge.registerGeofences(geofences);
  return geofences.length;
}
