# Phase 9: Encrypted Full-Archive Backup/Restore & Smart Natural Language Search

Milestone 3 (Release Candidate: v1.0.0-rc.1) begins with Phase 9. This phase delivers:
1. **Encrypted Full-Archive Backup & Atomic Restore Engine (`.mdbak`)**: Portable single-file archive bundling all SQLite table snapshots (`templates`, `notebooks`, `entries`, `media_attachments`) with SHA-256 integrity verification alongside physical sandboxed media (`media/*.webp`, `media/*.mp4`), supporting optional AES-256-GCM chunked encryption with PBKDF2 key derivation and fast key-check verification.
2. **Offline Natural Language Search Parser**: Pure Dart regex/semantic parser extracting temporal, holiday, weather, category, and media constraints from Chinese and English queries, mapping to `SearchFilters` with CJK substring (`LIKE`) fallback.
3. **Smart Event Suggestions & Association Chips**: Offline frequency & recency analyzer scanning non-deleted entries to aggregate and rank curated historical topics (e.g., 旅行, 考试, 生日, 工作, 复盘, 运动), rendering 1-tap interactive filter chips in `SearchScreen`.

100% Free Open-Source (MIT/BSD/Apache), $0 runtime cost, and zero network calls (`HttpOverrides` quarantined).

---

## Approved Architectural Decisions

| Area | Decision | Details & Rationale |
|---|---|---|
| **Archive Dependency** | `archive: ^4.0.7` | `pdf` 3.13 and `image` 4.5 lock `archive` at `4.0.7`. Pinning `^4.0.7` matches lockfile, avoids resolution failure, and is pure Dart MIT. |
| **Encryption Engine** | `pointycastle: ^3.9.1` | Pure Dart MIT implementation for **PBKDF2-HMAC-SHA256** and **AES-256-GCM** chunked encryption. Avoids rolling custom crypto over `crypto`. |
| **Chinese FTS Fallback** | `LIKE` + `FTS5` union | When residual query contains CJK characters (`\p{Script=Han}`), `searchEntriesWithFilters` supplements FTS5 with `plain_text LIKE '%kw%' OR title LIKE '%kw%'` to overcome SQLite's `unicode61` continuous CJK tokenization limitation without heavy native tokenizer dependencies. |
| **Restore Mode** | Replace Mode | Wipes current database and media records in favor of the archive contents inside a single atomic SQLite transaction and staging swap, preceded by an explicit destructive warning dialog. |
| **Unencrypted Backups** | Allowed with Warning | Encryption switch defaults to ON (with 8+ char passphrase validation). Toggling it OFF shows an explicit warning card regarding plaintext storage. |
| **Export Delivery** | Save & Share | Users can either save directly to device storage via `FilePicker.saveFile` or stream the `.mdbak` file via `share_plus` to avoid memory exhaustion on large archives. |
| **Holidays Scope** | Fixed Gregorian Only | Supports `元旦`, `情人节`, `五一/劳动节`, `国庆`, `圣诞` (and English equivalents `New Year`, `Valentine`, `Labor Day`, `National Day`, `Christmas`). Lunar calendar festivals remain out of scope for rc.1. |
| **Ambiguous Bare Month** | Most-Recent-Past | A standalone month query (e.g., `12月` or `December` executed in October 2026) resolves to the most recent past occurrence (`Dec 2025`). |
| **NL vs. Manual Filters** | Override + Removable Chips | Detected NL constraints override corresponding manual chips for the current query and display as removable `"Understood as"` `InputChip`s. Dismissing a chip removes the filter and retains the term as literal text. |

---

## Three Technical Watchpoints & Defenses

### Watchpoint 1: Prevent Duplicate `entries_fts` Rows on Restore
- **Risk**: SQLite triggers `entries_ai`, `entries_au`, and `entries_ad` installed in Phase 0 automatically insert/update/delete rows in `entries_fts` when the `entries` table is modified. If `replaceAllFromBackup` batch-inserts rows into `entries` (which fires `entries_ai`) and *then* executes `INSERT INTO entries_fts SELECT ...`, every entry is indexed twice in FTS5.
- **Defense**:
  1. During the restore transaction, execute `DELETE FROM entries_fts;` alongside table resets (`DELETE FROM media_attachments; DELETE FROM entries; ...`).
  2. Batch-insert rows into `entries`. Drift's standard table inserts fire the `entries_ai` trigger automatically, populating `entries_fts` on the fly.
  3. Omit manual `INSERT INTO entries_fts SELECT ...`. If any manual rebuild is desired for safety, always preface with `DELETE FROM entries_fts;`.

