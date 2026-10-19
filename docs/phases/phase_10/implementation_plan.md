# Phase 10 — Release Candidate Hardening, Disaster Recovery Audit & v1.0.0 Certification (Unified Synthesis)

## Goal Description
Conclude Milestone 3 (Release Candidate: `v1.0.0-rc.1`) and certify **MemoDiary (拾光日记) v1.0.0+1** for General Availability under a strict Feature Freeze. This unified plan synthesizes the best architectural decisions from both the Current Plan and the Gemini Argon High Plan:
1. **End-to-End Disaster Recovery Round-Trip Stress Test (`test/hardening/full_backup_restore_roundtrip_test.dart`)**: Comprehensive catastrophic recovery test seeding all 6 entry archetypes, custom templates, custom notebooks, WebP photos, and a **2.5 MiB multi-chunk MP4 video** with poster thumbnail. Evaluates both **Scenario A (in-place wipe)** and **Scenario B (fresh-device restore)** using fast `pbkdf2Iterations: 2000`, verifying 100% relational, cryptographic, FTS5, and byte-digest parity.
2. **Search & Settings UI Polish**:
   - Smooth `AnimatedSize` transitions and horizontal scrolling for Natural Language `"Understood as:"` filter chips in `SearchScreen`, with responsive icon collapse on narrow screens (<360px) and text-scale clamping to completely eliminate `RenderFlex` overflows and layout shifts.
   - Persistent `"Last successful backup"` timestamp tracking stored in `backup_meta.json` in the sandbox directory directly via `BackupRestoreService`, displayed in `SettingsScreen` without extra platform channels or dependencies.
3. **Bilingual App Branding & Release Metadata**:
   - Version bump in `pubspec.yaml` to `1.0.0+1`.
   - Native OS-level bilingual localization: Android `values/strings.xml` (`MemoDiary`) + `values-zh/strings.xml` (`拾光日记`) referenced via `@string/app_name`; iOS `CFBundleDisplayName` + `zh-Hans.lproj/InfoPlist.strings`.
   - Consolidated release metadata and zero-cloud network audit in `test/hardening/network_quarantine_audit_test.dart`.
4. **Final Quality Gates**: Zero analysis warnings (`flutter analyze`), 100% passing test regression suite (`flutter test`), and successful release build (`flutter build apk --release`).

---

## User Review Required

### Three Technical Watchpoints to Guard Against During Execution

> [!IMPORTANT]
> **Watchpoint 1: Key Synchronization in `SettingsScreen`**
> Ensure both `lib/features/settings/screens/settings_screen.dart` and `test/features/settings/settings_screen_test.dart` standardize on the exact same widget key:
> ```dart
> const Key('settings_last_backup_tile')
> ```
> This prevents widget test lookup mismatches and guarantees consistent automated UI verification.

> [!IMPORTANT]
> **Watchpoint 2: Deterministic 2.5 MiB MP4 Payload Generation**
> In `test/hardening/full_backup_restore_roundtrip_test.dart`, generate the 2.5 MiB video bytes deterministically starting with a standard 32-byte MP4 `ftyp` box header (`isom/iso2/avc1/mp41`):
> ```dart
> final ftypHeader = <int>[
>   0x00, 0x00, 0x00, 0x20, // 32-byte box length
>   0x66, 0x74, 0x79, 0x70, // 'ftyp'
>   0x69, 0x73, 0x6f, 0x6d, // major brand: 'isom'
>   0x00, 0x00, 0x02, 0x00, // minor version
>   0x69, 0x73, 0x6f, 0x6d, // compatible brand: 'isom'
>   0x69, 0x73, 0x6f, 0x32, // compatible brand: 'iso2'
>   0x61, 0x76, 0x63, 0x31, // compatible brand: 'avc1'
>   0x6d, 0x70, 0x34, 0x31, // compatible brand: 'mp41'
> ];
> ```
> Follow this immediately with pseudo-random fill bytes seeded by `Random(2026)` up to `2.5 * 1024 * 1024` bytes. This guarantees that file magic / MIME detection passes instantaneously while multi-chunk AES-256-GCM chunk boundaries (1 MiB chunks) are exercised bit-for-bit with 100% deterministic SHA-256 digests.

