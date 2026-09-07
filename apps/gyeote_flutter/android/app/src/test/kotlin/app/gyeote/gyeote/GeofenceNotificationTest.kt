package app.gyeote.gyeote

import android.Manifest
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.google.android.gms.location.Geofence
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

/**
 * 조용한 시간이 실제로 **어느 채널로 가는지** 본다.
 *
 * [GyeoteQuietHoursTest] 는 창 판정만 본다. 판정이 맞아도 알림이 같은 채널로
 * 가면 여전히 울린다. 여기서는 리시버가 실제로 올린 알림의 채널을 읽는다.
 */
@RunWith(RobolectricTestRunner::class)
class GeofenceNotificationTest {

    private lateinit var context: Context
    private lateinit var manager: NotificationManager
    private val receiver = GeofenceBroadcastReceiver()

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancelAll()
        // 리시버는 권한이 없으면 조용히 돌아간다. 그건 맞는 동작이고, 여기서
        // 보려는 것은 그 다음이다.
        shadowOf(context as Application).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
    }

    @Test
    fun `알림 권한이 없으면 아무것도 올리지 않는다`() {
        shadowOf(context as Application).denyPermissions(Manifest.permission.POST_NOTIFICATIONS)
        receiver.showPlaceAlertNotification(context, Geofence.GEOFENCE_TRANSITION_ENTER, quiet = false)
        assertEquals(0, shadowOf(manager).allNotifications.size)
    }

    private fun posted() = shadowOf(manager).allNotifications.single()

    @Test
    fun `조용한 시간 밖에서는 기본 채널로 간다`() {
        receiver.showPlaceAlertNotification(context, Geofence.GEOFENCE_TRANSITION_ENTER, quiet = false)
        assertEquals(GeofenceBroadcastReceiver.CHANNEL_ID, posted().channelId)
    }

    @Test
    fun `조용한 시간에는 소리 없는 채널로 가되 버리지 않는다`() {
        // 안전 앱에서 "도착했다"는 사실을 자고 있었다는 이유로 없앨 수는 없다.
        // 깨우지 않을 수만 있다. 알림은 있어야 하고, 채널만 달라야 한다.
        receiver.showPlaceAlertNotification(context, Geofence.GEOFENCE_TRANSITION_EXIT, quiet = true)
        assertEquals(GeofenceBroadcastReceiver.QUIET_CHANNEL_ID, posted().channelId)
    }

    @Test
    fun `조용한 채널은 낮은 중요도로 만들어진다`() {
        receiver.showPlaceAlertNotification(context, Geofence.GEOFENCE_TRANSITION_ENTER, quiet = true)

        val quiet = manager.getNotificationChannel(GeofenceBroadcastReceiver.QUIET_CHANNEL_ID)
        val loud = manager.getNotificationChannel(GeofenceBroadcastReceiver.CHANNEL_ID)
        assertNotNull(quiet)
        assertNotNull(loud)
        assertEquals(NotificationManager.IMPORTANCE_LOW, quiet!!.importance)
        assertEquals(NotificationManager.IMPORTANCE_DEFAULT, loud!!.importance)
    }

    @Test
    fun `문구는 리소스에서 온다`() {
        // 코틀린 리터럴이면 위젯처럼 한 언어에 묶인다. 리소스 값과 같아야 한다.
        receiver.showPlaceAlertNotification(context, Geofence.GEOFENCE_TRANSITION_ENTER, quiet = false)
        val text = posted().extras.getCharSequence("android.text").toString()
        assertEquals(context.getString(R.string.place_alert_arrived), text)
    }
}
