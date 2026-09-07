import Flutter
import CoreLocation
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    GyeoteLocationBridge.register(with: engineBridge.pluginRegistry.registrar(forPlugin: "GyeoteLocationBridge"))
  }
}

final class GyeoteLocationBridge: NSObject, FlutterPlugin, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private let uploadQueue = GyeoteIOSLocationUploadQueue()
  private var eventSink: FlutterEventSink?
  private var sequence: Int64 = 0
  private var lastLocation: CLLocation?
  private var activeSession: [String: Any?]?
  private var uploadConfig: [String: Any?]?
  private var sharingPolicy: [String: Any?] = [
    "enabled": true,
    "mode": "precise",
    "consentVersion": "2026-05-30",
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
    manager.pausesLocationUpdatesAutomatically = true
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPermissionSnapshot":
      result(permissionSnapshot())
    case "requestWhenInUse":
      manager.requestWhenInUseAuthorization()
      requestNotificationAuthorization()
      result(nil)
    case "requestAlways":
      manager.requestAlwaysAuthorization()
      requestNotificationAuthorization()
      result(nil)
    case "startLocationSession":
      activeSession = call.arguments as? [String: Any?]
      startLocationSession(activeSession)
      result(nil)
    case "stopLocationSession":
      activeSession = nil
      stopLocationSession()
      emitStatus("stopped")
      result(nil)
    case "setSharingPolicy":
      if let policy = call.arguments as? [String: Any?] {
        sharingPolicy = policy
      }
      if !canCollect(allowSos: false) {
        stopLocationSession()
      }
      emitPermissionChanged()
      result(nil)
    case "setPrivatePlaces":
      // 민감 장소만 갈아 끼운다. 전체 정책을 다시 밀면 안심 화면이 모드나
      // 일시정지처럼 자기가 모르는 값을 덮어쓰게 된다.
      let places = (call.arguments as? [String: Any?])?["privatePlaces"] as Any?
      sharingPolicy["privatePlaces"] = places
      result(nil)
    case "configureUpload":
      uploadConfig = call.arguments as? [String: Any?]
      emitStatus(uploadConfig == nil ? "upload_not_configured" : "upload_configured")
      uploadQueue.resetBackoff()
      flushUploadQueue(force: true)
      result(nil)
    case "clearUploadConfig":
      uploadConfig = nil
      uploadQueue.resetBackoff()
      result(nil)
    case "getLastKnownLocation":
      result(lastLocation.map { locationPayload($0) })
    case "registerGeofences":
      registerGeofences(call.arguments)
      result(nil)
    case "flushPendingLocations":
      flushUploadQueue(force: true)
      result(nil)
    case "requestSosFix":
      requestSosFix()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    emitPermissionChanged()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    emitPermissionChanged()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    lastLocation = location

    if !canCollect(allowSos: activeSession?["mode"] as? String == "sos") {
      stopLocationSession()
      emitStatus("policy_paused")
      return
    }

    let payload = locationPayload(location)
    uploadQueue.enqueue(payload: payload, config: uploadConfig)
    flushUploadQueue(force: false)
    eventSink?(payload)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    emitError("provider_disabled", error.localizedDescription)
  }

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    emitRegion("geofence.entered", region: region)
    showPlaceAlertNotification(for: "geofence.entered", regionId: region.identifier)
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    emitRegion("geofence.exited", region: region)
    showPlaceAlertNotification(for: "geofence.exited", regionId: region.identifier)
  }

  private func startLocationSession(_ config: [String: Any?]?) {
    guard hasForegroundLocationPermission else {
      emitError("permission_denied", "Location permission is required.")
      return
    }
    guard canCollect(allowSos: config?["mode"] as? String == "sos") else {
      emitError("policy_paused", "Sharing policy does not allow collection.")
      return
    }
    guard CLLocationManager.locationServicesEnabled() else {
      emitError("provider_disabled", "Location service is disabled.")
      return
    }

    manager.desiredAccuracy = (config?["desiredAccuracyM"] as? NSNumber)?.doubleValue ?? kCLLocationAccuracyNearestTenMeters
    manager.distanceFilter = (config?["minDistanceM"] as? NSNumber)?.doubleValue ?? 25
    manager.allowsBackgroundLocationUpdates = hasBackgroundLocationPermission && (config?["mode"] as? String != "passive")
    manager.showsBackgroundLocationIndicator = manager.allowsBackgroundLocationUpdates
    manager.startUpdatingLocation()
    emitStatus("started")
  }

  private func stopLocationSession() {
    manager.stopUpdatingLocation()
    manager.allowsBackgroundLocationUpdates = false
    manager.showsBackgroundLocationIndicator = false
  }

  private func requestSosFix() {
    guard hasForegroundLocationPermission else {
      emitError("permission_denied", "Location permission is required.")
      return
    }
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.requestLocation()
  }

  private func registerGeofences(_ arguments: Any?) {
    manager.monitoredRegions.forEach { manager.stopMonitoring(for: $0) }

    guard let payload = arguments as? [String: Any],
          let geofences = payload["geofences"] as? [[String: Any]] else {
      UserDefaults.standard.removeObject(forKey: Self.quietWindowsKey)
      return
    }

    // 조용한 시간 창은 저장소에 둔다. 리전 콜백은 앱이 내려간 뒤에도 온다.
    UserDefaults.standard.set(
      GyeoteQuietHours.windows(from: Array(geofences.prefix(20))),
      forKey: Self.quietWindowsKey
    )

    for geofence in geofences.prefix(20) {
      guard let id = geofence["id"] as? String,
            let center = geofence["center"] as? [String: Any],
            let latitude = center["latitude"] as? CLLocationDegrees,
            let longitude = center["longitude"] as? CLLocationDegrees,
            let radius = geofence["radiusM"] as? CLLocationDistance else {
        continue
      }

      let region = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        radius: min(radius, manager.maximumRegionMonitoringDistance),
        identifier: id
      )
      region.notifyOnEntry = geofence["notifyOnArrival"] as? Bool ?? true
      region.notifyOnExit = geofence["notifyOnDeparture"] as? Bool ?? true
      manager.startMonitoring(for: region)
    }
  }

  private func emitLocation(_ location: CLLocation, sourceOverride: String? = nil) {
    let payload = locationPayload(location, eventType: "location.updated", sourceOverride: sourceOverride)
    uploadQueue.enqueue(payload: payload, config: uploadConfig)
    flushUploadQueue(force: false)
    eventSink?(payload)
  }

  private func locationPayload(
    _ location: CLLocation,
    eventType: String = "location.updated",
    sourceOverride: String? = nil
  ) -> [String: Any?] {
    sequence += 1
    let recordedAt = isoDate(location.timestamp)
    return [
      "type": eventType,
      "schemaVersion": 1,
      "sequence": sequence,
      "idempotencyKey": "ios-\(sequence)-\(recordedAt)",
      "rawCoordinate": [
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
      ],
      "sharedCoordinate": sharedCoordinate(location),
      "accuracyM": location.horizontalAccuracy,
      "altitudeM": location.verticalAccuracy >= 0 ? location.altitude : nil,
      "speedMps": location.speed >= 0 ? location.speed : nil,
      "headingDeg": location.course >= 0 ? location.course : nil,
      "recordedAt": recordedAt,
      "source": sourceOverride ?? locationSource(location),
      "isMocked": false,
      "batteryPercent": batteryPercent(),
      "permissionSnapshot": permissionSnapshot(),
      "consentVersion": consentVersion,
    ]
  }

  /// 공유될 좌표. 민감 장소 가림이 정밀도 하향보다 **먼저** 온다 — 순서를
  /// 바꾸면 반올림된 값이 반경 밖으로 밀려 가림을 빠져나간다.
  private func sharedCoordinate(_ location: CLLocation) -> [String: Double] {
    let places = GyeotePrivatePlaces.fromPolicy(sharingPolicy)
    if let covering = GyeotePrivatePlaces.covering(
      places,
      lat: location.coordinate.latitude,
      lng: location.coordinate.longitude
    ) {
      return ["latitude": covering.lat, "longitude": covering.lng]
    }

    switch sharingMode {
    case "area":
      return [
        "latitude": (location.coordinate.latitude * 1000).rounded() / 1000,
        "longitude": (location.coordinate.longitude * 1000).rounded() / 1000,
      ]
    case "balanced":
      return [
        "latitude": (location.coordinate.latitude * 10000).rounded() / 10000,
        "longitude": (location.coordinate.longitude * 10000).rounded() / 10000,
      ]
    default:
      return [
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
      ]
    }
  }

  private func permissionSnapshot() -> [String: Any] {
    return [
      "foregroundGranted": hasForegroundLocationPermission,
      "backgroundGranted": hasBackgroundLocationPermission,
      "preciseGranted": preciseGranted,
      "notificationsGranted": true,
      "serviceEnabled": CLLocationManager.locationServicesEnabled(),
    ]
  }

  private func emitPermissionChanged() {
    sequence += 1
    eventSink?([
      "type": "permission.changed",
      "schemaVersion": 1,
      "sequence": sequence,
      "recordedAt": isoDate(Date()),
      "source": "unknown",
      "permissionSnapshot": permissionSnapshot(),
      "consentVersion": consentVersion,
    ])
  }

  private func emitStatus(_ status: String, details: [String: Any?] = [:]) {
    sequence += 1
    var payload: [String: Any?] = [
      "type": "service.statusChanged",
      "status": status,
      "schemaVersion": 1,
      "sequence": sequence,
      "recordedAt": isoDate(Date()),
      "source": "unknown",
      "permissionSnapshot": permissionSnapshot(),
      "consentVersion": consentVersion,
    ]
    details.forEach { payload[$0.key] = $0.value }
    eventSink?(payload)
  }

  private func emitRegion(_ type: String, region: CLRegion) {
    sequence += 1
    eventSink?([
      "type": type,
      "geofenceId": region.identifier,
      "schemaVersion": 1,
      "sequence": sequence,
      "recordedAt": isoDate(Date()),
      "source": "geofence",
      "permissionSnapshot": permissionSnapshot(),
      "consentVersion": consentVersion,
    ])
  }

  private func emitError(_ code: String, _ message: String, details: [String: Any?] = [:]) {
    sequence += 1
    var payload: [String: Any?] = [
      "type": "location.error",
      "code": code,
      "message": message,
      "schemaVersion": 1,
      "sequence": sequence,
      "recordedAt": isoDate(Date()),
      "source": "unknown",
      "permissionSnapshot": permissionSnapshot(),
      "consentVersion": consentVersion,
    ]
    details.forEach { payload[$0.key] = $0.value }
    eventSink?(payload)
  }

  private func flushUploadQueue(force: Bool) {
    uploadQueue.flush(
      config: uploadConfig,
      sharingMode: sharingMode,
      companionSessionId: activeSession?["companionSessionId"] as? String,
      force: force,
      emitStatus: { [weak self] status, details in
        DispatchQueue.main.async {
          self?.emitStatus(status, details: details)
        }
      },
      emitError: { [weak self] code, message, details in
        DispatchQueue.main.async {
          self?.emitError(code, message, details: details)
        }
      }
    )
  }

  private func requestNotificationAuthorization() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
  }

  private func showPlaceAlertNotification(for eventType: String, regionId: String) {
    let center = UNUserNotificationCenter.current()
    let windows = UserDefaults.standard.dictionary(forKey: Self.quietWindowsKey) as? [String: String] ?? [:]
    // 창 안이면 소리 없이 간다. 버리지는 않는다 — "도착했다"를 자고 있었다는
    // 이유로 없앨 수는 없다.
    let quiet = GyeoteQuietHours.isQuiet(
      windows: windows,
      ids: [regionId],
      minuteOfDay: GyeoteQuietHours.currentMinuteOfDay()
    )

    center.getNotificationSettings { settings in
      guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
        return
      }

      let content = UNMutableNotificationContent()
      content.title = GyeoteNativeStrings.text("place_alert_channel")
      content.body = self.placeAlertNotificationText(for: eventType)
      content.sound = quiet ? nil : .default
      if #available(iOS 15.0, *) {
        content.interruptionLevel = quiet ? .passive : .active
      }

      let request = UNNotificationRequest(
        identifier: "gyeote.place-alert.\(UUID().uuidString)",
        content: content,
        trigger: nil
      )
      center.add(request)
    }
  }

  private func placeAlertNotificationText(for eventType: String) -> String {
    switch eventType {
    case "geofence.entered":
      return GyeoteNativeStrings.text("place_alert_arrived")
    case "geofence.exited":
      return GyeoteNativeStrings.text("place_alert_departed")
    default:
      return GyeoteNativeStrings.text("place_alert_changed")
    }
  }

  private static let quietWindowsKey = "gyeote.geofence.quiet.v1"

  private var hasForegroundLocationPermission: Bool {
    let status = authorizationStatus
    return status == .authorizedWhenInUse || status == .authorizedAlways
  }

  private var hasBackgroundLocationPermission: Bool {
    authorizationStatus == .authorizedAlways
  }

  private var preciseGranted: Bool {
    if #available(iOS 14.0, *) {
      return manager.accuracyAuthorization == .fullAccuracy
    }
    return true
  }

  private var authorizationStatus: CLAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return manager.authorizationStatus
    }
    return CLLocationManager.authorizationStatus()
  }

  private var sharingMode: String {
    sharingPolicy["mode"] as? String ?? "precise"
  }

  private var consentVersion: String {
    sharingPolicy["consentVersion"] as? String ?? "2026-05-30"
  }

  private func canCollect(allowSos: Bool) -> Bool {
    let enabled = sharingPolicy["enabled"] as? Bool ?? true
    if !enabled || sharingMode == "hidden" {
      return false
    }
    if sharingMode == "sosOnly" && !allowSos {
      return false
    }
    if isFutureIso(sharingPolicy["pausedUntil"] as? String) {
      return false
    }
    if isPastIso(sharingPolicy["expiresAt"] as? String) {
      return false
    }
    return true
  }

  private func locationSource(_ location: CLLocation) -> String {
    if location.horizontalAccuracy <= 25 {
      return "gps"
    }
    return "network"
  }

  private func batteryPercent() -> Int {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    return level >= 0 ? Int((level * 100).rounded()) : -1
  }

  private func isoDate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }

  private func isFutureIso(_ value: String?) -> Bool {
    guard let date = parseIso(value) else { return false }
    return date > Date()
  }

  private func isPastIso(_ value: String?) -> Bool {
    guard let date = parseIso(value) else { return false }
    return date < Date()
  }

  private func parseIso(_ value: String?) -> Date? {
    guard let value, !value.isEmpty else { return nil }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) {
      return date
    }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value)
  }
}

