package app.gyeote.gyeote

import android.location.Location
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * 공유 좌표가 만들어지는 자리. [GyeotePrivatePlacesTest] 는 가림 함수만 보고,
 * 이 테스트는 그 함수가 **정밀도 하향보다 먼저** 걸리는지 본다. 순서가 반대면
 * 반올림된 값이 반경 밖으로 밀려 가림을 빠져나간다.
 */
@RunWith(RobolectricTestRunner::class)
class SharedCoordinateTest {

    private val homeLat = 37.5000
    private val homeLng = 127.0000

    private fun location(lat: Double, lng: Double) = Location("test").apply {
        latitude = lat
        longitude = lng
    }

    private fun policy(mode: String, withHome: Boolean) {
        GyeoteLocationState.sharingPolicy = mapOf(
            "enabled" to true,
            "mode" to mode,
            "privatePlaces" to if (withHome) {
                listOf(mapOf("lat" to homeLat, "lng" to homeLng, "radiusM" to 120))
            } else {
                emptyList<Any>()
            },
        )
    }

    @After
    fun tearDown() {
        GyeoteLocationState.sharingPolicy = mapOf("enabled" to true, "mode" to "precise")
    }

    @Test
    fun `민감 장소 안이면 정확 모드여도 중심으로 스냅된다`() {
        policy("precise", withHome = true)
        // 집에서 약 90m 북쪽.
        val shared = GyeoteLocationPayloads.sharedCoordinate(location(homeLat + 90 / 111320.0, homeLng))
        assertEquals(homeLat, shared["latitude"]!!, 1e-9)
        assertEquals(homeLng, shared["longitude"]!!, 1e-9)
    }

    @Test
    fun `가림이 정밀도 하향보다 먼저다`() {
        // 동네 모드는 소수 셋째 자리로 반올림한다(약 111m 격자). 집에서 100m
        // 떨어진 점은 반올림하면 반경(120m) 밖 격자점으로 밀릴 수 있다. 그래도
        // 원래 위치가 반경 안이었으므로 결과는 중심이어야 한다.
        policy("area", withHome = true)
        val shared = GyeoteLocationPayloads.sharedCoordinate(location(homeLat + 100 / 111320.0, homeLng + 0.0004))
        assertEquals(homeLat, shared["latitude"]!!, 1e-9)
        assertEquals(homeLng, shared["longitude"]!!, 1e-9)
    }

    @Test
    fun `민감 장소 밖에서는 모드대로 뭉갠다`() {
        policy("area", withHome = true)
        val shared = GyeoteLocationPayloads.sharedCoordinate(location(37.5123456, 127.0123456))
        assertEquals(37.512, shared["latitude"]!!, 1e-9)
        assertEquals(127.012, shared["longitude"]!!, 1e-9)
    }

    @Test
    fun `민감 장소가 없으면 정확 모드는 그대로 나간다`() {
        policy("precise", withHome = false)
        val shared = GyeoteLocationPayloads.sharedCoordinate(location(37.5123456, 127.0123456))
        assertEquals(37.5123456, shared["latitude"]!!, 1e-12)
    }
}
