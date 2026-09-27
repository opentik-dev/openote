import 'package:shared_preferences/shared_preferences.dart';

/// Manages user preferences including favorites, theme, language,
/// view mode, and archived notes using relative paths for storage portability.
class PreferencesService {
  static const String _keyFavorites = 'favorite_note_relative_paths';
  static const String _keyArchived = 'archived_note_relative_paths';
  static const String _keyThemeMode = 'app_theme_mode'; // 'system' | 'light' | 'dark'
  static const String _keyLocale = 'app_locale_code'; // 'ar' | 'en' | 'system'
  static const String _keyViewMode = 'home_view_mode'; // 'list' | 'grid'

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// Factory initializer to obtain SharedPreferences instance.
  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // --- Favorites Management ---

  /// Returns the set of relative paths of notes marked as favorites.
  Set<String> getFavoritePaths() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.toSet();
  }

  /// Checks if a note at [relativePath] is currently marked as favorite.
  bool isFavorite(String relativePath) {
    return getFavoritePaths().contains(relativePath);
  }

  /// Toggles favorite status for a given [relativePath].
  Future<bool> toggleFavorite(String relativePath) async {
    final favorites = getFavoritePaths();
    final bool willBeFavorite;
    if (favorites.contains(relativePath)) {
      favorites.remove(relativePath);
      willBeFavorite = false;
    } else {
      favorites.add(relativePath);
      willBeFavorite = true;
    }
    await _prefs.setStringList(_keyFavorites, favorites.toList());
    return willBeFavorite;
  }

  // --- Archive Management ---

  /// Returns the set of relative paths of notes marked as archived.
  Set<String> getArchivedPaths() {
    final list = _prefs.getStringList(_keyArchived) ?? [];
    return list.toSet();
  }

  /// Checks if a note at [relativePath] is archived.
  bool isArchived(String relativePath) {
    return getArchivedPaths().contains(relativePath);
  }

  /// Toggles archive status for a given [relativePath].
  Future<bool> toggleArchive(String relativePath) async {
    final archived = getArchivedPaths();
    final bool willBeArchived;
    if (archived.contains(relativePath)) {
      archived.remove(relativePath);
      willBeArchived = false;
    } else {
      archived.add(relativePath);
      willBeArchived = true;
    }
    await _prefs.setStringList(_keyArchived, archived.toList());
    return willBeArchived;
  }

  // --- File Lifecycle Synchronization ---

  /// Updates favorite and archived paths when a note is renamed, preventing orphaned entries.
  Future<void> onNoteRenamed(String oldPath, String newPath) async {
    final favorites = getFavoritePaths();
    if (favorites.contains(oldPath)) {
      favorites.remove(oldPath);
      favorites.add(newPath);
      await _prefs.setStringList(_keyFavorites, favorites.toList());
    }

    final archived = getArchivedPaths();
    if (archived.contains(oldPath)) {
      archived.remove(oldPath);
      archived.add(newPath);
      await _prefs.setStringList(_keyArchived, archived.toList());
    }
  }

  /// Removes a deleted note from favorites and archive lists.
  Future<void> onNoteDeleted(String relativePath) async {
    final favorites = getFavoritePaths();
    if (favorites.contains(relativePath)) {
      favorites.remove(relativePath);
      await _prefs.setStringList(_keyFavorites, favorites.toList());
    }

    final archived = getArchivedPaths();
    if (archived.contains(relativePath)) {
      archived.remove(relativePath);
      await _prefs.setStringList(_keyArchived, archived.toList());
    }
  }

  // --- Theme Mode ---

  /// Returns current theme mode: 'system', 'light', or 'dark'.
  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  /// Sets the app theme mode.
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  // --- Language / Locale ---

  /// Returns current locale code: 'ar', 'en', or 'system'.
  String getAppLocale() {
    return _prefs.getString(_keyLocale) ?? 'ar';
  }

  /// Sets the app locale code.
  Future<void> setAppLocale(String localeCode) async {
    await _prefs.setString(_keyLocale, localeCode);
  }

  // --- View Mode ---

  /// Returns home screen layout mode: 'list' or 'grid'.
  String getViewMode() {
    return _prefs.getString(_keyViewMode) ?? 'list';
  }

  /// Sets home screen layout mode: 'list' or 'grid'.
  Future<void> setViewMode(String mode) async {
    await _prefs.setString(_keyViewMode, mode);
  }
}