final class GyeoteIOSLocationUploadQueue {
  private let worker = DispatchQueue(label: "app.gyeote.location.uploadQueue")
  private let maxQueueItems = 120
  private let initialBackoff: TimeInterval = 15
  private let maxBackoff: TimeInterval = 5 * 60
  private let authBackoff: TimeInterval = 10 * 60
  private var isFlushing = false
  private var nextAttemptAt = Date.distantPast
  private var failureStreak = 0
  private var lastFailureCode: String?

  func enqueue(payload: [String: Any?], config: [String: Any?]?) {
    guard hasRequiredConfig(config) else { return }
    let jsonPayload = normalizedPayload(payload)

    worker.async {
      var queue = self.readQueue()
      queue.append(jsonPayload)
      if queue.count > self.maxQueueItems {
        queue = Array(queue.suffix(self.maxQueueItems))
      }
      self.writeQueue(queue)
    }
  }

  func resetBackoff() {
    worker.async {
      self.failureStreak = 0
      self.nextAttemptAt = .distantPast
      self.lastFailureCode = nil
    }
  }

  func flush(
    config: [String: Any?]?,
    sharingMode: String,
    companionSessionId: String?,
    force: Bool,
    emitStatus: @escaping (String, [String: Any?]) -> Void,
    emitError: @escaping (String, String, [String: Any?]) -> Void
  ) {
    worker.async {
      let now = Date()
      if !force && self.nextAttemptAt > now {
        emitStatus("upload_retry_wait", [
          "pendingCount": self.readQueue().count,
          "retryInSeconds": max(1, Int(ceil(self.nextAttemptAt.timeIntervalSince(now)))),
          "failureCode": self.lastFailureCode,
        ])
        return
      }

      if self.isFlushing {
        emitStatus("upload_already_running", ["pendingCount": self.readQueue().count])
        return
      }

      self.isFlushing = true
      defer { self.isFlushing = false }

      guard self.hasRequiredConfig(config), let config else {
        emitStatus("upload_not_configured", ["pendingCount": self.readQueue().count])
        return
      }

      let queue = self.readQueue()
      if queue.isEmpty {
        self.failureStreak = 0
        self.nextAttemptAt = .distantPast
        self.lastFailureCode = nil
        emitStatus("upload_queue_empty", ["pendingCount": 0])
        return
      }

      var remaining: [[String: Any]] = []
      var uploadedCount = 0
      var firstFailure: UploadFailure?

      for (index, payload) in queue.enumerated() {
        do {
          try self.uploadPayload(
            config: config,
            payload: payload,
            sharingMode: sharingMode,
            companionSessionId: companionSessionId
          )
          uploadedCount += 1
        } catch let error as UploadFailure {
          firstFailure = error
          remaining.append(payload)
          remaining.append(contentsOf: queue.dropFirst(index + 1))
          break
        } catch {
          firstFailure = UploadFailure(code: "upload_failed", message: error.localizedDescription)
          remaining.append(payload)
          remaining.append(contentsOf: queue.dropFirst(index + 1))
          break
        }
      }

      self.writeQueue(remaining)

      guard let failure = firstFailure else {
        self.failureStreak = 0
        self.nextAttemptAt = .distantPast
        self.lastFailureCode = nil
        emitStatus("upload_flushed", [
          "uploadedCount": uploadedCount,
          "pendingCount": 0,
        ])
        return
      }

      let retryInSeconds = self.registerFailure(failure)
      let details: [String: Any?] = [
        "uploadedCount": uploadedCount,
        "pendingCount": remaining.count,
        "retryInSeconds": retryInSeconds,
        "httpStatus": failure.httpStatus,
      ]

      if failure.authRelated {
        emitError(
          "upload_auth_failed",
          GyeoteNativeStrings.text("upload_auth_expired"),
          details
        )
      } else {
        var retryDetails = details
        retryDetails["failureCode"] = failure.code
        emitStatus("upload_retry_scheduled", retryDetails)
      }
    }
  }

