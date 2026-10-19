# Phase 10 — RC Hardening, Disaster Recovery Audit & v1.0.0 Certification (Unified Synthesis)

> Completed all Phase 10 certification criteria, passed full regression test suite (211/211 tests), and completed all 4 TDD review refactoring slices.

- [x] **1. Backup Timestamp Persistence & Settings UI Polish**
  - [x] Add `_getMetadataFile()`, `getLastBackupTimestamp()`, and `_recordLastBackupTimestamp()` to `lib/features/import_export/services/backup_restore_service.dart`.
  - [x] Record timestamp automatically inside `createBackup()`.
  - [x] Add `_lastBackupAt` and status tile standardized on `const Key('settings_last_backup_tile')` in `lib/features/settings/screens/settings_screen.dart` (Watchpoint 1).
  - [x] Update `test/features/settings/settings_screen_test.dart` to assert timestamp display and immediate update using `const Key('settings_last_backup_tile')` (Watchpoint 1).

- [x] **2. Search Screen NL Chip Layout Polish**
  - [x] Update `lib/features/search/screens/search_screen.dart` with `AnimatedSize(180ms)`, horizontal `SingleChildScrollView`, responsive `< 360px` icon prefix toggle, text-scale clamp, and `ConstrainedBox(180)` on chip labels.
  - [x] Add 320px narrow-screen widget test in `test/features/search/search_screen_nl_test.dart` verifying zero `RenderFlex` overflows.

- [x] **3. End-to-End Disaster Recovery Round-Trip Stress Test**
  - [x] Create `test/hardening/full_backup_restore_roundtrip_test.dart` with deterministic seed of all 6 entry archetypes, custom template, custom notebook, WebP photo, and **2.5 MiB MP4 video** (starting with 32-byte `ftyp` box header `[0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6f, 0x6d, ...]` + `Random(2026)` fill crossing 1 MiB chunk boundaries) + poster thumbnail (Watchpoint 2).
  - [x] Implement Scenario A (in-place wipe & restore), Scenario B (fresh-device restore), and Scenario C (wrong passphrase rejection) with `pbkdf2Iterations: 2000`.
  - [x] Verify 100% field parity, 100% byte-digest parity, non-duplicate FTS5 rows, keyword/CJK/NL search, privacy exclusion, and single-entry PIN verification.

- [x] **4. Bilingual App Branding & Release Metadata Audit**
  - [x] Bump version in `pubspec.yaml` to `1.0.0+1`.
  - [x] Create `android/app/src/main/res/values/strings.xml` (`MemoDiary`) and `android/app/src/main/res/values-zh/strings.xml` (`拾光日记`).
  - [x] Update `android/app/src/main/AndroidManifest.xml` to reference `@string/app_name`.
  - [x] Update `ios/Runner/Info.plist` with `CFBundleDisplayName = "MemoDiary"`, `CFBundleName = "MemoDiary"`, and `CFBundleLocalizations`.
  - [x] Create `ios/Runner/zh-Hans.lproj/InfoPlist.strings` with `拾光日记`.
  - [x] Extend `test/hardening/network_quarantine_audit_test.dart` with `'v1.0.0 Release Metadata & Manifest Audit'`.

- [x] **5. Quality Gates & Release Verification**
  - [x] Run `flutter analyze` (enforce 0 errors, 0 warnings, 0 lints).
  - [x] Run full `flutter test` regression suite across all phases.
  - [x] Run `flutter build apk --release` (executed with `BypassSandbox: true` per Watchpoint 3) to certify production compilation and verify binary metadata/permissions via `aapt2`.
  - [x] Generate `walkthrough.md` for Phase 10 completion.

- [x] **6. Code Review & TDD Refactoring Slices**
  - [x] Slice 1: Settings UI dynamic update test verifying tile updates from `'No backup created yet'` to today's date upon completing backup creation.
  - [x] Slice 2: SearchScreen `MediaQuery.withClampedTextScaling` refactored outside `.map` and 320px narrow screen multi-chip delete interaction verified with `ensureVisible` and zero overflow.
  - [x] Slice 3: Scenario B fresh-device restore asserts custom notebook `notebook_rc_2026` title and default template parity, plus relational table count parity (`length == 2`).
  - [x] Slice 4: BackupRestoreService constructor accepts optional `baseDirProvider` seam defaulting to `mediaService.getBaseDirectory`, decoupling metadata persistence and tested via redirection unit test.
