import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user preferences including favorites, theme, language,
/// view mode, archived notes, color coding, and PIN security locks.
class PreferencesService {
  static const String _keyFavorites = 'favorite_note_relative_paths';
  static const String _keyArchived = 'archived_note_relative_paths';
  static const String _keyLockedNotes = 'locked_note_relative_paths';
  static const String _keyNoteColors = 'note_colors_map';
  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyAppPin = 'app_security_pin';
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

  // --- Note Colors Management ---

  /// Returns map of note colors (relativePath -> hex string).
  Map<String, String> getNoteColors() {
    final raw = _prefs.getString(_keyNoteColors);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Gets color hex string for [relativePath] or null if default.
  String? getNoteColor(String relativePath) {
    return getNoteColors()[relativePath];
  }

  /// Sets or clears color hex string for [relativePath].
  Future<void> setNoteColor(String relativePath, String? colorHex) async {
    final colors = getNoteColors();
    if (colorHex == null || colorHex.isEmpty) {
      colors.remove(relativePath);
    } else {
      colors[relativePath] = colorHex;
    }
    await _prefs.setString(_keyNoteColors, json.encode(colors));
  }

  // --- Security & PIN Lock ---

  /// Whether app lock is enabled.
  bool isAppLockEnabled() {
    return _prefs.getBool(_keyAppLockEnabled) ?? false;
  }

  /// Enables or disables app lock.
  Future<void> setAppLockEnabled(bool enabled) async {
    await _prefs.setBool(_keyAppLockEnabled, enabled);
  }

  /// Returns stored app PIN or null.
  String? getAppPin() {
    return _prefs.getString(_keyAppPin);
  }

  /// Saves new app PIN.
  Future<void> setAppPin(String pin) async {
    await _prefs.setString(_keyAppPin, pin);
  }

  /// Verifies entered PIN against stored PIN.
  bool verifyPin(String enteredPin) {
    final stored = getAppPin();
    if (stored == null) return false;
    return stored == enteredPin;
  }

  /// Returns set of relative paths of locked notes.
  Set<String> getLockedNotePaths() {
    final list = _prefs.getStringList(_keyLockedNotes) ?? [];
    return list.toSet();
  }

  /// Checks if [relativePath] is locked.
  bool isNoteLocked(String relativePath) {
    return getLockedNotePaths().contains(relativePath);
  }

  /// Toggles note lock status for [relativePath].
  Future<bool> toggleNoteLock(String relativePath) async {
    final locked = getLockedNotePaths();
    final bool willBeLocked;
    if (locked.contains(relativePath)) {
      locked.remove(relativePath);
      willBeLocked = false;
    } else {
      locked.add(relativePath);
      willBeLocked = true;
    }
    await _prefs.setStringList(_keyLockedNotes, locked.toList());
    return willBeLocked;
  }

  // --- File Lifecycle Synchronization ---

  /// Updates all preferences when a note is renamed, preventing orphaned entries.
  Future<void> onNoteRenamed(String oldPath, String newPath) async {
    // 1. Favorites
    final favorites = getFavoritePaths();
    if (favorites.contains(oldPath)) {
      favorites.remove(oldPath);
      favorites.add(newPath);
      await _prefs.setStringList(_keyFavorites, favorites.toList());
    }

    // 2. Archived
    final archived = getArchivedPaths();
    if (archived.contains(oldPath)) {
      archived.remove(oldPath);
      archived.add(newPath);
      await _prefs.setStringList(_keyArchived, archived.toList());
    }

    // 3. Locked
    final locked = getLockedNotePaths();
    if (locked.contains(oldPath)) {
      locked.remove(oldPath);
      locked.add(newPath);
      await _prefs.setStringList(_keyLockedNotes, locked.toList());
    }

    // 4. Color
    final colors = getNoteColors();
    if (colors.containsKey(oldPath)) {
      final color = colors.remove(oldPath)!;
      colors[newPath] = color;
      await _prefs.setString(_keyNoteColors, json.encode(colors));
    }
  }

  /// Removes a deleted note from all preference registries.
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

    final locked = getLockedNotePaths();
    if (locked.contains(relativePath)) {
      locked.remove(relativePath);
      await _prefs.setStringList(_keyLockedNotes, locked.toList());
    }

    final colors = getNoteColors();
    if (colors.containsKey(relativePath)) {
      colors.remove(relativePath);
      await _prefs.setString(_keyNoteColors, json.encode(colors));
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
