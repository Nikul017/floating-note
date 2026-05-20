import 'package:flutter/services.dart';
import '../../features/notes/models/note_model.dart';
import '../database/database_service.dart';

class OverlayChannel {
  static final OverlayChannel instance = OverlayChannel._init();
  static const MethodChannel _channel = MethodChannel('com.example.floatnotex/overlay');

  OverlayChannel._init() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  // Callbacks registered by Riverpod or view layers
  void Function(Note note)? onNoteUpdatedCallback;
  void Function(String noteId)? onNoteDeletedCallback;

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onNoteUpdated':
          final Map<String, dynamic> arguments = Map<String, dynamic>.from(call.arguments);
          final noteId = arguments['id'] as String;

          // Retrieve current checklist items from DB to preserve them, or Kotlin might pass checklist updates
          final existingNote = await DatabaseService.instance.getNoteById(noteId);
          final items = existingNote?.checklistItems ?? [];

          // Preserve the original database timestamps when syncing from native Kotlin
          if (existingNote != null) {
            arguments['createdAt'] ??= existingNote.createdAt;
            arguments['updatedAt'] ??= existingNote.updatedAt;
          }

          final updatedNote = Note.fromMap(arguments, checklistItems: items);
          await DatabaseService.instance.updateNote(updatedNote);

          if (onNoteUpdatedCallback != null) {
            onNoteUpdatedCallback!(updatedNote);
          }
          break;

        case 'onNoteDeleted':
          final noteId = call.arguments as String;
          await DatabaseService.instance.deleteNote(noteId);

          if (onNoteDeletedCallback != null) {
            onNoteDeletedCallback!(noteId);
          }
          break;

        case 'onOverlayClosed':
          final noteId = call.arguments as String;
          final existingNote = await DatabaseService.instance.getNoteById(noteId);
          if (existingNote != null) {
            // Update docked state or open state
            final updatedNote = existingNote.copyWith(isDocked: true, updatedAt: DateTime.now().millisecondsSinceEpoch);
            await DatabaseService.instance.updateNote(updatedNote);

            if (onNoteUpdatedCallback != null) {
              onNoteUpdatedCallback!(updatedNote);
            }
          }
          break;

        case 'onQuickCreate':
          final newNote = Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'New Note',
            content: 'Tap to write...',
            type: NoteType.plain,
            color: 'yellow',
            icon: '📌',
            opacity: 0.95,
            posX: 150.0,
            posY: 250.0,
            width: 250.0,
            height: 220.0,
            isDocked: false,
            isLocked: false,
            bubbleSize: 60,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await DatabaseService.instance.insertNote(newNote);
          await createOverlay(newNote);
          if (onNoteUpdatedCallback != null) {
            onNoteUpdatedCallback!(newNote);
          }
          break;

        default:
          print('Unknown method called from native overlay: ${call.method}');
      }
    } catch (e) {
      print('Error in OverlayChannel MethodCallHandler: $e');
    }
  }

  // --- ACTIONS FLUTTER -> KOTLIN ---

  Future<bool> checkOverlayPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkOverlayPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print('Failed to check overlay permission: ${e.message}');
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print('Failed to request overlay permission: ${e.message}');
    }
  }

  Future<bool> isServiceRunning() async {
    try {
      final bool running = await _channel.invokeMethod('isServiceRunning');
      return running;
    } on PlatformException catch (e) {
      print('Failed to check if service running: ${e.message}');
      return false;
    }
  }

  Future<void> startOverlayService() async {
    try {
      await _channel.invokeMethod('startOverlayService');
    } on PlatformException catch (e) {
      print('Failed to start overlay service: ${e.message}');
    }
  }

  Future<void> stopOverlayService() async {
    try {
      await _channel.invokeMethod('stopOverlayService');
    } on PlatformException catch (e) {
      print('Failed to stop overlay service: ${e.message}');
    }
  }

  Future<void> createOverlay(Note note) async {
    try {
      await _channel.invokeMethod('createOverlay', _noteToMap(note));
    } on PlatformException catch (e) {
      print('Failed to create native overlay: ${e.message}');
    }
  }

  Future<void> updateOverlay(Note note) async {
    try {
      await _channel.invokeMethod('updateOverlay', _noteToMap(note));
    } on PlatformException catch (e) {
      print('Failed to update native overlay: ${e.message}');
    }
  }

  Future<void> removeOverlay(String noteId) async {
    try {
      await _channel.invokeMethod('removeOverlay', {'id': noteId});
    } on PlatformException catch (e) {
      print('Failed to remove native overlay: ${e.message}');
    }
  }

  Future<void> updateAllOverlays(List<Note> notes) async {
    try {
      final List<Map<String, dynamic>> maps = notes.map((note) => _noteToMap(note)).toList();
      await _channel.invokeMethod('updateAllOverlays', {'notes': maps});
    } on PlatformException catch (e) {
      print('Failed to update all native overlays: ${e.message}');
    }
  }

  Map<String, dynamic> _noteToMap(Note note) {
    final noteMap = note.toMap();
    // Add checklist items as raw JSON maps so Kotlin can render checkbox lists natively
    noteMap['checklist'] = note.checklistItems.map((item) => item.toMap()).toList();
    return noteMap;
  }
}