> [!WARNING]
> **Watchpoint 3: Release Build Environment (`flutter build apk --release`)**
> Building a release APK invokes native Gradle compilation, Java toolchains, and Android NDK tools. When executing this final quality gate step, the command will be run outside the sandbox (`BypassSandbox: true`) as required for full toolchain and filesystem access, while all code edits, analysis, and test suites run sandboxed.

---

## Proposed Changes

### Component 1: Backup Timestamp Persistence & Settings UI Polish

#### [MODIFY] [backup_restore_service.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/backup_restore_service.dart)
- Add metadata helper methods to `BackupRestoreService` resolving `backup_meta.json` in the parent directory of `_mediaSandbox.getBaseDirectory()`:
  ```dart
  Future<File> _getMetadataFile() async {
    final mediaDir = await _mediaSandbox.getBaseDirectory();
    return File(p.join(mediaDir.parent.path, 'backup_meta.json'));
  }

  Future<DateTime?> getLastBackupTimestamp() async {
    try {
      final file = await _getMetadataFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final raw = data['lastBackupAt'] as String?;
      return raw != null ? DateTime.tryParse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordLastBackupTimestamp(DateTime timestamp) async {
    try {
      final file = await _getMetadataFile();
      await file.writeAsString(
        jsonEncode({'lastBackupAt': timestamp.toUtc().toIso8601String()}),
        flush: true,
      );
    } catch (_) {}
  }
  ```
- In `createBackup(...)`, invoke `await _recordLastBackupTimestamp(result.createdAt);` right after the backup file is finalized.

#### [MODIFY] [settings_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/settings/screens/settings_screen.dart)
- Add `DateTime? _lastBackupAt;` state field.
- In `_loadAll()` / `initState()`, query `await _effectiveBackupService.getLastBackupTimestamp()` and store in `_lastBackupAt`.
- In `_buildDataPortabilityCard(theme)`, add the status tile using the synchronized key `const Key('settings_last_backup_tile')`:
  ```dart
  ListTile(
    key: const Key('settings_last_backup_tile'),
    leading: const Icon(Icons.history_edu_outlined, size: 20),
    title: const Text('Last Successful Backup'),
    subtitle: Text(
      _lastBackupAt != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(_lastBackupAt!.toLocal())
          : 'No backup created yet',
    ),
    dense: true,
  ),
  ```
- In `_handleCreateBackup()`, when `CreateBackupDialog.show` returns a non-null `result`, reload `_lastBackupAt` and call `setState` so the UI immediately reflects the new backup time.

#### [MODIFY] [settings_screen_test.dart](file:///home/harry1029/projects/memodiary/test/features/settings/settings_screen_test.dart)
- Assert that `find.byKey(const Key('settings_last_backup_tile'))` shows `'No backup created yet'` when no backup has occurred.
- Assert that after creating a backup, the tile updates to the formatted timestamp.

---

### Component 2: Search Screen Natural Language Chip Layout Polish

#### [MODIFY] [search_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/search/screens/search_screen.dart)
- Wrap `_buildUnderstoodAsBar` in `AnimatedSize(duration: Duration(milliseconds: 180), curve: Curves.easeOut, alignment: Alignment.topCenter)`.
- Use a single-line horizontal `SingleChildScrollView(scrollDirection: Axis.horizontal)`.
- Add responsive prefix with `LayoutBuilder`: on viewports `< 360px`, collapse the label to an `Icon(Icons.psychology_outlined)` with a `Tooltip('Understood as')`; on wider viewports, show both the icon and `'Understood as:'` text.
- Enforce `ConstrainedBox(constraints: BoxConstraints(maxWidth: 180), child: Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis))` on each chip label.
- Add `deleteIcon: const Icon(Icons.close, size: 16)` with `Semantics(label: 'Remove ${c.label} filter')`.
- Clamp text scaler: `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3)`.

#### [MODIFY] [search_screen_nl_test.dart](file:///home/harry1029/projects/memodiary/test/features/search/search_screen_nl_test.dart)
- Add a narrow-screen test (`tester.view.physicalSize = const Size(320, 568)`) with a multi-constraint natural language query (`'去年国庆 晴天 带图 所有周记'`), asserting:
  * Zero `RenderFlex` overflow errors.
  * `nl_understood_as_bar` renders smoothly.
  * Deleting a chip works as expected.

