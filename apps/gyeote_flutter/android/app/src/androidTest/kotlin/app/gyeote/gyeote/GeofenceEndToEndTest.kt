package app.gyeote.gyeote

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import android.os.Looper
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.Tasks
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.TimeUnit

/**
 * 진짜 Play Services 가 만든 지오펜스 전환이 리시버까지 오고, 조용한 시간이면
 * 소리 없는 채널로 가는지 본다.
 *
 * Robolectric 은 리시버를 직접 부른다. 여기서는 부르지 않는다 — 시스템에 지오펜스를
 * 등록하고, 기기가 이미 반경 안에 있으므로 INITIAL_TRIGGER_ENTER 로 Play Services
 * 가 전환 이벤트를 만들어 앱의 PendingIntent 로 보낸다. 그 사이의 어느 것도
 * 흉내내지 않는다.
 *
 * 전제: 에뮬레이터에 GMS 가 있고, 위치가 켜져 있고, `adb emu geo fix 127.0 37.5`
 * 로 위치가 잡혀 있으며, FINE·BACKGROUND 위치와 POST_NOTIFICATIONS 가 허가돼 있다.
 * `tools/android-emulator-check.ps1` 이 그렇게 만든다.
 */
@RunWith(AndroidJUnit4::class)
class GeofenceEndToEndTest {

    private val context: Context =
        InstrumentationRegistry.getInstrumentation().targetContext

    /** MainActivity.geofencePendingIntent 와 같은 정체성이어야 앱의 리시버가 받는다. */
    private fun pendingIntent(): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
            .setAction("app.gyeote.GEOFENCE_TRANSITION")
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }
        return PendingIntent.getBroadcast(context, 4201, intent, flags)
    }

    @Test
    fun realTransitionInsideQuietWindowReachesQuietChannel() =
        runTransition(quiet = true, expectedChannel = "gyeote_place_alerts_quiet")

    @Test
    fun realTransitionOutsideQuietWindowReachesDefaultChannel() =
        runTransition(quiet = false, expectedChannel = "gyeote_place_alerts")

    private fun runTransition(quiet: Boolean, expectedChannel: String) {
        // Gradle 이 테스트마다 앱을 다시 설치하면서 런타임 권한이 사라진다. 권한
        // 없이 addGeofences 는 예외 없이 아무 일도 하지 않는다 — 첫 실행이 그렇게
        // 2분을 조용히 기다렸다. 계측이 스스로 준다. BACKGROUND 는 FINE 뒤여야 한다.
        val automation = InstrumentationRegistry.getInstrumentation().uiAutomation
        for (permission in listOf(
            android.Manifest.permission.ACCESS_FINE_LOCATION,
            android.Manifest.permission.ACCESS_COARSE_LOCATION,
            android.Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            android.Manifest.permission.POST_NOTIFICATIONS,
        )) {
            automation.grantRuntimePermission(context.packageName, permission)
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancelAll()

        // 하루 종일 조용한 창, 또는 창 없음. 시각과 무관하게 채널이 갈려야 한다.
        GyeoteQuietHours.store(
            context,
            listOf(
                if (quiet) {
                    mapOf("id" to "e2e-home", "quietStart" to "00:00", "quietEnd" to "23:59")
                } else {
                    mapOf("id" to "e2e-home")
                },
            ),
        )

        val client = LocationServices.getGeofencingClient(context)
        val pending = pendingIntent()
        Tasks.await(client.removeGeofences(pending), 30, TimeUnit.SECONDS)

        val geofence = Geofence.Builder()
            .setRequestId("e2e-home")
            .setCircularRegion(37.5000, 127.0000, 200f)
            .setExpirationDuration(10 * 60 * 1000L)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
            .build()
        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()

        Tasks.await(client.addGeofences(request, pending), 30, TimeUnit.SECONDS)

        // 지오펜스는 위치가 **흘러야** 평가된다. 에뮬레이터의 geo fix 는 GPS 공급자에
        // 값을 넣을 뿐이고, 아무도 위치를 요청하지 않으면 fused 는 fix 를 만들지
        // 않아 초기 진입 판정이 영영 안 난다. 실제 앱에서는 포그라운드 서비스가 이
        // 역할을 한다. 여기서는 테스트가 그 자리를 대신한다.
        val fused = LocationServices.getFusedLocationProviderClient(context)
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1_000L)
            .setMinUpdateIntervalMillis(500L)
            .build()
        val callback = object : LocationCallback() {}
        fused.requestLocationUpdates(locationRequest, callback, Looper.getMainLooper())

        // Play Services 가 초기 진입을 판단해 브로드캐스트를 보낼 때까지 기다린다.
        val deadline = System.currentTimeMillis() + 120_000L
        var posted = manager.activeNotifications.filter { it.id == 5200 }
        while (posted.isEmpty() && System.currentTimeMillis() < deadline) {
            Thread.sleep(2_000)
            posted = manager.activeNotifications.filter { it.id == 5200 }
        }

        assertTrue("2분 안에 장소 알림이 오지 않았다", posted.isNotEmpty())
        assertEquals(expectedChannel, posted.first().notification.channelId)

        fused.removeLocationUpdates(callback)
        Tasks.await(client.removeGeofences(pending), 30, TimeUnit.SECONDS)
    }
}
