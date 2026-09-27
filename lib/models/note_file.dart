import '../utils/file_name_utils.dart';

/// Pure File Descriptor representing a note on the filesystem.
///
/// Note: By architectural design (SSOT), [NoteFile] does NOT contain
/// the full markdown content. Full content is always read on demand directly
/// from disk via [FileStorageService.readNote].
class NoteFile {
  /// The path relative to the root notes directory (e.g. "Projects/App.md" or "MyNote.md").
  final String relativePath;

  /// The raw file name including extension (e.g. "App.md").
  final String fileName;

  /// Human-friendly display title (extracted from `# Title` or fileName without `.md`).
  final String title;

  /// Physical last-modified timestamp from the filesystem.
  final DateTime modifiedAt;

  /// A short 1-line snippet of the content for fast list previews.
  final String previewSnippet;

  /// Whether this note is marked as favorite in user preferences.
  final bool isFavorite;

  /// Whether this note is marked as archived in user preferences.
  final bool isArchived;

  const NoteFile({
    required this.relativePath,
    required this.fileName,
    required this.title,
    required this.modifiedAt,
    required this.previewSnippet,
    this.isFavorite = false,
    this.isArchived = false,
  });

  /// The folder category portion of the relative path, or null if in root.
  String? get folder => FileNameUtils.extractFolder(relativePath);

  /// Creates a copy with optionally modified fields.
  NoteFile copyWith({
    String? relativePath,
    String? fileName,
    String? title,
    DateTime? modifiedAt,
    String? previewSnippet,
    bool? isFavorite,
    bool? isArchived,
  }) {
    return NoteFile(
      relativePath: relativePath ?? this.relativePath,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      previewSnippet: previewSnippet ?? this.previewSnippet,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteFile &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath &&
          modifiedAt == other.modifiedAt &&
          isFavorite == other.isFavorite &&
          isArchived == other.isArchived;

  @override
  int get hashCode =>
      relativePath.hashCode ^
      modifiedAt.hashCode ^
      isFavorite.hashCode ^
      isArchived.hashCode;

  @override
  String toString() =>
      'NoteFile(relativePath: $relativePath, title: $title, modifiedAt: $modifiedAt, isFavorite: $isFavorite, isArchived: $isArchived)';
}
