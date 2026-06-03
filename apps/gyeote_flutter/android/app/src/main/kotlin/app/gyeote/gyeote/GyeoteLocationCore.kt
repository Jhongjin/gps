package app.gyeote.gyeote

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.google.android.gms.location.Geofence
import io.flutter.plugin.common.EventChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.round

object GyeoteLocationState {
    @Volatile
    var sharingPolicy: Map<String, Any?> = mapOf(
        "enabled" to true,
        "mode" to "precise",
        "consentVersion" to "2026-05-30",
    )

    @Volatile
    var activeSession: Map<String, Any?>? = null

    @Volatile
    var lastLocation: Location? = null

    @Volatile
    var serviceActive: Boolean = false

    @Volatile
    var uploadConfig: Map<String, Any?>? = null
}

object GyeoteLocationEvents {
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    @Volatile
    private var sequence = 0L

    fun attach(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun detach() {
        eventSink = null
    }

    fun nextSequence(): Long {
        sequence += 1
        return sequence
    }

    fun emit(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }
}

object GyeoteLocationPayloads {
    fun locationPayload(
        context: Context,
        locationManager: LocationManager,
        location: Location,
        eventType: String = "location.updated",
        sourceOverride: String? = null,
    ): Map<String, Any?> {
        val sequence = GyeoteLocationEvents.nextSequence()
        val recordedAt = isoDate(location.time.takeIf { it > 0L } ?: System.currentTimeMillis())
        val source = sourceOverride ?: providerSource(location.provider)
        val rawCoordinate = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
        )

        GyeoteLocationState.lastLocation = location

        return mapOf(
            "type" to eventType,
            "schemaVersion" to 1,
            "sequence" to sequence,
            "idempotencyKey" to "android-$sequence-$recordedAt",
            "rawCoordinate" to rawCoordinate,
            "sharedCoordinate" to sharedCoordinate(location),
            "accuracyM" to location.accuracy.toDouble(),
            "altitudeM" to if (location.hasAltitude()) location.altitude else null,
            "speedMps" to if (location.hasSpeed()) location.speed.toDouble() else null,
            "headingDeg" to if (location.hasBearing()) location.bearing.toDouble() else null,
            "recordedAt" to recordedAt,
            "source" to source,
            "isMocked" to isMocked(location),
            "batteryPercent" to batteryPercent(context),
            "permissionSnapshot" to permissionSnapshot(context, locationManager),
            "consentVersion" to consentVersion(),
        )
    }

    fun permissionSnapshot(context: Context, locationManager: LocationManager): Map<String, Any?> {
        return mapOf(
            "foregroundGranted" to hasForegroundLocationPermission(context),
            "backgroundGranted" to hasBackgroundLocationPermission(context),
            "preciseGranted" to hasFineLocationPermission(context),
            "notificationsGranted" to hasNotificationPermission(context),
            "serviceEnabled" to isLocationServiceEnabled(locationManager),
        )
    }

    fun emitPermissionChanged(context: Context, locationManager: LocationManager) {
        GyeoteLocationEvents.emit(
            baseEvent(context, locationManager, "permission.changed"),
        )
    }

    fun emitStatus(
        context: Context,
        locationManager: LocationManager,
        status: String,
        details: Map<String, Any?> = emptyMap(),
    ) {
        GyeoteLocationEvents.emit(
            baseEvent(context, locationManager, "service.statusChanged") +
                ("status" to status) +
                details,
        )
    }

    fun emitError(
        context: Context,
        locationManager: LocationManager,
        code: String,
        message: String,
        details: Map<String, Any?> = emptyMap(),
    ) {
        GyeoteLocationEvents.emit(
            baseEvent(context, locationManager, "location.error") +
                ("code" to code) +
                ("message" to message) +
                details,
        )
    }

    fun emitGeofenceTransition(
        context: Context,
        locationManager: LocationManager,
        eventType: String,
        transition: Int,
        requestIds: List<String>,
    ) {
        GyeoteLocationEvents.emit(
            baseEvent(context, locationManager, eventType) +
                ("source" to "geofence") +
                ("geofenceTransition" to geofenceTransitionLabel(transition)) +
                ("geofenceIds" to requestIds) +
                ("geofenceId" to requestIds.firstOrNull()),
        )
    }

