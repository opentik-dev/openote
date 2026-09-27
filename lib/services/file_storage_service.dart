import '../models/note_file.dart';

/// Abstract contract for storage operations on physical markdown notes.
///
/// Decouples the UI and domain logic from the underlying storage mechanism
/// (e.g. App-private sandbox in V1 vs Android SAF in V2).
abstract interface class FileStorageService {
  /// Initializes the storage root directory.
  Future<void> initialize();

  /// Recursively lists all markdown notes in the storage, matching against [favoritePaths].
  Future<List<NoteFile>> listNotes({Set<String>? favoritePaths});

  /// Reads the raw Markdown content of a specific note by its relative path.
  Future<String> readNote(String relativePath);

  /// Writes content to a specific note file at [relativePath], creating parent directories if needed.
  Future<void> writeNote(String relativePath, String content);

  /// Renames or moves a note from [oldPath] to [newPath].
  Future<void> renameNote(String oldPath, String newPath);

  /// Deletes the note file at [relativePath].
  Future<void> deleteNote(String relativePath);

  /// Creates a new note file in an optional [folder], with an optional [title] and [initialContent].
  /// Returns the newly created [NoteFile] descriptor.
  Future<NoteFile> createNote({
    String? folder,
    String? title,
    String initialContent = '',
  });

  /// Checks if a note file exists at [relativePath].
  Future<bool> noteExists(String relativePath);

  /// Returns the filesystem last-modified timestamp of the file at [relativePath], or null if not found.
  Future<DateTime?> getModifiedTime(String relativePath);

  /// Returns the absolute filesystem root path of the notes storage.
  Future<String> getRootPath();
}
