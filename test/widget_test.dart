import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floatingn_note/main.dart';
import 'package:floatingn_note/features/notes/providers/notes_provider.dart';
import 'package:floatingn_note/core/settings/settings_manager.dart';
import 'screenshot_generator_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('com.example.floatnotex/overlay');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'checkOverlayPermission') {
        return true;
      }
      if (methodCall.method == 'isServiceRunning') {
        return true;
      }
      return null;
    });
  });

  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    final mockSettings = MockSettingsNotifier(AppSettings(
      folders: ['Work', 'Personal', 'Ideas'],
      isGridView: true,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) => MockNotesNotifier(ref, mockNotesList)),
          settingsProvider.overrideWith((ref) => mockSettings),
        ],
        child: const FloatNoteXApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that our dashboard screen renders search bar menu icon and add button
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Add Note'), findsOneWidget);
  });
}
