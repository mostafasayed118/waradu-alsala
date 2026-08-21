package com.salawat.salawat_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class SalawatWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val name = widgetData.getString("counter_name", "")
            val count = widgetData.getInt("counter_count", 0)

            val views = RemoteViews(context.packageName, R.layout.salawat_widget).apply {
                setTextViewText(R.id.widget_counter_name, name)
                setTextViewText(R.id.widget_counter_count, count.toString())

                val incrementPending = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("salawatwidget://increment")
                )
                setOnClickPendingIntent(R.id.widget_increment_button, incrementPending)

                val openPending = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("salawatwidget://open")
                )
                setOnClickPendingIntent(R.id.widget_counter_count, openPending)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
