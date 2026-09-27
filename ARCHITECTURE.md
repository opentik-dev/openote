# MarkNote Architecture & Principles

> **The filesystem Markdown file is authoritative. All application state is derived from or auxiliary to the Markdown files. No cache, index, database, synchronization layer, or UI state may become an alternative source of truth.**

---

## 1. Core Principles

1. **Pure Markdown Files (`*.md`) as Single Source of Truth (SSOT)**
   Every note is a physical `.md` file stored within the filesystem hierarchy. The contents of notes are NEVER stored in a secondary database or closed binary storage (e.g. Hive, Isar, ObjectBox, SQLite).

2. **In-Memory Index Derived on the Fly**
   The application state maintains an in-memory index (`List<NoteFile>`) that is populated by scanning the filesystem on startup, on return to foreground (`resumed` lifecycle), and on pull-to-refresh.

3. **Preferences for Auxiliary State Only**
   Only metadata that cannot naturally reside within standard Markdown files—specifically `favoritePaths`—is stored in lightweight preferences (`SharedPreferences`). Favorite paths are stored strictly as **relative paths** (`Projects/Note.md`), ensuring portability across storage directories.
   When notes are renamed or deleted, the favorite set is pruned or updated to prevent orphaned paths.

4. **Strict H1 Heading Extraction**
   Note titles are derived without mutating the file:
   - A line is treated as an H1 heading only if it matches: `^#\s+(.+?)\s*$` (matching `# ` with whitespace).
   - If no H1 heading is present in the document's leading non-empty lines, the title defaults to the file name without the `.md` extension.
   - The file is never rewritten or prepended with an artificial `# ` just to give it a title.

5. **External Modification Awareness (No Silent Overwrite)**
   When a note is open in the editor, its opening timestamp and hash are tracked. If an external editor (such as Obsidian, Syncthing, or a desktop editor) modifies the file while it is open:
   - The app detects the change during autosave or upon resumption.
   - Autosave is withheld to protect the external work.
   - A conflict resolution prompt gives the user an explicit choice:
     - **Reload from disk** (discard uncommitted editor changes and load latest external version).
     - **Keep my edit** (explicitly save the current editor buffer to disk or save under a new name).

---

## 2. Layered Architecture

```text
lib/
├── main.dart
│
├── models/
│   └── note_file.dart             # Pure File Descriptor (relativePath, fileName, title, modifiedAt, previewSnippet)
│
├── services/
│   ├── file_storage_service.dart   # Abstract contract for file operations
│   ├── app_private_storage.dart    # V1 implementation using App Documents Directory
│   ├── markdown_service.dart       # Title resolution, snippet extraction, formatting helpers
│   └── preferences_service.dart    # Manages relative favorite paths
│
├── state/
│   └── notes_state_notifier.dart   # In-memory index, search filter, external change rescan
│
├── screens/
│   ├── notes_home_screen.dart      # Note list, tabs (All / Favorites / Folders), search
│   └── note_editor_screen.dart     # Auto-saving editor, Edit/Preview toggle, conflict prompt
│
├── widgets/
│   ├── note_list_tile.dart         # List item with snippet, date, and actions
│   ├── markdown_toolbar.dart       # Horizontal keyboard accessory with inline & block code
│   ├── markdown_preview.dart       # Verified Markdown renderer (GFM tables, checklists, code)
│   └── notes_search_bar.dart       # Fast real-time in-memory filter
│
└── utils/
    ├── markdown_utils.dart         # Cursor text manipulation and markdown tag wrappers
    └── file_name_utils.dart        # Safe filename sanitization and path operations
```

---

## 3. Storage Abstraction Roadmap

- **V1 (Current):** `AppPrivateStorage` implements `FileStorageService` using standard application sandbox storage (`<AppDocs>/Notes/`).
- **V2:** `SafFolderStorage` implements `FileStorageService` using Android Storage Access Framework (SAF), allowing the user to select an existing folder on their device shared with Syncthing, Nextcloud, or SD card.
- **V3:** A separate `SyncProvider` engine (WebDAV, Nextcloud) with explicit 3-way conflict resolution (`Note (conflict YYYY-MM-DD HH-mm).md`), operating on the storage layer without altering the editor or UI.
