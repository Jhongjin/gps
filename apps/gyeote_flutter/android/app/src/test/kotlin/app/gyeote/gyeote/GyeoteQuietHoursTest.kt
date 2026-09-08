package app.gyeote.gyeote

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * 조용한 시간 창 판정. 자정을 넘는 창이 핵심이다 — 가장 흔한 프리셋(22:00–07:00)
 * 이 바로 그것이고, 단순 범위 비교로 쓰면 한 번도 켜지지 않는다.
 */
@RunWith(RobolectricTestRunner::class)
class GyeoteQuietHoursTest {

    private lateinit var context: Context

    private fun m(h: Int, min: Int = 0) = h * 60 + min

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        GyeoteQuietHours.store(context, emptyList())
    }

    @Test
    fun `자정을 넘는 창은 밤에도 새벽에도 켜진다`() {
        val night = GyeoteQuietHours.windowOf("22:00", "07:00")!!
        assertTrue(night.contains(m(23)))
        assertTrue(night.contains(m(3)))
        assertTrue(night.contains(m(22)))
        assertFalse(night.contains(m(7)))
        assertFalse(night.contains(m(12)))
    }

    @Test
    fun `낮 창은 그 사이에만 켜진다`() {
        val work = GyeoteQuietHours.windowOf("09:00", "17:00")!!
        assertTrue(work.contains(m(9)))
        assertTrue(work.contains(m(12, 30)))
        assertFalse(work.contains(m(17)))
        assertFalse(work.contains(m(8, 59)))
        assertFalse(work.contains(m(23)))
    }

    @Test
    fun `형태가 어긋나면 창을 만들지 않는다`() {
        // 창을 잘못 만드느니 안 만드는 편이 낫다. 잘못된 창은 알림을 엉뚱한
        // 시간에 죽인다.
        assertNull(GyeoteQuietHours.windowOf("25:00", "07:00"))
        assertNull(GyeoteQuietHours.windowOf("22", "07:00"))
        assertNull(GyeoteQuietHours.windowOf(null, "07:00"))
        assertNull(GyeoteQuietHours.windowOf("22:00", "22:00"))
        assertNull(GyeoteQuietHours.windowOf("ab:cd", "07:00"))
    }

    @Test
    fun `등록 페이로드의 창을 리시버가 읽는다`() {
        // 리시버는 앱이 죽어 있어도 돈다. 메모리가 아니라 저장소를 거쳐야 한다.
        GyeoteQuietHours.store(
            context,
            listOf(
                mapOf("id" to "home", "quietStart" to "22:00", "quietEnd" to "07:00"),
                mapOf("id" to "school"),
            ),
        )

        assertTrue(GyeoteQuietHours.isQuietNow(context, listOf("home"), m(2)))
        assertFalse(GyeoteQuietHours.isQuietNow(context, listOf("home"), m(12)))
        assertFalse(GyeoteQuietHours.isQuietNow(context, listOf("school"), m(2)))
    }

    @Test
    fun `겹친 지오펜스 중 하나라도 조용하면 조용하다`() {
        GyeoteQuietHours.store(
            context,
            listOf(mapOf("id" to "home", "quietStart" to "22:00", "quietEnd" to "07:00")),
        )
        assertTrue(GyeoteQuietHours.isQuietNow(context, listOf("school", "home"), m(2)))
    }

    @Test
    fun `다시 등록하면 이전 창이 남지 않는다`() {
        GyeoteQuietHours.store(
            context,
            listOf(mapOf("id" to "home", "quietStart" to "22:00", "quietEnd" to "07:00")),
        )
        GyeoteQuietHours.store(context, listOf(mapOf("id" to "home")))

        assertNull(GyeoteQuietHours.windowFor(context, "home"))
        assertEquals(false, GyeoteQuietHours.isQuietNow(context, listOf("home"), m(2)))
    }
}
