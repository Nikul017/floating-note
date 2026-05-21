import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../core/settings/settings_manager.dart';
import '../../../core/spacing/app_spacing.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/motion/app_motion.dart';
import '../../../widgets/buttons/pressable_scale.dart';
import '../../../widgets/cards/premium_note_card.dart';
import '../../notes/models/note_model.dart';
import '../../notes/providers/notes_provider.dart';
import '../../notes/screens/note_editor_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'pinned', 'checklist', 'reminder', 'temporary' or 'folder:name'
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notesProvider.notifier).loadNotes());
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final settings = ref.watch(settingsProvider);
    final isGridView = settings.isGridView;

    // Filter notes by search query
    final searchedNotes = notes.where((note) {
      if (_searchQuery.isEmpty) return true;
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Filter notes by category/folder
    final filteredNotes = searchedNotes.where((note) {
      if (_selectedCategory == 'all') return true;
      if (_selectedCategory == 'reminder') return note.type == NoteType.reminder;
      if (_selectedCategory == 'checklist') return note.type == NoteType.checklist;
      if (_selectedCategory == 'pinned') return note.type == NoteType.pinned;
      if (_selectedCategory == 'temporary') return note.type == NoteType.temporary;
      if (_selectedCategory.startsWith('folder:')) {
        final folderName = _selectedCategory.substring(7);
        return note.folder == folderName;
      }
      return true;
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(settings),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSearchBar(settings),
            
            // Selected filter tag indicator
            if (_selectedCategory != 'all')
              _buildFilterIndicator(),
            
            Expanded(
              child: filteredNotes.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: isGridView
                          ? _buildPinterestGrid(filteredNotes)
                          : _buildListView(filteredNotes),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: PressableScale(
        onTap: () => _showNoteEditorSheet(context),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              AppSpacing.w8,
              Text(
                'Add Note',
                style: AppTypography.bodySemibold.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSearchBar(AppSettings settings) {
    return AnimatedContainer(
      duration: AppMotion.micro,
      margin: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: _isSearchFocused ? AppColors.cardBg : AppColors.cardBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isSearchFocused ? AppColors.primary.withOpacity(0.8) : AppColors.border.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSearchFocused ? AppColors.primary.withOpacity(0.12) : Colors.black.withOpacity(0.18),
            blurRadius: _isSearchFocused ? 16 : 8,
            spreadRadius: _isSearchFocused ? 0 : -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: AppTypography.bodyLarge.copyWith(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search your notes...',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 15),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          IconButton(
            icon: Icon(
              settings.isGridView ? Icons.view_stream_rounded : Icons.dashboard_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              ref.read(settingsProvider.notifier).updateLayoutGrid(!settings.isGridView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                ref.read(notesProvider.notifier).loadNotes();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterIndicator() {
    String label = '';
    if (_selectedCategory == 'pinned') label = 'Pinned Notes';
    else if (_selectedCategory == 'checklist') label = 'Checklists';
    else if (_selectedCategory == 'reminder') label = 'Reminders';
    else if (_selectedCategory == 'temporary') label = 'Temporary Notes';
    else if (_selectedCategory.startsWith('folder:')) {
      label = 'Folder: ${_selectedCategory.substring(7)}';
    }
    
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xs,
        top: AppSpacing.xxs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list_rounded, size: 12, color: AppColors.primary),
              AppSpacing.w8,
              Text(
                label,
                style: AppTypography.captionSemibold.copyWith(
                  color: AppColors.primary,
                  fontSize: 11,
                ),
              ),
              AppSpacing.w8,
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = 'all';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 10,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(AppSettings settings) {
    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.xxl + AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardBg,
                  AppColors.cardBg.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    AppSpacing.w12,
                    Text(
                      'FloatNoteX',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                AppSpacing.h16,
                Text(
                  'Your Floating Productivity Panel',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              children: [
                _buildDrawerItem(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'All Notes',
                  isSelected: _selectedCategory == 'all',
                  onTap: () {
                    setState(() => _selectedCategory = 'all');
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.push_pin_outlined,
                  title: 'Pinned Notes',
                  isSelected: _selectedCategory == 'pinned',
                  onTap: () {
                    setState(() => _selectedCategory = 'pinned');
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.check_box_outlined,
                  title: 'Checklists',
                  isSelected: _selectedCategory == 'checklist',
                  onTap: () {
                    setState(() => _selectedCategory = 'checklist');
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Reminders',
                  isSelected: _selectedCategory == 'reminder',
                  onTap: () {
                    setState(() => _selectedCategory = 'reminder');
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.timer_outlined,
                  title: 'Temporary Notes',
                  isSelected: _selectedCategory == 'temporary',
                  onTap: () {
                    setState(() => _selectedCategory = 'temporary');
                    Navigator.pop(context);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  child: Divider(color: AppColors.border, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FOLDERS / LABELS',
                        style: AppTypography.captionSemibold.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                      PressableScale(
                        onTap: _showAddFolderDialog,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                        ),
                      )
                    ],
                  ),
                ),
                // Custom folders list
                if (settings.folders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
                    child: Text(
                      'No folders created yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...settings.folders.map((folder) {
                    final folderKey = 'folder:$folder';
                    final isSelected = _selectedCategory == folderKey;
                    return _buildDrawerFolderItem(
                      folderName: folder,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedCategory = folderKey);
                        Navigator.pop(context);
                      },
                      onDelete: () => _confirmDeleteFolder(folder),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: AppSpacing.sm),
      child: PressableScale(
        onTap: onTap,
        scaleFactor: 0.98,
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.04),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary.withOpacity(0.25) : Colors.transparent,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Active Vertical accent indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
                AppSpacing.w12,
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                AppSpacing.w16,
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodySemibold.copyWith(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFolderItem({
    required String folderName,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: AppSpacing.sm),
      child: PressableScale(
        onTap: onTap,
        scaleFactor: 0.98,
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.04),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary.withOpacity(0.25) : Colors.transparent,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Active Vertical accent indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
                AppSpacing.w12,
                Icon(
                  isSelected ? Icons.folder_rounded : Icons.folder_open_rounded,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                AppSpacing.w16,
                Expanded(
                  child: Text(
                    folderName,
                    style: AppTypography.bodySemibold.copyWith(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: isSelected ? Colors.redAccent.withOpacity(0.8) : AppColors.textSecondary.withOpacity(0.5),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onDelete,
                ),
                AppSpacing.w8,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddFolderDialog() {
    final folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Folder', style: AppTypography.headingLarge),
        content: TextField(
          controller: folderController,
          autofocus: true,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Enter folder name...',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodySemibold.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = folderController.text.trim();
              if (name.isNotEmpty) {
                await ref.read(settingsProvider.notifier).addFolder(name);
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text('Create', style: AppTypography.bodySemibold.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(String folderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete folder "$folderName"?', style: AppTypography.headingLarge),
        content: Text(
          'Any notes tagged with this folder will not be deleted, but will become uncategorized.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodySemibold.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(notesProvider.notifier).removeFolderFromNotes(folderName);
              await ref.read(settingsProvider.notifier).removeFolder(folderName);
              
              if (_selectedCategory == 'folder:$folderName') {
                setState(() {
                  _selectedCategory = 'all';
                });
              }
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('Delete', style: AppTypography.bodySemibold.copyWith(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.h24,
              Text(
                _selectedCategory == 'all' ? 'Capturing thoughts on the fly' : 'This category is empty',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
              AppSpacing.h8,
              Text(
                _selectedCategory == 'all'
                    ? 'Create floating notes that stay on top of other apps, check lists, reminders, and more.'
                    : 'Notes assigned to this category or folder will show up right here.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              AppSpacing.h24,
              PressableScale(
                onTap: () => _showNoteEditorSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      AppSpacing.w8,
                      Text(
                        'Create First Note',
                        style: AppTypography.bodySemibold.copyWith(
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppMotion.page).scale(begin: const Offset(0.97, 0.97), curve: AppMotion.curvePage);
  }

  Widget _buildPinterestGrid(List<Note> notes) {
    final leftColumnNotes = <Note>[];
    final rightColumnNotes = <Note>[];
    
    for (int i = 0; i < notes.length; i++) {
      if (i % 2 == 0) {
        leftColumnNotes.add(notes[i]);
      } else {
        rightColumnNotes.add(notes[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftColumnNotes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: PressableScale(
                  onTap: () => _showNoteEditorSheet(context, note: note),
                  child: PremiumNoteCard(
                    note: note,
                    onTap: () => _showNoteEditorSheet(context, note: note),
                    onOpenOverlay: () {
                      ref.read(notesProvider.notifier).toggleOverlay(note);
                    },
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: (index * 50).ms, duration: AppMotion.page)
              .slideY(begin: 0.1, end: 0, curve: AppMotion.curvePage);
            }).toList(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            children: rightColumnNotes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: PressableScale(
                  onTap: () => _showNoteEditorSheet(context, note: note),
                  child: PremiumNoteCard(
                    note: note,
                    onTap: () => _showNoteEditorSheet(context, note: note),
                    onOpenOverlay: () {
                      ref.read(notesProvider.notifier).toggleOverlay(note);
                    },
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: (index * 50 + 25).ms, duration: AppMotion.page)
              .slideY(begin: 0.1, end: 0, curve: AppMotion.curvePage);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<Note> notes) {
    return Column(
      children: notes.asMap().entries.map((entry) {
        final index = entry.key;
        final note = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: PressableScale(
            onTap: () => _showNoteEditorSheet(context, note: note),
            child: PremiumNoteCard(
              note: note,
              onTap: () => _showNoteEditorSheet(context, note: note),
              onOpenOverlay: () {
                ref.read(notesProvider.notifier).toggleOverlay(note);
              },
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: AppMotion.page)
        .slideY(begin: 0.05, end: 0, curve: AppMotion.curvePage);
      }).toList(),
    );
  }

  void _showNoteEditorSheet(BuildContext context, {Note? note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    ).then((_) {
      ref.read(notesProvider.notifier).loadNotes();
    });
  }
}
