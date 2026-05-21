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

class VisiblesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val intent = Intent(context, OverlayService::class.java).apply {
                action = OverlayService.ACTION_TOGGLE_VISIBILITY
            }
            val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(
                    context,
                    1002,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getService(
                    context,
                    1002,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
            }

            val views = RemoteViews(context.packageName, R.layout.widget_visibles)
            views.setOnClickPendingIntent(R.id.btn_toggle_visibility, pendingIntent)

            // Dynamically show Visibles / Hidden state icon and text
            val isVisible = OverlayService.overlaysVisible
            val visibleIcon = if (isVisible) R.drawable.ic_visibles else R.drawable.ic_invisibles
            val visibleText = if (isVisible) "Visibles" else "Hidden"
            views.setImageViewResource(R.id.img_widget_visibles, visibleIcon)
            views.setTextViewText(R.id.txt_widget_visibles, visibleText)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
