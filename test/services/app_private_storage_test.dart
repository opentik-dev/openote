import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openote/services/app_private_storage.dart';

void main() {
  group('AppPrivateStorage', () {
    late Directory tempDir;
    late AppPrivateStorage storage;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('marknote_test_');
      storage = AppPrivateStorage(rootDir: tempDir);
      await storage.initialize();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initialize creates directory and seeds Welcome note', () async {
      final exists = await storage.noteExists('Welcome.md');
      expect(exists, isTrue);

      final content = await storage.readNote('Welcome.md');
      expect(content, contains('مرحباً بك في تطبيق الملاحظات'));
    });

    test('createNote creates physical .md file and returns NoteFile descriptor', () async {
      final note = await storage.createNote(
        folder: 'Projects',
        title: 'AlphaGenome Explorer',
        initialContent: '# AlphaGenome Explorer\n\nNotes on genome analysis.',
      );

      expect(note.relativePath, 'Projects/AlphaGenome Explorer.md');
      expect(note.fileName, 'AlphaGenome Explorer.md');
      expect(note.title, 'AlphaGenome Explorer');
      expect(note.folder, 'Projects');

      // Verify physical file on disk
      final fileOnDisk = File('${tempDir.path}/Projects/AlphaGenome Explorer.md');
      expect(fileOnDisk.existsSync(), isTrue);

      final readContent = await storage.readNote(note.relativePath);
      expect(readContent, contains('Notes on genome analysis.'));
    });

    test('createNote handles duplicates by appending numbers', () async {
      final note1 = await storage.createNote(title: 'SameName');
      final note2 = await storage.createNote(title: 'SameName');

      expect(note1.fileName, 'SameName.md');
      expect(note2.fileName, 'SameName_1.md');
    });

    test('renameNote moves physical file to new path', () async {
      await storage.createNote(title: 'OldName');
      expect(await storage.noteExists('OldName.md'), isTrue);

      await storage.renameNote('OldName.md', 'NewName.md');
      expect(await storage.noteExists('OldName.md'), isFalse);
      expect(await storage.noteExists('NewName.md'), isTrue);
    });

    test('deleteNote removes physical file from disk', () async {
      final note = await storage.createNote(title: 'ToDelete');
      expect(await storage.noteExists(note.relativePath), isTrue);

      await storage.deleteNote(note.relativePath);
      expect(await storage.noteExists(note.relativePath), isFalse);
    });

    test('preserves UTF-8 Arabic and ancient Musnad characters without Mojibake', () async {
      const musnadTitle = '𐩣𐩯𐩬𐩵 𐩺𐩣𐩬';
      const bodyContent = '# $musnadTitle\n\nنقوش سبئية وحميرية قديمة:\n𐩥𐩤𐩢𐩽𐩱𐩡𐩣𐩤𐩠𐩽𐩦𐩺𐩣𐩬';

      final note = await storage.createNote(
        title: 'ملاحظة مسندية',
        initialContent: bodyContent,
      );

      // Verify reading back full content
      final content = await storage.readNote(note.relativePath);
      expect(content, bodyContent);

      // Verify listNotes decodes UTF-8 title and snippet correctly
      final notes = await storage.listNotes();
      final listedNote = notes.firstWhere((n) => n.relativePath == note.relativePath);
      expect(listedNote.title, musnadTitle);
      expect(listedNote.previewSnippet, contains('نقوش سبئية وحميرية قديمة'));
      expect(listedNote.previewSnippet, contains('𐩥𐩤𐩢𐩽𐩱𐩡𐩣𐩤𐩠'));
    });
  });
}
