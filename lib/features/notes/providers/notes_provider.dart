import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/platform/overlay_channel.dart';
import '../../../core/settings/settings_manager.dart';
import '../models/note_model.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier(ref);
});

class NotesNotifier extends StateNotifier<List<Note>> {
  final Ref ref;
  final _uuid = const Uuid();

  NotesNotifier(this.ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await loadNotes();

    // Register callbacks from the native platform overlay
    OverlayChannel.instance.onNoteUpdatedCallback = (updatedNote) {
      _updateNoteInState(updatedNote);
    };

    OverlayChannel.instance.onNoteDeletedCallback = (deletedId) {
      _deleteNoteFromState(deletedId);
    };

    OverlayChannel.instance.onQuickCreateCallback = () async {
      final count = state.length;
      final offset = (count % 5) * 35.0;
      return await addNote(
        title: '',
        content: '',
        type: NoteType.plain,
        color: 'yellow',
        icon: '📌',
        posX: 150.0 + offset,
        posY: 250.0 + offset,
      );
    };

    try {
      await OverlayChannel.instance.notifyDartInitialized();
    } catch (e) {
      print('Error notifying native overlay of Dart initialization: $e');
    }
  }

  Future<void> loadNotes() async {
    try {
      final notes = await DatabaseService.instance.getAllNotes();
      state = notes;
    } catch (e) {
      print('Error loading notes from DB: $e');
    }
  }

  Future<Note> addNote({
    required String title,
    required String content,
    required NoteType type,
    required String color,
    required String icon,
    double opacity = 0.9,
    double posX = 100.0,
    double posY = 200.0,
    double width = 250.0,
    double height = 220.0,
    int bubbleSize = 60,
    String folder = '',
    List<ChecklistItem> checklistItems = const [],
    int? createdAt,
  }) async {
    final noteId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Create a copy of checklist items with proper noteId
    final mappedChecklist = checklistItems
        .map((item) => item.copyWith(noteId: noteId))
        .toList();

    final settings = ref.read(settingsProvider);
    final newNote = Note(
      id: noteId,
      title: title,
      content: content,
      type: type,
      color: color,
      icon: icon,
      opacity: opacity,
      posX: posX,
      posY: posY,
      width: width,
      height: height,
      isDocked: false,
      isLocked: false,
      bubbleSize: settings.globalBubbleSize,
      bubbleShape: settings.globalBubbleShape,
      folder: folder,
      createdAt: createdAt ?? now,
      updatedAt: now,
      checklistItems: mappedChecklist,
    );

    await DatabaseService.instance.insertNote(newNote);
    state = [newNote, ...state];

    // Trigger Kotlin native overlay rendering with the global bubble size and shape
    final noteWithGlobalSettings = newNote.copyWith(
      bubbleSize: settings.globalBubbleSize,
      bubbleShape: settings.globalBubbleShape,
    );
    await OverlayChannel.instance.createOverlay(noteWithGlobalSettings);

    return newNote;
  }

  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await DatabaseService.instance.updateNote(updatedNote);
    _updateNoteInState(updatedNote);

    // Sync changes to Kotlin native overlay with the global bubble size and shape
    final settings = ref.read(settingsProvider);
    final noteWithGlobalSettings = updatedNote.copyWith(
      bubbleSize: settings.globalBubbleSize,
      bubbleShape: settings.globalBubbleShape,
    );
    await OverlayChannel.instance.updateOverlay(noteWithGlobalSettings);
  }

  Future<void> deleteNote(String id) async {
    await DatabaseService.instance.deleteNote(id);
    _deleteNoteFromState(id);

    // Remove Kotlin native overlay
    await OverlayChannel.instance.removeOverlay(id);
  }

  Future<void> toggleOverlay(Note note) async {
    // If the service is running, toggle overlay rendering or position
    // For now, let's re-trigger overlay creation which expands a docked/minimized note
    final expandedNote = note.copyWith(
      isDocked: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await updateNote(expandedNote);
  }

  Future<void> addChecklistItem(String noteId, String itemText) async {
    final note = state.firstWhere((n) => n.id == noteId);
    final newItem = ChecklistItem(
      id: _uuid.v4(),
      noteId: noteId,
      text: itemText,
      checked: false,
    );

    final updatedChecklist = [...note.checklistItems, newItem];
    final updatedNote = note.copyWith(checklistItems: updatedChecklist);
    await updateNote(updatedNote);
  }

  Future<void> toggleChecklistItem(String noteId, String itemId) async {
    final note = state.firstWhere((n) => n.id == noteId);
    final updatedChecklist = note.checklistItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(checked: !item.checked);
      }
      return item;
    }).toList();

    final updatedNote = note.copyWith(checklistItems: updatedChecklist);
    await updateNote(updatedNote);
  }

  Future<void> removeFolderFromNotes(String folderName) async {
    final normalized = folderName.trim();
    for (final note in state) {
      if (note.folder == normalized) {
        await updateNote(note.copyWith(folder: ''));
      }
    }
  }

  // --- STATE HELPERS ---

  void _updateNoteInState(Note updatedNote) {
    state = [
      for (final note in state)
        if (note.id == updatedNote.id) updatedNote else note
    ];
  }

  void _deleteNoteFromState(String id) {
    state = state.where((note) => note.id != id).toList();
  }
}
