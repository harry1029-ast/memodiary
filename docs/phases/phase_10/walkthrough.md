# Phase 10: Release Candidate Hardening, Disaster Recovery Audit & v1.0.0 Certification

MemoDiary (拾光日记) has officially achieved **Milestone 3 (Release Candidate: v1.0.0-rc.1)** certification, culminating the complete 11-phase development roadmap.

---

## 1. Executive Summary & Verification Highlights

| Verification Dimension | Standard / Invariant | Status | Evidence / Outcome |
| :--- | :--- | :---: | :--- |
| **Disaster Recovery Round-Trip** | 100% field & byte parity with 2.5 MiB media payload | **PASSED** | [full_backup_restore_roundtrip_test.dart](file:///home/harry1029/projects/memodiary/test/hardening/full_backup_restore_roundtrip_test.dart) (Scenarios A, B, C) |
| **Media Chunk Integrity** | Deterministic MP4 `ftyp` box header crossing 1 MiB chunk boundaries | **PASSED** | 32-byte header `[0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, ...]` + SHA-256 matching 100% |
| **Search UI Responsiveness** | Zero `RenderFlex` overflow on narrow viewports (320px) | **PASSED** | [search_screen_nl_test.dart](file:///home/harry1029/projects/memodiary/test/features/search/search_screen_nl_test.dart) (`< 360px` icon tooltip toggle, text-scale clamp) |
| **Last Backup Timestamp** | Persistence across app documents and immediate Settings UI refresh | **PASSED** | [settings_screen_test.dart](file:///home/harry1029/projects/memodiary/test/features/settings/settings_screen_test.dart) (`const Key('settings_last_backup_tile')`) |
| **Bilingual Branding** | English `MemoDiary` & Simplified Chinese `拾光日记` | **PASSED** | Android `values/` + `values-zh/`; iOS `Info.plist` + `zh-Hans.lproj/InfoPlist.strings` |
| **Zero-Cloud Quarantine** | Absence of `android.permission.INTERNET` in release build | **PASSED** | Certified in source and merged release manifests via `aapt2 dump badging` |
| **Static Code Quality** | Enforce 0 errors, 0 warnings, 0 lints | **PASSED** | `flutter analyze` completed with 0 issues |
| **Full Regression Suite** | Unit, widget, and hardening suite across all 11 phases | **PASSED** | **209 / 209 tests passed** |
| **Production Build** | Release compilation (`flutter build apk --release`) | **PASSED** | `build/app/outputs/flutter-apk/app-release.apk` (86.7 MB, `versionName='1.0.0'`) |

---

## 2. Disaster Recovery Stress Test (`full_backup_restore_roundtrip_test.dart`)

The hardening test asserts full relational and physical recovery across all 6 entry archetypes and multimodal attachments:

```
[Seeded Database & Sandbox]
  ├── Custom Template: 'template_custom_rc_grid' (RC Vintage Grid)
  ├── Custom Notebook: 'notebook_rc_2026' (2026 拾光纪事)
  ├── Entry 1: Active Multimodal ('京都秋日旅行', 2025-10-03, sunny, mood 5)
  ├── Entry 2: Recycle Bin Soft-Deleted ('已删除的草稿', isDeleted=true)
  ├── Entry 3: Single-Entry PIN-Locked ('加密私密日记', SHA-256 salt+hash)
  ├── Entry 4: Sealed Time Capsule ('给未来的信', unlockAt=2027-10-19)
  ├── Entry 5: Weekly Review ('十月第二周复盘', week 41, isWeeklyReview=true)
  ├── Entry 6: CJK Substring Event Target ('京都咖啡小馆')
  └── Physical Media:
        ├── 'rc_photo_01.webp' (200 KiB, RIFF/WEBP header)
        ├── 'rc_video_01.mp4' (2.5 MiB, 32-byte MP4 ftyp box + Random(2026))
        └── 'rc_video_01_thumb.webp' (10 KiB poster thumbnail)

[Catastrophic Wipe Simulation]
  ├── DELETE FROM media_attachments, entries, notebooks, templates
  ├── DELETE FROM entries_fts
  └── rm -rf media/*

[Atomic Restore with PBKDF2 + AES-256-GCM]
  ├── 100% Relational Parity: 6 entries, 5 templates, 2 notebooks, 2 attachments
  ├── 100% Physical Parity: SHA-256 digests identical for photo, video, and thumbnail
  ├── FTS5 Deduplication: Exactly 6 rows in entries_fts (zero trigger duplicates)
  ├── Keyword & NL Search:
  │     ├── '京都' -> matches Entry 1 & Entry 6
  │     ├── '旅行' (CJK LIKE fallback) -> matches Entry 1
  │     ├── '去年国庆 晴天 带图' (NL multi-constraint) -> matches Entry 1
  │     └── '10月所有周记' -> matches Entry 5
  ├── Privacy Invariant: '绝对机密令牌' (sealed) & '回收站保留' (deleted) return 0 results
  └── PIN Verification: '8426' verifies successfully; '0000' rejected
```

In addition to **Scenario A** (In-Place Total Wipe), the suite validates:
- **Scenario B (Fresh-Device Restore)**: Restoring onto a fresh database with default schema pre-seeding cleanly replaces defaults without primary key or foreign key constraint collisions.
- **Scenario C (Wrong Passphrase Defense)**: Supplying an incorrect passphrase throws `WrongPassphraseException` via HMAC KCV verification, leaving existing database rows and media files completely untouched.

---

## 3. UI Polish & Timestamp Persistence

### Backup Timestamp Persistence
- [backup_restore_service.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/backup_restore_service.dart): Persists backup metadata to `backup_meta.json` at the app root documents directory (safely preserved across sandbox swaps).
- [settings_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/settings/screens/settings_screen.dart):
  * Standardized tile with key `const Key('settings_last_backup_tile')`.
  * Displays `'No backup created yet'` or formatted date `'yyyy-MM-dd HH:mm'`.
  * Immediately reloads and refreshes state upon creating a backup.

### Narrow-Screen Search NL Layout
- [search_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/search/screens/search_screen.dart):
  * Responsive prefix: On viewports `< 360px`, collapses `'Understood as:'` into `Icons.psychology_outlined` with tooltip; displays full text on wider screens.
  * Single-line horizontal scrolling (`SingleChildScrollView(scrollDirection: Axis.horizontal)`).
  * Label truncation: `ConstrainedBox(maxWidth: 180)` with `TextOverflow.ellipsis`.
  * Text scale clamping: `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3)`.
  * Semantics: `Semantics(label: 'Remove ${c.label} filter')` on delete actions.
- [event_suggestion_chips.dart](file:///home/harry1029/projects/memodiary/lib/features/search/widgets/event_suggestion_chips.dart): Title wrapped in `Expanded` with single-line ellipsis to prevent overflow on 320px screens.

---

## 4. Release Metadata & Manifest Audit

### Version & Branding
- [pubspec.yaml](file:///home/harry1029/projects/memodiary/pubspec.yaml): Bumped to `version: 1.0.0+1`.
- **Android Localization**:
  * [values/strings.xml](file:///home/harry1029/projects/memodiary/android/app/src/main/res/values/strings.xml): `<string name="app_name">MemoDiary</string>`
  * [values-zh/strings.xml](file:///home/harry1029/projects/memodiary/android/app/src/main/res/values-zh/strings.xml): `<string name="app_name">拾光日记</string>`
  * [AndroidManifest.xml](file:///home/harry1029/projects/memodiary/android/app/src/main/AndroidManifest.xml): `android:label="@string/app_name"`
- **iOS Localization**:
  * [Info.plist](file:///home/harry1029/projects/memodiary/ios/Runner/Info.plist): `CFBundleDisplayName = "MemoDiary"`, `CFBundleName = "MemoDiary"`, `CFBundleLocalizations = ["en", "zh-Hans"]`
  * [InfoPlist.strings](file:///home/harry1029/projects/memodiary/ios/Runner/zh-Hans.lproj/InfoPlist.strings): `"CFBundleDisplayName" = "拾光日记";`, `"CFBundleName" = "拾光日记";`

### Manifest & Binary Audit (`aapt2`)
Inspection of the compiled production APK (`build/app/outputs/flutter-apk/app-release.apk`):
```text
package: name='com.memodiary.memodiary' versionCode='1' versionName='1.0.0'
application-label:'MemoDiary'
application-label-zh:'拾光日记'
application-label-zh-CN:'拾光日记'
uses-permission: name='android.permission.RECORD_AUDIO'
uses-permission: name='android.permission.CAMERA'
uses-permission: name='android.permission.READ_EXTERNAL_STORAGE' maxSdkVersion='32'
uses-permission: name='android.permission.READ_MEDIA_IMAGES'
uses-permission: name='android.permission.POST_NOTIFICATIONS'
uses-permission: name='android.permission.VIBRATE'
uses-permission: name='android.permission.USE_BIOMETRIC'
uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
uses-permission: name='android.permission.WAKE_LOCK'
uses-permission: name='android.permission.USE_FINGERPRINT'
Zero android.permission.INTERNET
```

---

## 5. Verification Commands & Outputs

```bash
# 1. Static Analysis (0 errors, 0 warnings, 0 lints)
$ flutter analyze
Analyzing memodiary...
No issues found! (ran in 2.8s)

# 2. Complete Test Suite (209/209 passed)
$ flutter test
00:21 +209: All tests passed!

# 3. Production Release APK Compilation
$ flutter build apk --release
Running Gradle task 'assembleRelease'...                          152.9s
✓ Built build/app/outputs/flutter-apk/app-release.apk (86.7MB)

# 4. Release Permission Quarantine Assertion
$ grep -i "android.permission.INTERNET" build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml || echo "NO_INTERNET_FOUND"
NO_INTERNET_FOUND
```

MemoDiary v1.0.0-rc.1 is fully hardened, offline-quarantined, and ready for release.
