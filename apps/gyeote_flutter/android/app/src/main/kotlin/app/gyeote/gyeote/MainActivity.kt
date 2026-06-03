package app.gyeote.gyeote

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "app.gyeote/location"
    private val eventChannelName = "app.gyeote/location_events"
    private val whenInUseRequestCode = 4101
    private val alwaysRequestCode = 4102

    private lateinit var locationManager: LocationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getPermissionSnapshot" -> result.success(GyeoteLocationPayloads.permissionSnapshot(this, locationManager))
                    "requestWhenInUse" -> {
                        requestWhenInUse()
                        result.success(null)
                    }
                    "requestAlways" -> {
                        requestAlways()
                        result.success(null)
                    }
                    "startLocationSession" -> {
                        GyeoteLocationState.activeSession = call.arguments as? Map<String, Any?>
                        startLocationService(LocationForegroundService.ACTION_START)
                        result.success(null)
                    }
                    "stopLocationSession" -> {
                        GyeoteLocationState.activeSession = null
                        startLocationService(LocationForegroundService.ACTION_STOP)
                        result.success(null)
                    }
                    "setSharingPolicy" -> {
                        GyeoteLocationState.sharingPolicy = (call.arguments as? Map<String, Any?>) ?: GyeoteLocationState.sharingPolicy
                        startLocationService(LocationForegroundService.ACTION_POLICY_CHANGED)
                        GyeoteLocationPayloads.emitPermissionChanged(this, locationManager)
                        result.success(null)
                    }
                    "configureUpload" -> {
                        GyeoteLocationState.uploadConfig = call.arguments as? Map<String, Any?>
                        GyeoteLocationUploadQueue.resetBackoff()
                        GyeoteLocationUploadQueue.flushAsync(applicationContext, locationManager, force = true)
                        result.success(null)
                    }
                    "clearUploadConfig" -> {
                        GyeoteLocationState.uploadConfig = null
                        GyeoteLocationUploadQueue.resetBackoff()
                        result.success(null)
                    }
                    "getLastKnownLocation" -> {
                        val location = GyeoteLocationState.lastLocation ?: lastKnownLocation()
                        result.success(location?.let { GyeoteLocationPayloads.locationPayload(this, locationManager, it) })
                    }
                    "registerGeofences" -> {
                        // Region monitoring is owned by the next Android native queue.
                        GyeoteLocationPayloads.emitStatus(this, locationManager, "geofences_registered")
                        result.success(null)
                    }
                    "flushPendingLocations" -> {
                        GyeoteLocationUploadQueue.flushAsync(applicationContext, locationManager, force = true)
                        result.success(null)
                    }
                    "requestSosFix" -> {
                        startLocationService(LocationForegroundService.ACTION_SOS)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: SecurityException) {
                result.error("permission_denied", error.message, null)
            } catch (error: IllegalArgumentException) {
                result.error("invalid_payload", error.message, null)
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    GyeoteLocationEvents.attach(events)
                    GyeoteLocationPayloads.emitPermissionChanged(this@MainActivity, locationManager)
                }

                override fun onCancel(arguments: Any?) {
                    GyeoteLocationEvents.detach()
                }
            },
        )
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == whenInUseRequestCode || requestCode == alwaysRequestCode) {
            GyeoteLocationPayloads.emitPermissionChanged(this, locationManager)
        }
    }

    private fun requestWhenInUse() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            GyeoteLocationPayloads.emitPermissionChanged(this, locationManager)
            return
        }

        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions += Manifest.permission.POST_NOTIFICATIONS
        }
        requestPermissions(permissions.toTypedArray(), whenInUseRequestCode)
    }

    private fun requestAlways() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            GyeoteLocationPayloads.emitPermissionChanged(this, locationManager)
            return
        }

        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            permissions += Manifest.permission.ACCESS_BACKGROUND_LOCATION
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions += Manifest.permission.POST_NOTIFICATIONS
        }
        requestPermissions(permissions.toTypedArray(), alwaysRequestCode)
    }

    private fun startLocationService(action: String) {
        val intent = Intent(this, LocationForegroundService::class.java).setAction(action)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && action != LocationForegroundService.ACTION_STOP) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
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
}
