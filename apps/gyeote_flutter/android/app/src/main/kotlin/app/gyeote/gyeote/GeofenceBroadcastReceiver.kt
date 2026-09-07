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
        // 조용한 시간이면 소리 없는 채널로 간다. 버리지는 않는다 — 안전 앱에서
        // "도착했다"는 사실을 자고 있었다는 이유로 없앨 수는 없다.
        showPlaceAlertNotification(
            context,
            transition,
            quiet = GyeoteQuietHours.isQuietNow(context, requestIds),
        )
    }

    /** 테스트가 어느 채널로 갔는지 볼 수 있도록 internal 로 연다. */
    @androidx.annotation.VisibleForTesting
    internal fun showPlaceAlertNotification(context: Context, transition: Int, quiet: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        createNotificationChannels(context)
        val channelId = if (quiet) QUIET_CHANNEL_ID else CHANNEL_ID

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val pendingIntent = PendingIntent.getActivity(context, 5200, launchIntent, flags)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        val notification = builder
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(context.getString(R.string.place_alert_channel))
            .setContentText(placeAlertNotificationText(context, transition))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_STATUS)
            .setShowWhen(true)
            .apply {
                // O 미만은 채널이 없어 우선순위로 조용히 한다.
                if (quiet && Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    @Suppress("DEPRECATION")
                    setPriority(Notification.PRIORITY_LOW)
                }
            }
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.place_alert_channel),
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = context.getString(R.string.place_alert_channel_description)
                setShowBadge(true)
            },
        )
        // 채널은 한 번 만들어지면 중요도를 코드로 못 바꾼다. 조용한 시간은
        // 별도 채널이어야 하고, 사용자가 시스템 설정에서 따로 다룰 수 있다.
        manager.createNotificationChannel(
            NotificationChannel(
                QUIET_CHANNEL_ID,
                context.getString(R.string.place_alert_quiet_channel),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = context.getString(R.string.place_alert_quiet_channel_description)
                setShowBadge(true)
            },
        )
    }

    private fun placeAlertNotificationText(context: Context, transition: Int): String {
        return context.getString(
            when (transition) {
                Geofence.GEOFENCE_TRANSITION_ENTER -> R.string.place_alert_arrived
                Geofence.GEOFENCE_TRANSITION_EXIT -> R.string.place_alert_departed
                else -> R.string.place_alert_changed
            },
        )
    }

    internal companion object {
        const val CHANNEL_ID = "gyeote_place_alerts"
        const val QUIET_CHANNEL_ID = "gyeote_place_alerts_quiet"
        const val NOTIFICATION_ID = 5200
    }
}