  private func uploadPayload(
    config: [String: Any?],
    payload: [String: Any],
    sharingMode: String,
    companionSessionId: String?
  ) throws {
    let latestRow = rowFromPayload(
      config: config,
      payload: payload,
      sharingMode: sharingMode,
      companionSessionId: companionSessionId,
      includeHistoryFields: false
    )
    let historyRow = rowFromPayload(
      config: config,
      payload: payload,
      sharingMode: sharingMode,
      companionSessionId: companionSessionId,
      includeHistoryFields: true
    )

    try postgrestRequest(
      config: config,
      path: "/rest/v1/latest_locations?on_conflict=profile_id",
      body: latestRow,
      prefer: "resolution=merge-duplicates,return=minimal"
    )
    try postgrestRequest(
      config: config,
      path: "/rest/v1/location_history?on_conflict=profile_id,idempotency_key",
      body: [historyRow],
      prefer: "resolution=ignore-duplicates,return=minimal"
    )
  }

  private func rowFromPayload(
    config: [String: Any?],
    payload: [String: Any],
    sharingMode: String,
    companionSessionId: String?,
    includeHistoryFields: Bool
  ) -> [String: Any] {
    // 원시 좌표는 올리지 않는다. 페이로드에는 남아 있지만 그건 기기 안에서
    // 민감 장소를 판정하는 용도다. 018 이 그 칸을 없앴으므로 여기 남아 있으면
    // insert 자체가 거절되고, 그 결과는 iOS 위치 업로드 전면 중단이다.
    let sharedCoordinate = payload["sharedCoordinate"] as? [String: Any]
    let sharingPrecision = sharingPrecisionFromMode(sharingMode)
    let hideSharedCoordinate = sharingPrecision == "hidden"
    let recordedAt = payload["recordedAt"] as? String ?? isoDate(Date())

    var row: [String: Any] = [
      "profile_id": configString(config, "profileId") ?? "",
      "device_id": configString(config, "deviceId") ?? "",
      "source": payload["source"] as? String ?? "unknown",
      "shared_lat": hideSharedCoordinate ? NSNull() : number(sharedCoordinate?["latitude"]) ?? NSNull(),
      "shared_lng": hideSharedCoordinate ? NSNull() : number(sharedCoordinate?["longitude"]) ?? NSNull(),
      "accuracy_m": number(payload["accuracyM"]) ?? NSNull(),
      "sharing_precision": sharingPrecision,
      "recorded_at": recordedAt,
    ]

    if includeHistoryFields {
      row["idempotency_key"] = idempotencyKey(config: config, payload: payload, recordedAt: recordedAt)
      row["companion_session_id"] = companionSessionId ?? NSNull()
    } else {
      row["updated_at"] = isoDate(Date())
      row["speed_mps"] = number(payload["speedMps"]) ?? NSNull()
      row["heading_deg"] = number(payload["headingDeg"]) ?? NSNull()
      row["battery_percent"] = intNumber(payload["batteryPercent"]) ?? NSNull()
    }

    return row
  }

