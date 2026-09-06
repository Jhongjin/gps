package app.gyeote.gyeote

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 좌표를 만들어 내는 것은 네이티브다. 여기서 가리지 못하면 업로드 큐가 정확한
 * 좌표를 그대로 올린다 — Dart 쪽 가림은 그 경로를 지나가지 않는다.
 */
class GyeotePrivatePlacesTest {

    private val lat = 37.5000
    private val lng = 127.0000

    /** 위도 1도 ≈ 111.32km. 위도로만 움직여 거리를 손으로 검산한다. */
    private fun north(meters: Double) = lat + meters / 111320.0

    private val home = GyeotePrivatePlaces.Place(lat, lng, 300.0)

    @Test
    fun `반경 안의 서로 다른 지점이 같은 값이 된다`() {
        // 이 단언이 기능의 전부다. 반올림이면 같은 집 안에서도 값이 몇 가지로
        // 갈리고, 그 분포에서 원래 위치가 복원된다.
        val a = GyeotePrivatePlaces.mask(listOf(home), north(10.0), lng)
        val b = GyeotePrivatePlaces.mask(listOf(home), north(250.0), lng)

        assertEquals(a, b)
        assertEquals(lat, a.first, 1e-9)
    }

    @Test
    fun `반경 밖이면 좌표를 건드리지 않는다`() {
        val outside = north(900.0)
        val masked = GyeotePrivatePlaces.mask(listOf(home), outside, lng)
        assertEquals(outside, masked.first, 1e-9)
    }

    @Test
    fun `등록된 곳이 없으면 좌표를 건드리지 않는다`() {
        val masked = GyeotePrivatePlaces.mask(emptyList(), lat, lng)
        assertEquals(lat, masked.first, 1e-9)
        assertEquals(lng, masked.second, 1e-9)
    }

    @Test
    fun `겹치면 중심이 가까운 쪽을 고른다`() {
        val wide = GyeotePrivatePlaces.Place(north(500.0), lng, 1000.0)
        val covering =
            GyeotePrivatePlaces.covering(listOf(wide, home), north(100.0), lng)
        assertEquals(home, covering)
    }

    @Test
    fun `두 번 걸어도 결과가 같다`() {
        // Dart 가 네이티브 결과 위에 한 번 더 건다. 멱등하지 않으면 두 겹
        // 방어가 값을 망가뜨린다.
        val once = GyeotePrivatePlaces.mask(listOf(home), north(120.0), lng)
        val twice = GyeotePrivatePlaces.mask(listOf(home), once.first, once.second)
        assertEquals(once, twice)
    }

    @Test
    fun `정책이 비었거나 망가져도 죽지 않는다`() {
        // 여기서 예외가 나면 위치 수집 자체가 멈춘다.
        assertTrue(GyeotePrivatePlaces.fromPolicy(null).isEmpty())
        assertTrue(GyeotePrivatePlaces.fromPolicy(mapOf("mode" to "precise")).isEmpty())
        assertTrue(
            GyeotePrivatePlaces.fromPolicy(
                mapOf("privatePlaces" to listOf("not a map", 7)),
            ).isEmpty(),
        )
    }

    @Test
    fun `항목이 망가져 있으면 그 항목만 버린다`() {
        val places = GyeotePrivatePlaces.fromPolicy(
            mapOf(
                "privatePlaces" to listOf(
                    mapOf("lat" to lat, "lng" to lng, "radiusM" to 300),
                    mapOf("lat" to lat, "lng" to lng),
                    mapOf("lat" to lat, "lng" to lng, "radiusM" to 0),
                ),
            ),
        )
        assertEquals(1, places.size)
        assertEquals(300.0, places.first().radiusM, 1e-9)
    }

    @Test
    fun `정책에 이름이 실려 오지 않는다`() {
        // Dart 가 이름을 빼고 보낸다. 여기서도 읽지 않는다는 것을 고정한다.
        val places = GyeotePrivatePlaces.fromPolicy(
            mapOf(
                "privatePlaces" to listOf(
                    mapOf("lat" to lat, "lng" to lng, "radiusM" to 300, "name" to "정신과"),
                ),
            ),
        )
        assertEquals(1, places.size)
        assertNull(
            "Place 가 이름을 담을 자리를 가지면 안 된다",
            places.first()::class.java.declaredFields.firstOrNull { it.name == "name" },
        )
    }
}
