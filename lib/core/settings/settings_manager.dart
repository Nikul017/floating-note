import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  final int globalBubbleSize;
  final String globalBubbleShape;
  final List<String> folders;
  final bool isGridView;

  AppSettings({
    this.globalBubbleSize = 60, // Default to Medium (60)
    this.globalBubbleShape = 'circle', // Default to Circle
    this.folders = const ['Work', 'Personal', 'Ideas'],
    this.isGridView = true,
  });

  AppSettings copyWith({
    int? globalBubbleSize,
    String? globalBubbleShape,
    List<String>? folders,
    bool? isGridView,
  }) {
    return AppSettings(
      globalBubbleSize: globalBubbleSize ?? this.globalBubbleSize,
      globalBubbleShape: globalBubbleShape ?? this.globalBubbleShape,
      folders: folders ?? this.folders,
      isGridView: isGridView ?? this.isGridView,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'globalBubbleSize': globalBubbleSize,
      'globalBubbleShape': globalBubbleShape,
      'folders': folders,
      'isGridView': isGridView,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      globalBubbleSize: map['globalBubbleSize'] ?? 60,
      globalBubbleShape: map['globalBubbleShape'] ?? 'circle',
      folders: map['folders'] != null 
          ? List<String>.from(map['folders']) 
          : const ['Work', 'Personal', 'Ideas'],
      isGridView: map['isGridView'] ?? true,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    loadSettings();
  }

  Future<File> get _settingsFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/app_settings.json');
  }

  Future<void> loadSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = json.decode(content) as Map<String, dynamic>;
        state = AppSettings.fromMap(map);
      }
    } catch (e) {
      // Keep default configuration
    }
  }

  Future<void> _save() async {
    try {
      final file = await _settingsFile;
      await file.writeAsString(json.encode(state.toMap()));
    } catch (e) {
      // Ignore write errors
    }
  }

  Future<void> updateBubbleSize(int size) async {
    state = state.copyWith(globalBubbleSize: size);
    await _save();
  }

  Future<void> updateBubbleShape(String shape) async {
    state = state.copyWith(globalBubbleShape: shape);
    await _save();
  }

  Future<void> updateLayoutGrid(bool isGrid) async {
    state = state.copyWith(isGridView: isGrid);
    await _save();
  }

  Future<void> addFolder(String folderName) async {
    final normalized = folderName.trim();
    if (normalized.isNotEmpty && !state.folders.contains(normalized)) {
      state = state.copyWith(folders: [...state.folders, normalized]);
      await _save();
    }
  }

  Future<void> removeFolder(String folderName) async {
    state = state.copyWith(folders: state.folders.where((f) => f != folderName).toList());
    await _save();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

