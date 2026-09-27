import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openote/services/preferences_service.dart';

void main() {
  group('PreferencesService', () {
    late PreferencesService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = await PreferencesService.create();
    });

    test('stores and toggles relative favorite paths', () async {
      expect(service.getFavoritePaths(), isEmpty);

      final added = await service.toggleFavorite('Projects/Plan.md');
      expect(added, isTrue);
      expect(service.isFavorite('Projects/Plan.md'), isTrue);
      expect(service.getFavoritePaths(), contains('Projects/Plan.md'));

      final removed = await service.toggleFavorite('Projects/Plan.md');
      expect(removed, isFalse);
      expect(service.isFavorite('Projects/Plan.md'), isFalse);
      expect(service.getFavoritePaths(), isEmpty);
    });

    test('onNoteRenamed preserves favorite status without leaving orphans', () async {
      await service.toggleFavorite('Ideas/Draft.md');
      expect(service.isFavorite('Ideas/Draft.md'), isTrue);

      await service.onNoteRenamed('Ideas/Draft.md', 'Ideas/Final.md');
      expect(service.isFavorite('Ideas/Draft.md'), isFalse);
      expect(service.isFavorite('Ideas/Final.md'), isTrue);
      expect(service.getFavoritePaths(), contains('Ideas/Final.md'));
    });

    test('onNoteDeleted purges path from favorites', () async {
      await service.toggleFavorite('Todo.md');
      expect(service.isFavorite('Todo.md'), isTrue);

      await service.onNoteDeleted('Todo.md');
      expect(service.isFavorite('Todo.md'), isFalse);
      expect(service.getFavoritePaths(), isEmpty);
    });

    test('stores and toggles archived paths', () async {
      expect(service.getArchivedPaths(), isEmpty);

      final archived = await service.toggleArchive('Old/ArchiveNote.md');
      expect(archived, isTrue);
      expect(service.isArchived('Old/ArchiveNote.md'), isTrue);

      final unarchived = await service.toggleArchive('Old/ArchiveNote.md');
      expect(unarchived, isFalse);
      expect(service.isArchived('Old/ArchiveNote.md'), isFalse);
    });

    test('persists and retrieves theme mode, locale, and view mode', () async {
      expect(service.getThemeMode(), 'system');
      expect(service.getAppLocale(), 'ar');
      expect(service.getViewMode(), 'list');

      await service.setThemeMode('dark');
      await service.setAppLocale('en');
      await service.setViewMode('grid');

      expect(service.getThemeMode(), 'dark');
      expect(service.getAppLocale(), 'en');
      expect(service.getViewMode(), 'grid');
    });
  });
}