---

### Component 3: End-to-End Disaster Recovery Round-Trip Stress Test

#### [NEW] [full_backup_restore_roundtrip_test.dart](file:///home/harry1029/projects/memodiary/test/hardening/full_backup_restore_roundtrip_test.dart)
Stress test asserting 100% recovery parity across all production invariants:
- **Seed Invariants Simultaneously**:
  1. **Custom Template**: `id: 'template_custom_rc_grid'`, `name: 'RC Vintage Grid'`, `backgroundType: 'grid'`, `backgroundValue: '#FAF6F0'`, `fontFamily: 'Serif'`, `lineSpacing: 1.6`, `marginHorizontal: 24.0`, `isCustom: true`.
  2. **Custom Notebook**: `id: 'notebook_rc_2026'`, `title: '2026 拾光纪事'`, `defaultTemplateId: 'template_custom_rc_grid'`.
  3. **Entry 1 (Active Multimodal + NL Target)**: `entryDate: 2025-10-03` (`去年国庆`), `mood: 5`, `weather: 'sunny'`, `title: '京都秋日旅行'`, `plainText: '去年国庆在京都旅行，晴天拍了枫叶照片和短视频。'`, notebook: `notebook_rc_2026`, template: `template_custom_rc_grid`.
  4. **Entry 2 (Soft-Deleted Recycle Bin)**: `isDeleted: true`, `title: '已删除的草稿'`, `plainText: '回收站保留三十天测试内容'`.
  5. **Entry 3 (Single-Entry PIN-Locked)**: `isLocked: true`, `entryPinHash: AuthService().hashEntryPin('8426')`, `title: '加密私密日记'`, `plainText: '只有独立密码才能查看的正文'`.
  6. **Entry 4 (Sealed Time Capsule)**: `unlockAt: 2027-10-19`, `title: '给未来的信'`, `plainText: '时间胶囊未解锁绝对机密令牌'`.
  7. **Entry 5 (Weekly Review)**: `isWeeklyReview: true`, `weekNumber: 41`, `entryDate: 2026-10-11`, `title: '十月第二周复盘'`, `plainText: '本周工作与运动复盘总结'`.
  8. **Physical Media Files**:
     * `media/rc_photo_01.webp`: 200 KiB random bytes with RIFF/WEBP header (Entry 1).
     * `media/rc_video_01.mp4`: **2.5 MiB** deterministic payload starting with the 32-byte `ftyp` box header (`isom/iso2/avc1/mp41`) followed by `Random(2026)` fill bytes crossing 1 MiB AES-GCM chunk boundaries (Entry 1).
     * `media/rc_video_01_thumb.webp`: 10 KiB poster thumbnail payload.
- **Scenario A (In-Place Total Wipe & Restore)**:
  1. Capture SHA-256 of all media files and database snapshot.
  2. `createBackup(destination: mdbakFile, passphrase: 'ReleaseCandidatePassphrase2026!', pbkdf2Iterations: 2000)`.
  3. Purge all rows from `media_attachments`, `entries`, `entries_fts`, `notebooks`, `templates`, and delete all files in `media/`.
  4. Assert database and sandbox are completely empty.
  5. `restoreBackup(source: mdbakFile, passphrase: 'ReleaseCandidatePassphrase2026!')`.
  6. Assertions:
     * 100% relational field parity for all tables.
     * 100% byte-digest parity for `rc_photo_01.webp`, `rc_video_01.mp4`, and `rc_video_01_thumb.webp`.
     * Non-duplicate FTS5 rows (`SELECT count(*) FROM entries_fts` == `entries.length`).
     * Keyword search `'京都'` returns Entry 1.
     * CJK `LIKE` fallback `'旅行'` returns Entry 1.
     * NL query `'去年国庆 晴天 带图'` returns Entry 1.
     * NL query `'10月所有周记'` returns Entry 5.
     * Privacy invariant: searching `'绝对机密令牌'` (sealed capsule) or `'回收站保留'` (deleted) returns 0 results.
     * PIN authentication: `verifyEntryPin('8426')` is true; `verifyEntryPin('0000')` is false.