    fun canCollect(allowSos: Boolean): Boolean {
        val policy = GyeoteLocationState.sharingPolicy
        val enabled = policy["enabled"] as? Boolean ?: true
        val mode = sharingMode()
        if (!enabled) return false
        if (mode == "hidden") return false
        if (mode == "sosOnly" && !allowSos) return false
        if (isFutureIso(policy["pausedUntil"] as? String)) return false
        if (isPastIso(policy["expiresAt"] as? String)) return false
        return true
    }

    fun hasForegroundLocationPermission(context: Context): Boolean {
        return hasFineLocationPermission(context) || checkSelfPermissionCompat(context, Manifest.permission.ACCESS_COARSE_LOCATION)
    }

    fun hasFineLocationPermission(context: Context): Boolean {
        return checkSelfPermissionCompat(context, Manifest.permission.ACCESS_FINE_LOCATION)
    }

    fun hasBackgroundLocationPermission(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            checkSelfPermissionCompat(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
    }

    fun hasNotificationPermission(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermissionCompat(context, Manifest.permission.POST_NOTIFICATIONS)
    }

    fun isLocationServiceEnabled(locationManager: LocationManager): Boolean {
        return try {
            locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        } catch (_: Exception) {
            false
        }
    }

    private fun baseEvent(context: Context, locationManager: LocationManager, type: String): Map<String, Any?> {
        return mapOf(
            "type" to type,
            "schemaVersion" to 1,
            "sequence" to GyeoteLocationEvents.nextSequence(),
            "recordedAt" to isoDate(System.currentTimeMillis()),
            "source" to "unknown",
            "permissionSnapshot" to permissionSnapshot(context, locationManager),
            "consentVersion" to consentVersion(),
        )
    }

    private fun sharedCoordinate(location: Location): Map<String, Double> {
        return when (sharingMode()) {
            "area" -> mapOf(
                "latitude" to round(location.latitude * 1000.0) / 1000.0,
                "longitude" to round(location.longitude * 1000.0) / 1000.0,
            )
            "balanced" -> mapOf(
                "latitude" to round(location.latitude * 10000.0) / 10000.0,
                "longitude" to round(location.longitude * 10000.0) / 10000.0,
            )
            else -> mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
            )
        }
    }

    private fun checkSelfPermissionCompat(context: Context, permission: String): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun sharingMode(): String {
        return GyeoteLocationState.sharingPolicy["mode"] as? String ?: "precise"
    }

    private fun consentVersion(): String {
        return GyeoteLocationState.sharingPolicy["consentVersion"] as? String ?: "2026-05-30"
    }

    private fun providerSource(provider: String?): String {
        return when (provider) {
            LocationManager.GPS_PROVIDER -> "gps"
            LocationManager.NETWORK_PROVIDER -> "network"
            else -> "unknown"
        }
    }

    private fun geofenceTransitionLabel(transition: Int): String {
        return when (transition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> "enter"
            Geofence.GEOFENCE_TRANSITION_EXIT -> "exit"
            Geofence.GEOFENCE_TRANSITION_DWELL -> "dwell"
            else -> "unknown"
        }
    }

    private fun batteryPercent(context: Context): Int? {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager ?: return null
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY).takeIf { it >= 0 }
    }

    private fun isMocked(location: Location): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            location.isMock
        } else {
            @Suppress("DEPRECATION")
            location.isFromMockProvider
        }
    }

    private fun isoDate(timeMs: Long): String {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return format.format(Date(timeMs))
    }

    private fun isFutureIso(value: String?): Boolean {
        val parsed = parseIso(value) ?: return false
        return parsed.time > System.currentTimeMillis()
    }

    private fun isPastIso(value: String?): Boolean {
        val parsed = parseIso(value) ?: return false
        return parsed.time < System.currentTimeMillis()
    }

    private fun parseIso(value: String?): Date? {
        if (value.isNullOrBlank()) return null
        val normalized = value.replace(Regex("(\\.\\d{3})\\d+Z$"), "$1Z")
        val formats = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
        )

        return formats.firstNotNullOfOrNull { pattern ->
            runCatching {
                val format = SimpleDateFormat(pattern, Locale.US)
                format.timeZone = TimeZone.getTimeZone("UTC")
                format.parse(normalized)
            }.getOrNull()
        }
    }
}
