import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:floatingn_note/features/dashboard/views/dashboard_screen.dart';
import 'package:floatingn_note/features/dashboard/views/settings_screen.dart';
import 'package:floatingn_note/features/notes/screens/note_editor_screen.dart';
import 'package:floatingn_note/features/notes/models/note_model.dart';
import 'package:floatingn_note/features/notes/providers/notes_provider.dart';
import 'package:floatingn_note/core/settings/settings_manager.dart';
import 'package:floatingn_note/theme/app_theme.dart';

// --- MOCK PROVIDERS ---

class MockNotesNotifier extends NotesNotifier {
  final List<Note> initialNotes;

  MockNotesNotifier(Ref ref, this.initialNotes) : super(ref) {
    state = initialNotes;
  }

  @override
  Future<void> loadNotes() async {
    state = initialNotes;
  }

  @override
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
    final newNote = Note(
      id: 'mock_new_note',
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
      bubbleSize: bubbleSize,
      folder: folder,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      checklistItems: checklistItems,
    );
    state = [newNote, ...state];
    return newNote;
  }

  @override
  Future<void> updateNote(Note note) async {
    state = [
      for (final n in state)
        if (n.id == note.id) note else n
    ];
  }

  @override
  Future<void> deleteNote(String id) async {
    state = state.where((n) => n.id != id).toList();
  }

  @override
  Future<void> toggleOverlay(Note note) async {
    // Empty stub
  }

  @override
  Future<void> addChecklistItem(String noteId, String itemText) async {
    // Empty stub
  }

  @override
  Future<void> toggleChecklistItem(String noteId, String itemId) async {
    // Empty stub
  }
}

class MockSettingsNotifier extends SettingsNotifier {
  final AppSettings initialSettings;

  MockSettingsNotifier(this.initialSettings) : super();

  @override
  Future<void> loadSettings() async {
    state = initialSettings;
  }

  @override
  Future<void> _save() async {
    // Override persistence to prevent path_provider calling channels
  }

  @override
  Future<void> updateBubbleSize(int size) async {
    state = state.copyWith(globalBubbleSize: size);
  }

  @override
  Future<void> updateBubbleShape(String shape) async {
    state = state.copyWith(globalBubbleShape: shape);
  }

  @override
  Future<void> updateLayoutGrid(bool isGrid) async {
    state = state.copyWith(isGridView: isGrid);
  }

  @override
  Future<void> addFolder(String folderName) async {
    state = state.copyWith(folders: [...state.folders, folderName]);
  }

  @override
  Future<void> removeFolder(String folderName) async {
    state = state.copyWith(folders: state.folders.where((f) => f != folderName).toList());
  }
}

// High fidelity mock data mimicking power-user's dashboard
final mockNotesList = [
  Note(
    id: '1',
    title: '💡 Design Sprint Ideas',
    content: '1. Create brutalist card borders.\n2. Add custom pastel color themes.\n3. Implement springy card animations using flutter_animate.',
    type: NoteType.plain,
    color: 'lavender',
    icon: '💡',
    opacity: 0.95,
    posX: 100,
    posY: 100,
    width: 250,
    height: 220,
    isDocked: false,
    isLocked: false,
    folder: 'Ideas',
    createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60,
    updatedAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 30,
  ),
  Note(
    id: '2',
    title: '🏃 Weekly Gym Workout',
    content: '',
    type: NoteType.checklist,
    color: 'mint',
    icon: '📌',
    opacity: 0.9,
    posX: 120,
    posY: 120,
    width: 250,
    height: 220,
    isDocked: false,
    isLocked: false,
    folder: 'Personal',
    createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 2,
    updatedAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60,
    checklistItems: [
      ChecklistItem(id: 'c1', noteId: '2', text: 'Squats: 5 sets x 5 reps', checked: true, indent: 0),
      ChecklistItem(id: 'c2', noteId: '2', text: 'Bench Press: 4 sets x 8 reps', checked: true, indent: 0),
      ChecklistItem(id: 'c3', noteId: '2', text: 'Deadlifts: 3 sets x 5 reps', checked: false, indent: 0),
      ChecklistItem(id: 'c4', noteId: '2', text: 'Core work / Stretching', checked: false, indent: 1),
    ],
  ),
  Note(
    id: '3',
    title: '🚀 App Launch Prep',
    content: '',
    type: NoteType.checklist,
    color: 'yellow',
    icon: '🚀',
    opacity: 0.95,
    posX: 140,
    posY: 140,
    width: 250,
    height: 220,
    isDocked: false,
    isLocked: true,
    folder: 'Work',
    createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24,
    updatedAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 2,
    checklistItems: [
      ChecklistItem(id: 'c5', noteId: '3', text: 'Generate Play Store assets', checked: false, indent: 0),
      ChecklistItem(id: 'c6', noteId: '3', text: 'Set up golden testing suite', checked: true, indent: 0),
      ChecklistItem(id: 'c7', noteId: '3', text: 'Upload beta build to Console', checked: false, indent: 0),
    ],
  ),
  Note(
    id: '4',
    title: '🕒 Reminder: Call Jack',
    content: '• Call design agency at 2 PM\n• Sync with marketing coordinator\n• Follow up on server issues',
    type: NoteType.reminder,
    color: 'blue',
    icon: '🕒',
    opacity: 0.9,
    posX: 160,
    posY: 160,
    width: 250,
    height: 220,
    isDocked: false,
    isLocked: false,
    folder: 'Personal',
    createdAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 5,
    updatedAt: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 5,
  ),
];

