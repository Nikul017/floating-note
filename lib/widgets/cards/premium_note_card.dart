import 'package:flutter/material.dart';
import '../../core/spacing/app_spacing.dart';
import '../../core/typography/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../features/notes/models/note_model.dart';

class PremiumNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onOpenOverlay;

  const PremiumNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onOpenOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final Color rawColor = AppColors.getStickyColor(note.color);
    final Color textColor = AppColors.getStickyTextColor(note.color);
    
    // Determine note shade context
    final bool isDarkNote = note.color.toLowerCase() == 'charcoal' || 
                            note.color.toLowerCase() == 'glass' || 
                            note.color.toLowerCase() == 'indigo' || 
                            note.color.toLowerCase() == 'maroon' || 
                            note.color.toLowerCase() == 'dark_mint';
    
    final Color cardBackground = rawColor;
    
    // Checklist progress calculation
    final int totalItems = note.checklistItems.length;
    final int completedItems = note.checklistItems.where((item) => item.checked).length;
    final double progress = totalItems > 0 ? completedItems / totalItems : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkNote ? AppColors.border : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: rawColor.withOpacity(isDarkNote ? 0.08 : 0.22),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          splashColor: textColor.withOpacity(0.1),
          highlightColor: textColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Card Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        note.icon,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    AppSpacing.w8,
                    Expanded(
                      child: Text(
                        note.title.isNotEmpty ? note.title : 'Untitled',
                        style: AppTypography.bodySemibold.copyWith(
                          color: textColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.w4,
                    // Minimize / Float Button Action
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onOpenOverlay,
                        borderRadius: BorderRadius.circular(10),
                        splashColor: textColor.withOpacity(0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.open_in_new_rounded,
                            size: 15,
                            color: textColor.withOpacity(0.65),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.h12,
                
                // Content Rendering (Checklist Preview vs Plain Text)
                if (note.type == NoteType.checklist && note.checklistItems.isNotEmpty) ...[
                  ...note.checklistItems.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          item.checked ? Icons.check_circle : Icons.circle_outlined,
                          size: 13,
                          color: textColor.withOpacity(item.checked ? 0.45 : 0.75),
                        ),
                        AppSpacing.w8,
                        Expanded(
                          child: Text(
                            item.text.isNotEmpty ? item.text : 'Unspecified Task',
                            style: AppTypography.bodyMedium.copyWith(
                              color: textColor.withOpacity(item.checked ? 0.45 : 0.85),
                              decoration: item.checked ? TextDecoration.lineThrough : null,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (totalItems > 3) ...[
                    AppSpacing.h4,
                    Text(
                      '+ ${totalItems - 3} more items',
                      style: AppTypography.caption.copyWith(
                        color: textColor.withOpacity(0.55),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  AppSpacing.h12,
                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: textColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              textColor.withOpacity(0.65),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      AppSpacing.w8,
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTypography.caption.copyWith(
                          color: textColor.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    note.content.isNotEmpty ? note.content : 'Write down a note...',
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                
                // Footer Badges
                if (_hasBadge) ...[
                  AppSpacing.h12,
                  Divider(height: 1, thickness: 0.5, color: Colors.black.withOpacity(0.06)),
                  AppSpacing.h8,
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (note.type == NoteType.pinned)
                        _buildBadge('Pinned', Icons.push_pin, textColor),
                      if (note.type == NoteType.temporary)
                        _buildBadge('Temporary', Icons.timer_outlined, textColor),
                      if (note.type == NoteType.reminder)
                        _buildBadge('Reminder', Icons.notifications_none, textColor),
                      if (note.folder.isNotEmpty)
                        _buildBadge(note.folder, Icons.folder_open, textColor),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasBadge =>
      note.type == NoteType.pinned ||
      note.type == NoteType.temporary ||
      note.type == NoteType.reminder ||
      note.folder.isNotEmpty;

  Widget _buildBadge(String label, IconData icon, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor.withOpacity(0.65)),
          AppSpacing.w4,
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
