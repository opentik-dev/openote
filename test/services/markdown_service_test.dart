import 'package:flutter_test/flutter_test.dart';
import 'package:openote/services/markdown_service.dart';

void main() {
  const service = MarkdownService();

  group('MarkdownService.resolveTitle', () {
    test('extracts title from valid H1 heading', () {
      const content = '# My Note Title\n\nSome body text here.';
      expect(service.resolveTitle(content, 'Note.md'), 'My Note Title');
    });

    test('ignores leading empty lines before H1', () {
      const content = '\n\n   \n# Heading After Blank Lines\nBody';
      expect(service.resolveTitle(content, 'Note.md'), 'Heading After Blank Lines');
    });

    test('rejects hashtag #tag and falls back to filename', () {
      const content = '#tag #another_tag\nSome body';
      expect(service.resolveTitle(content, 'DevNotes.md'), 'DevNotes');
    });

    test('rejects H2 ## Subtitle and falls back to filename', () {
      const content = '## Only Subtitle Here\nBody content';
      expect(service.resolveTitle(content, 'MyDoc.md'), 'MyDoc');
    });

    test('falls back to filename when document has no H1', () {
      const content = 'This is just a regular paragraph without any heading.';
      expect(service.resolveTitle(content, 'ShoppingList.md'), 'ShoppingList');
    });

    test('falls back to filename when file is empty', () {
      expect(service.resolveTitle('', 'EmptyNote.md'), 'EmptyNote');
    });

    test('extracts Arabic title correctly', () {
      const content = '# نقوش سبئية وحميرية\n\nنص باللغة العربية.';
      expect(service.resolveTitle(content, 'ArabNote.md'), 'نقوش سبئية وحميرية');
    });

    test('extracts ancient Yemeni Musnad title correctly', () {
      const content = '# 𐩣𐩯𐩬𐩵 𐩺𐩣𐩬\n\n𐩥𐩤𐩢𐩽𐩱𐩡𐩣𐩤𐩠';
      expect(service.resolveTitle(content, 'Musnad.md'), '𐩣𐩯𐩬𐩵 𐩺𐩣𐩬');
    });
  });

  group('MarkdownService.extractSnippet', () {
    test('skips leading H1 title and captures body text', () {
      const content = '# My Title\n\nThis is the actual snippet of the note.';
      final snippet = service.extractSnippet(content);
      expect(snippet, 'This is the actual snippet of the note.');
    });

    test('cleans markdown symbols from preview snippet', () {
      const content = '- [ ] First task\n> An important quote\n**Bold text**';
      final snippet = service.extractSnippet(content);
      expect(snippet, contains('First task'));
      expect(snippet, contains('An important quote'));
    });

    test('truncates snippet when exceeding maxLength', () {
      final longText = 'A' * 200;
      final snippet = service.extractSnippet(longText, maxLength: 50);
      expect(snippet.length, lessThanOrEqualTo(53)); // 50 + '...'
      expect(snippet.endsWith('...'), isTrue);
    });
  });
}
