import 'package:flutter_test/flutter_test.dart';
import 'package:openote/utils/file_name_utils.dart';

void main() {
  group('FileNameUtils', () {
    test('sanitizeFileName removes illegal filesystem characters', () {
      expect(
        FileNameUtils.sanitizeFileName('Project: Plan / 2026? *important*'),
        'Project_ Plan _ 2026_ _important_.md',
      );
    });

    test('sanitizeFileName ensures .md extension', () {
      expect(FileNameUtils.sanitizeFileName('MyNote'), 'MyNote.md');
      expect(FileNameUtils.sanitizeFileName('MyNote.md'), 'MyNote.md');
      expect(FileNameUtils.sanitizeFileName('MyNote.MD'), 'MyNote.MD');
    });

    test('sanitizeFileName handles empty input with fallback', () {
      expect(FileNameUtils.sanitizeFileName('   '), 'Untitled.md');
      expect(FileNameUtils.sanitizeFileName('???', fallback: 'Note'), '___.md');
    });

    test('extractTitleFromFileName removes .md extension only', () {
      expect(FileNameUtils.extractTitleFromFileName('MyNote.md'), 'MyNote');
      expect(FileNameUtils.extractTitleFromFileName('Note.with.dots.md'), 'Note.with.dots');
      expect(FileNameUtils.extractTitleFromFileName('JustAText'), 'JustAText');
    });

    test('joinRelativePath joins folder and filename safely', () {
      expect(
        FileNameUtils.joinRelativePath('Projects', 'Note.md'),
        'Projects/Note.md',
      );
      expect(
        FileNameUtils.joinRelativePath(null, 'Note.md'),
        'Note.md',
      );
      expect(
        FileNameUtils.joinRelativePath('  ', 'Note.md'),
        'Note.md',
      );
    });

    test('extractFolder returns folder or null for root files', () {
      expect(FileNameUtils.extractFolder('Projects/Sub/Note.md'), 'Projects/Sub');
      expect(FileNameUtils.extractFolder('Projects/Note.md'), 'Projects');
      expect(FileNameUtils.extractFolder('Note.md'), isNull);
    });
  });
}