  private func postgrestRequest(
    config: [String: Any?],
    path: String,
    body: Any,
    prefer: String
  ) throws {
    guard let supabaseUrl = configString(config, "supabaseUrl")?.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
          let publishableKey = configString(config, "publishableKey"),
          let accessToken = configString(config, "accessToken"),
          let url = URL(string: "\(supabaseUrl)\(path)") else {
      throw UploadFailure(code: "upload_not_configured", message: "Supabase upload config is incomplete.")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 15
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(publishableKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue(prefer, forHTTPHeaderField: "Prefer")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let semaphore = DispatchSemaphore(value: 0)
    var responseStatus = 0
    var responseBody = ""
    var responseError: Error?

    URLSession.shared.dataTask(with: request) { data, response, error in
      responseError = error
      responseStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
      if let data {
        responseBody = String(data: data, encoding: .utf8) ?? ""
      }
      semaphore.signal()
    }.resume()

    _ = semaphore.wait(timeout: .now() + 20)

    if let responseError {
      throw UploadFailure(code: "upload_network_failed", message: responseError.localizedDescription)
    }
    if !(200...299).contains(responseStatus) {
      throw UploadFailure(
        code: responseStatus == 401 || responseStatus == 403 ? "upload_auth_failed" : "upload_http_\(responseStatus)",
        message: responseBody.isEmpty ? "Supabase upload failed with HTTP \(responseStatus)." : responseBody,
        authRelated: responseStatus == 401 || responseStatus == 403,
        httpStatus: responseStatus
      )
    }
  }

  private func readQueue() -> [[String: Any]] {
    let url = queueFileURL()
    guard FileManager.default.fileExists(atPath: url.path),
          let data = try? Data(contentsOf: url),
          let object = try? JSONSerialization.jsonObject(with: data),
          let json = object as? [[String: Any]] else {
      return []
    }
    return json
  }

  private func writeQueue(_ queue: [[String: Any]]) {
    let url = queueFileURL()
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let data = try? JSONSerialization.data(withJSONObject: queue) else { return }
    try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  private func queueFileURL() -> URL {
    let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return baseURL.appendingPathComponent("gyeote_location_upload_queue.json")
  }

  private func hasRequiredConfig(_ config: [String: Any?]?) -> Bool {
    guard let config else { return false }
    return ["supabaseUrl", "publishableKey", "accessToken", "profileId", "deviceId"].allSatisfy {
      !(configString(config, $0)?.isEmpty ?? true)
    }
  }

  private func normalizedPayload(_ payload: [String: Any?]) -> [String: Any] {
    var result: [String: Any] = [:]
    payload.forEach { key, value in
      result[key] = jsonValue(value)
    }
    return result
  }

  private func jsonValue(_ value: Any?) -> Any {
    guard let value else { return NSNull() }
    if let dictionary = value as? [String: Any?] {
      var result: [String: Any] = [:]
      dictionary.forEach { result[$0.key] = jsonValue($0.value) }
      return result
    }
    if let dictionary = value as? [String: Any] {
      var result: [String: Any] = [:]
      dictionary.forEach { result[$0.key] = jsonValue($0.value) }
      return result
    }
    if let array = value as? [Any?] {
      return array.map { jsonValue($0) }
    }
    return value
  }

  private func configString(_ config: [String: Any?], _ key: String) -> String? {
    guard let wrapped = config[key], let value = wrapped else { return nil }
    let string = "\(value)"
    return string.isEmpty ? nil : string
  }

  private func number(_ value: Any?) -> Double? {
    if let number = value as? NSNumber {
      let result = number.doubleValue
      return result.isFinite ? result : nil
    }
    if let string = value as? String, let result = Double(string), result.isFinite {
      return result
    }
    return nil
  }

  private func intNumber(_ value: Any?) -> Int? {
    if let number = value as? NSNumber {
      return number.intValue
    }
    if let string = value as? String {
      return Int(string)
    }
    return nil
  }

  private func sharingPrecisionFromMode(_ mode: String) -> String {
    mode == "sosOnly" ? "sos_only" : mode
  }

  private func idempotencyKey(config: [String: Any?], payload: [String: Any], recordedAt: String) -> String {
    let deviceId = configString(config, "deviceId") ?? "ios"
    if let existing = payload["idempotencyKey"] as? String, existing.hasPrefix("\(deviceId)-") {
      return existing
    }
    let sequence = intNumber(payload["sequence"]) ?? 0
    return "\(deviceId)-\(sequence)-\(recordedAt)"
  }

  private func registerFailure(_ failure: UploadFailure) -> Int {
    failureStreak = min(failureStreak + 1, 6)
    lastFailureCode = failure.code
    let retrySeconds: TimeInterval
    if failure.authRelated {
      retrySeconds = authBackoff
    } else {
      retrySeconds = min(initialBackoff * pow(2, Double(failureStreak - 1)), maxBackoff)
    }
    nextAttemptAt = Date().addingTimeInterval(retrySeconds)
    return max(1, Int(ceil(retrySeconds)))
  }

  private func isoDate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }

  private struct UploadFailure: Error {
    let code: String
    let message: String
    var authRelated = false
    var httpStatus: Int?
  }
}

// MARK: - GyeotePortable (Foundation only)
//
// 이 구역은 Apple 프레임워크를 쓰지 않는다. 이유는 검증이다. 이 워크스페이스는
// Windows 라 Xcode 가 없지만, Foundation 만 쓰는 코드는 Swift for Windows 로
// 컴파일하고 돌려 볼 수 있다. `tools/check_ios_logic.py` 가 아래 구역을 잘라내
// `tools/ios_logic_tests.swift` 와 함께 빌드한다. 새 파일로 빼지 않는 것은
// pbxproj 등록이 필요해서다 — Xcode 없이 손으로 만지면 프로젝트가 깨진다.
//
// 이 구역에서 UIKit·CoreLocation·UserNotifications 를 import 하거나 참조하면
// 검증이 불가능해진다. 그런 것은 위쪽 클래스에 둔다.

/// 정확한 좌표를 내보내지 않을 장소. 안드로이드 `GyeotePrivatePlaces` 와 같은
/// 규칙이다: 반올림이 아니라 **중심으로 스냅**한다. 이름은 받지 않는다.
enum GyeotePrivatePlaces {
  struct Place: Equatable {
    let lat: Double
    let lng: Double
    let radiusM: Double
  }

  private static let earthRadiusM = 6371008.8

  /// 형태가 어긋난 항목은 조용히 버린다. 여기서 죽으면 위치 수집이 멈춘다.
  static func fromPolicy(_ policy: [String: Any?]) -> [Place] {
    guard let raw = policy["privatePlaces"] as? [Any] else { return [] }
    return raw.compactMap { entry in
      guard let map = entry as? [String: Any],
            let lat = doubleValue(map["lat"]),
            let lng = doubleValue(map["lng"]),
            let radius = doubleValue(map["radiusM"]),
            radius > 0 else {
        return nil
      }
      return Place(lat: lat, lng: lng, radiusM: radius)
    }
  }

  /// 이 좌표를 감싸는 장소. 겹치면 중심이 가장 가까운 것.
  static func covering(_ places: [Place], lat: Double, lng: Double) -> Place? {
    var best: Place?
    var bestDistance = Double.greatestFiniteMagnitude
    for place in places {
      let distance = distanceMeters(place.lat, place.lng, lat, lng)
      if distance <= place.radiusM && distance < bestDistance {
        best = place
        bestDistance = distance
      }
    }
    return best
  }

  static func mask(_ places: [Place], lat: Double, lng: Double) -> (lat: Double, lng: Double) {
    guard let place = covering(places, lat: lat, lng: lng) else { return (lat, lng) }
    return (place.lat, place.lng)
  }

  static func distanceMeters(_ lat1: Double, _ lng1: Double, _ lat2: Double, _ lng2: Double) -> Double {
    let phi1 = lat1 * .pi / 180
    let phi2 = lat2 * .pi / 180
    let dPhi = phi2 - phi1
    let dLambda = (lng2 - lng1) * .pi / 180
    let h = sin(dPhi / 2) * sin(dPhi / 2) + cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2)
    return 2 * earthRadiusM * asin(min(1, sqrt(h)))
  }

  private static func doubleValue(_ value: Any?) -> Double? {
    if let d = value as? Double { return d }
    if let i = value as? Int { return Double(i) }
    if let n = value as? NSNumber { return n.doubleValue }
    return nil
  }
}

/// 장소 알림의 조용한 시간. 안드로이드 `GyeoteQuietHours` 와 같은 규칙이다.
/// 창 안이라고 알림을 버리지 않는다 — 소리만 없앤다.
enum GyeoteQuietHours {
  struct Window: Equatable {
    let startMinute: Int
    let endMinute: Int

