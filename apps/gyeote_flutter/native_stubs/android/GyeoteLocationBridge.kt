package app.gyeote.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Instant

class GyeoteLocationBridge : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var sequence = 0
    private var sharingPolicy: Map<String, Any?> = mapOf(
        "enabled" to false,
        "mode" to "hidden",
        "consentVersion" to "2026-05-30"
    )

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "app.gyeote/location")
        eventChannel = EventChannel(binding.binaryMessenger, "app.gyeote/location_events")
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPermissionSnapshot" -> result.success(permissionSnapshot())
            "requestWhenInUse" -> result.success(null)
            "requestAlways" -> result.success(null)
            "startLocationSession" -> {
                startLocationSession(call.arguments)
                result.success(null)
            }
            "stopLocationSession" -> {
                stopLocationSession()
                result.success(null)
            }
            "setSharingPolicy" -> {
                sharingPolicy = call.arguments as? Map<String, Any?> ?: sharingPolicy
                result.success(null)
            }
            "getLastKnownLocation" -> result.success(null)
            "registerGeofences" -> {
                emitServiceEvent("service.statusChanged", mapOf("state" to "geofencesRegistered"))
                result.success(null)
            }
            "flushPendingLocations" -> {
                emitServiceEvent("service.statusChanged", mapOf("state" to "flushRequested"))
                result.success(null)
            }
            "requestSosFix" -> {
                emitServiceEvent("service.statusChanged", mapOf("state" to "sosFixRequested"))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        emitServiceEvent("service.statusChanged", mapOf("state" to "listening"))
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startLocationSession(arguments: Any?) {
        if (!ordinaryCollectionAllowed()) {
            emitServiceEvent("location.error", mapOf("code" to "policy_paused"))
            return
        }

        emitServiceEvent("service.statusChanged", mapOf("state" to "startRequested"))
        // Wire this to a foreground service and Fused Location Provider in the generated Android project.
    }

    private fun stopLocationSession() {
        emitServiceEvent("service.statusChanged", mapOf("state" to "stopped"))
        // Stop the foreground service, remove active callbacks, and flush the local queue.
    }

    private fun ordinaryCollectionAllowed(): Boolean {
        val enabled = sharingPolicy["enabled"] as? Boolean ?: false
        val mode = sharingPolicy["mode"] as? String ?: "hidden"
        return enabled && mode != "hidden" && mode != "sosOnly" && !isPolicyPaused() && !isPolicyExpired()
    }

    private fun locationEvent(location: Location): Map<String, Any?> {
        val sequence = nextSequence()
        val coordinate = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude
        )
        return baseEvent("location.updated", sequence) + mapOf(
            "idempotencyKey" to "android:$sequence:${location.time}",
            "rawCoordinate" to coordinate,
            "sharedCoordinate" to coordinate,
            "accuracyM" to location.accuracy.toDouble(),
            "speedMps" to location.speed.toDouble(),
            "headingDeg" to location.bearing.toDouble(),
            "recordedAt" to Instant.ofEpochMilli(location.time).toString(),
            "source" to "gps",
            "isMocked" to location.isFromMockProvider
        )
    }

    private fun emitServiceEvent(type: String, details: Map<String, Any?>) {
        eventSink?.success(baseEvent(type) + details)
    }

    private fun baseEvent(type: String, sequence: Int = nextSequence()): Map<String, Any?> {
        return mapOf(
            "type" to type,
            "schemaVersion" to 1,
            "sequence" to sequence,
            "recordedAt" to Instant.now().toString(),
            "source" to "unknown",
            "permissionSnapshot" to permissionSnapshot(),
            "consentVersion" to (sharingPolicy["consentVersion"] ?: "2026-05-30")
        )
    }

    private fun permissionSnapshot(): Map<String, Any?> {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val fineGranted = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        val coarseGranted = hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        val notificationsGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            hasPermission(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            true
        }
        val serviceEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
            locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        return mapOf(
            "foregroundGranted" to (fineGranted || coarseGranted),
            "backgroundGranted" to hasPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
            "preciseGranted" to fineGranted,
            "notificationsGranted" to notificationsGranted,
            "serviceEnabled" to serviceEnabled
        )
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun nextSequence(): Int {
        sequence += 1
        return sequence
    }

    private fun isPolicyPaused(): Boolean {
        val raw = sharingPolicy["pausedUntil"] as? String ?: return false
        return runCatching { Instant.parse(raw).isAfter(Instant.now()) }.getOrDefault(false)
    }

    private fun isPolicyExpired(): Boolean {
        val raw = sharingPolicy["expiresAt"] as? String ?: return false
        return runCatching { !Instant.parse(raw).isAfter(Instant.now()) }.getOrDefault(false)
    }
}
