import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load app fonts declared in pubspec.yaml (SpaceGrotesk, PlusJakartaSans, etc.)
  await loadAppFonts();

  await testMain();
}