- **Scenario B (Fresh-Device Restore)**:
  * Close previous database, instantiate fresh `AppDatabase.memory()` (re-seeds default templates) and fresh empty sandbox directory.
  * Restore `mdbakFile`.
  * Verify all custom templates, notebooks, and entries cleanly replace default seeded records without duplicate row or foreign key conflict.
- **Scenario C (Wrong Passphrase Defense)**:
  * Attempt restore with `'WrongPassphrase!'`. Throws `WrongPassphraseException`, and database remains clean with zero partial writes.

---

### Component 4: Release Metadata & Manifest Audit

#### [MODIFY] [pubspec.yaml](file:///home/harry1029/projects/memodiary/pubspec.yaml)
- Bump version to `1.0.0+1`:
  ```yaml
  version: 1.0.0+1
  ```

#### [NEW] `android/app/src/main/res/values/strings.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">MemoDiary</string>
</resources>
```

#### [NEW] `android/app/src/main/res/values-zh/strings.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">拾光日记</string>
</resources>
```

#### [MODIFY] [android/app/src/main/AndroidManifest.xml](file:///home/harry1029/projects/memodiary/android/app/src/main/AndroidManifest.xml)
- Change `android:label="memodiary"` to `android:label="@string/app_name"`.

#### [MODIFY] [ios/Runner/Info.plist](file:///home/harry1029/projects/memodiary/ios/Runner/Info.plist)
- Update `CFBundleDisplayName` and `CFBundleName` to `MemoDiary`.
- Add `CFBundleLocalizations` with `en` and `zh-Hans`.

#### [NEW] `ios/Runner/zh-Hans.lproj/InfoPlist.strings`
```strings
"CFBundleDisplayName" = "拾光日记";
"CFBundleName" = "拾光日记";
```

#### [MODIFY] [test/hardening/network_quarantine_audit_test.dart](file:///home/harry1029/projects/memodiary/test/hardening/network_quarantine_audit_test.dart)
- Append test group `'v1.0.0 Release Metadata & Manifest Audit'`:
  * Asserts `pubspec.yaml` contains `version: 1.0.0+1`.
  * Asserts `android/app/src/main/AndroidManifest.xml` references `@string/app_name` and has zero `android.permission.INTERNET`.
  * Asserts `values/strings.xml` defines `MemoDiary` and `values-zh/strings.xml` defines `拾光日记`.
  * Asserts `ios/Runner/Info.plist` has `CFBundleDisplayName` set to `MemoDiary`, `CFBundleLocalizations` declared, and zero arbitrary network permissions.
  * If release merged manifest exists (`build/app/intermediates/merged_manifests/release/...`), asserts absence of `INTERNET`.

---

## Verification Plan

### Automated Tests
```bash
# 1. Dependency resolution and static analysis
flutter analyze

# 2. Disaster Recovery Stress Test (Scenario A, B, C with 2.5 MiB multi-chunk video)
flutter test test/hardening/full_backup_restore_roundtrip_test.dart

# 3. Settings & Search UI Polish Widget Tests
flutter test test/features/settings/settings_screen_test.dart
flutter test test/features/search/search_screen_nl_test.dart

# 4. Consolidated Release Metadata & Quarantine Audit
flutter test test/hardening/network_quarantine_audit_test.dart

# 5. Full Project Regression Suite Across All Phases
flutter test

# 6. Production Release APK Compilation Gate
flutter build apk --release
```

### Manual Verification
- Launch application or inspect generated `app-release.apk` with `aapt2`:
  * Confirm `versionName='1.0.0'`, `versionCode='1'`.
  * Confirm `application-label:'MemoDiary'` and `application-label-zh:'拾光日记'`.
  * Confirm absence of `android.permission.INTERNET`.
- In `SettingsScreen`, verify "Last Successful Backup" shows `'No backup created yet'` initially, and updates to the current timestamp after creating a backup.
- In `SearchScreen`, test typing a multi-filter query on a narrow device and verify smooth animation and zero overflow.
