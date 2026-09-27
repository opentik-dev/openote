import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/note_file.dart';
import '../utils/file_name_utils.dart';
import 'file_storage_service.dart';
import 'markdown_service.dart';

/// V1 implementation of [FileStorageService] using standard application documents storage.
class AppPrivateStorage implements FileStorageService {
  final Directory? _overrideRootDir;
  final MarkdownService _markdownService;
  Directory? _resolvedRootDir;

  AppPrivateStorage({
    Directory? rootDir,
    MarkdownService markdownService = const MarkdownService(),
  })  : _overrideRootDir = rootDir,
        _markdownService = markdownService;

  @override
  Future<void> initialize() async {
    if (_overrideRootDir != null) {
      _resolvedRootDir = _overrideRootDir;
    } else {
      final appDocs = await getApplicationDocumentsDirectory();
      _resolvedRootDir = Directory(p.join(appDocs.path, 'Notes'));
    }

    if (!await _resolvedRootDir!.exists()) {
      await _resolvedRootDir!.create(recursive: true);
    }
    
    final welcomeFile = File(p.join(_resolvedRootDir!.path, 'Welcome.md'));
    if (!await welcomeFile.exists() && _resolvedRootDir!.listSync().isEmpty) {
      await _seedWelcomeNote();
    }
  }

  Directory get _root {
    if (_resolvedRootDir == null) {
      throw StateError(
          'AppPrivateStorage has not been initialized. Call initialize() first.');
    }
    return _resolvedRootDir!;
  }

  @override
  Future<String> getRootPath() async {
    return _root.path;
  }

  String _toAbsolutePath(String relativePath) {
    return p.join(_root.path, relativePath);
  }

  String _toRelativePath(String absolutePath) {
    return p.relative(absolutePath, from: _root.path).replaceAll(r'\', '/');
  }

  @override
  Future<bool> noteExists(String relativePath) async {
    final file = File(_toAbsolutePath(relativePath));
    return file.exists();
  }

  @override
  Future<DateTime?> getModifiedTime(String relativePath) async {
    final file = File(_toAbsolutePath(relativePath));
    if (!await file.exists()) return null;
    return file.lastModified();
  }

  @override
  Future<List<NoteFile>> listNotes({Set<String>? favoritePaths}) async {
    if (!await _root.exists()) {
      return [];
    }

    final notes = <NoteFile>[];
    final entities = _root.listSync(recursive: true, followLinks: false);

    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.md')) {
        final relPath = _toRelativePath(entity.path);
        final fileName = p.basename(entity.path);

        DateTime modifiedAt;
        try {
          modifiedAt = entity.lastModifiedSync();
        } catch (_) {
          modifiedAt = DateTime.now();
        }

        // Read up to first 4KB for fast title & snippet parsing with proper UTF-8 decoding
        String sampleContent = '';
        try {
          final stream = entity.openRead(0, 4096);
          final bytes = await stream.expand((chunk) => chunk).toList();
          sampleContent = utf8.decode(bytes, allowMalformed: true);
        } catch (_) {
          sampleContent = '';
        }

        final title = _markdownService.resolveTitle(sampleContent, fileName);
        final snippet = _markdownService.extractSnippet(sampleContent);
        final tags = _markdownService.extractTags(sampleContent);
        final isFav = favoritePaths?.contains(relPath) ?? false;

        notes.add(NoteFile(
          relativePath: relPath,
          fileName: fileName,
          title: title,
          modifiedAt: modifiedAt,
          previewSnippet: snippet,
          isFavorite: isFav,
          tags: tags,
        ));
      }
    }

