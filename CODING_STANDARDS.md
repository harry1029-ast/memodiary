# MemoDiary Coding Standards & Review Conventions

This document defines the code shape, naming conventions, architectural seams, and test hygiene standards enforced by `/code-review` and pair programming in MemoDiary.

Architectural product invariants (zero backend, $0 FOSS stack, SQLCipher encryption, and schema rules) are authored in [GEMINI.md](file:///home/harry1029/projects/memodiary/GEMINI.md).

---

## 1. Naming & Identifiers

- **Domain Names over Single Letters**: Never use single-letter variables in widget tree iterations, collection mappings, or callbacks.
  ```dart
  // Bad
  ..._detectedConstraints.map((c) => InputChip(label: Text(c.label)))

  // Good
  ..._detectedConstraints.map((constraint) => InputChip(label: Text(constraint.label)))
  ```
- **Consistent Widget Keys**: Standardize widget keys using snake_case descriptive tokens prefixed by feature domain:
  - Scenery: `Key('scenery_<element>')` (e.g. `const Key('scenery_realm_badge')`, `const Key('scenery_realm_option_<kind>')`)
  - Settings: `Key('settings_<feature>_<element>')` (e.g. `const Key('settings_last_backup_tile')`)
  - Search: `Key('nl_constraint_chip_<kind>')`, `Key('event_chip_<keyword>')`
  - Dialogs: `Key('backup_<action>_button')`, `Key('backup_encrypt_switch')`
- **Predictable Constructor Parameters**: Match public property names exactly to constructor parameters; avoid synthetic renames unless adapting legacy signatures.

---

## 2. Service Architecture & Seams

- **Injectable Directory Providers**: Any service performing filesystem I/O must accept optional directory provider seams defaulting to system/service providers:
  ```dart
  class BackupRestoreService {
    final Future<Directory> Function() _baseDirProvider;
    final Future<Directory> Function() _tempDirProvider;

    BackupRestoreService({
      required this.database,
      required this.mediaService,
      Future<Directory> Function()? baseDirProvider,
      Future<Directory> Function()? tempDirProvider,
    })  : _baseDirProvider = baseDirProvider ?? mediaService.getBaseDirectory,
          _tempDirProvider = tempDirProvider ?? (() async => Directory.systemTemp);
  }
  ```
- **Typed Value Objects over Ad-Hoc Maps**: Do not use raw `Map<String, dynamic>` string literals for internal state or service metadata. Model configurations and state records as immutable Dart classes or records.
- **Typed Value Objects for Composite Layout Metadata**: When $\ge 3$ contextual properties travel together to render canvas layouts, interactive 3D folios, or book spreads (e.g., lunar calendar strings, destination tags, route summaries), bundle them into an immutable typed value object (e.g. `BookIntroFolioData`) rather than passing loose primitive strings across widget constructors.
- **Background Isolate Offloading**: CPU-intensive operations (ZIP compression, chunked encryption/decryption, SHA-256 calculation on files $\ge 1\text{ MiB}$, batch database ingestion) must execute inside `Isolate.run()` to prevent UI stutter.
- **WYSIWYG Export Transform Parity**: Any headless document exporter (PDF generator, raster image synthesizer) consuming interactive canvas models must reproduce all user canvas transformations (pan offsets `panOffsetX`/`panOffsetY`, zoom scale, rotation, layer stacking order) with 1:1 mathematical parity.
- **Dominant-Axis Downsampling**: Image transcoders downsampling arbitrary user photos must evaluate input aspect ratios and constrain along the dominant dimension (`origW >= origH ? targetWidth : targetHeight`) rather than fixing a single dimension, protecting against memory spikes on extreme panoramic or portrait aspect ratios.
- **No Silent In-Memory Fallbacks in Production UI**: Screen and container widgets must never instantiate in-memory databases (`AppDatabase.memory()`) or unconfigured services inside state getters to satisfy optional constructor parameters. Pass required dependencies explicitly via constructors or inherit from provider/context. Silent fallbacks mask missing wiring bugs and create split state during navigation.
- **Modal Route State Encapsulation**: Widgets presented via `showModalBottomSheet` or `showDialog` that contain interactive controls (sliders, tab selectors, toggles, chips) must maintain internal mutable state within their own `StatefulWidget` (or consume a shared reactive notifier/InheritedNotifier) and invoke `setState()` when user interactions occur. Never rely on the caller screen's `setState()` to rebuild an active modal route.
- **Bidirectional Media Lifecycle Parity**: Deleting or replacing an embedded media attachment (photo or video) from the editor, delta, or canvas model must purge both the in-memory document state and the backing SQLite `media_attachments` record (via `AppDatabase.deleteMediaForEntryByPath`) to maintain referential integrity and prevent ghost attachment resurrection on entry reload or Folio pagination.
- **Rich-Text Document Structural Emptiness Invariant**: In rich-text editor viewports and virtual sheet partitions, a document or sheet is only considered empty when `document.length <= 1` (zero user-entered characters, only the mandatory trailing terminal newline `\n`). Never use `plainText.trim().isEmpty` to determine whether an active document or partition is empty, because whitespace, indentation, blank lines (`\n\n`), and formatting deltas are intentional user content. Using `.trim().isEmpty` causes premature sheet deletion and disposes active input channels mid-composition.
- **Trailing-Only Sheet Collapse Boundaries**: Automated sheet collapse algorithms (e.g. `collapseEmptyContinuationSheets`) must strictly be restricted to trailing continuation sheets (`index == totalSheets - 1`), immediately breaking on the first non-empty sheet (`break`). An active or intermediate sheet must never be collapsed while the diarist is focused on or typing within it.
- **Active IME Controller Disposal Safety**: Never call `controller.dispose()` or `document.close()` on an active editor sheet or viewport while focus or event dispatch may be directed to it. In Flutter Quill, calling `dispose()` closes the document change stream; any subsequent platform IME keystrokes received by `TextInputClient` fail with `!documentChangeObserver.isClosed`, permanently locking user input.
- **Stationery Sheet Spill IME Symmetry**: Any forward or reverse pagination mutation (`performAutoSpill`, `performSpillBack`, sheet collapse, or layout re-balance) must guard against active mobile IME composition on all involved sheets (`isSheetComposing`) at entry, deferring until composition commits to protect user input.
- **Pure Presentation Reading Seams (Folio & Book Spreads)**: Reading viewports, content leaves, and book spreads (`ThreadBoundFolioScreen`, `FolioContentLeafPage`, `PhotobookSpread`) must remain pure presentation components decoupled from direct database queries. Never pass `AppDatabase` into leaf or spread widgets to execute queries inside event handlers; bubble state updates (e.g. `onOverlayPositionChanged`, `onPageTurn`) through callbacks handled at the screen or repository level.
- **Native Reflection Keep Rules & JNI Extraction**: On Android, any library relying on reflection during startup (e.g. ML Kit `ComponentRegistrar`, `MlKitInitProvider`) must carry explicit `-keep` rules in `android/app/proguard-rules.pro` protecting public `<init>()` constructors. Packages relying on Dart FFI `DynamicLibrary.open` on bundled native `.so` files (`sqlcipher_flutter_libs`) must configure `packaging.jniLibs.useLegacyPackaging = true` in `build.gradle.kts` so libraries are extracted at install time (`android:extractNativeLibs="true"`).
- **Migration Writer Coverage**: A data migration's selection rule (which rows to copy, move, or reset) must hold for every code path that has ever written the migrated columns: check each write method and its git history, not just the column's documented meaning. The migration test seeds one row per writer shape (e.g. never-scanned, OCR-scanned, OCR Sentinel, in-app caption) and asserts each outcome.

---

## 3. UI Widgets & Accessibility (a11y)

- **Scoped Semantics on Actionable Elements**: When an action button lives inside an informative widget (e.g., delete icon inside an `InputChip`), wrap only the actionable button in `Semantics`:
  ```dart
  // Bad: Overwrites the chip's entire label and role in screen readers
  Semantics(
    label: 'Remove filter',
    child: InputChip(label: Text(constraint.label)),
  )

  // Good: Screen reader reads chip title, then deletion action on button
  InputChip(
    label: Text(constraint.label),
    deleteIcon: Semantics(
      label: 'Remove ${constraint.label} filter',
      child: const Icon(Icons.close, size: 16),
    ),
    onDeleted: () => _remove(constraint),
  )
  ```
- **Text-Scale Clamping & Responsive Bounds**:
  - Horizontal chip ribbons and toolbars must clamp `MediaQuery.withClampedTextScaling` (max $\le 1.3$).
  - Dynamic user-generated text inside chips must be bounded by `ConstrainedBox(maxWidth: 180)` and `TextOverflow.ellipsis` to prevent `RenderFlex` overflow on viewports down to $320\text{px}$.
- **Explicit Icon Sizing**: Secondary action icons in list tiles and toolbar buttons must specify explicit pixel sizes (e.g., `size: 20` for secondary list tiles, `size: 16` for chip trailing icons) rather than relying on ambiguous inherited ambient defaults.
- **3D Transform & Matrix4 Perspective Invariants**: When implementing outward page flips or 3D rotations in Flutter (`rotateY` with `Alignment.centerLeft`), perspective projection must use a negative scale factor (e.g. `setEntry(3, 2, -0.0008)`) so points with positive $z$ expand outward toward the camera rather than collapsing inward.
- **Accessible Semantics on Canvas Overlays**: Transparent touch targets placed atop a `CustomPainter` (e.g. an empty `InkWell` over a custom canvas) must be explicitly wrapped in `Semantics(button: true, label: '<Action description>')`. Never leave transparent touch targets unlabelled for screen readers.
- **Complex Vector Painter Modularity & ui.Picture Separation**: Custom painters with rich static and dynamic geometry (e.g., Scenery Realms, Photobook Canvas) must decouple static backgrounds into a dedicated static architecture helper recorded once into an immutable `ui.Picture` layer, and dynamic 60 FPS actors into a separate painter class, keeping individual source files under 450 lines to prevent context bloat and stream limits.
- **Immediate SnackBar Feedback Dismissal**: When presenting immediate user feedback upon state mutation, always invoke `ScaffoldMessenger.of(context).hideCurrentSnackBar()` prior to `showSnackBar()` to prevent queued duration stalls in interactive flows and widget test harnesses.
- **Displacement over Coexistence (Legacy Scaffolding Cleanup)**: When a specification or architecture decision explicitly mandates replacing an interaction seam, modal, or toolbar menu with a unified component, remove the deprecated UI component and migrate its corresponding widget test assertions to exercise the replacement seam in the same change set. Never preserve dead legacy UI scaffolding to satisfy un-migrated test assertions.

---

## 4. Testing & Verification Hygiene

- **Shared Test Doubles (`test/helpers/`)**: Reusable test doubles, mocks, and fake service implementations (e.g. `MockSecureStorage`, `MockFileSelectorService`, `FakeEditorVideoPlatform`, `StubEditorImagePicker`, `SyncTestMediaSandboxService` in `test/helpers/editor_test_harness.dart`) must live under `test/helpers/` rather than being re-declared as private classes across multiple individual test suites.
- **Shared Test Harness Extraction**: When widget setup requires screen sizing overrides, database initialization, or service dependency wiring:
  - Extract a reusable `pump<Feature>Screen(WidgetTester tester, ...)` helper.
  - Never copy-paste identical physical size or provider wiring blocks across multiple tests in the same suite.
- **Synchronous dart:io Fixtures in FakeAsync testWidgets**: Inside Flutter widget tests (`testWidgets`), the test framework executes in a `FakeAsync` zone. Asynchronous `dart:io` operations (`File.exists()`, `File.copy()`, `File.writeAsBytes()`, `Directory.create()`) dispatch to the real OS thread pool and never resolve without `await tester.runAsync(...)`, causing permanent test-runner deadlocks. Widget test setup and media mocks must use synchronous `dart:io` methods (`writeAsBytesSync`, `existsSync`, `copySync`, `createSync`) or `SyncTestMediaSandboxService` from `test/helpers/editor_test_harness.dart`.
- **Repeating Ticker Decoupling & Test Settling**: Widgets driving infinite ambient loops (`controller.repeat()`) must be decoupled from test settling. Test suites testing such widgets must use bounded step pumps (`tester.pump(duration)`) rather than `tester.pumpAndSettle()`. Top-level app entrypoints must default ambient intro loops (`showIntroOnLaunch: false`) to false in component test environments, and widgets driving background animations must guard execution with `Platform.environment['FLUTTER_TEST'] != 'true'` or an explicit `enableAmbientAnimation` flag.
- **List Header Ticker Auto-Suspension**: Ambient 60 FPS loops rendered within scrollable list headers must expose an `isVisible` property and pause `controller.stop()` when scrolled past their viewport bounds, resuming ticking only when returned to visibility.
- **Deep Field Parity over Bare Counts**: Stress and round-trip tests must verify 100% field parity against known-good pre-test snapshots (all columns: `title`, `contentDelta`, `entryDate`, `mood`, `weather`, `unlockAt`, `isDeleted`, `entryPinHash`), rather than only verifying table row counts.
- **Deterministic Test Payloads**:
  - File format fixtures (such as MP4 or WebP) must declare valid magic-byte headers deterministically (e.g. 32-byte `ftyp` box header `[0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, ...]`) so format parsers pass instantaneously without flaky mocking.
  - Pure-Dart cryptographic loops (PBKDF2) must support configurable low iteration counts in unit test configurations (e.g. `iterations: 1000` or `2000`) while defaulting to $200,000$ in production.
- **Scrollable Sheet Tap Assurance**: When writing widget tests that interact with elements inside scrollable modal bottom sheets, bottom drawers, or scroll views (`SingleChildScrollView`, `ListView`), precede interactive taps with `await tester.ensureVisible(finder);` (or `WidgetTesterScrollHelpers.tapVisible`) to prevent offscreen coordinate warnings and hit-test misses on standard headless viewports ($800 \times 600$).
- **Interactive UI Mutation over Bare Callback Dispatch**: Widget tests for interactive modal sheets, sliders, dropdowns, and selection chips must assert on the **resulting visual UI state** (e.g. active highlight border, checkmark icon, updated slider value label) while the component remains open, not merely verify that an event callback was invoked. Testing only callback dispatch masks modal route state-isolation bugs.
- **Layout Tests Beyond the Reference Phone**: Layout and keyboard-chrome tests cover a short viewport (desk height under 420dp, e.g. landscape) and the largest clamped text scale, not only the 360×780 reference phone. A single viewport hides clamp-dependent reflow (e.g. hiding the Writing Dock resizing the Stationery Sheet) and fixed-row overflows (e.g. the Journal Letterhead snapping to five rows).

---

## 5. Security & Network Quarantine Invariants

- **Strict Zero Remote Endpoints**: Never import HTTP/REST/WebSocket networking clients in application features.
- **Manifest Defense**:
  - `android/app/src/main/AndroidManifest.xml` and release merged manifests must strictly omit `android.permission.INTERNET`.
  - `ios/Runner/Info.plist` must strictly omit `NSAppTransportSecurity`, `NSAllowsArbitraryLoads`, and `NSAllowsLocalNetworking`.
- Every release build must pass `network_quarantine_audit_test.dart` and `flutter analyze` with 0 issues before merge.

