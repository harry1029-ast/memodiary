# Milestone 3 (v1.0.0-rc.1) — Phase 9 Task Checklist
**Phase 9: Encrypted Full-Archive Backup/Restore & Smart Natural Language Search**

- [x] **1. Dependencies & Network Quarantine Verification**
  - [x] Update `pubspec.yaml` to add `archive: ^4.0.7` and `pointycastle: ^3.9.1` (100% pure-Dart MIT FOSS, 0 network calls).
  - [x] Run `flutter pub get` and verify `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist` retain zero network permissions.

- [x] **2. Encrypted Full-Archive Backup & Restore Engine**
  - [x] Create [backup_manifest.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/models/backup_manifest.dart) (`BackupManifest`, `BackupMediaRecord`, `BackupDatabaseSnapshot`, `BackupInspection`, `BackupResult`, `RestoreResult`, and `BackupException` hierarchy).
  - [x] Create [backup_crypto.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/backup_crypto.dart) implementing `.mdbak` v1 binary header (`"MDBAK\0\0\1"`), PBKDF2-HMAC-SHA256 key derivation (`encKey` + `macKey`, configurable `pbkdf2Iterations` defaulting to 200,000 and read dynamically from header offset `25..29`), 32-byte `HMAC-SHA256` key check value (`MDBAK-KCV`), and 1 MiB chunked `AES-256-GCM` encryption/decryption with final-chunk truncation flag.
  - [x] Extend [media_sandbox_service.dart](file:///home/harry1029/projects/memodiary/lib/core/services/media_sandbox_service.dart) with `getBaseDirectory()` and path-traversal guard (`isStrictlyRelative`).
  - [x] Extend [app_database.dart](file:///home/harry1029/projects/memodiary/lib/core/database/app_database.dart) with `exportAllTablesSnapshot()` and atomic Replace-mode `replaceAllFromBackup(BackupDatabaseSnapshot snapshot)` (clearing `entries_fts` prior to insert so the `entries_ai` trigger indexes each entry once without duplicate FTS rows).
  - [x] Implement [backup_restore_service.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/backup_restore_service.dart) (`createBackup`, `inspectBackup`, `restoreBackup` inside background `Isolate` + atomic transaction + staging swap).
  - [x] Extend [file_selector_service.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/file_selector_service.dart) with `pickBackupFile()` and `saveBackupFile()`.
  - [x] Create [backup_dialogs.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/widgets/backup_dialogs.dart) (`CreateBackupDialog` with encryption switch default ON, unencrypted warning banner, and both **Save to Device** & **Share...** actions; `RestoreBackupDialog` with Replace mode confirmation).
  - [x] Wire **"Create Encrypted Backup"** and **"Restore from Backup"** into [settings_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/settings/screens/settings_screen.dart).

- [x] **3. Offline Natural Language Event Search Parser & CJK Substring Fallback**
  - [x] Create [natural_language_search_parser.dart](file:///home/harry1029/projects/memodiary/lib/features/search/services/natural_language_search_parser.dart) (`NaturalLanguageSearchParser`, `ParsedSearchQuery`, `DetectedConstraint`, `ConstraintKind`).
  - [x] Support Chinese & English temporal ranges (`去年`, `今年`, `上个月`/`last month`, `本月`/`this month`, `上周`/`last week`, `本周`/`this week`, `YYYY年M月`, bare `M月` resolved to most-recent-past occurrence).
  - [x] Support fixed Gregorian holidays (`去年国庆`, `今年国庆`, `元旦`, `情人节`, `五一`/`劳动节`, `圣诞`, plus English equivalents).
  - [x] Support category, media, and weather flags (`所有周记`/`周记`/`weekly review`, `带图`/`有图`/`with photos`, `晴天`/`雨天`/`多云`/`雪天`/`大风`/`大雾`).
  - [x] Update `AppDatabase.searchEntriesWithFilters` in [app_database.dart](file:///home/harry1029/projects/memodiary/lib/core/database/app_database.dart) to union FTS5 results with an escaped `LIKE` fallback whenever the residual keyword contains CJK characters (`\p{Script=Han}`).

- [x] **4. Event Suggestions & Smart Association Chips**
  - [x] Create [event_suggestion_service.dart](file:///home/harry1029/projects/memodiary/lib/features/search/services/event_suggestion_service.dart) scanning active, non-deleted, non-sealed entries (and inspecting locked entries by title only) for curated event vocabulary (`旅行`/`Travel`, `考试`/`Exam`, `生日`/`Birthday`, `工作`/`Work`, `复盘`/`Review`, `运动`/`Workout`, `阅读`/`Reading`, etc.) and recurring title tokens ($\ge 3$ entries).
  - [x] Create [event_suggestion_chips.dart](file:///home/harry1029/projects/memodiary/lib/features/search/widgets/event_suggestion_chips.dart) and integrate both removable `"Understood as"` `InputChip`s and 1-tap `"Smart Event Suggestions"` into [search_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/search/screens/search_screen.dart).

- [x] **5. Automated Verification & Regression Suite**
  - [x] Write unit tests in [backup_crypto_test.dart](file:///home/harry1029/projects/memodiary/test/features/import_export/backup_crypto_test.dart) and [backup_manifest_test.dart](file:///home/harry1029/projects/memodiary/test/features/import_export/backup_manifest_test.dart).
  - [x] Write integration & rollback tests in [backup_restore_service_test.dart](file:///home/harry1029/projects/memodiary/test/features/import_export/backup_restore_service_test.dart) (using `pbkdf2Iterations: 1000` for fast test execution).
  - [x] Write parser unit tests in [natural_language_search_parser_test.dart](file:///home/harry1029/projects/memodiary/test/features/search/natural_language_search_parser_test.dart).
  - [x] Write unit & widget tests in [event_suggestion_service_test.dart](file:///home/harry1029/projects/memodiary/test/features/search/event_suggestion_service_test.dart), [search_screen_nl_test.dart](file:///home/harry1029/projects/memodiary/test/features/search/search_screen_nl_test.dart), [settings_screen_test.dart](file:///home/harry1029/projects/memodiary/test/features/settings/settings_screen_test.dart), and [network_quarantine_audit_test.dart](file:///home/harry1029/projects/memodiary/test/hardening/network_quarantine_audit_test.dart).
  - [x] Run `flutter analyze` (0 warnings/errors) and full `flutter test` suite.
