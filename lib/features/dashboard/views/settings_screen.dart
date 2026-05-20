import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/platform/overlay_channel.dart';
import '../../../core/settings/settings_manager.dart';
import '../../../core/spacing/app_spacing.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/motion/app_motion.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/buttons/pressable_scale.dart';
import '../../notes/providers/notes_provider.dart';

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
        title: Text('Settings', style: AppTypography.headingLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title: Permissions & Services
            Text(
              'Permissions & Services',
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            AppSpacing.h12,
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
                            Text(
                              'Overlay Permission',
                              style: AppTypography.bodySemibold,
                            ),
                            AppSpacing.h4,
                            Text(
                              _hasOverlayPermission
                                  ? 'Permission granted successfully'
                                  : 'Required to show floating notes over other apps',
                              style: AppTypography.caption.copyWith(
                                color: _hasOverlayPermission
                                    ? Colors.greenAccent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.w8,
                      if (!_hasOverlayPermission)
                        PressableScale(
                          onTap: _requestPermission,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.security, size: 14, color: Colors.white),
                                AppSpacing.w4,
                                Text(
                                  'Grant',
                                  style: AppTypography.captionSemibold.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
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
                            Text(
                              'Active Overlay Service',
                              style: AppTypography.bodySemibold,
                            ),
                            AppSpacing.h4,
                            Text(
                              _isServiceActive
                                  ? 'Active overlay service is running'
                                  : 'Start service to allow floating notes',
                              style: AppTypography.caption.copyWith(
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
            ).animate().fadeIn(duration: AppMotion.page).slideY(begin: 0.05, end: 0, curve: AppMotion.curvePage),
            AppSpacing.h32,

            // Section title: Appearance Settings
            Text(
              'Appearance Settings',
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            AppSpacing.h12,
            _buildSettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Global Floating Bubble Size',
                    style: AppTypography.bodySemibold,
                  ),
                  AppSpacing.h4,
                  Text(
                    'Choose the size of all active floating bubbles on the screen.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  AppSpacing.h16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSizeOption(45, 'Small', settings.globalBubbleSize),
                      _buildSizeOption(60, 'Medium', settings.globalBubbleSize),
                      _buildSizeOption(75, 'Large', settings.globalBubbleSize),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 32),
                  Text(
                    'Global Floating Bubble Shape',
                    style: AppTypography.bodySemibold,
                  ),
                  AppSpacing.h4,
                  Text(
                    'Choose the shape of the docked floating notes.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  AppSpacing.h16,
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
            ).animate(delay: 80.ms).fadeIn(duration: AppMotion.page).slideY(begin: 0.05, end: 0, curve: AppMotion.curvePage),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
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
      child: PressableScale(
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
            color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.captionSemibold.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeOption(String shapeValue, String label, IconData icon, String currentShape) {
    final isSelected = currentShape == shapeValue;
    return PressableScale(
      onTap: () async {
        await ref.read(settingsProvider.notifier).updateBubbleShape(shapeValue);
        if (_isServiceActive) {
          _syncAllOverlaysWithSettings();
        }
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
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
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            AppSpacing.w8,
            Text(
              label,
              style: AppTypography.captionSemibold.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