    /// 22:00–07:00 처럼 자정을 넘는 창은 "start 이후 **또는** end 이전"이다.
    /// "그리고"로 쓰면 야간 창이 한 번도 켜지지 않는다.
    func contains(_ minuteOfDay: Int) -> Bool {
      if startMinute <= endMinute {
        return minuteOfDay >= startMinute && minuteOfDay < endMinute
      }
      return minuteOfDay >= startMinute || minuteOfDay < endMinute
    }
  }

  /// "HH:mm" → 하루 안의 분. 형태가 어긋나면 nil — 창을 만들지 않는다.
  static func parseMinute(_ value: String?) -> Int? {
    guard let value else { return nil }
    let parts = value.split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count == 2,
          let hour = Int(parts[0]),
          let minute = Int(parts[1]),
          (0...23).contains(hour),
          (0...59).contains(minute) else {
      return nil
    }
    return hour * 60 + minute
  }

  static func windowOf(_ start: String?, _ end: String?) -> Window? {
    guard let s = parseMinute(start), let e = parseMinute(end), s != e else { return nil }
    return Window(startMinute: s, endMinute: e)
  }

  /// 등록 페이로드에서 id → "start|end". 창이 없는 항목은 들어가지 않는다.
  static func windows(from geofences: [[String: Any]]) -> [String: String] {
    var result: [String: String] = [:]
    for geofence in geofences {
      guard let id = geofence["id"] as? String else { continue }
      let start = geofence["quietStart"] as? String
      let end = geofence["quietEnd"] as? String
      if let start, let end, windowOf(start, end) != nil {
        result[String(id.prefix(100))] = "\(start)|\(end)"
      }
    }
    return result
  }