### Watchpoint 2: Configurable PBKDF2 Iterations for Unit Tests
- **Risk**: Pure-Dart PBKDF2-HMAC-SHA256 with 200,000 iterations takes ~0.5–1.5s per run. Running 15–20 tests would add 20+ seconds to `flutter test`.
- **Defense**:
  - `BackupCrypto.encryptFileChunked` and `BackupRestoreService.createBackup` accept an optional `int pbkdf2Iterations = 200000` parameter.
  - The iteration count is written as an unsigned 32-bit big-endian integer into byte offset `25..29` of the `.mdbak` header.
  - `BackupCrypto.decryptFileChunked` reads the exact iteration count from header offset `25..29`, so test files created with `pbkdf2Iterations: 1000` decrypt instantaneously without modifying decryption parameters.

### Watchpoint 3: `archive: ^4.0.7` API Compatibility
- **Risk**: `archive` 4.x modernized several classes and methods from 3.x (e.g. streaming encoders, `ZipFileEncoder`, `ArchiveFile`).
- **Defense**:
  - Backup bundling uses `ZipFileEncoder().zipDirectory(stagingDir, filename: tempZipPath)` or explicit `create(zipPath)` / `addFile(file)` / `close()`.
  - Unpacking uses `ZipDecoder().decodeBuffer(InputFileStream(zipPath))` or `ZipDecoder().decodeBytes(bytes)` ensuring compatibility with archive 4.x streams and avoiding in-memory decompression of large video payloads.

---

## Technical Specifications

### 1. `.mdbak` Binary Container Format

```text
Offset (Bytes)  Size (Bytes)  Field Name        Description
0..7            8             Magic Header      ASCII "MDBAK\0\0\1" (Format version 1)
8               1             Flags             Bit 0: IsEncrypted (0 = Plain ZIP, 1 = Encrypted)
                                                Bits 1..7: Reserved (0)
[If IsEncrypted == 1]:
9..24           16            PBKDF2 Salt       Cryptographically secure random salt
25..28          4             Iterations        Uint32 BE (Default: 200,000; Test: 1,000)
29..36          8             Nonce Prefix      Random 8-byte prefix for AES-GCM nonces
37..68          32            Key Check Value   HMAC-SHA256(macKey, "MDBAK-KCV") for instant password rejection
69..end         Variable      Payload Chunks    Series of 1 MiB ciphertext blocks:
                                                [4B Uint32 chunk_len] + [chunk_ciphertext] + [16B GCM tag]
                                                Nonce = NoncePrefix (8B) + ChunkCounter (4B BE)
                                                AAD = MagicHeader (8B) + Flags (1B) + IsFinalChunk (1B)
[If IsEncrypted == 0]:
9..end          Variable      Raw Payload       Standard ZIP archive bytes
```

### 2. Inner Archive Layout (`manifest.json` & Media)

```text
archive.zip
├── manifest.json              # Full SQLite tables JSON snapshot + metadata
├── manifest.sha256            # Hex digest of manifest.json
└── media/                     # Sandboxed photos and videos
    ├── 3fa85f64-...webp
    ├── 7b841a12-...mp4
    └── 7b841a12-..._thumb.webp
```

**`manifest.json` schema**:
```json
{
  "format": "memodiary-backup",
  "formatVersion": 1,
  "appSchemaVersion": 2,
  "createdAt": "2026-10-19T01:00:00.000Z",
  "counts": {
    "templates": 4,
    "notebooks": 1,
    "entries": 42,
    "mediaAttachments": 15
  },
  "tables": {
    "templates": [ ... ],
    "notebooks": [ ... ],
    "entries": [ ... ],
    "mediaAttachments": [ ... ]
  },
  "mediaFiles": [
    {
      "relativePath": "media/3fa85f64.webp",
      "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "sizeBytes": 204800
    }
  ]
}
```

---

## File Changes Breakdown

### Dependencies Layer
#### [MODIFY] `pubspec.yaml`
- Add `archive: ^4.0.7`
- Add `pointycastle: ^3.9.1`

---

### Core & Database Layer
#### [MODIFY] `lib/core/services/media_sandbox_service.dart`
- Expose `Future<Directory> getBaseDirectory()` to allow the backup service to locate and enumerate the `media/` sandboxed directory without duplicating path logic.

