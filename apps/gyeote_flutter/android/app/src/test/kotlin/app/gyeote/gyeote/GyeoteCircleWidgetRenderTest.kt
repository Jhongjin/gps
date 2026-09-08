package app.gyeote.gyeote

import android.content.Context
import android.view.View
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * 위젯이 실제로 무엇을 그리는지 본다.
 *
 * 스냅샷 모델만 테스트하면 "무엇을 담는가"까지만 확인된다. 사용자가 홈 화면에서
 * 읽는 글자를 결정하는 것은 [GyeoteCircleWidget.buildViews] 이고, 그건 에뮬레이터
 * 없이 Robolectric 으로 확인할 수 있다.
 */
@RunWith(RobolectricTestRunner::class)
class GyeoteCircleWidgetRenderTest {

    private lateinit var context: Context

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        GyeoteWidgetSnapshot.clear(context)
    }

    private fun render(): View =
        GyeoteCircleWidget.buildViews(context).apply(context, null)

    private fun text(view: View, id: Int): String =
        view.findViewById<TextView>(id).text.toString()

    private fun visibility(view: View, id: Int): Int =
        view.findViewById<View>(id).visibility

    private fun store(
        hasCircle: Boolean = true,
        sharingCount: Int = 4,
        attentionCount: Int = 0,
        ageMillis: Long = 0,
        members: List<Map<String, Any?>> = listOf(
            mapOf("name" to "준", "status" to "균형 공유 중", "tone" to "brand"),
        ),
    ) {
        GyeoteWidgetSnapshot.write(
            context,
            GyeoteWidgetSnapshot.fromChannel(
                mapOf(
                    "circleName" to "우리 가족",
                    "sharingCount" to sharingCount,
                    "attentionCount" to attentionCount,
                    "hasCircle" to hasCircle,
                    "updatedAtMillis" to System.currentTimeMillis() - ageMillis,
                    "members" to members,
                ),
            ),
        )
    }

    @Test
    fun `저장된 것이 없으면 빈 상태를 그린다`() {
        val view = render()
        assertEquals(View.VISIBLE, visibility(view, R.id.widget_empty))
        assertEquals(View.GONE, visibility(view, R.id.widget_row_0))
    }

    @Test
    fun `서클이 있으면 이름과 멤버를 그린다`() {
        store()
        val view = render()

        assertEquals("우리 가족", text(view, R.id.widget_title))
        assertEquals("준", text(view, R.id.widget_name_0))
        assertEquals("균형 공유 중", text(view, R.id.widget_status_0))
        assertEquals(View.GONE, visibility(view, R.id.widget_empty))
    }

    @Test
    fun `오래된 스냅샷은 현재처럼 보여 주지 않는다`() {
        // 이 테스트가 이 위젯의 존재 이유에 가깝다. 앱이 죽은 채 몇 시간이
        // 지났는데 "4명 공유 중"이 그대로 남아 있으면 거짓 안심이 된다.
        store(ageMillis = GyeoteWidgetSnapshot.STALE_AFTER_MILLIS + 60_000L)
        val stale = text(render(), R.id.widget_subtitle)

        store(ageMillis = 60_000L)
        val fresh = text(render(), R.id.widget_subtitle)

        assertTrue("오래된 상태에 공유 인원이 남았다", !stale.contains("4"))
        assertTrue("최신 상태에 공유 인원이 없다", fresh.contains("4"))
        assertTrue("최신 상태에 나이가 없다", fresh.contains("1"))
    }

    @Test
    fun `확인 필요는 있을 때만 보인다`() {
        store(attentionCount = 0)
        assertEquals(View.GONE, visibility(render(), R.id.widget_attention))

        store(attentionCount = 2)
        val view = render()
        assertEquals(View.VISIBLE, visibility(view, R.id.widget_attention))
        assertTrue(text(view, R.id.widget_attention).contains("2"))
    }

    @Test
    fun `멤버가 적으면 남는 줄을 숨긴다`() {
        store(
            members = listOf(
                mapOf("name" to "준", "status" to "s", "tone" to "brand"),
                mapOf("name" to "하나", "status" to "s", "tone" to "warm"),
            ),
        )
        val view = render()

        assertEquals(View.VISIBLE, visibility(view, R.id.widget_row_0))
        assertEquals(View.VISIBLE, visibility(view, R.id.widget_row_1))
        assertEquals(View.GONE, visibility(view, R.id.widget_row_2))
    }

    @Test
    fun `그려진 글자 어디에도 좌표가 없다`() {
        // 위젯은 잠금화면에서 누구에게나 보인다. 모델이 좌표를 버리는 것과
        // 별개로, 화면에 찍힌 결과로도 한 번 더 확인한다.
        store(
            members = listOf(
                mapOf(
                    "name" to "준",
                    "status" to "균형 공유 중",
                    "tone" to "brand",
                    "lat" to 37.4979,
                    "lng" to 127.0276,
                ),
            ),
        )
        val view = render()
        val rendered = listOf(
            R.id.widget_title, R.id.widget_subtitle,
            R.id.widget_name_0, R.id.widget_status_0,
        ).joinToString(" ") { text(view, it) }

        listOf("37.4", "127.0").forEach { leaked ->
            assertTrue("위젯에 $leaked 가 그려졌다", !rendered.contains(leaked))
        }
    }
}
