package app.gyeote.gyeote

import android.Manifest
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import kotlin.math.max

class LocationForegroundService : Service() {
    private lateinit var locationManager: LocationManager
    private var sosOnlyRequest = false

    private val locationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) {
            if (!GyeoteLocationPayloads.canCollect(allowSos = activeMode() == "sos" || sosOnlyRequest)) {
                stopLocationUpdates()
                GyeoteLocationPayloads.emitStatus(this@LocationForegroundService, locationManager, "policy_paused")
                stopSelf()
                return
            }

            val payload = GyeoteLocationPayloads.locationPayload(this@LocationForegroundService, locationManager, location)
            GyeoteLocationUploadQueue.enqueue(this@LocationForegroundService, payload)
            GyeoteLocationUploadQueue.flushAsync(this@LocationForegroundService, locationManager)
            GyeoteLocationEvents.emit(payload)
            if (sosOnlyRequest && activeMode() != "sos") {
                sosOnlyRequest = false
                stopSelf()
            }
        }

        override fun onProviderEnabled(provider: String) {
            GyeoteLocationPayloads.emitStatus(this@LocationForegroundService, locationManager, "provider_enabled")
        }

        override fun onProviderDisabled(provider: String) {
            GyeoteLocationPayloads.emitError(this@LocationForegroundService, locationManager, "provider_disabled", "$provider is disabled.")
        }
    }

    override fun onCreate() {
        super.onCreate()
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopLocationUpdates()
                GyeoteLocationPayloads.emitStatus(this, locationManager, "stopped")
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_SOS -> {
                sosOnlyRequest = true
                startForegroundSafely(getString(R.string.sharing_status_sos))
                requestSosFix()
            }
            ACTION_POLICY_CHANGED -> {
                if (!GyeoteLocationPayloads.canCollect(allowSos = false)) {
                    stopLocationUpdates()
                    stopSelf()
                } else if (GyeoteLocationState.serviceActive) {
                    startForegroundSafely(getString(R.string.sharing_status_policy))
                }
            }
            else -> {
                startForegroundSafely(getString(R.string.sharing_status_companion))
                startLocationUpdates()
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        stopLocationUpdates()
        GyeoteLocationState.serviceActive = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    @SuppressLint("MissingPermission")
    private fun startLocationUpdates() {
        if (!GyeoteLocationPayloads.hasForegroundLocationPermission(this)) {
            GyeoteLocationPayloads.emitError(this, locationManager, "permission_denied", "Location permission is required.")
            stopSelf()
            return
        }
        if (!GyeoteLocationPayloads.canCollect(allowSos = activeMode() == "sos")) {
            GyeoteLocationPayloads.emitError(this, locationManager, "policy_paused", "Sharing policy does not allow collection.")
            stopSelf()
            return
        }
        if (!GyeoteLocationPayloads.isLocationServiceEnabled(locationManager)) {
            GyeoteLocationPayloads.emitError(this, locationManager, "provider_disabled", "Location service is disabled.")
            stopSelf()
            return
        }

        stopLocationUpdates()

        val config = GyeoteLocationState.activeSession
        val minDistanceM = (config?.get("minDistanceM") as? Number)?.toFloat() ?: 25f
        val minIntervalSeconds = (config?.get("minIntervalSeconds") as? Number)?.toLong() ?: 20L
        val minTimeMs = max(5L, minIntervalSeconds) * 1000L
        val providers = locationManager.getProviders(true).filter {
            it == LocationManager.GPS_PROVIDER || it == LocationManager.NETWORK_PROVIDER
        }

        providers.forEach { provider ->
            locationManager.requestLocationUpdates(provider, minTimeMs, minDistanceM, locationListener, Looper.getMainLooper())
        }

        lastKnownLocation()?.let {
            val payload = GyeoteLocationPayloads.locationPayload(this, locationManager, it)
            GyeoteLocationUploadQueue.enqueue(this, payload)
            GyeoteLocationUploadQueue.flushAsync(this, locationManager)
            GyeoteLocationEvents.emit(payload)
        }
        GyeoteLocationState.serviceActive = true
        GyeoteLocationPayloads.emitStatus(this, locationManager, "started")
    }

    private fun stopLocationUpdates() {
        try {
            locationManager.removeUpdates(locationListener)
        } catch (_: SecurityException) {
            // Permission may have been revoked while updates were active.
        }
        GyeoteLocationState.serviceActive = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    @SuppressLint("MissingPermission")
    private fun requestSosFix() {
        if (!GyeoteLocationPayloads.hasForegroundLocationPermission(this)) {
            GyeoteLocationPayloads.emitError(this, locationManager, "permission_denied", "Location permission is required.")
            stopSelf()
            return
        }

        val provider = when {
            locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
            locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
            else -> null
        }

        if (provider == null) {
            GyeoteLocationPayloads.emitError(this, locationManager, "provider_disabled", "Location service is disabled.")
            stopSelf()
            return
        }

        locationManager.requestSingleUpdate(provider, locationListener, Looper.getMainLooper())
        GyeoteLocationPayloads.emitStatus(this, locationManager, "sos_requested")
    }

    @SuppressLint("MissingPermission")
    private fun lastKnownLocation(): Location? {
        if (!GyeoteLocationPayloads.hasForegroundLocationPermission(this)) {
            return null
        }

        return locationManager.getProviders(true)
            .mapNotNull { provider ->
                try {
                    locationManager.getLastKnownLocation(provider)
                } catch (_: SecurityException) {
                    null
                } catch (_: IllegalArgumentException) {
                    null
                }
            }
            .maxByOrNull { it.time }
    }

    private fun startForegroundSafely(message: String) {
        val notification = buildNotification(message)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (error: SecurityException) {
            GyeoteLocationPayloads.emitError(this, locationManager, "permission_denied", error.message ?: "Foreground location permission is required.")
            stopSelf()
        }
    }

    private fun buildNotification(message: String): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val pendingIntent = PendingIntent.getActivity(this, 0, launchIntent, flags)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(getString(R.string.sharing_channel))
            .setContentText(message)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.sharing_channel),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.sharing_channel_description)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun activeMode(): String? {
        return GyeoteLocationState.activeSession?.get("mode") as? String
    }

    companion object {
        const val ACTION_START = "app.gyeote.location.START"
        const val ACTION_STOP = "app.gyeote.location.STOP"
        const val ACTION_SOS = "app.gyeote.location.SOS"
        const val ACTION_POLICY_CHANGED = "app.gyeote.location.POLICY_CHANGED"

        private const val CHANNEL_ID = "gyeote_location_sharing"
        private const val NOTIFICATION_ID = 4201
    }
}
