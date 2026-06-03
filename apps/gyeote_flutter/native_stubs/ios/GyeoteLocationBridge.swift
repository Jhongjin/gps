import CoreLocation
import Flutter
import UIKit

final class GyeoteLocationBridge: NSObject, FlutterPlugin, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var eventSink: FlutterEventSink?
  private var sequence = 0
  private var sharingPolicy: [String: Any] = [
    "enabled": false,
    "mode": "hidden",
    "consentVersion": "2026-05-30"
  ]

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = GyeoteLocationBridge()
    let methodChannel = FlutterMethodChannel(
      name: "app.gyeote/location",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "app.gyeote/location_events",
      binaryMessenger: registrar.messenger()
    )

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.distanceFilter = 50
    manager.pausesLocationUpdatesAutomatically = true
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPermissionSnapshot":
      result(permissionSnapshot())
    case "requestWhenInUse":
      manager.requestWhenInUseAuthorization()
      result(nil)
    case "requestAlways":
      manager.requestAlwaysAuthorization()
      result(nil)
    case "startLocationSession":
      startLocationSession(call.arguments)
      result(nil)
    case "stopLocationSession":
      stopLocationSession()
      result(nil)
    case "setSharingPolicy":
      if let args = call.arguments as? [String: Any] {
        sharingPolicy = args
      }
      result(nil)
    case "getLastKnownLocation":
      result(manager.location.map(locationPayload))
    case "registerGeofences":
      registerGeofences(call.arguments)
      result(nil)
    case "flushPendingLocations":
      emitServiceEvent("service.statusChanged", details: ["state": "flushRequested"])
      result(nil)
    case "requestSosFix":
      manager.requestLocation()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    emitServiceEvent("service.statusChanged", details: ["state": "listening"])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    emitServiceEvent("permission.changed", details: permissionSnapshot())
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    eventSink?(locationEvent(location))
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    emitServiceEvent("location.error", details: ["code": "provider_disabled", "message": error.localizedDescription])
  }

  private func startLocationSession(_ arguments: Any?) {
    guard ordinaryCollectionAllowed() else {
      emitServiceEvent("location.error", details: ["code": "policy_paused"])
      return
    }

    if let args = arguments as? [String: Any], let mode = args["mode"] as? String {
      manager.desiredAccuracy = mode == "companion" ? kCLLocationAccuracyBest : kCLLocationAccuracyHundredMeters
      manager.distanceFilter = mode == "companion" ? 25 : 100
      manager.allowsBackgroundLocationUpdates = mode == "companion"
    }

    manager.startUpdatingLocation()
  }

  private func stopLocationSession() {
    manager.stopUpdatingLocation()
    manager.allowsBackgroundLocationUpdates = false
    emitServiceEvent("service.statusChanged", details: ["state": "stopped"])
  }

  private func registerGeofences(_ arguments: Any?) {
    manager.monitoredRegions.forEach(manager.stopMonitoring)

    guard let args = arguments as? [String: Any],
          let geofences = args["geofences"] as? [[String: Any]] else {
      return
    }

    geofences.prefix(20).forEach { geofence in
      guard let id = geofence["id"] as? String,
            let center = geofence["center"] as? [String: Any],
            let latitude = center["latitude"] as? Double,
            let longitude = center["longitude"] as? Double,
            let radius = geofence["radiusM"] as? Double else {
        return
      }

      let region = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        radius: radius,
        identifier: id
      )
      region.notifyOnEntry = geofence["notifyOnArrival"] as? Bool ?? true
      region.notifyOnExit = geofence["notifyOnDeparture"] as? Bool ?? true
      manager.startMonitoring(for: region)
    }
  }

  private func ordinaryCollectionAllowed() -> Bool {
    let enabled = sharingPolicy["enabled"] as? Bool ?? false
    let mode = sharingPolicy["mode"] as? String ?? "hidden"
    return enabled &&
      mode != "hidden" &&
      mode != "sosOnly" &&
      !isPolicyPaused() &&
      !isPolicyExpired()
  }

  private func locationEvent(_ location: CLLocation) -> [String: Any] {
    let sequence = nextSequence()
    var payload = locationPayload(location)
    payload["type"] = "location.updated"
    payload["schemaVersion"] = 1
    payload["sequence"] = sequence
    payload["idempotencyKey"] = "ios:\(sequence):\(Int(location.timestamp.timeIntervalSince1970 * 1000))"
    payload["permissionSnapshot"] = permissionSnapshot()
    payload["consentVersion"] = sharingPolicy["consentVersion"] as? String ?? "2026-05-30"
    return payload
  }

  private func locationPayload(_ location: CLLocation) -> [String: Any] {
    let coordinate = [
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude
    ]
    return [
      "rawCoordinate": coordinate,
      "sharedCoordinate": coordinate,
      "accuracyM": location.horizontalAccuracy,
      "speedMps": max(location.speed, 0),
      "headingDeg": max(location.course, 0),
      "recordedAt": iso8601(location.timestamp),
      "source": "gps",
      "isMocked": false,
      "permissionSnapshot": permissionSnapshot()
    ]
  }

  private func permissionSnapshot() -> [String: Any] {
    let status = manager.authorizationStatus
    return [
      "foregroundGranted": status == .authorizedWhenInUse || status == .authorizedAlways,
      "backgroundGranted": status == .authorizedAlways,
      "preciseGranted": manager.accuracyAuthorization == .fullAccuracy,
      "notificationsGranted": false,
      "serviceEnabled": CLLocationManager.locationServicesEnabled()
    ]
  }

  private func emitServiceEvent(_ type: String, details: [String: Any]) {
    var payload = details
    payload["type"] = type
    payload["schemaVersion"] = 1
    payload["sequence"] = nextSequence()
    payload["recordedAt"] = iso8601(Date())
    payload["source"] = "unknown"
    payload["permissionSnapshot"] = permissionSnapshot()
    payload["consentVersion"] = sharingPolicy["consentVersion"] as? String ?? "2026-05-30"
    eventSink?(payload)
  }

  private func nextSequence() -> Int {
    sequence += 1
    return sequence
  }

  private func iso8601(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }

  private func isPolicyPaused() -> Bool {
    guard let raw = sharingPolicy["pausedUntil"] as? String,
          let date = ISO8601DateFormatter().date(from: raw) else {
      return false
    }
    return date > Date()
  }

  private func isPolicyExpired() -> Bool {
    guard let raw = sharingPolicy["expiresAt"] as? String,
          let date = ISO8601DateFormatter().date(from: raw) else {
      return false
    }
    return date <= Date()
  }
}
