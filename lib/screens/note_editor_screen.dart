import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note_file.dart';
import '../state/notes_state_notifier.dart';
import '../widgets/markdown_preview.dart';
import '../widgets/markdown_toolbar.dart';

/// Screen for editing and previewing Markdown notes with autosave
/// and external modification conflict detection.
class NoteEditorScreen extends StatefulWidget {
  final NoteFile note;
  final NotesStateNotifier notifier;

  const NoteEditorScreen({
    super.key,
    required this.note,
    required this.notifier,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late NoteFile _currentNote;
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isPreview = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _conflictDetected = false;

  late DateTime _openedAtModifiedTime;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _openedAtModifiedTime = widget.note.modifiedAt;
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final content =
          await widget.notifier.readNoteContent(_currentNote.relativePath);
      _contentController.text = content;
      final diskTime = await widget.notifier
          .getFileModifiedTime(_currentNote.relativePath);
      if (diskTime != null) {
        _openedAtModifiedTime = diskTime;
      }
      _hasUnsavedChanges = false;
      _conflictDetected = false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في قراءة الملاحظة: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onContentChanged(String newText) {
    if (_conflictDetected) return;

    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _performSave();
    });
  }

  Future<void> _performSave({bool force = false}) async {
    if (!_hasUnsavedChanges && !force) return;
    if (_conflictDetected && !force) return;

    // Check if the file on disk was modified externally
    final isExternallyChanged = await widget.notifier
        .isExternallyModified(_currentNote.relativePath, _openedAtModifiedTime);

    if (isExternallyChanged && !force) {
      setState(() {
        _conflictDetected = true;
        _hasUnsavedChanges = true;
      });
      _promptExternalConflictDialog();
      return;
    }

    setState(() => _isSaving = true);
    try {
      final newModified = await widget.notifier
          .saveNote(_currentNote.relativePath, _contentController.text);
      _openedAtModifiedTime = newModified;
      _hasUnsavedChanges = false;
      _conflictDetected = false;

      // Update current note header descriptor
      final updated = widget.notifier.allNotes.firstWhere(
        (n) => n.relativePath == _currentNote.relativePath,
        orElse: () => _currentNote,
      );
      _currentNote = updated;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _promptExternalConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('تغيير خارجي للملف'),
          ],
        ),
        content: const Text(
          'تم تعديل هذا الملف على القرص بواسطة تطبيق آخر (مثل Obsidian أو محرر خارجي).\n\n'
          'لمنع الكتابة فوق تعديلك أو التعديل الخارجي بصمت، يرجى اختيار الإجراء المناسب:',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadContent(); // Reload disk content
            },
            child: const Text('إعادة تحميل من القرص'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _performSave(force: true); // Force overwrite with user edit
            },
            child: const Text('الاحتفاظ بتحريري'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_hasUnsavedChanges && !_conflictDetected) {
      widget.notifier
          .saveNote(_currentNote.relativePath, _contentController.text);
    }
    _contentController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentNote.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                if (_conflictDetected)
                  const Text(
                    '⚠️ تعديل خارجي معلق',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  )
                else if (_isSaving)
                  const Text(
                    'جارِ الحفظ...',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  )
                else if (_hasUnsavedChanges)
                  const Text(
                    'تعديلات غير محفوظة',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  )
                else
                  const Text(
                    'محفوظ ✓',
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                if (_currentNote.folder != null) ...[
                  const Text(' • ', style: TextStyle(fontSize: 11)),
                  Text(
                    _currentNote.folder!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: Icon(
                _isPreview ? Icons.edit_note : Icons.remove_red_eye_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                _isPreview ? 'تحرير' : 'معاينة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansArabic',
                  color: theme.colorScheme.primary,
                ),
              ),
              onPressed: () {
                if (_hasUnsavedChanges && !_conflictDetected) {
                  _performSave();
                }
                setState(() => _isPreview = !_isPreview);
              },
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _currentNote.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _currentNote.isFavorite ? Colors.redAccent : null,
            ),
            tooltip: _currentNote.isFavorite
                ? 'إزالة من المفضلة'
                : 'إضافة للمفضلة',
            onPressed: () async {
              await widget.notifier.toggleFavorite(_currentNote.relativePath);
              setState(() {
                _currentNote = _currentNote.copyWith(
                  isFavorite: !_currentNote.isFavorite,
                );
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _isPreview
                        ? MarkdownPreview(data: _contentController.text)
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _contentController,
                              focusNode: _editorFocusNode,
                              maxLines: null,
                              expands: true,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              textDirection: TextDirection.rtl,
                              onChanged: _onContentChanged,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.7,
                                fontFamily: 'NotoSansArabic',
                                fontFamilyFallback: const [
                                  'NotoSansArabic',
                                  'NotoSansOldSouthArabian',
                                ],
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                hintText: '# اكتب ملاحظتك هنا بصيغة Markdown...',
                                hintTextDirection: TextDirection.rtl,
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                  ),
                  if (!_isPreview)
                    MarkdownToolbar(controller: _contentController),
                ],
              ),
            ),
    );
  }
}
