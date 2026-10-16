# Walkthrough — Phase 0: Architecture, Encrypted Database & Sandbox Foundation

We have initialized and implemented **Phase 0** for MemoDiary (拾光日记), establishing the zero-backend local-first encrypted architecture, sandboxed media isolation pipeline, biometric/PIN app lock gate, and comprehensive test suite.

---

## What Was Completed

### 1. 100% Free FOSS Dependencies Verified
- Confirmed all dependencies in [`pubspec.yaml`](file:///home/harry1029/projects/memodiary/pubspec.yaml):
  - `drift` & `sqlcipher_flutter_libs` (AES-256 encrypted SQLite at rest)
  - `flutter_secure_storage` & `local_auth` (hardware Keystore/Keychain key management and biometric authentication)
  - `path_provider`, `path`, `uuid`, `flutter_image_compress` (sandboxed WebP media handling)
- Resolved experimental dot-shorthand syntax in [`lib/main.dart`](file:///home/harry1029/projects/memodiary/lib/main.dart) to ensure clean builds across standard Flutter channels.

---

### 2. Encrypted Drift Database (`lib/core/database/`)

Implemented the 5 core tables and FTS5 synchronization invariant specified in `GEMINI.md`:

1. **[`Templates`](file:///home/harry1029/projects/memodiary/lib/core/database/tables/templates.dart)**:
   - Visual styling attributes (`backgroundType`, `backgroundValue`, `fontFamily`, `lineSpacing`, `marginHorizontal`, `isCustom`).
   - Strictly decoupled from diary Delta content.
2. **[`Notebooks`](file:///home/harry1029/projects/memodiary/lib/core/database/tables/notebooks.dart)**:
   - Diary folders (`id`, `title`, `defaultTemplateId`, `createdAt`).
3. **[`Entries`](file:///home/harry1029/projects/memodiary/lib/core/database/tables/entries.dart)**:
   - Records (`id`, `notebookId`, `templateId`, `title`, `contentDelta`, `plainText`, `entryDate`, `mood`, `weather`, `isWeeklyReview`, `weekNumber`, `unlockAt`, `createdAt`, `updatedAt`, `isDeleted`).
4. **[`MediaAttachments`](file:///home/harry1029/projects/memodiary/lib/core/database/tables/media_attachments.dart)**:
   - Sandboxed media references (`id`, `entryId`, `mediaType`, `relativePath`, `thumbnailPath`, `ocrText`, `createdAt`).
5. **[`entries_fts` (SQLite FTS5) + Triggers](file:///home/harry1029/projects/memodiary/lib/core/database/app_database.dart)**:
   - Virtual full-text search table with automatic SQLite sync triggers:
     - `entries_ai`: Syncs newly inserted entries into `entries_fts`.
     - `entries_au`: Updates `entries_fts` on title or plain text changes.
     - `entries_ad`: Cleans up `entries_fts` on entry deletion.
   - Built-in `searchEntries(query)` method supporting FTS5 matching.
6. **Default Seed Data**:
   - Seeded the 4 default templates:
     - **Minimalist White** (`template_minimalist_white`, color `#FFFFFF`, spacing 1.5, margin 20.0)
     - **Lined Paper** (`template_lined_paper`, lined `#FDFBF7`, spacing 1.8, margin 24.0)
     - **Retro Kraft Scrapbook** (`template_retro_kraft`, paper_texture `#EFE6D5`, spacing 1.6, margin 20.0)
     - **Weekly Review** (`template_weekly_review`, grid `#F4F5F7`, spacing 1.5, margin 16.0)
   - Seeded default notebook `notebook_default` ("My Diary").
7. **[`DatabaseKeyManager`](file:///home/harry1029/projects/memodiary/lib/core/database/database_key_manager.dart)**:
   - Generates a 256-bit cryptographically secure random key (`Random.secure()`, 32 bytes hex encoded).
   - Persists securely in `flutter_secure_storage` (Android Keystore / iOS Keychain).
   - Unlocks SQLCipher database file via `PRAGMA key = '$key';`.
8. **Generated Drift Code**:
   - Executed `drift_dev` / `build_runner` to generate [`lib/core/database/app_database.g.dart`](file:///home/harry1029/projects/memodiary/lib/core/database/app_database.g.dart).

---

### 3. Media Sandbox Service (`lib/core/services/media_sandbox_service.dart`)

Implemented [`MediaSandboxService`](file:///home/harry1029/projects/memodiary/lib/core/services/media_sandbox_service.dart):
- **UUID Filenames**: Generates RFC 4122 v4 UUIDs for every imported or captured image.
- **WebP Compression**: Compresses to WebP at max 1600px dimension and 80% quality via `flutter_image_compress`.
- **Sandbox Isolation**: Never stores gallery paths; returns strictly relative paths (`media/{uuid}.webp`).
- **Path Resolution**: Provides `getFileFromRelativePath(relativePath)` to resolve sandboxed files.
- **Safe Deletion**: Deletes sandboxed media files on demand.
- **Strict Relative Validation**: Validates paths to ensure absolute host paths never leak into SQLite.

---

### 4. App Security & Lifecycle Lock Gate (`lib/features/auth/`)

1. **[`AuthService`](file:///home/harry1029/projects/memodiary/lib/core/services/auth_service.dart)**:
   - Salts and hashes PINs with SHA-256 before writing to `flutter_secure_storage`.
   - Native biometric authentication via `local_auth`.
2. **[`AppLockGate`](file:///home/harry1029/projects/memodiary/lib/features/auth/app_lock_gate.dart)**:
   - Top-level gate wrapping app content in [`lib/main.dart`](file:///home/harry1029/projects/memodiary/lib/main.dart).
   - Lifecycle observer intercepting cold start and app resume transitions (`WidgetsBindingObserver`).
   - Clean numeric PIN pad with dot indicators, invalid attempt error messaging, and biometric prompt button.

---

## Verification Results

### 1. Static Analysis
Ran static analysis across the entire project:
```bash
flutter analyze
```
**Result**:
```
Analyzing memodiary...
No issues found! (ran in 1.0s)
```

### 2. Automated Unit & Widget Tests
Executed all 19 tests across the test suite:
```bash
flutter test test/core/database/ test/core/services/ test/features/auth/ test/widget_test.dart
```

**Results (19/19 Passing)**:
- `test/core/database/database_key_manager_test.dart`:
  - `generates and persists 256-bit hex encryption key` (PASSED)
  - `clearKey deletes the stored key` (PASSED)
- `test/core/database/app_database_test.dart`:
  - `seeds 4 default templates on creation` (PASSED)
  - `seeds default notebook on creation` (PASSED)
  - `supports entries and media attachments CRUD` (PASSED)
  - `FTS5 automatically indexes inserted entries via triggers` (PASSED)
  - `soft deleted entries are excluded from search results` (PASSED)
- `test/core/services/media_sandbox_service_test.dart`:
  - `copyAndCompressImage generates relative path with media/{uuid}.webp format` (PASSED)
  - `isStrictlyRelative rejects absolute paths` (PASSED)
  - `deleteMedia removes sandboxed file from disk` (PASSED)
  - `copyAndCompressImage throws exception if source does not exist` (PASSED)
- `test/core/services/auth_service_test.dart`:
  - `isLockEnabled returns false initially` (PASSED)
  - `setting and verifying PIN with cryptographic hash` (PASSED)
  - `removePin clears all security credentials` (PASSED)
  - `biometric authentication flow` (PASSED)
- `test/features/auth/app_lock_gate_test.dart`:
  - `renders child immediately when lock is disabled` (PASSED)
  - `displays lock screen when lock is enabled, unlocks with correct PIN` (PASSED)
  - `re-locks on app resume lifecycle transition` (PASSED)
- `test/widget_test.dart`:
  - `Counter increments smoke test` (PASSED)

```
00:01 +19: All tests passed!
```
