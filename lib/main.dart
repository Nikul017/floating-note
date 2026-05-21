import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/platform/overlay_channel.dart';
import 'features/dashboard/views/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Explicitly initialize the OverlayChannel MethodCallHandler early
  OverlayChannel.instance;

  runApp(
    const ProviderScope(
      child: FloatNoteXApp(),
    ),
  );
}

class FloatNoteXApp extends StatelessWidget {
  const FloatNoteXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FloatNoteX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.brutalistTheme,
      home: const DashboardScreen(),
    );
  }
}
