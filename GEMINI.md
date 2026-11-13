# MemoDiary (拾光日记) — Antigravity Workspace Rules & Invariants

## 1. Product Vision & Core Constraints
- **Local-First & Zero Backend**: MemoDiary is an offline-first, privacy-focused personal diary and weekly review app for Android (10+) and iOS (15+). All user data defaults to local device storage with zero mandatory registration or cloud uploads.
- **$0 Build & Runtime Cost**: Use 100% free, open-source packages (MIT/BSD/Apache/SIL OFL) and built-in native OS APIs (with the sole documented exception of Android's free bundled on-device `com.google.mlkit:text-recognition-chinese` binary stripped of `INTERNET` permissions per ADR 0004). Never introduce paid third-party SDKs (no paid speech APIs, no paid handwriting SDKs, no cloud LLM/OCR APIs).
- **Decoupled Content & Presentation**: Diary text/media semantics (`flutter_quill` Delta JSON) must be strictly separated from visual template styling (`templates` table). Switching a template on a saved entry must only alter visual presentation without mutating or losing text content.
- **Sandboxed Media Isolation**: Never store absolute paths to the system photo gallery. Copy all captured/imported photos into the app's private sandbox directory using UUID filenames, compress images to WebP (max 1600px, 80% quality), and store only relative paths in SQLite.
- **Multimodal System Reuse**: Rely strictly on native OS keyboards (Pinyin, English, and OS handwriting input panel) and native OS Speech-to-Text (`iOS Speech` / `Android SpeechRecognizer`). Do not build a custom freehand stylus drawing engine.

## 2. Locked Tech Stack ($0 FOSS)
- **Framework**: Flutter (Dart)
- **Database & Encryption**: `drift` + `sqlcipher_flutter_libs` (SQLCipher AES-256 encryption at rest)
- **Key Storage & Auth**: `flutter_secure_storage` + `local_auth` (Face ID / Fingerprint / PIN lock)
- **Rich Text Editor**: `flutter_quill` (Delta JSON serialization)
- **Full-Text Search**: SQLite FTS5 virtual tables (`entries_fts` + `media_fts`) + offline Chinese word segmentation (`jieba`)
- **On-Device OCR**: Native `memodiary/ocr` channel (`Apple Vision` on iOS 15.0+, bundled `com.google.mlkit:text-recognition-chinese` with `INTERNET` stripped on Android per ADR 0004)
- **Media & Files**: `image_picker`, `flutter_image_compress`, `file_picker`, `path_provider`, `share_plus`
- **Typography**: System built-in fonts + bundled SIL Open Font License (OFL) fonts (≥10 fonts total)

## 3. Core SQLite Schema Invariant
Table definitions live in `lib/core/database/tables/`, the schema version and migrations in `lib/core/database/app_database.dart`. Read them for columns; these invariants hold across every schema version:
- `entries.content_delta` stores Quill Delta JSON; `entries.plain_text` mirrors it for FTS. Templates (`templates` table) style presentation only and never mutate content.
- `entries.is_deleted` (0/1) is a 30-day trash bin, not a hard delete.
- `entries_fts` (FTS5 + `jieba` segmentation) indexes `title` and `plain_text`.
- Media rows (`media_attachments`, `album_photos`) store strictly relative sandbox paths.
- `media_fts` (FTS5 `unicode61`) indexes `ocr_text` only, across `media_attachments` and `album_photos`. Diarist captions (`caption`) are never indexed.

## 4. Coding & Verification Standards
- Keep UI widgets decoupled from SQLite queries using repository/provider layers.
- Ensure all file imports and bulk SQLite writes run inside background `Isolate` workers or batched transactions so the UI thread maintains 60 FPS.
- Write unit tests for every data model, date-parsing regex rule, and repository method.
- **Generated Code Boundary (`.g.dart`)**: Never inspect, diff, or manually edit `.g.dart` files. Always modify table schema definitions in `lib/core/database/tables/` or `app_database.dart` and regenerate inside that working directory (`cd <dir> && /home/harry1029/development/flutter/bin/dart run build_runner build`; `dart run` has no `--directory` flag).
- Detailed code shape, naming, `< 450` LOC decomposition, a11y semantics, and test harness standards live in [CODING_STANDARDS.md](file:///home/harry1029/projects/memodiary/CODING_STANDARDS.md); read it during `/code-review` and before UI/service refactors.
- **Specs, ADRs & Roadmap**: Numbered specifications live at `docs/specs/000X-<slug>.md`, architecture records at `docs/adr/000X-<slug>.md`, and Milestone 1–4 phase history at [docs/roadmap.md](file:///home/harry1029/projects/memodiary/docs/roadmap.md).
- **Implementer Worktree Branches**: Worktree branches for feature or ticket subagents must use flat hyphenated names (`spec-NNN-XX-<slug>`), never slashes (`spec-NNN/...`), to prevent Git loose ref directory collisions with the integration branch file.
- **Agent Skills Config**: Issue tracker, triage labels, and domain-doc conventions used by the engineering skills are defined in `docs/agents/` (`issue-tracker.md`, `triage-labels.md`, `domain.md`).
- **Execution & Tooling**: In environments where `flutter` or `dart` is not on the default sandbox `$PATH`, invoke `/home/harry1029/development/flutter/bin/flutter` (or `/home/harry1029/development/flutter/bin/dart`). External SDK binaries and Git index writes (`git add`, `git rm`, `git commit`) require `BypassSandbox: true`; use Standard Sandbox Mode (`BypassSandbox: false`) for all read-only inspection, search, and file commands (`find`, `grep`, `wc`, `git status`, `git log`, `git diff`) to prevent approval stalls in autonomous subagents. For isolated git worktrees, verify with `tool/worktree-verify.sh <worktree> [test-paths...]` instead of passing a worktree path to `flutter analyze` from the main workspace. For one-off Dart evaluations, write a scratch script in `<appDataDir>/brain/<id>/scratch/` and run with `dart run <file>`. On headless Linux (where `xdg-open` is absent), link generated HTML files directly instead of invoking `xdg-open`.
- **Tool Economy & Token Hygiene**: Run tests with `tool/test.sh <paths>` (no paths = full suite): one summary line on success, only failing test names and Expected/Actual lines on failure. Reserve full-suite runs for milestone certification. Restrict log/search inspections using pipe limits (`head -n 20`, `grep -m 5`).
- **Headless Release Diagnostics**: When investigating release APK crashes without a physical device, inspect R8 mapping outputs under `build/app/outputs/mapping/release/` (`usage.txt` lists stripped classes/constructors, `seeds.txt` lists preserved entry points) and verify merged APK binary manifest attributes (`extractNativeLibs`) via `/home/harry1029/android-sdk/build-tools/34.0.0/aapt2 dump xmltree --file AndroidManifest.xml build/app/outputs/flutter-apk/app-release.apk`.
