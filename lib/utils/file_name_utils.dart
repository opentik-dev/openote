import 'package:path/path.dart' as p;

/// Utility functions for handling note file names and relative paths.
class FileNameUtils {
  FileNameUtils._();

  /// Characters illegal in filenames across Linux, Android, and Windows.
  static final RegExp _illegalChars = RegExp(r'[\\/:*?"<>|]');

  /// Sanitizes a string to make it a valid, safe file name with .md extension.
  static String sanitizeFileName(String input, {String fallback = 'Untitled'}) {
    var sanitized = input.replaceAll(_illegalChars, '_').trim();
    if (sanitized.isEmpty) {
      sanitized = fallback;
    }
    if (!sanitized.toLowerCase().endsWith('.md')) {
      sanitized = '$sanitized.md';
    }
    return sanitized;
  }

  /// Extracts the title from a file name by removing the `.md` extension.
  static String extractTitleFromFileName(String fileName) {
    if (fileName.toLowerCase().endsWith('.md')) {
      return fileName.substring(0, fileName.length - 3);
    }
    return fileName;
  }

  /// Joins an optional folder path and file name into a normalized relative path.
  static String joinRelativePath(String? folder, String fileName) {
    final sanitizedFileName = sanitizeFileName(fileName);
    if (folder == null || folder.trim().isEmpty) {
      return p.normalize(sanitizedFileName);
    }
    final normalizedFolder = p.normalize(folder.trim()).replaceAll(r'\', '/');
    return p.normalize('$normalizedFolder/$sanitizedFileName');
  }

  /// Extracts the folder directory portion of a relative path (e.g. "Projects" from "Projects/App.md").
  static String? extractFolder(String relativePath) {
    final dir = p.dirname(relativePath);
    if (dir == '.' || dir.isEmpty) {
      return null;
    }
    return dir.replaceAll(r'\', '/');
  }
}
