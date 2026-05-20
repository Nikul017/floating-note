import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';
import '../../../core/settings/settings_manager.dart';
import '../../notes/models/note_model.dart';
import '../../notes/providers/notes_provider.dart';
import '../../notes/screens/note_editor_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'pinned', 'checklist', 'reminder', 'temporary' or 'folder:name'

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notesProvider.notifier).loadNotes());
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            // Keep Style Top Search Bar
            _buildTopSearchBar(settings),
            
            // Selected filter tag indicator
            if (_selectedCategory != 'all')
              _buildFilterIndicator(),
            
            Expanded(
              child: filteredNotes.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: isGridView
                          ? _buildPinterestGrid(filteredNotes)
                          : _buildListView(filteredNotes),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showNoteEditorSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }

  Widget _buildTopSearchBar(AppSettings settings) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Search your notes...',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
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
              settings.isGridView ? Icons.view_stream_outlined : Icons.dashboard_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              ref.read(settingsProvider.notifier).updateLayoutGrid(!settings.isGridView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
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
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 8.0),
      child: Row(
        children: [
          Chip(
            avatar: const Icon(Icons.filter_list, size: 14, color: AppColors.primary),
            label: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary.withOpacity(0.2),
            deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
            onDeleted: () {
              setState(() {
                _selectedCategory = 'all';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(AppSettings settings) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Elegant Material Keep style drawer header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Text(
                      'FloatNoteX',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your Floating Productivity Panel',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Core Categories
                _buildDrawerItem(
                  icon: Icons.lightbulb_outline,
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
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Divider(color: AppColors.border, thickness: 1.5),
                ),
                // Folders Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FOLDERS / LABELS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAddFolderDialog,
                        child: const Icon(Icons.add, size: 18, color: AppColors.primary),
                      )
                    ],
                  ),
                ),
                // Custom folders list
                if (settings.folders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'No folders created yet',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
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
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textPrimary.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14.5,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
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
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.folder : Icons.folder_open_outlined,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          folderName,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textPrimary.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14.5,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
          onPressed: onDelete,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  void _showAddFolderDialog() {
    final folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: folderController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter folder name...',
            hintStyle: TextStyle(color: Colors.white38),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
            child: const Text('Create', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(String folderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text('Delete folder "$folderName"?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Any notes tagged with this folder will not be deleted, but will become uncategorized.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // Remove folder from notes first
              await ref.read(notesProvider.notifier).removeFolderFromNotes(folderName);
              // Delete folder setting
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
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notes, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            _selectedCategory == 'all' 
                ? 'No floating notes created yet' 
                : 'No notes in this folder',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showNoteEditorSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Note'),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
    );
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
            children: leftColumnNotes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNoteCard(note),
            )).toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: rightColumnNotes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNoteCard(note),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<Note> notes) {
    return Column(
      children: notes.map((note) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildNoteCard(note),
      )).toList(),
    );
  }

  Widget _buildNoteCard(Note note) {
    final cardColor = AppColors.getStickyColor(note.color);
    final textColor = AppColors.getStickyTextColor(note.color);

    int checkedCount = note.checklistItems.where((i) => i.checked).length;
    int totalCount = note.checklistItems.length;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showNoteEditorSheet(context, note: note),
            splashColor: textColor.withOpacity(0.12),
            highlightColor: textColor.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(note.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note.title.isNotEmpty ? note.title : 'Untitled',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            ref.read(notesProvider.notifier).toggleOverlay(note);
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: textColor.withOpacity(0.15),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 10, thickness: 0.5, color: Colors.black12),
                  Text(
                    note.content.isNotEmpty ? note.content : 'No content',
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textColor.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutQuad).slideY(begin: 0.05, end: 0);
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
