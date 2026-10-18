# Phase 8: Retrospective Suite, Writing Sanctum, Local Reminders & Analytics — Task Checklist

- [x] **1. Dependencies & Android Manifest (`pubspec.yaml` & `AndroidManifest.xml`)**
  - [x] Add `audioplayers: ^6.1.0`, `flutter_local_notifications: ^18.0.1`, and `timezone: ^0.10.1` to `pubspec.yaml`
  - [x] Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` to `android/app/src/main/AndroidManifest.xml` while keeping `INTERNET` absent
  - [x] Run `flutter pub get` and verify 0 dependency or license conflicts

- [x] **2. Single-Entry PIN / Biometric Lock & Drift Schema v2 Migration**
  - [x] Add `isLocked` (`BoolColumn`, default `false`) and `entryPinHash` (`TextColumn`, nullable) to `Entries` table (`lib/core/database/tables/entries.dart`)
  - [x] Bump `schemaVersion` to `2` in `AppDatabase` (`lib/core/database/app_database.dart`) with `onUpgrade` adding `isLocked` and `entryPinHash`
  - [x] Run `dart run build_runner build` to regenerate `lib/core/database/app_database.g.dart`
  - [x] Add `lockEntry`, `unlockEntryPermanently`, `hashEntryPin`, and `verifyEntryPin` (`lib/core/services/auth_service.dart`)
  - [x] Update `EntrySummaryCard` to obscure locked entry snippets (`🔒 This entry is locked`) and hide media thumbnails
  - [x] Update `EntryDetailScreen` with PIN/biometric unlock barrier and AppBar lock/unlock toggle

- [x] **3. Retrospective Reflection Engine ("On This Day" & Serendipity Roulette)**
  - [x] Implement `getEntriesOnThisDay(DateTime date)` (including leap-year Feb 29 handling on Feb 28 of non-leap years) and `getRandomOldEntry({int minDaysAgo = 90})` in `AppDatabase`
  - [x] Build `OnThisDayBanner` (`lib/features/retrospection/widgets/on_this_day_banner.dart`)
  - [x] Build `SerendipityRouletteCard` (`lib/features/retrospection/widgets/serendipity_roulette_card.dart`)
  - [x] Integrate retrospective banner and Memory Roulette trigger into `TimelineScreen`

- [x] **4. Writing Analytics & 52-Week Contribution Heatmap (`lib/features/analytics/`)**
  - [x] Implement `AnalyticsService` (`lib/features/analytics/services/analytics_service.dart`) with hybrid Latin word & CJK character counting, current/longest streaks, mood distribution, and daily activity map
  - [x] Implement `YearlyContributionHeatmap` (`lib/features/analytics/widgets/yearly_contribution_heatmap.dart`) with 52×7 `HeatmapGridPainter`
  - [x] Implement `AnalyticsDashboardScreen` (`lib/features/analytics/screens/analytics_dashboard_screen.dart`) and connect navigation from `TimelineScreen` and `SettingsScreen`

- [x] **5. Immersive Writing Sanctum & Tactile Haptics (`lib/features/editor/`)**
  - [x] Implement `ProceduralAudioSynthesizer` and `AudioSanctumService` (`lib/features/editor/services/audio_sanctum_service.dart`) generating 4-second 22,050Hz 16-bit mono WAV loops with 50ms linear fade-in/out for Gentle Rain, Vintage Library, and Mechanical Study
  - [x] Implement `SoundscapeModal` (`lib/features/editor/widgets/soundscape_modal.dart`) and wire into `EditorToolbar` & `EntryEditorScreen`
  - [x] Add `HapticFeedback.lightImpact()` on template switching, Time Capsule locking, entry PIN locking, and entry saving

- [x] **6. Scheduled Offline Local Reminders (`lib/features/notifications/` & `lib/features/settings/`)**
  - [x] Implement `NotificationReminderService` (`lib/features/notifications/services/notification_reminder_service.dart`) calling `tz.initializeTimeZones()` and scheduling Daily Writing (`1001`) and Sunday Weekly Review (`1002`) local notifications
  - [x] Implement `NotificationSettingsCard` (`lib/features/settings/widgets/notification_settings_card.dart`) and embed into `SettingsScreen`

- [x] **7. Verification & Regression Suite**
  - [x] `test/core/database/single_entry_lock_test.dart` (fresh v2 creation, simulated v1 -> v2 `onUpgrade`, and locked UI barrier)
  - [x] `test/features/retrospection/on_this_day_test.dart` (month/day matching, Feb 29 leap year handling, Serendipity >= 90 days)
  - [x] `test/features/analytics/analytics_service_test.dart` & `test/features/analytics/yearly_heatmap_test.dart`
  - [x] `test/features/editor/audio_sanctum_test.dart` (4s 22,050Hz WAV header & 50ms zero-crossing crossfade verification)
  - [x] `test/features/notifications/notification_reminder_test.dart`
  - [x] Run `analyze_files` (0 errors, 0 warnings) and full `flutter test` suite (162/162 passing)
