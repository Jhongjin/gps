package app.gyeote.gyeote

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * 위젯이 그릴 최소한의 상태.
 *
 * **좌표를 담지 않는다.** 위젯은 잠금화면에서 주머니에서 꺼낸 사람 누구에게나
 * 보인다. 이름과 대략의 상태까지가 한계이고, 어디 있는지는 앱을 열어야 보인다.
 * 이 규칙은 취향이 아니라 제품 원칙이라, 여기서 좌표를 받지 않는 것으로
 * 구조적으로 막는다.
 */
data class GyeoteWidgetSnapshot(
    val circleName: String,
    val sharingCount: Int,
    val attentionCount: Int,
    val members: List<Member>,
    val hasCircle: Boolean,
    /** 이 스냅샷을 받은 시각(epoch millis). 위젯이 나이를 그리는 데 쓴다. */
    val updatedAtMillis: Long,
) {
    /** 스냅샷이 얼마나 늙었는지. */
    fun ageMillis(now: Long = System.currentTimeMillis()): Long =
        (now - updatedAtMillis).coerceAtLeast(0L)

    /**
     * 너무 늙어서 더는 현재로 보여 주면 안 되는 상태인지.
     *
     * 앱이 꺼진 채 몇 시간이 지났는데 "1분 전 괜찮음"을 계속 보여 주면 위젯이
     * 거짓말을 하는 것이고, 안전 앱에서는 모르는 것보다 나쁘다.
     */
    fun isStale(now: Long = System.currentTimeMillis()): Boolean =
        ageMillis(now) >= STALE_AFTER_MILLIS

    data class Member(
        val name: String,
        /** 사람이 읽을 수 있는 상태 한 줄. 주소나 장소 이름은 들어가지 않는다. */
        val status: String,
        val tone: Tone,
    )

    enum class Tone { BRAND, WARM, ALERT }

    companion object {
        private const val PREFS = "gyeote_widget"
        private const val KEY = "snapshot_v1"

        /** 위젯에 세 줄만 들어간다. 더 받아 봐야 그릴 자리가 없다. */
        const val MAX_MEMBERS = 3

        /** 이 시간이 지나면 현재 상태로 보여 주지 않는다. */
        const val STALE_AFTER_MILLIS = 30 * 60 * 1000L

        fun read(context: Context): GyeoteWidgetSnapshot? {
            val raw = context
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY, null)
                ?: return null
            return runCatching { fromJson(JSONObject(raw)) }.getOrNull()
        }

        fun write(context: Context, snapshot: GyeoteWidgetSnapshot) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY, snapshot.toJson().toString())
                .apply()
        }

        fun clear(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .remove(KEY)
                .apply()
        }

        /**
         * Flutter 가 보낸 맵을 읽는다. 좌표 키가 섞여 와도 무시한다 — 채널
         * 반대편이 실수해도 위젯에는 위치가 새지 않는다.
         */
        fun fromChannel(arguments: Map<*, *>?): GyeoteWidgetSnapshot {
            val members = (arguments?.get("members") as? List<*>).orEmpty()
                .filterIsInstance<Map<*, *>>()
                .take(MAX_MEMBERS)
                .map { member ->
                    Member(
                        name = member["name"] as? String ?: "",
                        status = member["status"] as? String ?: "",
                        tone = toneOf(member["tone"] as? String),
                    )
                }

            return GyeoteWidgetSnapshot(
                circleName = arguments?.get("circleName") as? String ?: "",
                sharingCount = (arguments?.get("sharingCount") as? Number)?.toInt() ?: 0,
                attentionCount = (arguments?.get("attentionCount") as? Number)?.toInt() ?: 0,
                members = members,
                hasCircle = arguments?.get("hasCircle") as? Boolean ?: false,
                updatedAtMillis = (arguments?.get("updatedAtMillis") as? Number)
                    ?.toLong() ?: System.currentTimeMillis(),
            )
        }

        private fun toneOf(value: String?): Tone = when (value) {
            "alert" -> Tone.ALERT
            "warm" -> Tone.WARM
            else -> Tone.BRAND
        }

        private fun toneName(tone: Tone): String = when (tone) {
            Tone.ALERT -> "alert"
            Tone.WARM -> "warm"
            Tone.BRAND -> "brand"
        }

        private fun fromJson(json: JSONObject): GyeoteWidgetSnapshot {
            val array = json.optJSONArray("members") ?: JSONArray()
            val members = (0 until array.length()).mapNotNull { index ->
                array.optJSONObject(index)?.let { member ->
                    Member(
                        name = member.optString("name"),
                        status = member.optString("status"),
                        tone = toneOf(member.optString("tone")),
                    )
                }
            }

            return GyeoteWidgetSnapshot(
                circleName = json.optString("circleName"),
                sharingCount = json.optInt("sharingCount"),
                attentionCount = json.optInt("attentionCount"),
                members = members,
                hasCircle = json.optBoolean("hasCircle"),
                updatedAtMillis = json.optLong("updatedAtMillis"),
            )
        }
    }

    private fun toJson(): JSONObject {
        val array = JSONArray()
        members.forEach { member ->
            array.put(
                JSONObject()
                    .put("name", member.name)
                    .put("status", member.status)
                    .put("tone", toneName(member.tone)),
            )
        }

        return JSONObject()
            .put("circleName", circleName)
            .put("sharingCount", sharingCount)
            .put("attentionCount", attentionCount)
            .put("hasCircle", hasCircle)
            .put("updatedAtMillis", updatedAtMillis)
            .put("members", array)
    }
}
