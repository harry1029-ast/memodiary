---
id: SPEC-002
title: Entry Editor Redesign onto Full-Bleed Journal Sheet & Minimalist Writing Dock
status: ready-for-agent
created_at: 2026-10-30T21:05:00+08:00
---

# Specification: Entry Editor Redesign onto Full-Bleed Journal Sheet & Minimalist Writing Dock

## Problem Statement

Diarists opening MemoDiary to compose or edit a journal entry currently encounter a visually fragmented, button-cluttered editing environment:

1. **Harsh Visual "Sandwich" Fragmentation**: In Dark Mode, a jet-black AppBar and metadata strip sit atop an intrusive dark Thought Spark card, which sits atop a stark white inner rectangular paper container, and is capped by a dark bottom bar. The screen feels like an administrative CMS web form rather than an authentic paper diary.
2. **Button Proliferation and Duplication**: Soundscapes (🎧), Typography ('A'), and Template switchers are duplicated across both the AppBar and the bottom toolbar, resulting in over 18 competing buttons and acute cognitive overload before the writer even types a single character.
3. **Thought Spark Visual Obstruction**: A 150px persistent container card monopolizes the upper third of the vertical screen, pushing the journal paper downward and breaking the tranquil atmosphere of opening a fresh notebook.
4. **Clinical Metadata Form**: Date, weather, mood, and time-capsule controls are rendered as isolated computer-chip pills detached from the paper canvas, divorcing the entry from traditional diary stationery conventions.
5. **No Journal Identity**: The editor lacks the tactile warmth, quiet elegance, and typographic dignity expected of a personal diary application.

## Solution

A complete transformation of the diary editing screen into an authentic, distraction-free **Full-Bleed Journal Sheet**:

1. **Full-Bleed Journal Sheet (素笺全展)**:
   - The paper canvas extends across the entire screen viewport. The Android status bar, top navigation bar, and scaffold dynamically inherit the active template's paper tone, texture, ruled lines, and ink contrast.
   - Completely eliminates floating rectangular boxes, border seams, and letterbox contrast breaks across both Light and Dark OS modes.
2. **In-Paper Journal Letterhead (笺头题签)**:
   - Replaces the external metadata button strip with an authentic typographic header rendered directly onto the top lines of the Journal Sheet.
   - Displays entry date, day of week, and seasonal/solar term cues in Kaiti serif (`yyyy年M月d日 星期X · 节气`), flanked by subtle inline mood and weather emblems that open quiet bottom-sheet pickers when tapped.
   - Introduces an optional borderless stationery Title line (`题名 · Title...`) styled as a handwritten chapter heading that flows seamlessly into the stationery.
3. **In-Line Ghost Prompt (笺上隐题)**:
   - Completely removes the persistent 150px `ThoughtSparkBanner` container.
   - When the journal entry is empty, the inspirational reflection prompt appears as an elegant italicized placeholder directly inside the writing area (`“今天最让你心动或者难忘的一瞬间是什么？” 提笔落墨...`).
   - Diarists can tap an unobtrusive inline action (`由此题落墨 · Adopt Prompt`) to quote the spark into the entry with blockquote formatting, or simply begin typing their own thoughts, causing the ghost prompt to naturally vanish.
   - An on-demand spark action in the bottom dock allows cycling prompts at any time.
4. **Progressive 5-Tool Writing Dock (文房雅具)**:
   - Replaces the 15+ button horizontal scrollbar with a clean 5-tool dock docked above the keyboard:
     1. `[Aa 字法]` (Formatting drawer toggle)
     2. `[📷 拓影]` (Sandboxed photo insertion)
     3. `[🎥 短影]` (Sandboxed short video insertion)
     4. `[🎙️ 听写]` (Speech-to-text dictation)
     5. `[✨ 灵感]` (Cycle or reveal Ghost Prompt)
   - Tapping `[Aa 字法]` smoothly expands an inline formatting ribbon (Bold `B`, Italic `I`, Underline `U`, Title `H1`, Subtitle `H2`, Quote `”`, Bullet List `•`, Numbered List `1.`) docked directly to the soft keyboard.
5. **Pared-Down Minimalist AppBar**:
   - Strips duplicated tools (Soundscapes, Typography, Templates) from the top navigation bar.
   - Retains only: `[← Back]` (auto-saves draft), a discreet low-contrast autosave status indicator (`已保存 / 存墨中`), a Cinnabar Seal `[✓ 封卷]`, and an options overflow menu `[···]` for secondary stationery settings (Templates, Typography, Time Capsule, Soundscapes).