#### [MODIFY] `lib/core/database/app_database.dart`
- Add `Future<BackupDatabaseSnapshot> exportAllTablesSnapshot()`: retrieves all rows from `templates`, `notebooks`, `entries` (including deleted, locked, and time capsules), and `mediaAttachments`.
- Add `Future<void> replaceAllFromBackup(BackupDatabaseSnapshot snapshot)`:
  - Executes inside a Drift `transaction`.
  - Deletes existing records: `mediaAttachments`, `entries`, `notebooks`, custom `templates` (`isCustom = true`), and `entries_fts`.
  - Batch inserts snapshot records in foreign-key dependency order:
    1. Templates (custom & system)
    2. Notebooks
    3. Entries (Triggers `entries_ai` to populate `entries_fts`)
    4. MediaAttachments
- Update `searchEntriesWithFilters`:
  - When residual keyword contains Chinese characters (`RegExp(r'[\u4e00-\u9fa5]')`), complement FTS5 search with SQL `LIKE`:
    ```dart
    final escapedLike = '%${keyword.replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    // Union FTS matched IDs with (title LIKE escapedLike OR plainText LIKE escapedLike)
    ```

---

### Backup & Restore Feature Layer
#### [NEW] `lib/features/import_export/models/backup_manifest.dart`
- `BackupManifest`, `BackupMediaRecord`, `BackupDatabaseSnapshot`, `BackupInspection`, `BackupResult`, `RestoreResult`.
- Exception hierarchy: `BackupException`, `BackupFormatException`, `WrongPassphraseException`, `BackupCorruptedException`, `BackupVersionException`.

#### [NEW] `lib/features/import_export/services/backup_crypto.dart`
- Pure Dart crypto helper:
  - `deriveKeys(String passphrase, Uint8List salt, int iterations)` -> returns `(Uint8List encKey, Uint8List macKey)`.
  - `encryptFileChunked(...)` -> streams file through 1 MiB AES-256-GCM blocks, writes `.mdbak` container.
  - `decryptFileChunked(...)` -> parses `.mdbak` header, checks KCV via HMAC-SHA256, decrypts chunks with auth tag verification.
  - `inspectHeader(File source)` -> extracts format version, isEncrypted, iterations, salt.

#### [NEW] `lib/features/import_export/services/backup_restore_service.dart`
- `BackupRestoreService`:
  - `createBackup({required File destination, String? passphrase, int pbkdf2Iterations = 200000, void Function(double)? onProgress})`
  - `inspectBackup(File file)`
  - `restoreBackup({required File source, String? passphrase, void Function(double)? onProgress})`
  - Full atomic rollback guarantee: staging directory validation -> transaction commit -> media move.

#### [MODIFY] `lib/features/import_export/services/file_selector_service.dart`
- Add `pickBackupFile()` (filters `.mdbak`).
- Add `saveBackupFile({required String fileName, required File sourceFile})`.
- Update `NativeFileSelectorService` and `MockFileSelectorService` in test suites.

#### [NEW] `lib/features/import_export/widgets/backup_dialogs.dart`
- `CreateBackupBottomSheet`: passphrase input, strength indicator, plaintext warning toggle, save/share buttons, progress indicator.
- `RestoreBackupBottomSheet`: file picker trigger, passphrase challenge, destructive replace confirmation dialog, progress display.

#### [MODIFY] `lib/features/settings/screens/settings_screen.dart`
- Add `Backup & Restore` section card to Settings:
  - ListTile: `Create Encrypted Backup` (`Key('settings_create_backup_tile')`)
  - ListTile: `Restore from Backup` (`Key('settings_restore_backup_tile')`)
- Injectable `BackupRestoreService? backupService` parameter for clean widget testing.

---

### Search & Suggestions Layer
#### [NEW] `lib/features/search/services/natural_language_search_parser.dart`
- Extracts constraints:
  - Holidays: `去年国庆`, `今年国庆`, `国庆`, `元旦`, `情人节`, `五一/劳动节`, `圣诞`, `national day`, `christmas`, etc.
  - Relative dates: `上个月/last month`, `本月/this month`, `上周/last week`, `本周/this week`, `去年/last year`, `今年/this year`, `2025年`.
  - Specific months: `2025年10月`, `10月` (resolves to most recent past).
  - Category: `周记`, `所有周记`, `weekly review`.
  - Media: `带图`, `有图`, `带照片`, `with photos`.
  - Weather: `晴天`, `雨天`, `多云`, `雪天`, `大风`, `sunny`, `rainy`, `cloudy`, etc.
- Removes stop-phrases (`发生的事`, `的事情`, `what happened`, `entries`, etc.).
- Returns `ParsedSearchQuery` with `applyTo(SearchFilters)` method.

