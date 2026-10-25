# MemoDiary (拾光日记) — Antigravity Workspace Rules & Invariants

## 1. Product Vision & Core Constraints
- **Local-First & Zero Backend**: MemoDiary is an offline-first, privacy-focused personal diary and weekly review app for Android (10+) and iOS (15+). All user data defaults to local device storage with zero mandatory registration or cloud uploads.
- **$0 Build & Runtime Cost**: Use 100% free, open-source packages (MIT/BSD/Apache/SIL OFL) and built-in native OS APIs. Never introduce paid third-party SDKs (no paid speech APIs, no paid handwriting SDKs, no cloud LLM/OCR APIs).
- **Decoupled Content & Presentation**: Diary text/media semantics (`flutter_quill` Delta JSON) must be strictly separated from visual template styling (`templates` table). Switching a template on a saved entry must only alter visual presentation without mutating or losing text content.
- **Sandboxed Media Isolation**: Never store absolute paths to the system photo gallery[cite: 1]. Copy all captured/imported photos into the app's private sandbox directory using UUID filenames, compress images to WebP (max 1600px, 80% quality), and store only relative paths in SQLite.
- **Multimodal System Reuse**: Rely strictly on native OS keyboards (Pinyin, English, and OS handwriting input panel) and native OS Speech-to-Text (`iOS Speech` / `Android SpeechRecognizer`). Do not build a custom freehand stylus drawing engine[cite: 1, 5].

## 2. Locked Tech Stack ($0 FOSS)
- **Framework**: Flutter (Dart)
- **Database & Encryption**: `drift` + `sqlcipher_flutter_libs` (SQLCipher AES-256 encryption at rest)[cite: 1, 2]
- **Key Storage & Auth**: `flutter_secure_storage` + `local_auth` (Face ID / Fingerprint / PIN lock)[cite: 1, 2]
- **Rich Text Editor**: `flutter_quill` (Delta JSON serialization)[cite: 1, 2]
- **Full-Text Search**: SQLite FTS5 virtual table (`entries_fts`) + offline Chinese word segmentation (`jieba`)[cite: 1, 2]
- **Media & Files**: `image_picker`, `flutter_image_compress`, `file_picker`, `path_provider`, `share_plus`
- **Typography**: System built-in fonts + bundled SIL Open Font License (OFL) fonts (≥10 fonts total)

## 3. Core SQLite Schema Invariant
Maintain the following 5 core tables in `lib/core/database/app_database.dart`[cite: 1, 5]:
1. `templates`: `id`, `name`, `background_type` ('color', 'paper_texture', 'grid', 'lined'), `background_value`, `font_family`, `line_spacing`, `margin_horizontal`, `is_custom`[cite: 1, 5].
2. `notebooks`: `id`, `title`, `default_template_id`, `created_at`[cite: 1, 2].
3. `entries`: `id`, `notebook_id`, `template_id`, `title`, `content_delta` (Quill Delta JSON), `plain_text` (for FTS5), `entry_date` (epoch), `mood` (1-5), `weather`, `is_weekly_review`, `week_number`, `unlock_at` (epoch for Time Capsule), `created_at`, `updated_at`, `is_deleted` (0/1 for 30-day trash bin)[cite: 1, 3].
4. `entries_fts`: FTS5 virtual table indexing `title` and segmented `plain_text`[cite: 1].
5. `media_attachments`: `id`, `entry_id`, `media_type` ('image', 'video'), `relative_path`, `thumbnail_path`, `ocr_text`, `created_at`[cite: 1].

## 4. Coding & Verification Standards
- Keep UI widgets decoupled from SQLite queries using repository/provider layers.
- Ensure all file imports and bulk SQLite writes run inside background `Isolate` workers or batched transactions so the UI thread maintains 60 FPS[cite: 1, 2].
- Write unit tests for every data model, date-parsing regex rule, and repository method.
- Detailed code shape, naming, a11y semantics, and test harness standards are specified in [CODING_STANDARDS.md](file:///home/harry1029/projects/memodiary/CODING_STANDARDS.md).

## Development Roadmap (Reference Only)
Milestone 1 (Alpha):
- Phase 0: Encrypted Drift DB, Media Sandbox & Launch Security
- Phase 1: Decoupled Templates & Rich-Text Editor
- Phase 2: Timeline View, CRUD & Offline FTS5 Search
- Phase 3: Smart .txt/.md Date Ingestion & Export
- Phase 4: Benchmarking & Hardening
Milestone 2 (Beta):
- Phase 5: Custom Template Builder & Dedicated Weekly Review Aggregated Grid
- Phase 6: High-Fidelity Template-Preserving PDF Export Engine
- Phase 7: Sandboxed Short Video Ingestion & Inline Playback
- Phase 8: Retrospective Suite, Writing Sanctum, Local Reminders & Analytics
Milestone 3: Release Candidate (v1.0.0-rc.1)
- Phase 9: Encrypted Full-Archive Backup/Restore & Smart Natural Language Search
- Phase 10: Release Candidate Polish, Round-Trip Stress Audit & v1.0.0 Certification
Milestone 3.5: Travel Memory Album (v1.1.0-alpha)
- Phase 11: Drift Schema v3 Migration, Media Pipeline & Album Repository
- Phase 12: Collection Management, Batch Ingestion & Photo Annotation Workspace
- Phase 13: Keepsake Synthesis Engine, Interactive In-App Viewer & PDF Photobook Export
Intermediate Milestone 3.6: DIY Photobook Studio & Scrapbook Editor (v1.2.0-alpha)
- Phase 14: Studio Data Model, Collage Layout Library, Book Themes & Sticker/Background Engine
- Phase 15: Book Overview Spread Feed & Interactive Drag-and-Drop Page Editor UI
- Phase 16: WYSIWYG Vector PDF Photobook Renderer, Offline CJK Font Fix & Hardening