6. **Unified Autosave Synchronization**:
   - `EditorAutosaveManager` manages both Quill Delta/plain text and the stationery title, debouncing updates (2s) to SQLite's `entries` table and `entries_fts` search index with periodic (8s) safety flushes.

## User Stories

1. As a diarist, I want the diary editing screen to fill the entire device viewport with my selected paper texture and background color, so that writing feels like opening a physical notebook on my desk.
2. As a diarist using Dark Mode on my phone, I want the top navigation bar and system status bar to seamlessly match the active stationery's paper tone without black letterbox bars, so that visual contrast remains soothing and harmonious.
3. As a writer, I want to see my entry date, day of week, weather, and mood written directly onto the top lines of the paper sheet, so that my diary resembles classical printed stationery.
4. As a diarist backdating an entry, I want to tap the in-paper date header to open a calendar date-picker, so that I can easily adjust when the entry occurred.
5. As a diarist logging my emotional state, I want to tap the inline mood emblem on the paper to select from the 5 literati mood states (`沉郁`, `倦怠`, `静穆`, `怡然`, `欢欣`), so that I can capture my feelings without cluttering the screen.
6. As a diarist recording the day's climate, I want to tap the inline weather emblem on the paper to select from the 5 weather conditions (`晴明`, `阴翳`, `润雨`, `朔风`, `凝雪`), so that weather logging is intuitive and quiet.
7. As a writer who likes naming entries, I want an optional borderless title line directly below the date header, so that I can give my diary entry an expressive heading if desired.
8. As a diarist who prefers stream-of-consciousness writing, I want the entry title line to be completely optional and unobtrusive, so that I can leave it blank and start writing immediately.
9. As a writer facing a blank page, I want to see an inspirational Ghost Prompt gently displayed as italic placeholder text in an empty entry, so that I am gently nudged into reflection without intrusive popups.
10. As an inspired writer who likes the suggested Ghost Prompt, I want to tap a 1-click "由此题落墨" action next to the placeholder, so that the prompt is automatically quoted into the document body as an opening reflection.
11. As a writer who already knows what to write, I want the Ghost Prompt to naturally disappear as soon as I type my first character, so that it never gets in my way.
12. As a writer looking for different inspiration, I want to tap the `[✨ 灵感]` icon in the bottom dock to cycle through different prompts, so that I can find a topic that resonates with my day.
13. As a writer editing an existing diary entry with text, I want the Ghost Prompt to stay hidden, so that it does not distract from my written thoughts.
14. As a focused writer, I want the top navigation bar to contain only essential navigation (`[← Back]`), autosave status, and a single seal button (`[✓ 封卷]`), so that my eyes are not distracted by a row of unused icons.
15. As a writer seeking peace of mind, I want to see a subtle, low-contrast autosave indicator that pulses only when saving to disk and quietly confirms "已保存", so that I know my words are never lost.
16. As a writer who wants to seal an entry, I want to tap the Cinnabar Seal `[✓ 封卷]` in the upper right corner to trigger an immediate save, provide tactile haptic feedback, and return to the timeline.
17. As a writer, I want to access secondary settings like template switching, typography customization, soundscapes, and time capsule locking through a single `[···]` options menu, so that rare actions don't clutter common writing flows.
18. As a writer typing on a mobile keyboard, I want the bottom Writing Dock to show only 5 essential, high-frequency actions (`[Aa 字法]`, `[📷 拓影]`, `[🎥 短影]`, `[🎙️ 听写]`, `[✨ 灵感]`), so that my fingers can quickly reach the tools I actually need.
19. As a writer formatting my text, I want to tap `[Aa 字法]` to expand an inline formatting ribbon right above the keyboard with Bold, Italic, Underline, H1, H2, Quotes, and Lists, so that I can style text without leaving the writing flow.
20. As a writer done formatting, I want to easily collapse the formatting ribbon, so that the screen returns to its serene, minimal state.
21. As a multimedia diarist, I want to tap `[📷 拓影]` to insert a compressed, sandboxed WebP photo into my diary, so that my visual memories are preserved locally and securely.
22. As a diarist recording life moments, I want to tap `[🎥 短影]` to insert a sandboxed short video (≤60s), so that my dynamic moments are preserved within the text.
23. As a diarist who prefers speaking, I want to tap `[🎙️ 听写]` to activate native OS speech recognition, so that spoken words are inserted directly into the cursor position.
24. As a diarist sealing a Time Capsule, I want to configure an unlock date from the options menu, so that the entry is sealed until a designated future milestone.
25. As a reader listening to rain or zither music, I want to toggle ambient soundscapes from the options menu, so that background audio accompanies my writing session.
26. As a user modifying both the title and body text, I want both fields to be debounced and automatically saved together into SQLite, so that closing the app abruptly preserves both the title and text without loss.