#### [NEW] `lib/features/search/services/event_suggestion_service.dart`
- Scans non-deleted entries (excluding sealed capsules and inspecting locked entries only by title).
- Curated vocabulary mapping + token frequency/recency scoring (`count * (1 + 0.5 * recencyBoost)`).
- Minimum frequency threshold >= 3 occurrences for dynamic title tokens.
- Runs inside background `Isolate.run`.

#### [NEW] `lib/features/search/widgets/event_suggestion_chips.dart`
- Horizontal scrolling chips displaying dynamic smart suggestions (e.g., `旅行 · 12`, `考试 · 4`).
- Tapping triggers search with selected keyword.

#### [MODIFY] `lib/features/search/screens/search_screen.dart`
- Wire `NaturalLanguageSearchParser` and `EventSuggestionService`.
- Display "Understood as" removable `InputChip` row for detected NL constraints.
- Display `EventSuggestionChips` when in initial or idle search state.

---

## Verification Plan

### Automated Unit & Integration Tests

1. **`test/features/import_export/backup_crypto_test.dart`**:
   - Chunked AES-256-GCM encryption/decryption round-trip (empty file, exact 1 MiB chunk, 2.5 MiB multi-chunk).
   - Fast wrong-passphrase rejection via KCV without decrypting chunks.
   - Tampered ciphertext byte fails GCM auth tag.
   - Truncated chunk stream detected via final chunk AAD flag.
   - PBKDF2 iteration parameter verification (runs with `pbkdf2Iterations: 1000` in <50ms).

2. **`test/features/import_export/backup_manifest_test.dart`**:
   - JSON serialization & deserialization of `BackupManifest` and all database companion tables.
   - SHA-256 integrity digest calculations.

3. **`test/features/import_export/backup_restore_service_test.dart`**:
   - **Full End-to-End Round-Trip**: Seed database (notebooks, custom templates, active/deleted/locked/capsule entries, image and video attachments). Backup to `.mdbak`. Wipe database and local media. Restore from `.mdbak`. Verify all table rows and physical files match bit-for-bit. Verify FTS5 search works immediately post-restore.
   - **Wrong Password Guard**: Restore fails with `WrongPassphraseException`; database and media directories remain untouched.
   - **Corrupted Archive Guard**: Tampered manifest SHA-256 or modified media file fails validation; atomic rollback leaves database completely unchanged and staging directory clean.
   - **Path Traversal / Zip-Slip Defense**: Archive containing `../evil.webp` is rejected.
   - **Unencrypted Archive Round-Trip**: Successful backup and restore when passphrase is null.

4. **`test/features/search/natural_language_search_parser_test.dart`**:
   - Benchmark date `now = DateTime(2026, 10, 19)`:
     - `去年国庆发生的事` -> Date range `2025-10-01` to `2025-10-07`, residual keyword empty.
     - `10月所有周记` -> Date range `2026-10-01` to `2026-10-31`, `weeklyReviewOnly = true`.
     - `12月` -> Resolves to most recent past `2025-12-01` to `2025-12-31`.
     - `上个月有图` -> September 2026, `hasImage = true`.
     - `晴天 去公园` -> `weather = 'sunny'`, keyword `'去公园'`.
     - `雪糕` -> Does not trigger weather filter, remains keyword `'雪糕'`.

5. **`test/features/search/event_suggestion_service_test.dart`**:
   - Aggregates synonyms (`Travel` and `旅行` merged).
   - Enforces >= 3 threshold for title tokens.
   - Excludes sealed capsules and scans locked entries only by title.

6. **`test/features/search/search_screen_nl_test.dart` (Widget Test)**:
   - Renders search screen, types `去年国庆发生的事`, verifies "Understood as" chip appears.
   - Tapping remove on chip reverts filter and searches raw text.
   - Displays smart event suggestion chips, tapping chip executes search.

7. **`test/features/settings/settings_screen_test.dart`**:
   - Verifies "Backup & Restore" section, opens create and restore dialogs.

8. **`test/hardening/network_quarantine_audit_test.dart`**:
   - Executes backup and restore operations under `QuarantinedHttpOverrides` to ensure zero network egress.

### Verification Execution Commands
```bash
flutter pub get
flutter analyze
flutter test test/features/import_export/backup_crypto_test.dart
flutter test test/features/import_export/backup_manifest_test.dart
flutter test test/features/import_export/backup_restore_service_test.dart
flutter test test/features/search/
flutter test test/features/settings/
flutter test test/hardening/
flutter test
```
