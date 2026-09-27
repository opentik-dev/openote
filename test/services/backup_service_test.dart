import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openote/services/backup_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late Directory sourceNotesDir;
  late Directory backupDir;
  late Directory restoreDir;
  const backupService = BackupService();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('openote_backup_test_');
    sourceNotesDir = Directory(p.join(tempDir.path, 'notes'));
    backupDir = Directory(p.join(tempDir.path, 'backups'));
    restoreDir = Directory(p.join(tempDir.path, 'restored'));

    await sourceNotesDir.create(recursive: true);
    await backupDir.create(recursive: true);
    await restoreDir.create(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('createBackupZip and importBackupZip preserve files and structure', () async {
    // 1. Create sample notes
    final note1 = File(p.join(sourceNotesDir.path, 'note1.md'));
    await note1.writeAsString('# ملاحظة 1\nمحتوى علمي: \$E=mc^2\$ #فيزياء');

    final subDir = Directory(p.join(sourceNotesDir.path, 'science'));
    await subDir.create();
    final note2 = File(p.join(subDir.path, 'kinematics.md'));
    await note2.writeAsString('# حركة الأجسام\n\$v = \\frac{d}{t}\$ #فيزياء');

    // Create a non-md file that should be ignored
    final ignored = File(p.join(sourceNotesDir.path, 'ignore.tmp'));
    await ignored.writeAsString('should not be included');

    // 2. Create ZIP
    final zipFile = await backupService.createBackupZip(
      sourceNotesDir: sourceNotesDir,
      targetBackupDir: backupDir,
    );

    expect(await zipFile.exists(), isTrue);
    expect(zipFile.path.endsWith('.zip'), isTrue);

    // 3. Import ZIP into restoreDir
    final importedCount = await backupService.importBackupZip(
      zipFile: zipFile,
      destinationNotesDir: restoreDir,
    );

    expect(importedCount, equals(2));

    final restoredNote1 = File(p.join(restoreDir.path, 'note1.md'));
    expect(await restoredNote1.exists(), isTrue);
    expect(await restoredNote1.readAsString(), contains('# ملاحظة 1'));

    final restoredNote2 = File(p.join(restoreDir.path, 'science', 'kinematics.md'));
    expect(await restoredNote2.exists(), isTrue);
    expect(await restoredNote2.readAsString(), contains('v = \\frac{d}{t}'));

    final ignoredInRestore = File(p.join(restoreDir.path, 'ignore.tmp'));
    expect(await ignoredInRestore.exists(), isFalse);
  });

  test('exportSingleNote writes note as MD and TXT correctly', () async {
    const content = '# تجربة\nهذا نص تجريبي للتصدير';

    // Export as MD
    final mdFile = await backupService.exportSingleNote(
      relativePath: 'test_note.md',
      content: content,
      destinationDir: backupDir,
      asPlainText: false,
    );
    expect(await mdFile.exists(), isTrue);
    expect(mdFile.path.endsWith('test_note.md'), isTrue);
    expect(await mdFile.readAsString(), equals(content));

    // Export as TXT
    final txtFile = await backupService.exportSingleNote(
      relativePath: 'test_note.md',
      content: content,
      destinationDir: backupDir,
      asPlainText: true,
    );
    expect(await txtFile.exists(), isTrue);
    expect(txtFile.path.endsWith('test_note.txt'), isTrue);
    expect(await txtFile.readAsString(), equals(content));
  });
}