## Implementation Decisions

### 1. Structural Modules & Hierarchy
- **`JournalSheet`**: The root full-bleed viewport widget wrapping the editor canvas, paper custom painter, and adaptive status bar overlay. Dynamically binds to the active template's styling (background color, paper grain, ruled spacing, and text theme).
- **`JournalLetterhead`**: Typographic header widget embedded within the scrollable journal canvas above the rich-text body. Manages the inline presentation of entry date, weather picker, mood picker, and borderless title input field.
- **`GhostPromptView`**: An intelligent empty-state placeholder widget rendered inside the journal canvas when the entry has zero length. Coordinates prompt cycling, one-tap adoption into Quill Delta blockquote, and smooth fade-out on user keystrokes.
- **`WritingDock`**: Consolidated, two-tier bottom action dock anchored to the device keyboard. Tier 1 provides 5 primary icons (`Aa`, `Photo`, `Video`, `Dictate`, `Spark`). Tier 2 expands on-demand as an inline formatting ribbon providing Bold, Italic, Underline, H1, H2, Blockquote, Bullet List, and Numbered List.
- **`EntryEditorAppBar`**: Minimalist top navigation bar presenting Back button, subtle autosave indicator, Cinnabar Seal checkmark, and a single popup menu button (`[···]`) for secondary actions (Template Switcher, Typography Sheet, Time Capsule Date, and Soundscape Modal).

### 2. State & Autosave Synchronization
- **`EditorAutosaveManager`**: Extended to observe both Quill document changes and the new `TextEditingController` for the entry title. Both fields are debounced together (2s) and written atomically to `AppDatabase.updateEntryMetadata` and `AppDatabase.updateEntryContent`, ensuring SQLite FTS5 search indexing stays synchronized.

### 3. Decoupled Content & Presentation Invariant
- Visual presentation strictly adheres to the project's zero-backend and decoupled architecture:
  - Delta JSON remains 100% semantic text.
  - Template switching only updates the foreign key `entries.template_id` and visual painting, never modifying Delta tokens.

## Testing Decisions

### What Makes a Good Test
Tests must assert observable user-facing behavior and screen state rather than internal implementation details:
- Assert that tapping the date/mood/weather opens their respective selection sheets.
- Assert that empty entries show the Ghost Prompt, and tapping "由此题落墨" inserts the expected blockquote Delta into the controller.
- Assert that typing into the title and body triggers debounced autosave to SQLite.
- Assert that tapping `[Aa 字法]` reveals formatting actions, and applying formatting styles the text selection.
- Assert that the AppBar does not contain duplicated Soundscape, Typography, or Template action buttons.

### Modules Tested
1. **`EntryEditorScreen` (Widget Tests)**:
   - Full-bleed rendering with template styling.
   - Journal Letterhead rendering and interactions.
   - Ghost Prompt lifecycle (display, adopt, dismiss).
   - Writing Dock 5-tool presentation and formatting ribbon expansion.
   - AppBar minimalism and options menu dispatch.
2. **`EditorAutosaveManager` (Unit Tests)**:
   - Unified debounced autosave of title and Quill Delta.
   - Force-flush on demand.
   - FTS5 plain text synchronization.

### Prior Art
- `test/features/editor/entry_editor_screen_test.dart`
- `test/features/editor/editor_autosave_manager_test.dart`
- `test/features/timeline/entry_detail_screen_test.dart`

## Out of Scope
- Custom freehand stylus drawing engine (prohibited by core invariant; native OS handwriting input is reused).
- Cloud synchronization or remote analytics (prohibited by local-first $0 FOSS invariant).
- Modification of existing database tables or schema migrations (the existing `entries.title` column and `templates` table already satisfy all requirements).

## Further Notes
- Reuses existing [`TemplateCanvasPainter`](file:///home/harry1029/projects/memodiary/lib/features/templates/widgets/template_canvas_painter.dart) for vector paper texture, grid, and ruled lines at zero runtime asset cost.
- Preserves all sandboxed media isolation standards: images copied and compressed to WebP (≤1600px, 80%), videos restricted to ≤60s with generated poster frames.

