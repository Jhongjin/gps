package app.gyeote.gyeote

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val event = GeofencingEvent.fromIntent(intent) ?: return

        if (event.hasError()) {
            val errorCode = event.errorCode
            GyeoteLocationPayloads.emitError(
                context,
                locationManager,
                "geofence_transition_failed",
                GeofenceStatusCodes.getStatusCodeString(errorCode),
                mapOf("errorCode" to errorCode),
            )
            return
        }

        val transition = event.geofenceTransition
        val eventType = when (transition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> "geofence.entered"
            Geofence.GEOFENCE_TRANSITION_EXIT -> "geofence.exited"
            else -> "geofence.transition"
        }
        val requestIds = event.triggeringGeofences
            ?.map { geofence -> geofence.requestId }
            .orEmpty()

        GyeoteLocationPayloads.emitGeofenceTransition(
            context,
            locationManager,
            eventType,
            transition,
            requestIds,
        )
        showPlaceAlertNotification(context, transition)
    }

    private fun showPlaceAlertNotification(context: Context, transition: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        createNotificationChannel(context)

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val pendingIntent = PendingIntent.getActivity(context, 5200, launchIntent, flags)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        val notification = builder
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle("곁에 장소 알림")
            .setContentText(placeAlertNotificationText(transition))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_STATUS)
            .setShowWhen(true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "곁에 장소 알림",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "저장한 장소의 도착과 이탈 알림을 표시합니다."
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    private fun placeAlertNotificationText(transition: Int): String {
        return when (transition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> "저장한 장소 반경에 도착했습니다."
            Geofence.GEOFENCE_TRANSITION_EXIT -> "저장한 장소 반경을 벗어났습니다."
            else -> "저장한 장소 반경 변화가 감지됐습니다."
        }
    }

    private companion object {
        const val CHANNEL_ID = "gyeote_place_alerts"
        const val NOTIFICATION_ID = 5200
    }
}
