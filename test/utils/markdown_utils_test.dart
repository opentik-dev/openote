import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openote/utils/markdown_utils.dart';

void main() {
  group('MarkdownUtils', () {
    test('wrapSelection wraps highlighted text', () {
      final controller = TextEditingController(text: 'Hello world today');
      // Select 'world'
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11);

      MarkdownUtils.wrapSelection(controller, '**', '**');
      expect(controller.text, 'Hello **world** today');
      expect(controller.selection.textInside(controller.text), 'world');
    });

    test('wrapSelection inserts placeholder when no text selected', () {
      final controller = TextEditingController(text: 'Hello ');
      controller.selection = const TextSelection.collapsed(offset: 6);

      MarkdownUtils.wrapSelection(controller, '*', '*', defaultPlaceholder: 'italic');
      expect(controller.text, 'Hello *italic*');
      expect(controller.selection.textInside(controller.text), 'italic');
    });

    test('insertLinePrefix adds prefix at start of current line', () {
      final controller = TextEditingController(text: 'Line 1\nSecond line\nLine 3');
      // Cursor inside 'Second line'
      controller.selection = const TextSelection.collapsed(offset: 12);

      MarkdownUtils.insertLinePrefix(controller, '# ');
      expect(controller.text, 'Line 1\n# Second line\nLine 3');
    });

    test('insertInlineCode wraps text in backticks', () {
      final controller = TextEditingController(text: 'Run flutter test');
      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 16);

      MarkdownUtils.insertInlineCode(controller);
      expect(controller.text, 'Run `flutter test`');
    });

    test('insertCodeBlock wraps multi-line code properly', () {
      final controller = TextEditingController(text: 'void main() {\n  run();\n}');
      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);

      MarkdownUtils.insertCodeBlock(controller, language: 'dart');
      expect(controller.text, contains('```dart\nvoid main() {\n  run();\n}\n```'));
    });

    test('insertLink formats markdown link properly', () {
      final controller = TextEditingController(text: 'Check docs here');
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 10);

      MarkdownUtils.insertLink(controller, url: 'https://flutter.dev');
      expect(controller.text, 'Check [docs](https://flutter.dev) here');
    });
  });
}
