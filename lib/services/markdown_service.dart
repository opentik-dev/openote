import '../utils/file_name_utils.dart';

/// Service responsible for parsing markdown metadata (title, snippet) without mutating files.
class MarkdownService {
  const MarkdownService();

  /// Strict H1 Regex: must start with '#' followed by one or more whitespace characters.
  /// Does not match `#tag`, `## Subtitle`, or lines with no text after '#'.
  static final RegExp _h1Regex = RegExp(r'^#\s+(.+?)\s*$');

  /// Resolves the human-readable display title according to strict SSOT rules:
  /// 1. Finds the first non-empty line of the content.
  /// 2. If it matches `^#\s+(.+?)\s*$`, returns the trimmed heading text.
  /// 3. Otherwise, returns the file name without the `.md` extension.
  ///
  /// Note: The original file content is NEVER modified to inject an H1 header.
  String resolveTitle(String content, String fileName) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = _h1Regex.firstMatch(trimmed);
      if (match != null) {
        final headingText = match.group(1)?.trim();
        if (headingText != null && headingText.isNotEmpty) {
          return headingText;
        }
      }
      // Stop searching on first non-empty line: if it wasn't an H1, fall back to file name
      break;
    }
    return FileNameUtils.extractTitleFromFileName(fileName);
  }

  /// Extracts a short preview snippet (up to [maxLength] chars) for list display.
  /// Skips the first non-empty line if it was used as the H1 title.
  String extractSnippet(String content, {int maxLength = 120}) {
    final lines = content.split('\n');
    bool skippedTitle = false;
    final snippetLines = <String>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // If the first non-empty line is an H1 title, skip it from the snippet
      if (!skippedTitle) {
        skippedTitle = true;
        if (_h1Regex.hasMatch(line)) {
          continue;
        }
      }

      // Clean common markdown prefix decorators for cleaner snippet text
      final cleaned = line
          .replaceAll(RegExp(r'^[#>\-*\d\.\s\[\]x]+'), '')
          .replaceAll(RegExp(r'[*_`~]'), '')
          .trim();

      if (cleaned.isNotEmpty) {
        snippetLines.add(cleaned);
        if (snippetLines.join(' ').length >= maxLength) {
          break;
        }
      }
    }

    final combined = snippetLines.join(' ');
    if (combined.length <= maxLength) {
      return combined;
    }
    return '${combined.substring(0, maxLength)}...';
  }
}
