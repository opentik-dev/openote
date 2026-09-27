import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note_file.dart';
import '../state/notes_state_notifier.dart';
import '../widgets/about_openote_dialog.dart';
import '../widgets/note_grid_card.dart';
import '../widgets/note_list_tile.dart';
import '../widgets/notes_search_bar.dart';
import 'note_editor_screen.dart';

/// Main home screen displaying the searchable, filterable list of notes.
/// Observes AppLifecycleState to automatically rescan when returning to foreground.
class NotesHomeScreen extends StatefulWidget {
  final NotesStateNotifier notifier;

  const NotesHomeScreen({
    super.key,
    required this.notifier,
  });

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.notifier.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.notifier.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.notifier.rescan();
    }
  }

  void _openNote(NoteFile note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          note: note,
          notifier: widget.notifier,
        ),
      ),
    );
    widget.notifier.rescan();
  }

  Future<void> _promptCreateNote() async {
    final titleController = TextEditingController();
    final folderController = TextEditingController();
    final existingFolders = widget.notifier.availableFolders;
    String? selectedExistingFolder;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('ملاحظة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الملاحظة',
                    hintText: 'مثال: خطة العمل أو ملاحظات بحث',
                  ),
                ),
                const SizedBox(height: 16),
                if (existingFolders.isNotEmpty) ...[
                  const Text('أو اختر مجلداً موجوداً:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: selectedExistingFolder,
                    hint: const Text('المجلد الرئيسي (Root)'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('المجلد الرئيسي (Root)'),
                      ),
                      ...existingFolders.map(
                        (f) => DropdownMenuItem<String?>(
                          value: f,
                          child: Text(f),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedExistingFolder = val;
                        folderController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: folderController,
                  enabled: selectedExistingFolder == null,
                  decoration: const InputDecoration(
                    labelText: 'مجلد جديد (اختياري)',
                    hintText: 'مثال: أفكار أو أبحاث',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final rawTitle = titleController.text.trim();
      final title = rawTitle.isNotEmpty ? rawTitle : 'ملاحظة جديدة';
      final folder = selectedExistingFolder ??
          (folderController.text.trim().isNotEmpty
              ? folderController.text.trim()
              : null);

      final initialMarkdown = '# $title\n\n';
      final createdNote = await widget.notifier.createNote(
        folder: folder,
        title: title,
        initialContent: initialMarkdown,
      );

      if (mounted) {
        _openNote(createdNote);
      }
    }
  }

  Future<void> _promptRename(NoteFile note) async {
    final currentTitleWithoutExt =
        note.fileName.toLowerCase().endsWith('.md')
            ? note.fileName.substring(0, note.fileName.length - 3)
            : note.fileName;
    final controller = TextEditingController(text: currentTitleWithoutExt);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تسمية الملف'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم الملف الجديد',
            suffixText: '.md',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      final newFileName =
          newTitle.toLowerCase().endsWith('.md') ? newTitle : '$newTitle.md';
      final parentFolder = note.folder;
      final newRelativePath = parentFolder != null
          ? '$parentFolder/$newFileName'
          : newFileName;

      if (newRelativePath != note.relativePath) {
        await widget.notifier.renameNote(note.relativePath, newRelativePath);
      }
    }
  }

  Future<void> _confirmDelete(NoteFile note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف "${note.title}" من القرص نهائياً؟\n\n'
          'المسار: ${note.relativePath}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.notifier.deleteNote(note.relativePath);
    }
  }

  Future<void> _shareNoteContent(NoteFile note) async {
    try {
      final content =
          await widget.notifier.readNoteContent(note.relativePath);
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ محتوى الملاحظة إلى الحافظة ✓'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر قراءة الملاحظة للمشاركة: $e')),
        );
      }
    }
  }

  void _showThemeDialog() {
    final current = widget.notifier.themeMode;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اختر مظهر التطبيق'),
        children: [
          _buildOptionTile(
            ctx,
            title: 'تلقائي (حسب النظام)',
            icon: Icons.brightness_auto,
            isSelected: current == 'system',
            onTap: () => widget.notifier.setThemeMode('system'),
          ),
          _buildOptionTile(
            ctx,
            title: 'فاتح (Light)',
            icon: Icons.light_mode_outlined,
            isSelected: current == 'light',
            onTap: () => widget.notifier.setThemeMode('light'),
          ),
          _buildOptionTile(
            ctx,
            title: 'مظلم (Dark)',
            icon: Icons.dark_mode_outlined,
            isSelected: current == 'dark',
            onTap: () => widget.notifier.setThemeMode('dark'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final current = widget.notifier.localeCode;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('لغة واجهة التطبيق'),
        children: [
          _buildOptionTile(
            ctx,
            title: 'العربية (Arabic)',
            icon: Icons.language,
            isSelected: current == 'ar',
            onTap: () => widget.notifier.setLocaleCode('ar'),
          ),
          _buildOptionTile(
            ctx,
            title: 'English (الإنجليزية)',
            icon: Icons.language,
            isSelected: current == 'en',
            onTap: () => widget.notifier.setLocaleCode('en'),
          ),
          _buildOptionTile(
            ctx,
            title: 'تلقائي (حسب الجهاز)',
            icon: Icons.settings_suggest_outlined,
            isSelected: current == 'system',
            onTap: () => widget.notifier.setLocaleCode('system'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext ctx, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(ctx);
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.notifier;
    final notes = notifier.filteredNotes;
    final folders = notifier.availableFolders;
    final isGrid = notifier.viewMode == 'grid';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OpeNote',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'by OpenTik-Dev',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Toggle View Mode (List <-> Grid)
          IconButton(
            icon: Icon(
              isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            tooltip: isGrid ? 'عرض القائمة' : 'عرض الشبكة',
            onPressed: () => notifier.toggleViewMode(),
          ),

          // Rescan / Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة مسح المجلدات',
            onPressed: () => notifier.rescan(),
          ),

          // Settings / More Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'خيارات وإعدادات',
            onSelected: (val) {
              switch (val) {
                case 'theme':
                  _showThemeDialog();
                  break;
                case 'language':
                  _showLanguageDialog();
                  break;
                case 'about':
                  showDialog(
                    context: context,
                    builder: (_) => const AboutOpeNoteDialog(),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('مظهر التطبيق (فاتح / مظلم)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'language',
                child: Row(
                  children: [
                    Icon(Icons.language_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('لغة الواجهة'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.teal),
                    SizedBox(width: 10),
                    Text('حول OpeNote وسجل التحديثات'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: NotesSearchBar(
              initialQuery: notifier.searchQuery,
              onChanged: (q) => notifier.setSearchQuery(q),
            ),
          ),

          // Filter Chips: All / Favorites / Archived / Folders
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('الكل'),
                  selected: !notifier.showOnlyFavorites &&
                      !notifier.showOnlyArchived &&
                      notifier.selectedFolder == null,
                  onSelected: (_) {
                    if (notifier.showOnlyFavorites) {
                      notifier.toggleShowOnlyFavorites();
                    }
                    if (notifier.showOnlyArchived) {
                      notifier.toggleShowOnlyArchived();
                    }
                    notifier.setSelectedFolder(null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar:
                      const Icon(Icons.favorite, size: 16, color: Colors.red),
                  label: const Text('المفضلة'),
                  selected: notifier.showOnlyFavorites,
                  onSelected: (_) => notifier.toggleShowOnlyFavorites(),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.archive_outlined,
                      size: 16, color: Colors.amber),
                  label: const Text('المؤرشفة'),
                  selected: notifier.showOnlyArchived,
                  onSelected: (_) => notifier.toggleShowOnlyArchived(),
                ),
                if (folders.isNotEmpty) const SizedBox(width: 8),
                ...folders.map(
                  (folder) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(folder),
                      selected: notifier.selectedFolder == folder,
                      onSelected: (selected) {
                        notifier.setSelectedFolder(selected ? folder : null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Main Notes Area (List or Grid)
          Expanded(
            child: notifier.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              notifier.showOnlyArchived
                                  ? Icons.archive_outlined
                                  : Icons.note_alt_outlined,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notifier.searchQuery.isNotEmpty
                                  ? 'لا توجد نتائج مطابقة للبحث'
                                  : notifier.showOnlyArchived
                                      ? 'لا توجد ملاحظات مؤرشفة'
                                      : 'لا توجد ملاحظات بعد',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (notifier.searchQuery.isEmpty &&
                                !notifier.showOnlyArchived)
                              FilledButton.icon(
                                onPressed: _promptCreateNote,
                                icon: const Icon(Icons.add),
                                label: const Text('إنشاء ملاحظة جديدة'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifier.rescan(),
                        child: isGrid
                            ? GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: notes.length,
                                itemBuilder: (context, index) {
                                  final note = notes[index];
                                  return NoteGridCard(
                                    note: note,
                                    onTap: () => _openNote(note),
                                    onToggleFavorite: () => notifier
                                        .toggleFavorite(note.relativePath),
                                    onToggleArchive: () => notifier
                                        .toggleArchive(note.relativePath),
                                    onRename: () => _promptRename(note),
                                    onDelete: () => _confirmDelete(note),
                                    onShare: () => _shareNoteContent(note),
                                  );
                                },
                              )
                            : ListView.builder(
                                itemCount: notes.length,
                                itemBuilder: (context, index) {
                                  final note = notes[index];
                                  return NoteListTile(
                                    note: note,
                                    onTap: () => _openNote(note),
                                    onToggleFavorite: () => notifier
                                        .toggleFavorite(note.relativePath),
                                    onToggleArchive: () => notifier
                                        .toggleArchive(note.relativePath),
                                    onRename: () => _promptRename(note),
                                    onDelete: () => _confirmDelete(note),
                                    onShare: () => _shareNoteContent(note),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _promptCreateNote,
        icon: const Icon(Icons.add),
        label: const Text('ملاحظة'),
      ),
    );
  }
}
