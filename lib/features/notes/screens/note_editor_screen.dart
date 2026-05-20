import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../core/spacing/app_spacing.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/motion/app_motion.dart';
import '../../../widgets/buttons/pressable_scale.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../../../core/settings/settings_manager.dart';
import '../../../core/platform/overlay_channel.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _checklistInputController;

  late String _selectedColor;
  late String _selectedIcon;
  late NoteType _selectedType;
  late double _opacity;
  late bool _isLocked;
  late int _bubbleSize;
  late String _selectedFolder;
  late List<ChecklistItem> _checklistItems;

  late List<TextEditingController> _checklistControllers;
  late List<FocusNode> _checklistFocusNodes;
  final FocusNode _addItemFocusNode = FocusNode();
  int _focusedItemIndex = -1;

  late int _createdAt;
  late int _updatedAt;

  bool _showIconPicker = false;
  bool _showColorPicker = false;
  bool _isSaved = false;

  final List<String> _emojiGrid = [
    '📌', '💡', '🕒', '👥', '🛒', '📷', '♥️', '⭐️',
    '✈️', '🌐', '📞', '✉️', '⚠️', '🏠', 'ℹ️', '🍃',
    '🔒', '🔍', '🎤', '💵', '🎵', '🔔', '🖋️', '🖨️',
    '❓', '🚀', '👎', '👍', '🗑️', '💳', '💼', '🔥',
    '🛋️', '⌚️', '👁️', '⌨️', '🔱', '⛰️', '📱', '😄',
    '😵', '😃', '😌', '🙁', '🛡️', '🍴', '👤', '⏻',
    '🏊', '🐾', '🗣️', '🖱️', '🚲', '😄', '😢', '🌈'
  ];

  void _setupFocusNodeListener(FocusNode focusNode) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        final currentIdx = _checklistFocusNodes.indexOf(focusNode);
        if (currentIdx != -1) {
          setState(() {
            _focusedItemIndex = currentIdx;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _checklistInputController = TextEditingController();

    if (widget.note != null) {
      OverlayChannel.instance.removeOverlay(widget.note!.id);
    }

    _selectedColor = widget.note?.color ?? 'yellow';
    _selectedIcon = widget.note?.icon ?? '📌';
    _selectedType = widget.note?.type ?? NoteType.plain;
    _opacity = widget.note?.opacity ?? 0.9;
    _isLocked = widget.note?.isLocked ?? false;
    _bubbleSize = widget.note?.bubbleSize ?? 60;
    _selectedFolder = widget.note?.folder ?? '';
    _checklistItems = widget.note != null ? List.from(widget.note!.checklistItems) : [];
    _createdAt = widget.note?.createdAt ?? DateTime.now().millisecondsSinceEpoch;
    _updatedAt = widget.note?.updatedAt ?? DateTime.now().millisecondsSinceEpoch;

    _checklistControllers = _checklistItems.map((item) => TextEditingController(text: item.text)).toList();
    _checklistFocusNodes = _checklistItems.map((item) {
      final fn = FocusNode();
      _setupFocusNodeListener(fn);
      return fn;
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _checklistInputController.dispose();
    for (var c in _checklistControllers) {
      c.dispose();
    }
    for (var f in _checklistFocusNodes) {
      f.dispose();
    }
    _addItemFocusNode.dispose();
    
    if (widget.note != null && !_isSaved) {
      // Restore the overlay if the screen was closed without saving
      final settings = ref.read(settingsProvider);
      final noteWithGlobalSettings = widget.note!.copyWith(
        bubbleSize: settings.globalBubbleSize,
        bubbleShape: settings.globalBubbleShape,
      );
      OverlayChannel.instance.updateOverlay(noteWithGlobalSettings);
    }
    super.dispose();
  }

  void _saveNote() async {
    _isSaved = true;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (_selectedType == NoteType.checklist) {
      for (int i = 0; i < _checklistItems.length; i++) {
        _checklistItems[i] = _checklistItems[i].copyWith(text: _checklistControllers[i].text.trim());
      }
      _checklistItems.removeWhere((item) => item.text.isEmpty);
    }

    if (title.isEmpty && content.isEmpty && _checklistItems.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.note == null) {
      await ref.read(notesProvider.notifier).addNote(
            title: title,
            content: content,
            type: _selectedType,
            color: _selectedColor,
            icon: _selectedIcon,
            opacity: _opacity,
            bubbleSize: _bubbleSize,
            folder: _selectedFolder,
            checklistItems: _checklistItems,
            createdAt: _createdAt,
          );
    } else {
      final updated = widget.note!.copyWith(
        title: title,
        content: content,
        type: _selectedType,
        color: _selectedColor,
        icon: _selectedIcon,
        opacity: _opacity,
        isLocked: _isLocked,
        bubbleSize: _bubbleSize,
        folder: _selectedFolder,
        checklistItems: _checklistItems,
        createdAt: _createdAt,
      );
      await ref.read(notesProvider.notifier).updateNote(updated);
    }

    Navigator.pop(context);
  }

  void _addChecklistItem([String text = '']) {
    setState(() {
      final newItem = ChecklistItem(
        id: DateTime.now().toIso8601String(),
        noteId: widget.note?.id ?? '',
        text: text,
        checked: false,
        indent: 0,
      );
      _checklistItems.add(newItem);

      final controller = TextEditingController(text: text);
      _checklistControllers.add(controller);

      final focusNode = FocusNode();
      _setupFocusNodeListener(focusNode);
      _checklistFocusNodes.add(focusNode);

      _checklistInputController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    });
  }

  void _insertChecklistItem(int index) {
    setState(() {
      final newItem = ChecklistItem(
        id: DateTime.now().toIso8601String(),
        noteId: widget.note?.id ?? '',
        text: '',
        checked: false,
        indent: 0,
      );
      _checklistItems.insert(index, newItem);
      _checklistControllers.insert(index, TextEditingController());

      final focusNode = FocusNode();
      _setupFocusNodeListener(focusNode);
      _checklistFocusNodes.insert(index, focusNode);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    });
  }

  String _formatTimestamp(int timestamp, {bool showTime = true, bool verbose = false}) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    
    if (verbose) {
      final weekdayName = weekDays[dt.weekday - 1];
      return '$weekdayName, $month $day, $year at $hour:$minute $ampm';
    }
    
    if (showTime) {
      return '$month $day, $year, $hour:$minute $ampm';
    } else {
      return '$month $day, $year';
    }
  }

  Future<void> _editCreatedDate() async {
    final currentDate = DateTime.fromMillisecondsSinceEpoch(_createdAt);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;
    if (!context.mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;
    if (!context.mounted) return;

    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    setState(() {
      _createdAt = newDateTime.millisecondsSinceEpoch;
    });
    
    Navigator.pop(context);
    _showNoteDetailsSheet();
  }

  void _showNoteDetailsSheet() {
    final wordCount = _contentController.text.trim().isEmpty 
        ? 0 
        : _contentController.text.trim().split(RegExp(r'\s+')).length;
    final charCount = _contentController.text.length;
    final checklistWordCount = _checklistItems.fold<int>(0, (sum, item) {
      if (item.text.trim().isEmpty) return sum;
      return sum + item.text.trim().split(RegExp(r'\s+')).length;
    });
    final checklistCharCount = _checklistItems.fold<int>(0, (sum, item) => sum + item.text.length);

    final totalWords = wordCount + checklistWordCount;
    final totalChars = charCount + checklistCharCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                          AppSpacing.w8,
                          Text(
                            'Note Information',
                            style: AppTypography.headingLarge.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close, color: Colors.white70, size: 18),
                        ),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Created',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white54, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatTimestamp(_createdAt, verbose: true),
                          style: AppTypography.bodySemibold.copyWith(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar_outlined, color: AppColors.primary, size: 20),
                        tooltip: 'Change creation date',
                        onPressed: () async {
                          await _editCreatedDate();
                        },
                      ),
                    ],
                  ),
                  AppSpacing.h8,
                  if (widget.note != null) ...[
                    _buildDetailRow('Last Modified', _formatTimestamp(_updatedAt, verbose: true)),
                    AppSpacing.h12,
                  ],
                  _buildDetailRow('Characters', totalChars.toString()),
                  AppSpacing.h12,
                  _buildDetailRow('Words', totalWords.toString()),
                  AppSpacing.h12,
                  _buildDetailRow('Type', _selectedType.name.toUpperCase()),
                  if (_selectedFolder.isNotEmpty) ...[
                    AppSpacing.h12,
                    _buildDetailRow('Folder', _selectedFolder),
                  ],
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white54, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySemibold.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.getStickyColor(_selectedColor);
    final cardBorder = AppColors.getBorderColor(_selectedColor);
    final noteTextColor = AppColors.getStickyTextColor(_selectedColor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: InkWell(
          onTap: _showNoteDetailsSheet,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.note != null ? 'Created' : 'New Note',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                AppSpacing.h4,
                Text(
                  _formatTimestamp(_createdAt),
                  style: AppTypography.bodySemibold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E2C),
                    title: Text('Delete Note', style: AppTypography.headingLarge),
                    content: Text('Are you sure you want to delete this note?', style: AppTypography.bodyMedium),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel', style: AppTypography.bodySemibold.copyWith(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete', style: AppTypography.bodySemibold.copyWith(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await ref.read(notesProvider.notifier).deleteNote(widget.note!.id);
                  Navigator.pop(context);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary, size: 28),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Floating Dock toolbar of options (Icon, Color, Folder, Checklist toggle, Lock)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildToolbarButton(
                      icon: _selectedIcon,
                      isSelected: _showIconPicker,
                      textColor: AppColors.textPrimary,
                      onTap: () {
                        setState(() {
                          _showIconPicker = !_showIconPicker;
                          _showColorPicker = false;
                        });
                      },
                    ),
                    AppSpacing.w8,
                    _buildToolbarButton(
                      iconData: Icons.palette_outlined,
                      isSelected: _showColorPicker,
                      textColor: AppColors.textPrimary,
                      onTap: () {
                        setState(() {
                          _showColorPicker = !_showColorPicker;
                          _showIconPicker = false;
                        });
                      },
                    ),
                    AppSpacing.w8,
                    _buildToolbarButton(
                      iconData: Icons.folder_outlined,
                      isSelected: _selectedFolder.isNotEmpty,
                      textColor: AppColors.textPrimary,
                      onTap: _showFolderSelectionSheet,
                    ),
                    AppSpacing.w8,
                    _buildToolbarButton(
                      iconData: Icons.check_box_outlined,
                      isSelected: _selectedType == NoteType.checklist,
                      textColor: AppColors.textPrimary,
                      onTap: () {
                        setState(() {
                          if (_selectedType == NoteType.checklist) {
                            _selectedType = NoteType.plain;
                          } else {
                            _selectedType = NoteType.checklist;
                            if (_checklistItems.isEmpty) {
                              _addChecklistItem();
                            }
                          }
                        });
                      },
                    ),
                    AppSpacing.w8,
                    _buildToolbarButton(
                      iconData: _isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                      isSelected: _isLocked,
                      textColor: AppColors.textPrimary,
                      onTap: () {
                        setState(() {
                          _isLocked = !_isLocked;
                        });
                      },
                    ),

                  ],
                ),
              ),
            ),
            
            // Immersive Floating Note Canvas Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getGlowColor(_selectedColor),
                      blurRadius: 24,
                      spreadRadius: -8,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Representative Icon Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: noteTextColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _selectedIcon,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            AppSpacing.w12,
                            Expanded(
                              child: TextField(
                                controller: _titleController,
                                style: AppTypography.headingLarge.copyWith(
                                  color: noteTextColor,
                                  fontSize: 20,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Title',
                                  hintStyle: AppTypography.headingLarge.copyWith(
                                    color: noteTextColor.withOpacity(0.4),
                                    fontSize: 20,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.h4,
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: noteTextColor.withOpacity(0.08),
                        ),
                        AppSpacing.h8,
                        
                        // Folder and Attributes tag
                        if (_selectedFolder.isNotEmpty) ...[
                          Chip(
                            avatar: Icon(Icons.folder_open_rounded, size: 14, color: noteTextColor),
                            label: Text(
                              _selectedFolder,
                              style: AppTypography.captionSemibold.copyWith(color: noteTextColor),
                            ),
                            backgroundColor: noteTextColor.withOpacity(0.08),
                            side: BorderSide(color: noteTextColor.withOpacity(0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            deleteIcon: Icon(Icons.close_rounded, size: 14, color: noteTextColor.withOpacity(0.6)),
                            onDeleted: () {
                              setState(() {
                                _selectedFolder = '';
                              });
                            },
                          ),
                          AppSpacing.h12,
                        ],
                        
                        // Editor Body: Checklist vs Plain Text
                        if (_selectedType == NoteType.checklist) ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _checklistItems.length,
                            itemBuilder: (context, index) {
                              final item = _checklistItems[index];
                              final controller = _checklistControllers[index];
                              final focusNode = _checklistFocusNodes[index];

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    // Checkbox
                                    Checkbox(
                                      value: item.checked,
                                      activeColor: noteTextColor,
                                      checkColor: cardColor,
                                      side: BorderSide(color: noteTextColor.withOpacity(0.4), width: 1.2),
                                      onChanged: (val) {
                                        setState(() {
                                          _checklistItems[index] = item.copyWith(checked: val ?? false);
                                        });
                                      },
                                    ),
                                    
                                    // Item input
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: item.checked ? noteTextColor.withOpacity(0.4) : noteTextColor,
                                          decoration: item.checked ? TextDecoration.lineThrough : null,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'List item',
                                          hintStyle: AppTypography.bodyLarge.copyWith(
                                            color: noteTextColor.withOpacity(0.3),
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          filled: false,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        onSubmitted: (_) {
                                          _insertChecklistItem(index + 1);
                                        },
                                      ),
                                    ),
                                    
                                    // Delete checklist item
                                    IconButton(
                                      icon: Icon(Icons.close_rounded, size: 18, color: noteTextColor.withOpacity(0.4)),
                                      onPressed: () {
                                        setState(() {
                                          _checklistItems.removeAt(index);
                                          _checklistControllers.removeAt(index).dispose();
                                          _checklistFocusNodes.removeAt(index).dispose();
                                          if (_focusedItemIndex == index) {
                                            _focusedItemIndex = -1;
                                          } else if (_focusedItemIndex > index) {
                                            _focusedItemIndex--;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          AppSpacing.h8,
                          TextButton.icon(
                            onPressed: () => _addChecklistItem(),
                            icon: Icon(Icons.add_rounded, color: noteTextColor, size: 20),
                            label: Text(
                              'Add item',
                              style: AppTypography.bodySemibold.copyWith(color: noteTextColor),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _contentController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: AppTypography.bodyLarge.copyWith(
                              color: noteTextColor,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write down a note!',
                              hintStyle: AppTypography.bodyLarge.copyWith(
                                color: noteTextColor.withOpacity(0.4),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Overlaid Emoji tray
            if (_showIconPicker) _buildIconPickerTray(),
            // Overlaid Color Palette tray
            if (_showColorPicker) _buildColorPickerTray(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    String? icon,
    IconData? iconData,
    required bool isSelected,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: icon != null
            ? Text(icon, style: const TextStyle(fontSize: 18))
            : Icon(iconData, color: isSelected ? AppColors.primary : textColor.withOpacity(0.8), size: 20),
      ),
    );
  }

  Widget _buildIconPickerTray() {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select representative bubble icon',
                  style: AppTypography.bodySemibold.copyWith(color: Colors.white),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showIconPicker = false),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _emojiGrid.length,
              itemBuilder: (context, idx) {
                final emoji = _emojiGrid[idx];
                final isSelected = _selectedIcon == emoji;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = emoji;
                      _showIconPicker = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white10 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: AppMotion.page.inMilliseconds.ms, curve: AppMotion.curvePage);
  }

  Widget _buildColorPickerTray() {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Color Theme Palette',
                  style: AppTypography.headingMedium.copyWith(color: Colors.white),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showColorPicker = false),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              itemCount: AppColors.availableColors.length,
              itemBuilder: (context, idx) {
                final colorName = AppColors.availableColors[idx];
                final colorVal = AppColors.getStickyColor(colorName);
                final isSelected = _selectedColor == colorName;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorName;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorVal,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorVal.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: AppColors.getStickyTextColor(colorName),
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: AppMotion.page.inMilliseconds.ms, curve: AppMotion.curvePage);
  }

  void _showFolderSelectionSheet() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161622),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final folders = settings.folders;
            final newFolderController = TextEditingController();
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Organize into Folder',
                        style: AppTypography.headingLarge.copyWith(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  // List of folders
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: folders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = _selectedFolder.isEmpty;
                          return ListTile(
                            leading: Icon(
                              isSelected ? Icons.folder_rounded : Icons.folder_open_rounded,
                              color: isSelected ? AppColors.primary : Colors.white70,
                            ),
                            title: Text(
                              'No Folder (Uncategorized)',
                              style: AppTypography.bodySemibold.copyWith(
                                color: isSelected ? AppColors.primary : Colors.white,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedFolder = '';
                              });
                              Navigator.pop(context);
                            },
                          );
                        }
                        final folderName = folders[index - 1];
                        final isSelected = _selectedFolder == folderName;
                        return ListTile(
                          leading: Icon(
                            isSelected ? Icons.folder_rounded : Icons.folder_open_rounded,
                            color: isSelected ? AppColors.primary : Colors.white70,
                          ),
                          title: Text(
                            folderName,
                            style: AppTypography.bodySemibold.copyWith(
                              color: isSelected ? AppColors.primary : Colors.white,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedFolder = folderName;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  // Create new folder row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newFolderController,
                            style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Create new folder...',
                              hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          onPressed: () async {
                            final name = newFolderController.text.trim();
                            if (name.isNotEmpty) {
                              await ref.read(settingsProvider.notifier).addFolder(name);
                              setSheetState(() {});
                              setState(() {
                                _selectedFolder = name;
                              });
                              newFolderController.clear();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class TreeIndentGuide extends StatelessWidget {
  final int indent;
  final Color color;

  const TreeIndentGuide({
    super.key,
    required this.indent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (indent <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(indent, (index) {
        final isLast = index == indent - 1;
        return SizedBox(
          width: 16,
          height: 32,
          child: CustomPaint(
            painter: _TreeLinePainter(
              color: color,
              isLast: isLast,
            ),
          ),
        );
      }),
    );
  }
}

class _TreeLinePainter extends CustomPainter {
  final Color color;
  final bool isLast;

  _TreeLinePainter({required this.color, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double centerX = size.width / 2;

    if (isLast) {
      // Draw L-shape: vertical line from top to center, horizontal line from center to right
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height / 2), paint);
      canvas.drawLine(Offset(centerX, size.height / 2), Offset(size.width, size.height / 2), paint);
    } else {
      // Draw straight vertical line from top to bottom
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isLast != isLast;
  }
}
