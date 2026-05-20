package com.example.floatingn_note

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.example.floatingn_note.overlay.ChecklistItemData
import com.example.floatingn_note.overlay.NoteData
import com.example.floatingn_note.services.OverlayService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.floatnotex/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Link static channel reference in OverlayService for callbacks to Flutter
        OverlayService.methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "isServiceRunning" -> {
                    result.success(OverlayService.isRunning())
                }
                "startOverlayService" -> {
                    startOverlayService()
                    result.success(null)
                }
                "stopOverlayService" -> {
                    stopOverlayService()
                    result.success(null)
                }
                "createOverlay" -> {
                    val noteMap = call.arguments as? Map<String, Any>
                    if (noteMap != null) {
                        val note = parseNoteMap(noteMap)
                        OverlayService.createOrUpdate(note)
                        result.success(true)
                    } else {
                        result.error("BAD_ARGS", "Missing note parameters", null)
                    }
                }
                "updateOverlay" -> {
                    val noteMap = call.arguments as? Map<String, Any>
                    if (noteMap != null) {
                        val note = parseNoteMap(noteMap)
                        OverlayService.createOrUpdate(note)
                        result.success(true)
                    } else {
                        result.error("BAD_ARGS", "Missing note parameters", null)
                    }
                }
                "removeOverlay" -> {
                    val args = call.arguments as? Map<String, Any>
                    val id = args?.get("id") as? String
                    if (id != null) {
                        OverlayService.remove(id)
                        result.success(true)
                    } else {
                        result.error("BAD_ARGS", "Missing note id", null)
                    }
                }
                "updateAllOverlays" -> {
                    val args = call.arguments as? Map<String, Any>
                    val notesList = args?.get("notes") as? List<Map<String, Any>>
                    if (notesList != null) {
                        val notes = notesList.map { parseNoteMap(it) }
                        OverlayService.updateAll(notes)
                        result.success(true)
                    } else {
                        result.error("BAD_ARGS", "Missing notes list", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            }
        }
    }

    private fun startOverlayService() {
        if (!OverlayService.isRunning()) {
            val intent = Intent(this, OverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }

    private fun stopOverlayService() {
        if (OverlayService.isRunning()) {
            OverlayService.stop()
        }
    }

    // Type-safe map parser to NoteData (converts Dart double/ints cleanly to Float/Double)
    private fun parseNoteMap(map: Map<String, Any>): NoteData {
        val id = map["id"] as? String ?: ""
        val title = map["title"] as? String ?: ""
        val content = map["content"] as? String ?: ""
        val type = map["type"] as? String ?: "plain"
        val color = map["color"] as? String ?: "yellow"
        val icon = map["icon"] as? String ?: "📌"
        val opacity = (map["opacity"] as? Number)?.toFloat() ?: 0.9f
        val posX = (map["posX"] as? Number)?.toFloat() ?: 100f
        val posY = (map["posY"] as? Number)?.toFloat() ?: 200f
        val width = (map["width"] as? Number)?.toFloat() ?: 250f
        val height = (map["height"] as? Number)?.toFloat() ?: 220f
        val isDocked = (map["isDocked"] as? Number)?.toInt() == 1
        val isLocked = (map["isLocked"] as? Number)?.toInt() == 1
        val bubbleSize = (map["bubbleSize"] as? Number)?.toInt() ?: 60
        val bubbleShape = map["bubbleShape"] as? String ?: "circle"

        val checklistData = mutableListOf<ChecklistItemData>()
        val rawChecklist = map["checklist"] as? List<Map<String, Any>>
        if (rawChecklist != null) {
            for (itemMap in rawChecklist) {
                val itemId = itemMap["id"] as? String ?: ""
                val itemNoteId = itemMap["noteId"] as? String ?: ""
                val itemText = itemMap["text"] as? String ?: ""
                val itemChecked = (itemMap["checked"] as? Number)?.toInt() == 1
                val itemIndent = (itemMap["indent"] as? Number)?.toInt() ?: 0
                checklistData.add(ChecklistItemData(itemId, itemNoteId, itemText, itemChecked, itemIndent))
            }
        }

        return NoteData(
            id, title, content, type, color, icon, opacity, posX, posY, width, height, isDocked, isLocked, bubbleSize, bubbleShape, checklistData
        )
    }
}
