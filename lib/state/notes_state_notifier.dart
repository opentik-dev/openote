import 'package:flutter/foundation.dart';
import '../models/note_file.dart';
import '../services/file_storage_service.dart';
import '../services/preferences_service.dart';

/// Central state manager for notes.
///
/// Maintains an in-memory index derived strictly from the filesystem.
/// All note metadata is derived directly from disk; preferences hold UI favorites,
/// archived states, theme, language, and view layouts.
class NotesStateNotifier extends ChangeNotifier {
  final FileStorageService _storage;
  final PreferencesService _prefs;

  List<NoteFile> _allNotes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedFolder;
  bool _showOnlyFavorites = false;
  bool _showOnlyArchived = false;

  late String _themeMode; // 'system' | 'light' | 'dark'
  late String _localeCode; // 'ar' | 'en' | 'system'
  late String _viewMode; // 'list' | 'grid'

  NotesStateNotifier({
    required FileStorageService storage,
    required PreferencesService prefs,
  })  : _storage = storage,
        _prefs = prefs {
    _themeMode = _prefs.getThemeMode();
    _localeCode = _prefs.getAppLocale();
    _viewMode = _prefs.getViewMode();
  }

  List<NoteFile> get allNotes => List.unmodifiable(_allNotes);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedFolder => _selectedFolder;
  bool get showOnlyFavorites => _showOnlyFavorites;
  bool get showOnlyArchived => _showOnlyArchived;
  String get themeMode => _themeMode;
  String get localeCode => _localeCode;
  String get viewMode => _viewMode;

  /// Returns unique folders existing across all non-archived indexed notes.
  List<String> get availableFolders {
    final folders = <String>{};
    for (final note in _allNotes) {
      if (!note.isArchived && note.folder != null) {
        folders.add(note.folder!);
      }
    }
    final sorted = folders.toList()..sort();
    return sorted;
  }

  /// Returns the filtered list of notes according to search, folder, favorites, and archive filters.
  List<NoteFile> get filteredNotes {
    return _allNotes.where((note) {
      // Archive filter
      if (_showOnlyArchived) {
        if (!note.isArchived) return false;
      } else {
        // In normal view, hide archived notes unless searching
        if (note.isArchived && _searchQuery.isEmpty) return false;
      }

      // Favorite filter
      if (_showOnlyFavorites && !note.isFavorite) {
        return false;
      }

      // Folder filter
      if (_selectedFolder != null && note.folder != _selectedFolder) {
        return false;
      }

      // Search query filter (matches title, filename, snippet, or path)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = note.title.toLowerCase().contains(query);
        final matchesFileName = note.fileName.toLowerCase().contains(query);
        final matchesSnippet = note.previewSnippet.toLowerCase().contains(query);
        final matchesPath = note.relativePath.toLowerCase().contains(query);
        if (!matchesTitle && !matchesFileName && !matchesSnippet && !matchesPath) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Initial load of notes from storage.
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    await _storage.initialize();
    await _refreshFromDisk();

    _isLoading = false;
    notifyListeners();
  }

  /// Rescans the filesystem to detect external modifications, additions, and deletions.
  Future<void> rescan() async {
    await _refreshFromDisk();
    notifyListeners();
  }

  Future<void> _refreshFromDisk() async {
    final favorites = _prefs.getFavoritePaths();
    final archived = _prefs.getArchivedPaths();
    final loaded = await _storage.listNotes(favoritePaths: favorites);
    _allNotes = loaded
        .map((n) => n.copyWith(isArchived: archived.contains(n.relativePath)))
        .toList();
  }

  /// Sets active search query.
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  /// Selects or clears folder filter.
  void setSelectedFolder(String? folder) {
    _selectedFolder = folder;
    notifyListeners();
  }

  /// Toggles favorites-only view.
  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    if (_showOnlyFavorites) {
      _showOnlyArchived = false;
    }
    notifyListeners();
  }

  /// Toggles archived-only view.
  void toggleShowOnlyArchived() {
    _showOnlyArchived = !_showOnlyArchived;
    if (_showOnlyArchived) {
      _showOnlyFavorites = false;
      _selectedFolder = null;
    }
    notifyListeners();
  }

  /// Toggles favorite status for a given note.
  Future<void> toggleFavorite(String relativePath) async {
    final isFav = await _prefs.toggleFavorite(relativePath);

    final index = _allNotes.indexWhere((n) => n.relativePath == relativePath);
    if (index != -1) {
      _allNotes[index] = _allNotes[index].copyWith(isFavorite: isFav);
      notifyListeners();
    }
  }

  /// Toggles archive status for a given note.
  Future<void> toggleArchive(String relativePath) async {
    final isArch = await _prefs.toggleArchive(relativePath);

    final index = _allNotes.indexWhere((n) => n.relativePath == relativePath);
    if (index != -1) {
      _allNotes[index] = _allNotes[index].copyWith(isArchived: isArch);
      notifyListeners();
    }
  }

  /// Toggles home screen view layout (list <-> grid).
  Future<void> toggleViewMode() async {
    _viewMode = _viewMode == 'list' ? 'grid' : 'list';
    await _prefs.setViewMode(_viewMode);
    notifyListeners();
  }

  /// Updates app theme mode ('system', 'light', 'dark').
  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _prefs.setThemeMode(mode);
    notifyListeners();
  }

  /// Updates app locale ('ar', 'en', 'system').
  Future<void> setLocaleCode(String code) async {
    _localeCode = code;
    await _prefs.setAppLocale(code);
    notifyListeners();
  }

  /// Creates a new note on disk and appends it to the in-memory index.
  Future<NoteFile> createNote({
    String? folder,
    String? title,
    String initialContent = '',
  }) async {
    final note = await _storage.createNote(
      folder: folder,
      title: title,
      initialContent: initialContent,
    );
    await _refreshFromDisk();
    notifyListeners();
    return note;
  }

  /// Reads note content on demand from disk.
  Future<String> readNoteContent(String relativePath) async {
    return _storage.readNote(relativePath);
  }

  /// Checks if the file on disk was modified after [openedAtModifiedTime].
  Future<bool> isExternallyModified(
    String relativePath,
    DateTime openedAtModifiedTime,
  ) async {
    final currentDiskTime = await _storage.getModifiedTime(relativePath);
    if (currentDiskTime == null) return false;
    return currentDiskTime.isAfter(openedAtModifiedTime);
  }

  /// Gets current filesystem modified time for a file.
  Future<DateTime?> getFileModifiedTime(String relativePath) {
    return _storage.getModifiedTime(relativePath);
  }

  /// Saves content to disk, updating the in-memory note descriptor.
  Future<DateTime> saveNote(String relativePath, String content) async {
    await _storage.writeNote(relativePath, content);
    final newModifiedTime =
        await _storage.getModifiedTime(relativePath) ?? DateTime.now();

    await _refreshFromDisk();
    notifyListeners();

    return newModifiedTime;
  }

  /// Renames a note on disk and cleans up preferences.
  Future<void> renameNote(String oldPath, String newPath) async {
    await _storage.renameNote(oldPath, newPath);
    await _prefs.onNoteRenamed(oldPath, newPath);
    await _refreshFromDisk();
    notifyListeners();
  }

  /// Deletes a note from disk and cleans up preferences.
  Future<void> deleteNote(String relativePath) async {
    await _storage.deleteNote(relativePath);
    await _prefs.onNoteDeleted(relativePath);
    await _refreshFromDisk();
    notifyListeners();
  }
}
