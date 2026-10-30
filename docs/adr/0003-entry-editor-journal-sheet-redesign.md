# Entry Editor Redesign onto Full-Bleed Journal Sheet & Minimalist Writing Dock

## Context
The previous diary editor (`EntryEditorScreen`) suffered from visual fragmentation, toolbar sprawl, and an unauthentic journal experience:
1. **Visual "Sandwich" Fragmentation**: In Dark Mode, a pitch-black AppBar and metadata strip framed an intrusive dark Thought Spark card, followed by a stark white inner rectangular paper container (`TemplateCanvasContainer`), and capped by a dark bottom bar. The writing surface felt like an embedded web form rather than a physical journal notebook.
2. **Control Sprawl & Duplication**: Soundscapes (🎧), Typography (A), and Templates were duplicated across both the AppBar and bottom toolbar, resulting in over 18 competing buttons and cognitive friction during writing.
3. **Thought Spark Intrusion**: A 150px persistent banner card pushed the writing canvas down by a third of the screen, breaking contemplation and feeling like an in-app banner ad.
4. **Scattered Metadata Form**: Entry date, weather, mood, and time capsule controls were rendered as clinical software button pills isolated outside the writing page.

## Decision
We redesign `EntryEditorScreen` onto a cohesive, distraction-free literati journal architecture:

1. **Full-Bleed Journal Sheet (素笺全展)**:
   - The paper canvas extends across the entire screen viewport. The status bar, navigation bar, and scaffold dynamically inherit the active template's background color, texture, and text contrast.
   - Eliminates rectangular inset boxes and letterboxing across both Light and Dark OS modes.

2. **In-Paper Journal Letterhead (笺头题签)**:
   - Replaces the external metadata button strip with an authentic journal letterhead rendered directly on the upper lines of the Journal Sheet.
   - Displays the entry date and day of the week in Kaiti serif (`yyyy年M月d日 星期X · 节气`), flanked by subtle inline mood and weather emblems with quiet bottom-sheet selectors.
   - Introduces an optional borderless stationery title line (`题名 · Title...`) styled as a handwritten chapter heading.

3. **In-Line Ghost Prompt (笺上隐题)**:
   - Completely removes the persistent 150px `ThoughtSparkBanner` container.
   - When the journal sheet is empty, the inspirational reflection prompt appears as an elegant italicized placeholder directly inside the writing area (`“今天最让你心动或者难忘的一瞬间是什么？” 提笔落墨...`).
   - Writers can tap a subtle in-line "由此题落墨 · Adopt Prompt" action to quote the spark into the entry, or simply begin typing, causing the ghost prompt to naturally vanish.

4. **Progressive Writing Dock (文房雅具)**:
   - Replaces the 15+ button scrollbar with a clean 5-tool dock docked above the keyboard:
     1. `[Aa 字法]` (Formatting drawer toggle)
     2. `[📷 拓影]` (Sandboxed photo insertion)
     3. `[🎥 短影]` (Sandboxed short video insertion)
     4. `[🎙️ 听写]` (Speech-to-text dictation)
     5. `[✨ 灵感]` (Cycle or reveal Ghost Prompt)
   - Tapping `[Aa 字法]` expands an inline formatting ribbon (Bold, Italic, Underline, H1, H2, Blockquote, Bullet list, Numbered list) directly attached to the dock.

5. **Pared-Down Minimalist AppBar**:
   - Strips duplicated actions (Soundscapes, Typography, Templates) from the top bar.
   - Retains only: `[← Back]` (auto-saves draft), a discreet low-contrast autosave status indicator (`已保存 / 存墨中`), a Cinnabar Seal `[✓ 封卷]`, and an options overflow menu `[···]` for secondary stationery settings (Templates, Typography, Time Capsule, Soundscapes).

6. **Unified Autosave Synchronization**:
   - `EditorAutosaveManager` manages both Quill Delta/plain text and the entry title controller, debouncing updates (2s) to SQLite's `entries` table and `entries_fts` search index.

## Consequences
- **True Journal Immersion**: The device screen authentically embodies physical stationery, fostering mindful, distraction-free journaling.
- **Ergonomic Clarity**: Touch targets during writing are reduced from 18+ scattered buttons to 5 high-frequency thumb-accessible actions.
- **Content-Presentation Decoupling**: Strictly preserves the database invariant: Delta JSON remains pure while visual styling seamlessly follows the active template.
- **Backward Compatibility**: Fully compatible with existing templates, media attachments, and time-capsule locks.
