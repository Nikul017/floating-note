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
          'Settings',
          style: AppTypography.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
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
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.display_settings_rounded,
                          color: AppColors.primary,
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
                                    ? AppColors.primary
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
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.security_rounded, size: 14, color: Colors.white),
                                AppSpacing.w8,
                                Text(
                                  'Grant',
                                  style: AppTypography.captionSemibold.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                  Divider(color: AppColors.border.withOpacity(0.5), height: 32, thickness: 1),
                  // Active Service Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (_isServiceActive ? AppColors.primary : AppColors.textSecondary).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_isServiceActive ? AppColors.primary : AppColors.textSecondary).withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.offline_bolt_rounded,
                          color: _isServiceActive ? AppColors.primary : AppColors.textSecondary,
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
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isServiceActive,
                        activeColor: AppColors.accent,
                        activeTrackColor: AppColors.primary.withOpacity(0.2),
                        inactiveThumbColor: AppColors.textSecondary,
                        inactiveTrackColor: AppColors.cardBg,
                        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary.withOpacity(0.5);
                            }
                            return AppColors.border;
                          },
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
                        color: AppColors.primary,
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
                  Divider(color: AppColors.border.withOpacity(0.5), height: 32, thickness: 1),
                  Row(
                    children: [
                      const Icon(
                        Icons.category_rounded,
                        color: AppColors.primary,
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
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        AppSpacing.w12,
        Text(
          title,
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600, // Outfit-semibold
            letterSpacing: 0.2,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSizeOption(int size, String label, int currentSize) {
    final isSelected = currentSize == size;
    return Expanded(
      child: AnimatedScale(
        scale: isSelected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: PressableScale(
          onTap: () async {
            await ref.read(settingsProvider.notifier).updateBubbleSize(size);
            if (_isServiceActive) {
              _syncAllOverlaysWithSettings();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(1.5), // Gradient border width spacer
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.5),
                color: isSelected ? null : AppColors.cardBg.withOpacity(0.5),
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.12),
                          AppColors.primary.withOpacity(0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.border.withOpacity(0.4),
                        width: 1,
                      ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTypography.bodySemibold.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
    return AnimatedScale(
      scale: isSelected ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: PressableScale(
        onTap: () async {
          await ref.read(settingsProvider.notifier).updateBubbleShape(shapeValue);
          if (_isServiceActive) {
            _syncAllOverlaysWithSettings();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(1.5), // Gradient border width spacer
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.5),
              color: isSelected ? null : AppColors.cardBg.withOpacity(0.5),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.12),
                        AppColors.primary.withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              border: isSelected
                  ? null
                  : Border.all(
                      color: AppColors.border.withOpacity(0.4),
                      width: 1,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                AppSpacing.w8,
                Text(
                  label,
                  style: AppTypography.bodySemibold.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
