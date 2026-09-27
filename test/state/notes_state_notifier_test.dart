import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openote/services/app_private_storage.dart';
import 'package:openote/services/preferences_service.dart';
import 'package:openote/state/notes_state_notifier.dart';

void main() {
  group('NotesStateNotifier', () {
    late Directory tempDir;
    late AppPrivateStorage storage;
    late PreferencesService prefs;
    late NotesStateNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('marknote_notifier_test_');
      storage = AppPrivateStorage(rootDir: tempDir);
      prefs = await PreferencesService.create();
      notifier = NotesStateNotifier(storage: storage, prefs: prefs);
      await notifier.loadNotes();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initializes with seeded notes in memory', () {
      expect(notifier.allNotes.isNotEmpty, isTrue);
      expect(notifier.allNotes.any((n) => n.fileName == 'Welcome.md'), isTrue);
    });

    test('creates note and updates in-memory index', () async {
      final initialCount = notifier.allNotes.length;
      final note = await notifier.createNote(
        folder: 'Ideas',
        title: 'New Idea',
        initialContent: '# New Idea\n\nBrilliant thought.',
      );

      expect(notifier.allNotes.length, initialCount + 1);
      expect(notifier.allNotes.any((n) => n.relativePath == note.relativePath), isTrue);
      expect(notifier.availableFolders, contains('Ideas'));
    });

    test('search query filters in-memory notes by title and snippet', () async {
      await notifier.createNote(
        title: 'Flutter Roadmap',
        initialContent: '# Flutter Roadmap\n\nDetailed milestones.',
      );
      await notifier.createNote(
        title: 'Grocery List',
        initialContent: '# Grocery List\n\nApples, oranges.',
      );

      notifier.setSearchQuery('Roadmap');
      expect(notifier.filteredNotes.length, 1);
      expect(notifier.filteredNotes.first.title, 'Flutter Roadmap');

      notifier.setSearchQuery('apples');
      expect(notifier.filteredNotes.length, 1);
      expect(notifier.filteredNotes.first.title, 'Grocery List');
    });

    test('filters by folder and favorites', () async {
      final note = await notifier.createNote(
        folder: 'Work',
        title: 'Tasks',
        initialContent: '# Tasks\n\nStuff to do.',
      );

      notifier.setSelectedFolder('Work');
      expect(notifier.filteredNotes.length, 1);
      expect(notifier.filteredNotes.first.title, 'Tasks');

      // Favorite toggle
      await notifier.toggleFavorite(note.relativePath);
      notifier.setSelectedFolder(null);
      notifier.toggleShowOnlyFavorites();

      expect(notifier.filteredNotes.length, 1);
      expect(notifier.filteredNotes.first.relativePath, note.relativePath);
    });

    test('supports archiving notes and toggling archive view', () async {
      final note = await notifier.createNote(
        title: 'Old Project',
        initialContent: '# Old Project\n\nArchived details.',
      );

      // Archive note
      await notifier.toggleArchive(note.relativePath);

      // Verify normal view hides archived note
      notifier.setSearchQuery('');
      expect(notifier.filteredNotes.any((n) => n.relativePath == note.relativePath), isFalse);

      // Verify archive view displays it
      notifier.toggleShowOnlyArchived();
      expect(notifier.showOnlyArchived, isTrue);
      expect(notifier.filteredNotes.any((n) => n.relativePath == note.relativePath), isTrue);

      // Unarchive
      await notifier.toggleArchive(note.relativePath);
      expect(notifier.filteredNotes.any((n) => n.relativePath == note.relativePath), isFalse);
    });

    test('supports viewMode, themeMode, and locale updates', () async {
      expect(notifier.viewMode, 'list');
      await notifier.toggleViewMode();
      expect(notifier.viewMode, 'grid');

      await notifier.setThemeMode('dark');
      expect(notifier.themeMode, 'dark');

      await notifier.setLocaleCode('en');
      expect(notifier.localeCode, 'en');
    });

    test('detects external modifications', () async {
      final note = await notifier.createNote(title: 'SyncCheck');
      final openedTime = note.modifiedAt;

      // File not modified externally yet
      expect(await notifier.isExternallyModified(note.relativePath, openedTime), isFalse);

      // Wait a tick and simulate an external edit (e.g. Obsidian or nano)
      await Future.delayed(const Duration(milliseconds: 200));
      final file = File('${tempDir.path}/${note.relativePath}');
      await file.writeAsString('# SyncCheck\n\nEdited externally by Obsidian.');
      await file.setLastModified(openedTime.add(const Duration(seconds: 1)));

      expect(await notifier.isExternallyModified(note.relativePath, openedTime), isTrue);
    });
  });
}
