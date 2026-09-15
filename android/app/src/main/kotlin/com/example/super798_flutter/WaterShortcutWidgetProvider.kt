package com.example.super798_flutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class WaterShortcutWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { widgetId -> manager.updateAppWidget(widgetId, createViews(context)) }
    }

    companion object {
        private const val PREFS = "water_shortcut_widget"
        private const val DEVICE_NAME = "device_name"

        fun saveDevice(context: Context, name: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(DEVICE_NAME, name).apply()
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, WaterShortcutWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            ids.forEach { widgetId -> manager.updateAppWidget(widgetId, createViews(context)) }
        }

        private fun createViews(context: Context): RemoteViews {
            val configuredName = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(DEVICE_NAME, null)
            val name = configuredName ?: "我的净水器"
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            return RemoteViews(context.packageName, R.layout.water_shortcut_widget).apply {
                setTextViewText(R.id.widget_device_name, name)
                setTextViewText(R.id.widget_hint, if (configuredName == null) "请在应用内选择快捷设备" else "点击启动按钮打开应用")
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                setOnClickPendingIntent(R.id.widget_start_button, pendingIntent)
            }
        }
    }
}
