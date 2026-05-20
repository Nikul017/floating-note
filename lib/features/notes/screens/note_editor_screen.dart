import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../../../core/settings/settings_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  late int _createdAt;
  late int _updatedAt;

  bool _showIconPicker = false;
  bool _showColorPicker = false;

  final List<String> _emojiGrid = [
    '📌', '💡', '🕒', '👥', '🛒', '📷', '♥️', '⭐️',
    '✈️', '🌐', '📞', '✉️', '⚠️', '🏠', 'ℹ️', '🍃',
    '🔒', '🔍', '🎤', '💵', '🎵', '🔔', '🖋️', '🖨️',
    '❓', '🚀', '👎', '👍', '🗑️', '💳', '💼', '🔥',
    '🛋️', '⌚️', '👁️', '⌨️', '🔱', '⛰️', '📱', '😄',
    '😵', '😃', '😌', '🙁', '🛡️', '🍴', '👤', '⏻',
    '🏊', '🐾', '🗣️', '🖱️', '🚲', '😄', '😢', '🌈'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _checklistInputController = TextEditingController();

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
    _checklistFocusNodes = _checklistItems.map((item) => FocusNode()).toList();
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
    super.dispose();
  }

  void _saveNote() async {
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
      );
      _checklistItems.add(newItem);

      final controller = TextEditingController(text: text);
      _checklistControllers.add(controller);

      final focusNode = FocusNode();
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
      );
      _checklistItems.insert(index, newItem);
      _checklistControllers.insert(index, TextEditingController());

      final focusNode = FocusNode();
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
              surface: const Color(0xFF1E1E2C),
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
              surface: const Color(0xFF1E1E2C),
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
    _showNoteDetailsSheet(AppColors.getStickyTextColor(_selectedColor));
  }

  void _showNoteDetailsSheet(Color textColor) {
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
      backgroundColor: const Color(0xFF1E1E2C),
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
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Note Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                      const SizedBox(
                        width: 110,
                        child: Text(
                          'Created',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatTimestamp(_createdAt, verbose: true),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
                  const SizedBox(height: 8),
                  if (widget.note != null) ...[
                    _buildDetailRow('Last Modified', _formatTimestamp(_updatedAt, verbose: true)),
                    const SizedBox(height: 12),
                  ],
                  _buildDetailRow('Characters', totalChars.toString()),
                  const SizedBox(height: 12),
                  _buildDetailRow('Words', totalWords.toString()),
                  const SizedBox(height: 12),
                  _buildDetailRow('Type', _selectedType.name.toUpperCase()),
                  if (_selectedFolder.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getStickyColor(_selectedColor);
    final textColor = AppColors.getStickyTextColor(_selectedColor);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: InkWell(
          onTap: () => _showNoteDetailsSheet(textColor),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.note != null ? 'Created' : 'New Note',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.55),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(_createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: textColor, size: 24),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E2C),
                    title: const Text('Delete Note', style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to delete this note?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
            icon: Icon(Icons.check, color: textColor, size: 28),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal toolbar of options (Icon, Color, Alarm, Checklist, Calendar, Lock)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildToolbarButton(
                    icon: _selectedIcon,
                    isSelected: _showIconPicker,
                    textColor: textColor,
                    onTap: () {
                      setState(() {
                        _showIconPicker = !_showIconPicker;
                        _showColorPicker = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    iconData: Icons.palette_outlined,
                    isSelected: _showColorPicker,
                    textColor: textColor,
                    onTap: () {
                      setState(() {
                        _showColorPicker = !_showColorPicker;
                        _showIconPicker = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    iconData: Icons.folder_outlined,
                    isSelected: _selectedFolder.isNotEmpty,
                    textColor: textColor,
                    onTap: _showFolderSelectionSheet,
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    iconData: Icons.notifications_none_outlined,
                    isSelected: false,
                    textColor: textColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reminder features synchronized!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    iconData: Icons.calendar_today_outlined,
                    isSelected: false,
                    textColor: textColor,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reminder set for ${date.toLocal().toString().split(' ')[0]}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    iconData: _isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                    isSelected: _isLocked,
                    textColor: textColor,
                    onTap: () {
                      setState(() {
                        _isLocked = !_isLocked;
                      });
                    },
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.8,
              color: Colors.black.withOpacity(0.12),
            ),

            // Immersive Text Writing Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: Colors.black.withOpacity(0.12),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedFolder.isNotEmpty) ...[
                      Chip(
                        avatar: Icon(Icons.folder, size: 14, color: textColor.withOpacity(0.7)),
                        label: Text(
                          _selectedFolder,
                          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: textColor.withOpacity(0.1),
                        deleteIcon: Icon(Icons.close, size: 14, color: textColor.withOpacity(0.7)),
                        onDeleted: () {
                          setState(() {
                            _selectedFolder = '';
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                      // Plain Text Area
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write down a note!',
                          hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Dynamic bottom selector trays (Icon Picker or Color Palette)
            if (_showIconPicker) _buildIconPickerTray(textColor),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: textColor.withOpacity(0.1),
        highlightColor: textColor.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? textColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: icon != null
              ? Text(icon, style: const TextStyle(fontSize: 18))
              : Icon(iconData, color: textColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildIconPickerTray(Color textColor) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C), // Sleek matching dark background for consistency
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select representative bubble icon',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                      color: isSelected ? Colors.black.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildColorPickerTray() {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C), // Sleek matching dark background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Colors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
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
                                blurRadius: 8,
                                spreadRadius: 2,
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
    ).animate().slideY(begin: 1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }


  void _showFolderSelectionSheet() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
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
                      const Text(
                        'Organize into Folder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                              isSelected ? Icons.folder : Icons.folder_open_outlined,
                              color: isSelected ? AppColors.primary : Colors.white70,
                            ),
                            title: Text(
                              'No Folder (Uncategorized)',
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                            isSelected ? Icons.folder : Icons.folder_open_outlined,
                            color: isSelected ? AppColors.primary : Colors.white70,
                          ),
                          title: Text(
                            folderName,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Create new folder...',
                              hintStyle: TextStyle(color: Colors.white38),
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