  /// 겹친 지오펜스 중 하나라도 조용하면 조용하다.
  static func isQuiet(windows: [String: String], ids: [String], minuteOfDay: Int) -> Bool {
    for id in ids {
      guard let entry = windows[id] else { continue }
      let parts = entry.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
      guard parts.count == 2, let window = windowOf(parts[0], parts[1]) else { continue }
      if window.contains(minuteOfDay) { return true }
    }
    return false
  }

  static func currentMinuteOfDay(now: Date = Date(), calendar: Calendar = .current) -> Int {
    let parts = calendar.dateComponents([.hour, .minute], from: now)
    return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
  }
}

/// 네이티브 알림 문구.
///
/// Localizable.strings 로 가는 것이 정석이지만 그 파일은 pbxproj 등록이 필요하고,
/// 이 워크스페이스에는 Xcode 가 없다. 그래서 표를 코드에 둔다. 키는 안드로이드
/// `res/values/strings.xml` 과 같게 유지한다 — 두 플랫폼의 문구가 갈리면
/// 갈린 쪽이 틀린 것이다.
enum GyeoteNativeStrings {
  private static let table: [String: [String: String]] = [
    "place_alert_channel": ["en": "Place alerts", "ko": "장소 알림"],
    "place_alert_arrived": ["en": "Arrived at a saved place.", "ko": "저장한 장소 반경에 도착했습니다."],
    "place_alert_departed": ["en": "Left a saved place.", "ko": "저장한 장소 반경을 벗어났습니다."],
    "place_alert_changed": ["en": "A saved place boundary changed.", "ko": "저장한 장소 반경 변화가 감지됐습니다."],
    "upload_auth_expired": [
      "en": "Location upload sign-in expired. Open Gyeote to reconnect.",
      "ko": "위치 업로드 인증이 만료됐어요. 앱을 열어 다시 연결해 주세요.",
    ],
  ]

  static func text(_ key: String, languages: [String] = Locale.preferredLanguages) -> String {
    guard let entry = table[key] else { return key }
    for language in languages {
      let code = String(language.prefix(2)).lowercased()
      if let value = entry[code] { return value }
    }
    return entry["en"] ?? key
  }
}
// MARK: - end GyeotePortable
