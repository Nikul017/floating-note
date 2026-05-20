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

class ControlBarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_control_bar)

            // 1. New Button Pending Intent
            val newIntent = Intent(context, OverlayService::class.java).apply {
                action = OverlayService.ACTION_QUICK_CREATE
            }
            val newPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(
                    context,
                    2001,
                    newIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getService(
                    context,
                    2001,
                    newIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
            }
            views.setOnClickPendingIntent(R.id.btn_bar_new, newPendingIntent)

            // 2. Schedule Button Pending Intent (Opens main app)
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val schedulePendingIntent = PendingIntent.getActivity(
                context,
                2002,
                launchIntent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )
            views.setOnClickPendingIntent(R.id.btn_bar_schedule, schedulePendingIntent)

            // 3. Visibles Button Pending Intent
            val visiblesIntent = Intent(context, OverlayService::class.java).apply {
                action = OverlayService.ACTION_TOGGLE_VISIBILITY
            }
            val visiblesPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(
                    context,
                    2003,
                    visiblesIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getService(
                    context,
                    2003,
                    visiblesIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
            }
            views.setOnClickPendingIntent(R.id.btn_bar_visibles, visiblesPendingIntent)

            // 4. Stick Button Pending Intent
            val stickIntent = Intent(context, OverlayService::class.java).apply {
                action = OverlayService.ACTION_TOGGLE_DOCK_ALL
            }
            val stickPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(
                    context,
                    2004,
                    stickIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getService(
                    context,
                    2004,
                    stickIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
            }
            views.setOnClickPendingIntent(R.id.btn_bar_stick, stickPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
