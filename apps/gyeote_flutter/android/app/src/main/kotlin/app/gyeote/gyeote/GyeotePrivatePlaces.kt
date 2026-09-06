package app.gyeote.gyeote

import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * 정확한 좌표를 내보내지 않을 장소.
 *
 * 집·학교·병원처럼, 거기 있다는 사실보다 어디의 몇 번째 건물인지가 훨씬 많은
 * 것을 말해 주는 자리들이다. 좌표를 만들어 내는 것이 네이티브라서, 가림도
 * 여기서 걸려야 실제로 걸린다. Dart 쪽에서만 가리면 업로드 큐가 그걸 지나쳐
 * 정확한 좌표를 그대로 올린다.
 *
 * **이름을 받지 않는다.** 가리는 데 이름이 필요 없고, 이름 자체가 민감하다
 * ("정신과", "쉼터"). 로그나 크래시 리포트에 실릴 이유를 만들지 않는다.
 */
object GyeotePrivatePlaces {

    private const val EARTH_RADIUS_M = 6371008.8

    data class Place(val lat: Double, val lng: Double, val radiusM: Double)

    /**
     * 공유 정책에 실려 온 목록을 읽는다. 형태가 어긋난 항목은 조용히 버린다 —
     * 여기서 예외를 던지면 위치 수집 자체가 멈춘다.
     */
    fun fromPolicy(policy: Map<*, *>?): List<Place> {
        val raw = policy?.get("privatePlaces") as? List<*> ?: return emptyList()
        return raw.mapNotNull { entry ->
            val map = entry as? Map<*, *> ?: return@mapNotNull null
            val lat = (map["lat"] as? Number)?.toDouble() ?: return@mapNotNull null
            val lng = (map["lng"] as? Number)?.toDouble() ?: return@mapNotNull null
            val radius = (map["radiusM"] as? Number)?.toDouble() ?: return@mapNotNull null
            if (radius <= 0) null else Place(lat, lng, radius)
        }
    }

    /** 이 좌표를 감싸는 장소. 겹치면 중심이 가장 가까운 것. */
    fun covering(places: List<Place>, lat: Double, lng: Double): Place? {
        var best: Place? = null
        var bestDistance = Double.MAX_VALUE

        places.forEach { place ->
            val distance = distanceMeters(place.lat, place.lng, lat, lng)
            if (distance <= place.radiusM && distance < bestDistance) {
                best = place
                bestDistance = distance
            }
        }
        return best
    }

    /**
     * 반경 안이면 **중심으로 스냅**한다.
     *
     * 반올림이 아닌 이유는, 반올림은 격자를 만들 뿐이라 같은 집 안에서도 값이
     * 몇 가지로 갈리고 그 분포에서 원래 위치가 복원되기 때문이다. 중심 스냅은
     * 반경 안의 모든 지점이 정확히 같은 값이 되어 되돌릴 수 없다.
     */
    fun mask(places: List<Place>, lat: Double, lng: Double): Pair<Double, Double> {
        val place = covering(places, lat, lng) ?: return lat to lng
        return place.lat to place.lng
    }

    fun distanceMeters(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val phi1 = Math.toRadians(lat1)
        val phi2 = Math.toRadians(lat2)
        val dPhi = phi2 - phi1
        val dLambda = Math.toRadians(lng2 - lng1)

        val h = sin(dPhi / 2) * sin(dPhi / 2) +
            cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2)
        return 2 * EARTH_RADIUS_M * asin(min(1.0, sqrt(h)))
    }
}
