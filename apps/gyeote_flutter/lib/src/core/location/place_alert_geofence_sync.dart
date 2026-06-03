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
  bool requestBackgroundPermission = true,
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
        ),
      )
      .toList(growable: false);

  if (requestBackgroundPermission && geofences.isNotEmpty) {
    await locationBridge.requestAlways();
  }
  await locationBridge.registerGeofences(geofences);
  return geofences.length;
}
