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

---

## 4. Testing & Verification Hygiene

- **Shared Test Harness Extraction**: When widget setup requires screen sizing overrides, database initialization, or service dependency wiring:
  - Extract a reusable `pump<Feature>Screen(WidgetTester tester, ...)` helper.
  - Never copy-paste identical physical size or provider wiring blocks across multiple tests in the same suite.
- **Repeating Ticker Decoupling & Test Settling**: Widgets driving infinite ambient loops (`controller.repeat()`) must be decoupled from test settling. Test suites testing such widgets must use bounded step pumps (`tester.pump(duration)`) rather than `tester.pumpAndSettle()`. Top-level app entrypoints must default ambient intro loops (`showIntroOnLaunch: false`) to false in component test environments.
- **Deep Field Parity over Bare Counts**: Stress and round-trip tests must verify 100% field parity against known-good pre-test snapshots (all columns: `title`, `contentDelta`, `entryDate`, `mood`, `weather`, `unlockAt`, `isDeleted`, `entryPinHash`), rather than only verifying table row counts.
- **Deterministic Test Payloads**:
  - File format fixtures (such as MP4 or WebP) must declare valid magic-byte headers deterministically (e.g. 32-byte `ftyp` box header `[0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, ...]`) so format parsers pass instantaneously without flaky mocking.
  - Pure-Dart cryptographic loops (PBKDF2) must support configurable low iteration counts in unit test configurations (e.g. `iterations: 1000` or `2000`) while defaulting to $200,000$ in production.

---

## 5. Security & Network Quarantine Invariants

- **Strict Zero Remote Endpoints**: Never import HTTP/REST/WebSocket networking clients in application features.
- **Manifest Defense**:
  - `android/app/src/main/AndroidManifest.xml` and release merged manifests must strictly omit `android.permission.INTERNET`.
  - `ios/Runner/Info.plist` must strictly omit `NSAppTransportSecurity`, `NSAllowsArbitraryLoads`, and `NSAllowsLocalNetworking`.
- Every release build must pass `network_quarantine_audit_test.dart` and `flutter analyze` with 0 issues before merge.

