package app.gyeote.gyeote

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GyeoteWidgetSnapshotTest {

    @Test
    fun `채널이 좌표를 보내도 스냅샷은 버린다`() {
        // Flutter 쪽 계약에는 좌표 필드가 없지만, 채널은 결국 맵이다.
        // 반대편이 실수해도 위젯에는 위치가 새면 안 된다.
        val snapshot = GyeoteWidgetSnapshot.fromChannel(
            mapOf(
                "circleName" to "우리 가족",
                "sharingCount" to 4,
                "attentionCount" to 1,
                "hasCircle" to true,
                "latitude" to 37.5,
                "longitude" to 127.0,
                "members" to listOf(
                    mapOf(
                        "name" to "준",
                        "status" to "균형 공유 중",
                        "tone" to "brand",
                        "lat" to 37.5,
                        "lng" to 127.0,
                        "accuracyM" to 85.0,
                    ),
                ),
            ),
        )

        assertEquals("우리 가족", snapshot.circleName)
        assertEquals(1, snapshot.members.size)
        assertEquals("준", snapshot.members[0].name)
        assertEquals("균형 공유 중", snapshot.members[0].status)

        // 좌표를 담을 자리가 애초에 없다. 문자열로 만들어도 새어 나오지 않는다.
        val rendered = snapshot.toString()
        listOf("37.5", "127.0", "85.0").forEach { leaked ->
            assertTrue("스냅샷에 $leaked 이 남았다", !rendered.contains(leaked))
        }
    }

    @Test
    fun `세 명까지만 담는다`() {
        val members = (0 until 6).map {
            mapOf("name" to "멤버$it", "status" to "s", "tone" to "brand")
        }
        val snapshot = GyeoteWidgetSnapshot.fromChannel(
            mapOf("hasCircle" to true, "members" to members),
        )
        assertEquals(GyeoteWidgetSnapshot.MAX_MEMBERS, snapshot.members.size)
    }

    @Test
    fun `모르는 톤은 brand 로 떨어진다`() {
        val snapshot = GyeoteWidgetSnapshot.fromChannel(
            mapOf(
                "hasCircle" to true,
                "members" to listOf(
                    mapOf("name" to "n", "status" to "s", "tone" to "무엇"),
                ),
            ),
        )
        assertEquals(
            GyeoteWidgetSnapshot.Tone.BRAND,
            snapshot.members[0].tone,
        )
    }

    @Test
    fun `빈 인자는 서클 없음으로 읽는다`() {
        val snapshot = GyeoteWidgetSnapshot.fromChannel(null)
        assertEquals(false, snapshot.hasCircle)
        assertTrue(snapshot.members.isEmpty())
    }

    @Test
    fun `오래된 스냅샷은 현재로 보여 주지 않는다`() {
        // 앱이 꺼진 채 몇 시간이 지났는데 위젯이 "1분 전 괜찮음"을 계속 보여
        // 주면 거짓말이다. 안전 앱에서는 모르는 것보다 나쁘다.
        val now = 1_700_000_000_000L
        val fresh = snapshotAt(now - 60_000L)
        val old = snapshotAt(now - GyeoteWidgetSnapshot.STALE_AFTER_MILLIS - 1)

        assertEquals(false, fresh.isStale(now))
        assertEquals(true, old.isStale(now))
    }

    @Test
    fun `나이는 음수가 되지 않는다`() {
        // 기기 시계가 뒤로 가면 "-3분 전"이 나온다. 그건 버그로 보인다.
        val now = 1_700_000_000_000L
        val future = snapshotAt(now + 600_000L)
        assertEquals(0L, future.ageMillis(now))
    }

    @Test
    fun `갱신 시각이 없으면 지금으로 채운다`() {
        val before = System.currentTimeMillis()
        val snapshot = GyeoteWidgetSnapshot.fromChannel(mapOf("hasCircle" to true))
        assertTrue(snapshot.updatedAtMillis >= before)
    }

    private fun snapshotAt(millis: Long) = GyeoteWidgetSnapshot.fromChannel(
        mapOf("hasCircle" to true, "updatedAtMillis" to millis),
    )

    @Test
    fun `잘못된 타입이 와도 기본값으로 떨어진다`() {
        // 채널은 동적이다. 숫자 자리에 문자열이 와도 위젯이 죽으면 안 된다.
        val snapshot = GyeoteWidgetSnapshot.fromChannel(
            mapOf(
                "circleName" to 42,
                "sharingCount" to "넷",
                "hasCircle" to "yes",
                "members" to "목록 아님",
            ),
        )
        assertEquals("", snapshot.circleName)
        assertEquals(0, snapshot.sharingCount)
        assertEquals(false, snapshot.hasCircle)
        assertTrue(snapshot.members.isEmpty())
    }
}