    // Sort by latest modified date descending
    notes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return notes;
  }

  @override
  Future<String> readNote(String relativePath) async {
    final file = File(_toAbsolutePath(relativePath));
    if (!await file.exists()) {
      throw FileSystemException('Note not found', relativePath);
    }
    return file.readAsString(encoding: utf8);
  }

  @override
  Future<void> writeNote(String relativePath, String content) async {
    final file = File(_toAbsolutePath(relativePath));
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content, encoding: utf8, flush: true);
  }

  @override
  Future<void> renameNote(String oldPath, String newPath) async {
    final source = File(_toAbsolutePath(oldPath));
    if (!await source.exists()) {
      throw FileSystemException('Source note does not exist', oldPath);
    }

    final target = File(_toAbsolutePath(newPath));
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }

    if (await target.exists()) {
      throw FileSystemException('Target file already exists', newPath);
    }

    await source.rename(target.path);
  }

  @override
  Future<void> deleteNote(String relativePath) async {
    final file = File(_toAbsolutePath(relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<NoteFile> createNote({
    String? folder,
    String? title,
    String initialContent = '',
  }) async {
    final candidateName =
        (title != null && title.trim().isNotEmpty) ? title.trim() : 'Untitled';

    var fileName = FileNameUtils.sanitizeFileName(candidateName);
    var relativePath = FileNameUtils.joinRelativePath(folder, fileName);

    // If file already exists, find a unique numbered name
    int counter = 1;
    while (await noteExists(relativePath)) {
      final base = FileNameUtils.extractTitleFromFileName(candidateName);
      fileName = FileNameUtils.sanitizeFileName('${base}_$counter');
      relativePath = FileNameUtils.joinRelativePath(folder, fileName);
      counter++;
    }

    // Prepare initial content
    String contentToWrite = initialContent;
    if (contentToWrite.isEmpty && title != null && title.trim().isNotEmpty) {
      contentToWrite = '# ${title.trim()}\n\n';
    }

    await writeNote(relativePath, contentToWrite);

    final file = File(_toAbsolutePath(relativePath));
    final modifiedAt = await file.lastModified();
    final resolvedTitle = _markdownService.resolveTitle(contentToWrite, fileName);
    final snippet = _markdownService.extractSnippet(contentToWrite);

    return NoteFile(
      relativePath: relativePath,
      fileName: fileName,
      title: resolvedTitle,
      modifiedAt: modifiedAt,
      previewSnippet: snippet,
      isFavorite: false,
      tags: _markdownService.extractTags(contentToWrite),
    );
  }

  Future<void> _seedWelcomeNote() async {
    const welcome = '''# مرحباً بك في تطبيق الملاحظات

هذا تطبيق ملاحظات يومي مصمم بفلسفة **Local-first**.

### المبادئ الأساسية:
- **ملفات `.md` حقيقية:** كل ملاحظة تحفظ كملف ماركداون قياسي على جهازك.
- **توافق كامل:** يمكنك فتح هذا المجلد في أي وقت على **Obsidian** أو أي محرر نصوص.
- **بدون قواعد بيانات مغلقة:** لا يتم تخزين الملاحظات داخل قاعدة بيانات خفية.

### جرب أدوات الماركداون:
- [x] أنشئ ملاحظتك الأولى
- [ ] جرب شريط الأدوات العلوي
- [ ] اختبر التبديل بين وضع التحرير والمعاينة

| الميزة | الحالة |
| :--- | :--- |
| ملفات حقيقية | مدعوم |
| خط المسند اليمني القديم | مدعوم |
| معاينة حية | مدعوم |
| مفضلة وبحث | مدعوم |

### خط المسند اليمني القديم (Musnad):
- الحروف: 𐩠 𐩡 𐩢 𐩣 𐩤 𐩥 𐩦 𐩧 𐩨 𐩩 𐩪 𐩫 𐩬 𐩭 𐩮 𐩯 𐩰 𐩱 𐩲 𐩳 𐩴 𐩵 𐩶 𐩷 𐩸 𐩹 𐩺 𐩻 𐩼
- الفاصل بين الكلمات: 𐩽
- نقش ترحيبي: 𐩣𐩧𐩢𐩨𐩩𐩽𐩨𐩫𐩣𐩽𐩨𐩺𐩬𐩽𐩱𐩠𐩡𐩫𐩣

استمتع بتدوين أفكارك بحرية وخصوصية كاملة!
''';
    await writeNote('Welcome.md', welcome);
  }
}
