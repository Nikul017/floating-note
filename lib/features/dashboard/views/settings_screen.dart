import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/overlay_channel.dart';
import '../../../core/settings/settings_manager.dart';
import '../../../theme/app_colors.dart';
import '../../notes/providers/notes_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool _hasOverlayPermission = false;
  bool _isServiceActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystemStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemStatus();
    }
  }

  Future<void> _checkSystemStatus() async {
    final permission = await OverlayChannel.instance.checkOverlayPermission();
    final service = await OverlayChannel.instance.isServiceRunning();
    setState(() {
      _hasOverlayPermission = permission;
      _isServiceActive = service;
    });
  }

  Future<void> _toggleService(bool value) async {
    if (!_hasOverlayPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please grant Overlay Permission first!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (value) {
      await OverlayChannel.instance.startOverlayService();
      await Future.delayed(const Duration(milliseconds: 300));
      _syncAllOverlaysWithSettings();
    } else {
      await OverlayChannel.instance.stopOverlayService();
    }
    _checkSystemStatus();
  }

  Future<void> _requestPermission() async {
    await OverlayChannel.instance.requestOverlayPermission();
    Future.delayed(const Duration(seconds: 1), _checkSystemStatus);
  }

  Future<void> _syncAllOverlaysWithSettings() async {
    final settings = ref.read(settingsProvider);
    final notes = ref.read(notesProvider).map((note) => note.copyWith(
      bubbleSize: settings.globalBubbleSize,
      bubbleShape: settings.globalBubbleShape,
    )).toList();
    await OverlayChannel.instance.updateAllOverlays(notes);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title: Permissions & Services
            const Text(
              'Permissions & Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              child: Column(
                children: [
                  // Overlay Permission Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overlay Permission',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _hasOverlayPermission
                                  ? 'Permission granted successfully'
                                  : 'Required to show floating notes over other apps',
                              style: TextStyle(
                                fontSize: 12,
                                color: _hasOverlayPermission
                                    ? Colors.greenAccent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!_hasOverlayPermission)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _requestPermission,
                          icon: const Icon(Icons.security, size: 16),
                          label: const Text('Grant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        )
                      else
                        const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  // Active Service Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Overlay Service',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isServiceActive
                                  ? 'Active overlay service is running'
                                  : 'Start service to allow floating notes',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isServiceActive
                                    ? Colors.greenAccent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isServiceActive,
                        activeColor: AppColors.primary,
                        onChanged: _toggleService,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            // Section title: Appearance Settings
            const Text(
              'Appearance Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global Floating Bubble Size',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the size of all active floating bubbles on the screen.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSizeOption(45, 'Small', settings.globalBubbleSize),
                      _buildSizeOption(60, 'Medium', settings.globalBubbleSize),
                      _buildSizeOption(75, 'Large', settings.globalBubbleSize),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 32),
                  const Text(
                    'Global Floating Bubble Shape',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the shape of the docked floating notes.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildShapeOption('circle', 'Circle', Icons.circle_outlined, settings.globalBubbleShape),
                      _buildShapeOption('square', 'Square', Icons.crop_square_outlined, settings.globalBubbleShape),
                      _buildShapeOption('squircle', 'Squircle', Icons.layers_outlined, settings.globalBubbleShape),
                      _buildShapeOption('hexagon', 'Hexagon', Icons.hexagon_outlined, settings.globalBubbleShape),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSizeOption(int size, String label, int currentSize) {
    final isSelected = currentSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await ref.read(settingsProvider.notifier).updateBubbleSize(size);
          if (_isServiceActive) {
            _syncAllOverlaysWithSettings();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeOption(String shapeValue, String label, IconData icon, String currentShape) {
    final isSelected = currentShape == shapeValue;
    return InkWell(
      onTap: () async {
        await ref.read(settingsProvider.notifier).updateBubbleShape(shapeValue);
        if (_isServiceActive) {
          _syncAllOverlaysWithSettings();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected && icon == Icons.favorite_border ? Icons.favorite : 
              isSelected && icon == Icons.star_border ? Icons.star : 
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
