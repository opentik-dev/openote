import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Service for exporting, importing, and backing up notes as standard ZIP archives.
///
/// Fully compatible with tools like Obsidian, Joplin, and Google Keep (which use Markdown files in directories).
class BackupService {
  const BackupService();

  /// Exports all notes from [sourceNotesDir] into a timestamped ZIP archive
  /// in [targetBackupDir].
  ///
  /// Returns the absolute path of the generated ZIP file.
  Future<File> createBackupZip({
    required Directory sourceNotesDir,
    required Directory targetBackupDir,
  }) async {
    if (!await sourceNotesDir.exists()) {
      throw Exception('مجلد الملاحظات المصدر غير موجود: ${sourceNotesDir.path}');
    }

    if (!await targetBackupDir.exists()) {
      await targetBackupDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final zipPath = p.join(
      targetBackupDir.path,
      'OpeNote_Backup_$timestamp.zip',
    );

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    // Recursively add only markdown files and assets
    final entities = sourceNotesDir.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.md')) {
        final relPath = p.relative(entity.path, from: sourceNotesDir.path).replaceAll(r'\', '/');
        await encoder.addFile(entity, relPath);
      }
    }

    await encoder.close();
    return File(zipPath);
  }

  /// Imports all Markdown files from a [zipFile] into [destinationNotesDir].
  ///
  /// Preserves relative folder structure.
  /// Returns the count of successfully imported notes.
  Future<int> importBackupZip({
    required File zipFile,
    required Directory destinationNotesDir,
  }) async {
    if (!await zipFile.exists()) {
      throw Exception('ملف النسخة الاحتياطية غير موجود: ${zipFile.path}');
    }

    if (!await destinationNotesDir.exists()) {
      await destinationNotesDir.create(recursive: true);
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    int importedCount = 0;

    for (final entry in archive) {
      if (entry.isFile && entry.name.toLowerCase().endsWith('.md')) {
        // Sanitize entry path to prevent Zip Slip directory traversal vulnerabilities
        final safeRelativeName = p.normalize(entry.name).replaceAll(r'\', '/');
        if (safeRelativeName.startsWith('..') || safeRelativeName.startsWith('/')) {
          continue;
        }

        final targetPath = p.join(destinationNotesDir.path, safeRelativeName);
        final targetFile = File(targetPath);

        await targetFile.parent.create(recursive: true);
        final fileContent = entry.content as List<int>;
        await targetFile.writeAsBytes(fileContent);

        importedCount++;
      }
    }

    return importedCount;
  }

  /// Exports a single note as a standalone .txt or .md file.
  Future<File> exportSingleNote({
    required String relativePath,
    required String content,
    required Directory destinationDir,
    bool asPlainText = false,
  }) async {
    if (!await destinationDir.exists()) {
      await destinationDir.create(recursive: true);
    }

    final originalBase = p.basenameWithoutExtension(relativePath);
    final ext = asPlainText ? '.txt' : '.md';
    final targetPath = p.join(destinationDir.path, '$originalBase$ext');

    final file = File(targetPath);
    await file.writeAsString(content);
    return file;
  }
}
