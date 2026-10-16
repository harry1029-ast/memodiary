# Walkthrough — Phase 2: High-Speed Timeline, CRUD & Offline FTS5 Search

We have completed the implementation and automated verification of **Phase 2** for MemoDiary (拾光日记), delivering the reverse-chronological timeline feed, template-accurate read-only detail reader, complete soft/hard delete lifecycle with 30-day auto-purge and physical disk cleanup, and offline FTS5 full-text multi-condition search.

---

## What Was Completed

### 1. Dependencies Added
- [`pubspec.yaml`](file:///home/harry1029/projects/memodiary/pubspec.yaml):
  - `share_plus: ^12.0.2` (BSD-3-Clause, cross-platform entry sharing)

---

### 2. High-Speed Reverse-Chronological Timeline (`lib/features/timeline/`)
- **[`TimelineEntryItem`](file:///home/harry1029/projects/memodiary/lib/features/timeline/models/timeline_entry_item.dart)**:
  - Model linking `Entry`, `Template`, and primary thumbnail `MediaAttachment?`.
  - Helpers: `isSealedTimeCapsule`, `timeUntilUnlock`, and `remainingUnlockTimeFormatted`.
- **[`EntrySummaryCard`](file:///home/harry1029/projects/memodiary/lib/features/timeline/widgets/entry_summary_card.dart)**:
  - Header: Formatted date/time, mood emoji badge, weather badge, and weekly review ribbon (`W42 Review`).
  - Title and 2-line plain text snippet.
  - Right-aligned sandboxed thumbnail preview via `MediaSandboxService.getFileFromRelativePath()`.
- **[`TimeCapsuleCard`](file:///home/harry1029/projects/memodiary/lib/features/timeline/widgets/time_capsule_card.dart)**:
  - Sealed card with padlock icon and countdown pill ("Unlocks in X days").
  - **Strict Privacy Invariant**: Obscures plain text snippets, Delta JSON, and photos until the unlock date.
  - Interactive explanation dialog upon tapping.
- **[`TimelineScreen`](file:///home/harry1029/projects/memodiary/lib/features/timeline/screens/timeline_screen.dart)**:
  - Lazy-paginated feed (`ListView.builder`) with 20 items per page.
  - Search and Recycle Bin AppBar action buttons.
  - Extended Floating Action Button ("Write Diary") creating drafts and opening `EntryEditorScreen`.
  - Empty state with friendly illustration for brand-new users.

---

### 3. Template-Accurate Detail Reader Screen (`lib/features/timeline/screens/entry_detail_screen.dart`)
- **Visual Presentation**:
  - Encapsulates read-only content inside `TemplateCanvasContainer` using the entry's active `TemplateStyle`.
  - Header with formatted date, mood emoji, weather icon, and weekly review badges.
  - Read-only `QuillEditor` with `SandboxedImageEmbedBuilder` rendering sandboxed WebP photos.
- **Quick Action Bar**:
  - **Edit Entry**: Navigates to `EntryEditorScreen` and reloads upon save/exit.
  - **Template**: Opens `TemplateSwitcherSheet` to swap styling in real-time without mutating text.
  - **Share**: Formats and exports entry text via `SharePlus.instance.share()`.
  - **Delete**: Soft-deletes entry with confirmation dialog and pops back to timeline.

---

### 4. 30-Day Recycle Bin & Media Cleanup (`lib/features/recycle_bin/`)
- **[`RecycleBinService`](file:///home/harry1029/projects/memodiary/lib/core/services/recycle_bin_service.dart)**:
  - `permanentDeleteEntry`: Deletes physical sandboxed files (`media/{uuid}.webp`) from disk before deleting SQLite records to reclaim device storage.
  - `purgeExpiredEntries`: Auto-purges entries soft-deleted >30 days ago.
  - `emptyRecycleBin`: Wipes all soft-deleted entries and linked files.
- **[`RecycleBinScreen`](file:///home/harry1029/projects/memodiary/lib/features/recycle_bin/screens/recycle_bin_screen.dart)**:
  - Lists soft-deleted entries with remaining retention countdown pills (e.g. "28 days left").
  - Restore (↺) and Permanent Delete (🗑️) actions per card.
  - "Empty Bin" top action with confirmation.
- **App Launch Lifecycle (`lib/main.dart`)**:
  - Automatically runs `RecycleBinService.purgeExpiredEntries()` on app cold start.

---

### 5. Offline FTS5 Full-Text Search & Multi-Condition Filters (`lib/features/search/`)
- **[`SearchFilters`](file:///home/harry1029/projects/memodiary/lib/features/search/models/search_filters.dart)**:
  - Filter criteria: Date Range (`all`, `thisWeek`, `thisMonth`, `custom`), Mood (1–5), Weather, Has Photo, and Weekly Review.
- **[`SearchFilterChips`](file:///home/harry1029/projects/memodiary/lib/features/search/widgets/search_filter_chips.dart)**:
  - Horizontal interactive filter chip row with bottom-sheet pickers and reset button.
- **[`SearchScreen`](file:///home/harry1029/projects/memodiary/lib/features/search/screens/search_screen.dart)**:
  - Real-time search with 300ms input debounce.
  - Clean query branching: directly executes relational query when search text is empty.
  - Privacy guarantee: sealed Time Capsules (`now < unlockAt`) are strictly excluded from text searches.
  - Results feed displaying matching entries with one-tap navigation to detail view.

---

## Verification Results

### 1. Static Analysis
```bash
flutter analyze
```
**Result**:
```
Analyzing memodiary...
No issues found! (ran in 3.3s)
```

### 2. Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
**Result**:
```
Built with build_runner/aot in 28s; wrote 108 outputs.
```

### 3. Automated Test Suite (58/58 Passing Tests)
```bash
flutter test
```

**Results Breakdown**:
- `test/core/database/database_key_manager_test.dart`: 2 tests passed
- `test/core/database/app_database_test.dart`: 5 tests passed
- `test/core/services/media_sandbox_service_test.dart`: 4 tests passed
- `test/core/services/dictation_service_test.dart`: 3 tests passed
- `test/core/services/auth_service_test.dart`: 4 tests passed
- `test/features/auth/app_lock_gate_test.dart`: 3 tests passed
- `test/features/templates/template_canvas_painter_test.dart`: 2 tests passed
- `test/features/templates/template_switcher_test.dart`: 2 tests passed
- `test/features/editor/sandboxed_image_embed_test.dart`: 3 tests passed
- `test/features/editor/thought_spark_service_test.dart`: 2 tests passed
- `test/features/editor/editor_autosave_manager_test.dart`: 3 tests passed
- `test/features/editor/entry_editor_screen_test.dart`: 3 tests passed
- `test/widget_test.dart`: 3 tests passed
- **`test/features/timeline/timeline_repository_test.dart`**: 4 tests passed (pagination, soft-delete exclusion, primary media batching, Time Capsule status)
- **`test/features/recycle_bin/recycle_bin_test.dart`**: 4 tests passed (soft delete & restore, disk media deletion before SQLite removal, 30-day auto-purge, empty recycle bin)
- **`test/features/search/search_filter_test.dart`**: 6 tests passed (clean query branching, FTS5 keyword match, combined filters, photo & weekly review filters, sealed capsule exclusion, date range boundaries)
- **`test/features/timeline/entry_detail_screen_test.dart`**: 2 tests passed (template-accurate rendering, rich-text reader, share handler, soft delete confirmation)
- **`test/features/timeline/timeline_screen_test.dart`**: 3 tests passed (empty state, feed cards, sealed Time Capsule privacy obscuring, FAB draft creation)

```
00:02 +58: All tests passed!
```
