import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openote/services/app_private_storage.dart';
import 'package:openote/services/preferences_service.dart';
import 'package:openote/state/notes_state_notifier.dart';

void main() {
  group('SSOT & Local-first Round-trip Integration Tests', () {
    late Directory tempDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('marknote_roundtrip_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. Write -> Restart App -> Scan Filesystem -> Content matches original', () async {
      // Step A: App session 1: Create and write note
      final storage1 = AppPrivateStorage(rootDir: tempDir);
      final prefs1 = await PreferencesService.create();
      final notifier1 = NotesStateNotifier(storage: storage1, prefs: prefs1);
      await notifier1.loadNotes();

      const originalContent = '# My First Note\n\nThis is pure markdown content.';
      final note = await notifier1.createNote(
        folder: 'Journal',
        title: 'My First Note',
        initialContent: originalContent,
      );

      // Verify write
      final content1 = await notifier1.readNoteContent(note.relativePath);
      expect(content1, originalContent);

      // Step B: Simulate complete application shutdown (destroy in-memory state)
      // Step C: App session 2: Reopen app with a fresh notifier and scan disk
      final storage2 = AppPrivateStorage(rootDir: tempDir);
      final prefs2 = await PreferencesService.create();
      final notifier2 = NotesStateNotifier(storage: storage2, prefs: prefs2);
      await notifier2.loadNotes();

      // Verify filesystem scan re-indexed the note
      expect(notifier2.allNotes.any((n) => n.relativePath == 'Journal/My First Note.md'), isTrue);

      final content2 = await notifier2.readNoteContent('Journal/My First Note.md');
      expect(content2, originalContent);
    });

    test('2. External Creation: Created outside -> rescan() -> Application indexes it', () async {
      final storage = AppPrivateStorage(rootDir: tempDir);
      final prefs = await PreferencesService.create();
      final notifier = NotesStateNotifier(storage: storage, prefs: prefs);
      await notifier.loadNotes();

      final initialCount = notifier.allNotes.length;

      // Simulate external creation (e.g. from Obsidian, bash, or Nextcloud sync)
      final externalFile = File('${tempDir.path}/Projects/ObsidianNote.md');
      externalFile.parent.createSync(recursive: true);
      await externalFile.writeAsString('# Obsidian Created\n\nCreated directly on filesystem.');

      // Rescan (as happens on foreground resume or pull-to-refresh)
      await notifier.rescan();

      expect(notifier.allNotes.length, initialCount + 1);
      final found = notifier.allNotes.firstWhere(
        (n) => n.relativePath == 'Projects/ObsidianNote.md',
      );
      expect(found.title, 'Obsidian Created');
      expect(found.folder, 'Projects');

      final content = await notifier.readNoteContent('Projects/ObsidianNote.md');
      expect(content, contains('Created directly on filesystem.'));
    });

    test('3. External Modification: Modified outside -> rescan() -> Application sees new content', () async {
      final storage = AppPrivateStorage(rootDir: tempDir);
      final prefs = await PreferencesService.create();
      final notifier = NotesStateNotifier(storage: storage, prefs: prefs);
      await notifier.loadNotes();

      final note = await notifier.createNote(
        title: 'OriginalDoc',
        initialContent: '# OriginalDoc\n\nInitial version.',
      );

      // Wait a tick and simulate external modification
      await Future.delayed(const Duration(milliseconds: 150));
      final file = File('${tempDir.path}/${note.relativePath}');
      const externalUpdatedText = '# UpdatedDoc Title\n\nModified externally by Syncthing.';
      await file.writeAsString(externalUpdatedText);

      // Rescan
      await notifier.rescan();

      final updatedDescriptor = notifier.allNotes.firstWhere(
        (n) => n.relativePath == note.relativePath,
      );
      expect(updatedDescriptor.title, 'UpdatedDoc Title');

      final newReadContent = await notifier.readNoteContent(note.relativePath);
      expect(newReadContent, externalUpdatedText);
    });

    test('4. External Deletion: Deleted outside -> rescan() -> Disappears from in-memory index', () async {
      final storage = AppPrivateStorage(rootDir: tempDir);
      final prefs = await PreferencesService.create();
      final notifier = NotesStateNotifier(storage: storage, prefs: prefs);
      await notifier.loadNotes();

      final note = await notifier.createNote(title: 'NoteToDeleteOutside');
      expect(notifier.allNotes.any((n) => n.relativePath == note.relativePath), isTrue);

      // Delete file externally from disk
      final file = File('${tempDir.path}/${note.relativePath}');
      file.deleteSync();
      expect(file.existsSync(), isFalse);

      // Rescan
      await notifier.rescan();

      expect(notifier.allNotes.any((n) => n.relativePath == note.relativePath), isFalse);
    });

    test('5. External Rename: Renamed outside -> rescan() -> Old disappears, New appears', () async {
      final storage = AppPrivateStorage(rootDir: tempDir);
      final prefs = await PreferencesService.create();
      final notifier = NotesStateNotifier(storage: storage, prefs: prefs);
      await notifier.loadNotes();

      await notifier.createNote(title: 'OldFilename');
      expect(notifier.allNotes.any((n) => n.relativePath == 'OldFilename.md'), isTrue);

      // Rename file externally on disk
      final oldFile = File('${tempDir.path}/OldFilename.md');
      final newFile = File('${tempDir.path}/NewFilename.md');
      oldFile.renameSync(newFile.path);

      // Rescan
      await notifier.rescan();

      expect(notifier.allNotes.any((n) => n.relativePath == 'OldFilename.md'), isFalse);
      expect(notifier.allNotes.any((n) => n.relativePath == 'NewFilename.md'), isTrue);
    });
  });
}