void main() {
  // Setup standard Flutter binding
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock standard overlay channel responses
  setUpAll(() {
    const channel = MethodChannel('com.example.floatnotex/overlay');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'checkOverlayPermission') {
        return true; // Simulate permission granted
      }
      if (methodCall.method == 'isServiceRunning') {
        return true; // Simulate service active
      }
      return null;
    });
  });

  group('Golden Screenshot Generator', () {
    final devices = [
      const Device(
        name: 'android',
        size: Size(390, 844),
        devicePixelRatio: 3.0, // 3x density → crisp at any zoom level
      ),
    ];

    testGoldens('Dashboard Screen', (tester) async {
          final mockSettings = MockSettingsNotifier(AppSettings(
        folders: ['Work', 'Personal', 'Ideas'],
        isGridView: true,
      ));

      final widget = ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) => MockNotesNotifier(ref, mockNotesList)),
          settingsProvider.overrideWith((ref) => mockSettings),
        ],
        child: MaterialApp(
          theme: AppTheme.brutalistTheme,
          debugShowCheckedModeBanner: false,
          home: const DashboardScreen(),
        ),
      );

      // Disable animations to capture fully drawn UI state
      Animate.restartOnHotReload = true;

      await tester.pumpWidgetBuilder(widget);
      // Wait for animations and layout to settle
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await multiScreenGolden(tester, 'dashboard_screen', devices: devices);
    });

    testGoldens('Note Editor Text Note', (tester) async {
      final widget = ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) => MockNotesNotifier(ref, mockNotesList)),
          settingsProvider.overrideWith((ref) => MockSettingsNotifier(AppSettings())),
        ],
        child: MaterialApp(
          theme: AppTheme.brutalistTheme,
          debugShowCheckedModeBanner: false,
          home: NoteEditorScreen(note: mockNotesList[0]),
        ),
      );

      await tester.pumpWidgetBuilder(widget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await multiScreenGolden(tester, 'note_editor_text_note', devices: devices);
    });

    testGoldens('Note Editor Checklist Note', (tester) async {
      final widget = ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) => MockNotesNotifier(ref, mockNotesList)),
          settingsProvider.overrideWith((ref) => MockSettingsNotifier(AppSettings())),
        ],
        child: MaterialApp(
          theme: AppTheme.brutalistTheme,
          debugShowCheckedModeBanner: false,
          home: NoteEditorScreen(note: mockNotesList[1]),
        ),
      );

      await tester.pumpWidgetBuilder(widget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await multiScreenGolden(tester, 'note_editor_checklist_note', devices: devices);
    });

    testGoldens('Settings Screen', (tester) async {
      final widget = ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) => MockNotesNotifier(ref, mockNotesList)),
          settingsProvider.overrideWith((ref) => MockSettingsNotifier(AppSettings(
            globalBubbleSize: 60,
            globalBubbleShape: 'squircle',
            folders: ['Work', 'Personal', 'Ideas', 'Fitness', 'Shopping'],
          ))),
        ],
        child: MaterialApp(
          theme: AppTheme.brutalistTheme,
          debugShowCheckedModeBanner: false,
          home: const SettingsScreen(),
        ),
      );

      await tester.pumpWidgetBuilder(widget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await multiScreenGolden(tester, 'settings_screen', devices: devices);
    });
  });
}
