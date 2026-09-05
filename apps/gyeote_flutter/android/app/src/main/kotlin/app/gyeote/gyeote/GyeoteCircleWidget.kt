package app.gyeote.gyeote

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * 홈 화면 위젯.
 *
 * "아이가 집에 도착했나"를 확인하려고 앱을 여는 행동은 위젯이면 끝난다. 얼핏
 * DAU 를 깎을 것 같지만, 위젯이 앱을 습관으로 만들고 실제 진입은 조치가 필요할
 * 때 — 체류가 긴 세션 — 일어난다.
 *
 * 좌표는 절대 그리지 않는다. [GyeoteWidgetSnapshot] 이 애초에 좌표를 받지 않는다.
 */
class GyeoteCircleWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            refresh(context)
        }
    }

    companion object {
        const val ACTION_REFRESH = "app.gyeote.gyeote.WIDGET_REFRESH"

        private val dotIds = intArrayOf(
            R.id.widget_dot_0, R.id.widget_dot_1, R.id.widget_dot_2,
        )
        private val nameIds = intArrayOf(
            R.id.widget_name_0, R.id.widget_name_1, R.id.widget_name_2,
        )
        private val statusIds = intArrayOf(
            R.id.widget_status_0, R.id.widget_status_1, R.id.widget_status_2,
        )
        private val rowIds = intArrayOf(
            R.id.widget_row_0, R.id.widget_row_1, R.id.widget_row_2,
        )

        /**
         * 앱이 새 스냅샷을 받았을 때 부른다. 시스템 주기 갱신(30분)과 별개로,
         * 새 데이터는 즉시 반영돼야 한다.
         */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, GyeoteCircleWidget::class.java),
            )
            if (ids.isEmpty()) return

            val views = buildViews(context)
            ids.forEach { manager.updateAppWidget(it, views) }
        }

        private fun buildViews(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_circle)
            val snapshot = GyeoteWidgetSnapshot.read(context)

            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))

            if (snapshot == null || !snapshot.hasCircle) {
                renderEmpty(context, views)
                return views
            }

            views.setTextViewText(R.id.widget_title, snapshot.circleName)
            views.setViewVisibility(R.id.widget_empty, View.GONE)

            // 나이를 함께 적는다. 앱이 꺼진 채 시간이 흐르면 "1분 전"이 그대로
            // 굳는데, 안전 앱에서 오래된 안심은 모르는 것보다 나쁘다.
            views.setTextViewText(
                R.id.widget_subtitle,
                if (snapshot.isStale()) {
                    context.getString(R.string.widget_stale_notice)
                } else {
                    context.getString(
                        R.string.widget_sharing_with_age,
                        context.getString(
                            R.string.widget_sharing_count,
                            snapshot.sharingCount,
                        ),
                        ageLabel(context, snapshot.ageMillis()),
                    )
                },
            )

            if (snapshot.attentionCount > 0) {
                views.setTextViewText(
                    R.id.widget_attention,
                    context.getString(
                        R.string.widget_needs_check,
                        snapshot.attentionCount,
                    ),
                )
                views.setViewVisibility(R.id.widget_attention, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_attention, View.GONE)
            }

            rowIds.indices.forEach { index ->
                val member = snapshot.members.getOrNull(index)
                if (member == null) {
                    views.setViewVisibility(rowIds[index], View.GONE)
                    return@forEach
                }
                views.setViewVisibility(rowIds[index], View.VISIBLE)
                views.setTextViewText(nameIds[index], member.name)
                views.setTextViewText(statusIds[index], member.status)
                views.setImageViewResource(dotIds[index], dotFor(member.tone))
            }

            return views
        }

        private fun renderEmpty(context: Context, views: RemoteViews) {
            views.setTextViewText(
                R.id.widget_title,
                context.getString(R.string.widget_empty_title),
            )
            views.setTextViewText(R.id.widget_subtitle, "")
            views.setViewVisibility(R.id.widget_attention, View.GONE)
            rowIds.forEach { views.setViewVisibility(it, View.GONE) }
            views.setTextViewText(
                R.id.widget_empty,
                context.getString(R.string.widget_empty_body),
            )
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        }

        /** "방금" / "12분 전" / "3시간 전". */
        private fun ageLabel(context: Context, ageMillis: Long): String {
            val minutes = ageMillis / 60_000L
            return when {
                minutes < 1 -> context.getString(R.string.widget_updated_just_now)
                minutes < 60 -> context.getString(
                    R.string.widget_updated_minutes, minutes.toInt(),
                )
                else -> context.getString(
                    R.string.widget_updated_hours, (minutes / 60).toInt(),
                )
            }
        }

        private fun dotFor(tone: GyeoteWidgetSnapshot.Tone): Int = when (tone) {
            GyeoteWidgetSnapshot.Tone.ALERT -> R.drawable.widget_dot_alert
            GyeoteWidgetSnapshot.Tone.WARM -> R.drawable.widget_dot_warm
            GyeoteWidgetSnapshot.Tone.BRAND -> R.drawable.widget_dot_brand
        }

        private fun openAppIntent(context: Context): PendingIntent {
            val intent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
