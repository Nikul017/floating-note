package com.example.floatingn_note.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import com.example.floatingn_note.overlay.ChecklistItemData
import com.example.floatingn_note.overlay.FloatingNoteView
import com.example.floatingn_note.overlay.NoteData
import io.flutter.plugin.common.MethodChannel

class OverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private val activeOverlays = HashMap<String, FloatingNoteView>()
    private var deleteZoneView: DeleteZoneView? = null

    companion object {
        const val ACTION_QUICK_CREATE = "com.example.floatingn_note.ACTION_QUICK_CREATE"
        var instance: OverlayService? = null
        var methodChannel: MethodChannel? = null

        fun isRunning(): Boolean = instance != null

        // Static methods to trigger overlay updates from MethodChannel
        fun createOrUpdate(note: NoteData) {
            instance?.let { service ->
                Handler(Looper.getMainLooper()).post {
                    service.createOrUpdateOverlay(note)
                }
            }
        }

        fun remove(id: String) {
            instance?.let { service ->
                Handler(Looper.getMainLooper()).post {
                    service.removeOverlay(id)
                }
            }
        }

        fun updateAll(notes: List<NoteData>) {
            instance?.let { service ->
                Handler(Looper.getMainLooper()).post {
                    service.updateAllOverlays(notes)
                }
            }
        }

        fun stop() {
            instance?.let { service ->
                Handler(Looper.getMainLooper()).post {
                    service.stopService()
                }
            }
        }

        // static Delete Zone view controllers called from FloatingNoteView gestures
        fun showDeleteZone() {
            instance?.deleteZoneView?.show()
        }

        fun hideDeleteZone() {
            instance?.deleteZoneView?.hide()
        }

        fun updateDeleteZoneHover(noteView: FloatingNoteView, isHovered: Boolean) {
            instance?.deleteZoneView?.setTrashHovered(isHovered)
        }

        fun isOverDeleteZone(noteView: FloatingNoteView): Boolean {
            val service = instance ?: return false
            val trash = service.deleteZoneView ?: return false
            if (trash.visibility != View.VISIBLE) return false

            val displayMetrics = service.resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = service.resources.displayMetrics.heightPixels

            val noteCenterX = noteView.params.x + noteView.width / 2
            val noteCenterY = noteView.params.y + noteView.height / 2

            val trashCenterX = screenWidth / 2
            // Since trash uses gravity = BOTTOM, trash.params.y is its offset from the bottom of the screen
            val trashCenterY = screenHeight - service.dpToPx(50) - service.dpToPx(36) // 36dp is half of 72dp width/height

            val dx = noteCenterX - trashCenterX
            val dy = noteCenterY - trashCenterY
            val distance = Math.sqrt((dx * dx + dy * dy).toDouble())

            return distance < service.dpToPx(90) // 90dp responsive threshold
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startForegroundService()

        // Create the global invisible dustbin delete zone overlay!
        deleteZoneView = DeleteZoneView(this)
        windowManager.addView(deleteZoneView, deleteZoneView!!.params)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_QUICK_CREATE) {
            // Smoothly collapse the notification shade/drawer automatically!
            val closeIntent = Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS)
            sendBroadcast(closeIntent)

            Handler(Looper.getMainLooper()).post {
                methodChannel?.invokeMethod("onQuickCreate", null)
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun startForegroundService() {
        val channelId = "floatnotex_service_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Floating Notes Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent background workspace notification for Floating Notes"
                enableLights(false)
                enableVibration(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        // 1. Pending intent to create a quick note
        val quickCreateIntent = Intent(this, OverlayService::class.java).apply {
            action = ACTION_QUICK_CREATE
        }
        val quickCreatePendingIntent = PendingIntent.getService(
            this,
            201,
            quickCreateIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        // 2. Pending intent to launch the main app on tap
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val launchPendingIntent = PendingIntent.getActivity(
            this,
            202,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        // 3. Build a beautiful, styled and content-rich persistent notification
        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Floating Note Active")
            .setContentText("Tap to open app • Create quick notes instantly")
            .setSubText("Overlay Engine")
            .setSmallIcon(com.example.floatingn_note.R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setColor(Color.parseColor("#7C4DFF")) // Vibrant, premium purple brand color
            .setContentIntent(launchPendingIntent) // Launches dashboard when tapped
            .setOngoing(true)
            .setShowWhen(true)
            .setStyle(NotificationCompat.BigTextStyle()
                .setBigContentTitle("Floating Notes Workspace Running")
                .bigText("Your background overlay manager is active. Tapping this notification will open your notes Dashboard. Use the quick action button below to create and anchor a new note instantly.")
            )
            .addAction(
                com.example.floatingn_note.R.mipmap.ic_launcher,
                "➕ Quick Note",
                quickCreatePendingIntent
            )
            .build()

        // Handle Android 14 Special FGS Types
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                startForeground(
                    101,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } catch (e: Exception) {
                startForeground(101, notification)
            }
        } else {
            startForeground(101, notification)
        }
    }

    private fun createOrUpdateOverlay(note: NoteData) {
        val existing = activeOverlays[note.id]
        if (existing != null) {
            // Update fields and re-render
            existing.note.title = note.title
            existing.note.content = note.content
            existing.note.color = note.color
            existing.note.opacity = note.opacity
            existing.note.isDocked = note.isDocked
            existing.note.bubbleSize = note.bubbleSize
            existing.note.bubbleShape = note.bubbleShape
            existing.note.checklist = note.checklist
            
            // Adjust Window Params if toggling expand / collapse states
            val wasDocked = existing.params.width == dpToPx(existing.note.bubbleSize)
            if (note.isDocked != wasDocked) {
                if (note.isDocked) {
                    existing.note.isDocked = true
                    existing.params.width = dpToPx(note.bubbleSize)
                    existing.params.height = dpToPx(note.bubbleSize)
                } else {
                    existing.note.isDocked = false
                    existing.params.width = dpToPx(note.width.toInt())
                    existing.params.height = dpToPx(note.height.toInt())
                }
            }
            
            existing.alpha = note.opacity
            
            try {
                removeOverlay(note.id)
                createNewOverlay(note)
            } catch (e: Exception) {}
        } else {
            createNewOverlay(note)
        }
    }

    private fun createNewOverlay(note: NoteData) {
        val overlayView = FloatingNoteView(
            this,
            note,
            windowManager,
            onUpdate = { updatedNote ->
                sendUpdateToFlutter(updatedNote)
            },
            onDelete = { deletedId ->
                sendCloseToFlutter(deletedId)
                removeOverlay(deletedId)
            }
        )

        try {
            windowManager.addView(overlayView, overlayView.params)
            activeOverlays[note.id] = overlayView
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun removeOverlay(id: String) {
        val overlay = activeOverlays.remove(id)
        if (overlay != null) {
            try {
                windowManager.removeView(overlay)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun updateAllOverlays(notes: List<NoteData>) {
        val inputIds = notes.map { it.id }.toSet()
        val currentIds = activeOverlays.keys.toList()
        for (id in currentIds) {
            if (!inputIds.contains(id)) {
                removeOverlay(id)
            }
        }

        for (note in notes) {
            createOrUpdateOverlay(note)
        }
    }

    private fun sendUpdateToFlutter(note: NoteData) {
        Handler(Looper.getMainLooper()).post {
            val map = HashMap<String, Any>()
            map["id"] = note.id
            map["title"] = note.title
            map["content"] = note.content
            map["type"] = note.type
            map["color"] = note.color
            map["icon"] = note.icon
            map["opacity"] = note.opacity.toDouble()
            map["posX"] = note.posX.toDouble()
            map["posY"] = note.posY.toDouble()
            map["width"] = note.width.toDouble()
            map["height"] = note.height.toDouble()
            map["isDocked"] = if (note.isDocked) 1 else 0
            map["isLocked"] = if (note.isLocked) 1 else 0
            map["bubbleSize"] = note.bubbleSize
            map["bubbleShape"] = note.bubbleShape
            
            methodChannel?.invokeMethod("onNoteUpdated", map)
        }
    }

    private fun sendDeletionToFlutter(id: String) {
        Handler(Looper.getMainLooper()).post {
            methodChannel?.invokeMethod("onNoteDeleted", id)
        }
    }

    private fun sendCloseToFlutter(id: String) {
        Handler(Looper.getMainLooper()).post {
            methodChannel?.invokeMethod("onOverlayClosed", id)
        }
    }

    private fun stopService() {
        val keys = activeOverlays.keys.toList()
        for (key in keys) {
            removeOverlay(key)
        }
        deleteZoneView?.let {
            try {
                windowManager.removeView(it)
            } catch (e: Exception) {}
        }
        deleteZoneView = null
        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }
}

// Circular Trash Can (Dustbin) Overlay View that reacts dynamically to hover states
class DeleteZoneView(context: Context) : FrameLayout(context) {

    val params: WindowManager.LayoutParams
    private val circleView: TextView

    init {
        params = WindowManager.LayoutParams(
            dpToPx(72),
            dpToPx(72),
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = dpToPx(50) // Floating 50dp above bottom bar
        }

        circleView = TextView(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            gravity = Gravity.CENTER
            textSize = 28f
            text = "🗑️"
            
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#90263238")) // Matte dark-grey semi-transparent circle
                setStroke(dpToPx(2), Color.parseColor("#40FFFFFF"))
            }
        }
        addView(circleView)
        visibility = View.GONE
    }

    fun show() {
        visibility = View.VISIBLE
        setScale(1.0f)
        circleView.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor("#90263238"))
            setStroke(dpToPx(2), Color.parseColor("#40FFFFFF"))
        }
    }

    fun hide() {
        visibility = View.GONE
    }

    fun setTrashHovered(isHovered: Boolean) {
        if (isHovered) {
            setScale(1.3f) // Scale up on hover
            circleView.background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#F44336")) // Change to vibrant delete-red
                setStroke(dpToPx(3), Color.parseColor("#FFFFFF"))
            }
        } else {
            setScale(1.0f)
            circleView.background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#90263238"))
                setStroke(dpToPx(2), Color.parseColor("#40FFFFFF"))
            }
        }
    }

    private fun setScale(scale: Float) {
        animate().scaleX(scale).scaleY(scale).setDuration(150).start()
    }

    private fun dpToPx(dp: Int): Int {
        val density = context.resources.displayMetrics.density
        return (dp * density).toInt()
    }
}
