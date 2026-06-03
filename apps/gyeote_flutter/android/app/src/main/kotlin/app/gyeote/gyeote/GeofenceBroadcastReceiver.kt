package app.gyeote.gyeote

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.location.LocationManager
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
    }
}
