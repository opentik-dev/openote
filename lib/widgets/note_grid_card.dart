import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note_file.dart';

/// Grid card representing a note in the home screen grid mode.
class NoteGridCard extends StatelessWidget {
  final NoteFile note;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleArchive;
  final VoidCallback? onToggleLock;
  final VoidCallback? onChangeColor;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  const NoteGridCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onToggleArchive,
    this.onToggleLock,
    this.onChangeColor,
    required this.onRename,
    required this.onDelete,
    this.onShare,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return DateFormat('E HH:mm').format(date);
    } else {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final noteColor = _parseColor(note.colorHex);

    Color cardBg;
    if (noteColor != null) {
      cardBg = isDark
          ? noteColor.withValues(alpha: 0.22)
          : noteColor.withValues(alpha: 0.12);
    } else {
      cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    }

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: noteColor != null
              ? noteColor.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB)),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Folder or Lock / Archive badge + Favorite + Menu
              Row(
                children: [
                  if (note.isLocked) ...[
                    const Icon(Icons.lock_rounded,
                        size: 15, color: Colors.deepOrangeAccent),
                    const SizedBox(width: 4),
                  ],
                  if (note.isArchived)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'مؤرشفة',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (note.folder != null)
                    Expanded(
                      child: Text(
                        note.folder!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    icon: Icon(
                      note.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: note.isFavorite ? Colors.redAccent : Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onToggleFavorite,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      switch (value) {
                        case 'lock':
                          onToggleLock?.call();
                          break;
                        case 'color':
                          onChangeColor?.call();
                          break;
                        case 'archive':
                          onToggleArchive();
                          break;
                        case 'rename':
                          onRename();
                          break;
                        case 'share':
                          onShare?.call();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'lock',
                        child: Row(
                          children: [
                            Icon(
                              note.isLocked
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_outline_rounded,
                              size: 18,
                              color: Colors.deepOrangeAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(note.isLocked ? 'إلغاء القفل' : 'قفل الملاحظة'),
                          ],
                        ),
                      ),
                      if (onChangeColor != null)
                        const PopupMenuItem(
                          value: 'color',
                          child: Row(
                            children: [
                              Icon(Icons.palette_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('تغيير اللون'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              note.isArchived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(note.isArchived ? 'إلغاء الأرشفة' : 'أرشفة'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.drive_file_rename_outline, size: 18),
                            SizedBox(width: 8),
                            Text('إعادة تسمية'),
                          ],
                        ),
                      ),
                      if (onShare != null)
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 18),
                              SizedBox(width: 8),
                              Text('مشاركة المحتوى'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),

              // Snippet
              Expanded(
                child: Text(
                  note.isLocked
                      ? '🔒 ملاحظة محمية برمز سري...'
                      : (note.previewSnippet.isNotEmpty
                          ? note.previewSnippet
                          : 'ملاحظة فارغة...'),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontStyle: note.isLocked ? FontStyle.italic : FontStyle.normal,
                    color: isDark
                        ? const Color(0xFFA0A0A0)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),

              // Tags row if available
              if (note.tags.isNotEmpty && !note.isLocked) ...[
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: note.tags.take(3).map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 6),
              // Footer: Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(note.modifiedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
