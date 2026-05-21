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
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SETTINGS',
          style: AppTypography.displayMedium.copyWith(
            fontSize: 22,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: PressableScale(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Permissions & Services'),
            AppSpacing.h12,
            _buildSettingsCard(
              child: Column(
                children: [
                  // Overlay Permission Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.display_settings_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      AppSpacing.w16,
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
                                    ? const Color(0xFF008A5E) // Accessible green
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.security_rounded, size: 14, color: Colors.black),
                                AppSpacing.w8,
                                Text(
                                  'GRANT',
                                  style: AppTypography.captionSemibold.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.stickyNoteColors['mint'],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.black,
                                size: 14,
                              ),
                              AppSpacing.w4,
                              Text(
                                'ACTIVE',
                                style: AppTypography.captionSemibold.copyWith(
                                  color: Colors.black,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Divider(color: AppColors.border, height: 32, thickness: 2),
                  // Active Service Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isServiceActive ? AppColors.accent : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.offline_bolt_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      AppSpacing.w16,
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
                                    ? const Color(0xFF008A5E) // Accessible green
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isServiceActive,
                        activeColor: Colors.black,
                        activeTrackColor: AppColors.accent,
                        inactiveThumbColor: Colors.black,
                        inactiveTrackColor: Colors.white,
                        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                          (states) => AppColors.border,
                        ),
                        onChanged: _toggleService,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: AppMotion.page).slideY(begin: 0.05, end: 0, curve: AppMotion.curvePage),
            AppSpacing.h24,

            _buildSectionHeader('Appearance Settings'),
            AppSpacing.h12,
            _buildSettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_size_select_large_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                      AppSpacing.w8,
                      Text(
                        'Global Floating Bubble Size',
                        style: AppTypography.bodySemibold,
                      ),
                    ],
                  ),
                  AppSpacing.h4,
                  Padding(
                    padding: const EdgeInsets.only(left: 26.0),
                    child: Text(
                      'Choose the size of all active floating bubbles on the screen.',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
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
                  Divider(color: AppColors.border, height: 32, thickness: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.category_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                      AppSpacing.w8,
                      Text(
                        'Global Floating Bubble Shape',
                        style: AppTypography.bodySemibold,
                      ),
                    ],
                  ),
                  AppSpacing.h4,
                  Padding(
                    padding: const EdgeInsets.only(left: 26.0),
                    child: Text(
                      'Choose the shape of the docked floating notes.',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border.all(color: Colors.black, width: 2),
          ),
        ),
        AppSpacing.w12,
        Text(
          title.toUpperCase(),
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
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
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: AppTypography.bodySemibold.copyWith(
                  color: Colors.black,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
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
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.black,
            ),
            AppSpacing.w8,
            Text(
              label.toUpperCase(),
              style: AppTypography.bodySemibold.copyWith(
                color: Colors.black,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
