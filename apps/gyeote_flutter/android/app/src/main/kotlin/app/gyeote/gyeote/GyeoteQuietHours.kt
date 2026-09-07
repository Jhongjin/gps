package app.gyeote.gyeote

import android.content.Context
import org.json.JSONObject
import java.util.Calendar

/**
 * 장소 알림의 조용한 시간.
 *
 * 앱은 이 값을 저장하고, 보여 주고, 순환시켰지만 **어디서도 읽지 않았다.**
 * 알림은 시각과 무관하게 같은 소리로 울렸다. 지오펜스 전환은 앱이 죽어 있어도
 * 리시버에서 처리되므로, 창을 여기 기기 저장소에 두고 리시버가 직접 본다.
 *
 * 창 안이라고 알림을 **버리지는 않는다.** 소리 없는 채널로 보낸다. 안전 앱에서
 * "도착했다"는 사실을 사용자가 자고 있었다는 이유로 없앨 수는 없다.
 *
 * 시각은 기기 현지 시각이다. 시간대를 따로 저장하지 않는 이유는
 * `PlaceAlertQuietHours` 주석에 있다.
 */
object GyeoteQuietHours {

    private const val PREFS = "gyeote_geofence_quiet"
    private const val KEY = "windows_v1"

    /** 하루 안의 분 단위 창. [startMinute] > [endMinute] 면 자정을 넘는다. */
    data class Window(val startMinute: Int, val endMinute: Int) {
        /**
         * 22:00–07:00 처럼 자정을 넘는 창은 "start 이후 **또는** end 이전"이다.
         * 이걸 "start 이후 **그리고** end 이전"으로 쓰면 야간 창이 한 번도
         * 켜지지 않는다 — 가장 흔한 프리셋이 조용히 죽는 자리다.
         */
        fun contains(minuteOfDay: Int): Boolean =
            if (startMinute <= endMinute) {
                minuteOfDay in startMinute until endMinute
            } else {
                minuteOfDay >= startMinute || minuteOfDay < endMinute
            }
    }

    /** "HH:mm" 을 하루 안의 분으로. 형태가 어긋나면 null — 창을 만들지 않는다. */
    fun parseMinute(value: String?): Int? {
        val parts = value?.split(":") ?: return null
        if (parts.size != 2) return null
        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null
        if (hour !in 0..23 || minute !in 0..59) return null
        return hour * 60 + minute
    }

    fun windowOf(start: String?, end: String?): Window? {
        val s = parseMinute(start) ?: return null
        val e = parseMinute(end) ?: return null
        if (s == e) return null
        return Window(s, e)
    }

    /** 지오펜스 등록 페이로드에서 창을 모아 저장한다. 없는 항목은 창이 없다. */
    fun store(context: Context, geofences: List<Map<*, *>>) {
        val json = JSONObject()
        geofences.forEach { payload ->
            val id = payload["id"] as? String ?: return@forEach
            val start = payload["quietStart"] as? String
            val end = payload["quietEnd"] as? String
            if (windowOf(start, end) != null) {
                json.put(id.take(100), "$start|$end")
            }
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY, json.toString())
            .apply()
    }

    fun windowFor(context: Context, requestId: String): Window? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null) ?: return null
        val entry = runCatching { JSONObject(raw).optString(requestId, "") }
            .getOrDefault("")
        if (entry.isEmpty()) return null
        val (start, end) = entry.split("|").let {
            if (it.size == 2) it[0] to it[1] else return null
        }
        return windowOf(start, end)
    }

    /**
     * 전환을 일으킨 지오펜스 중 하나라도 지금 조용한 시간 안이면 true.
     *
     * 겹치는 지오펜스 여럿이 함께 울릴 때, 하나가 조용하면 조용하게 간다.
     * 반대로 하면 조용한 시간을 설정한 사람이 그 설정을 믿을 수 없게 된다.
     */
    fun isQuietNow(
        context: Context,
        requestIds: List<String>,
        minuteOfDay: Int = currentMinuteOfDay(),
    ): Boolean = requestIds.any { id ->
        windowFor(context, id)?.contains(minuteOfDay) == true
    }

    fun currentMinuteOfDay(): Int {
        val now = Calendar.getInstance()
        return now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
    }
}
