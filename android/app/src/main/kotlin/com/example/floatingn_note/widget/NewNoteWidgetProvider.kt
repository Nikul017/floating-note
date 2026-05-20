package com.example.floatingn_note.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import com.example.floatingn_note.R
import com.example.floatingn_note.services.OverlayService

class NewNoteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val intent = Intent(context, OverlayService::class.java).apply {
                action = OverlayService.ACTION_QUICK_CREATE
            }
            val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(
                    context,
                    1001,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getService(
                    context,
                    1001,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
            }

            val views = RemoteViews(context.packageName, R.layout.widget_new_note)
            views.setOnClickPendingIntent(R.id.btn_new_note, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
