import 'dart:math';
import 'package:flutter/widgets.dart';

/// Utilities for inserting and wrapping Markdown syntax around editor selections.
class MarkdownUtils {
  MarkdownUtils._();

  /// Wraps the current selection with [prefix] and [suffix].
  /// If no text is selected, inserts [defaultPlaceholder] wrapped by prefix and suffix,
  /// and selects the placeholder so the user can immediately overwrite it.
  static void wrapSelection(
    TextEditingController controller,
    String prefix,
    String suffix, {
    String defaultPlaceholder = '',
  }) {
    final text = controller.text;
    final selection = controller.selection;

    final start = max(0, min(selection.start, selection.end));
    final end = max(0, max(selection.start, selection.end));

    if (start != end) {
      // User has selected text
      final selectedText = text.substring(start, end);
      final newText = '$prefix$selectedText$suffix';
      final updated = text.replaceRange(start, end, newText);

      controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: start + prefix.length + selectedText.length,
        ),
      );
    } else {
      // No text selected; insert prefix + defaultPlaceholder + suffix
      final newText = '$prefix$defaultPlaceholder$suffix';
      final updated = text.replaceRange(start, start, newText);

      controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: start + prefix.length + defaultPlaceholder.length,
        ),
      );
    }
  }

  /// Inserts a prefix (e.g. "# ", "## ", "- ", "- [ ] ", "> ") at the start of the current line.
  static void insertLinePrefix(TextEditingController controller, String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    final cursor = max(0, selection.baseOffset);

    // Find the start of the current line
    final lineStart = text.lastIndexOf('\n', max(0, cursor - 1)) + 1;

    final updated = text.replaceRange(lineStart, lineStart, prefix);
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
  }

  /// Inserts inline code: `code`
  static void insertInlineCode(TextEditingController controller) {
    wrapSelection(controller, '`', '`', defaultPlaceholder: 'code');
  }

  /// Inserts a multi-line code block:
  /// ```lang
  /// code
  /// ```
  static void insertCodeBlock(
    TextEditingController controller, {
    String language = '',
  }) {
    final text = controller.text;
    final selection = controller.selection;
    final start = max(0, min(selection.start, selection.end));
    final end = max(0, max(selection.start, selection.end));

    final selected = (start != end) ? text.substring(start, end) : 'code';

    // Ensure leading and trailing newlines if not already at line boundary
    final needsLeadingNewline = start > 0 && text[start - 1] != '\n';
    final needsTrailingNewline = end < text.length && text[end] != '\n';

    final prefix = '${needsLeadingNewline ? '\n' : ''}```$language\n';
    final suffix = '\n```${needsTrailingNewline ? '\n' : ''}';
    final replacement = '$prefix$selected$suffix';

    final updated = text.replaceRange(start, end, replacement);
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selected.length,
      ),
    );
  }

  /// Inserts a markdown link: [title](url)
  static void insertLink(
    TextEditingController controller, {
    String url = 'https://',
    String defaultTitle = 'link',
  }) {
    final text = controller.text;
    final selection = controller.selection;
    final start = max(0, min(selection.start, selection.end));
    final end = max(0, max(selection.start, selection.end));

    final title = (start != end) ? text.substring(start, end) : defaultTitle;
    final replacement = '[$title]($url)';

    final updated = text.replaceRange(start, end, replacement);
    // Position cursor at the URL part
    final urlStart = start + title.length + 3; // after '[$title]('
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection(
        baseOffset: urlStart,
        extentOffset: urlStart + url.length,
      ),
    );
  }
}
