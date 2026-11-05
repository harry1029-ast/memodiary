---
id: SPEC-009
title: Tactile Split Desk Architecture, Sheet-Paired Ephemera Overlay & Single-Page Folio Showcase
status: completed
created_at: 2026-11-04T20:45:00+08:00
---

# Specification: Tactile Split Desk Architecture, Sheet-Paired Ephemera Overlay & Single-Page Folio Showcase

## Problem Statement

On modern tall aspect-ratio mobile devices (20:9, 19.5:9), composing in the paginated entry editor presents a jarring visual disconnect when the software keyboard is dismissed: the integer-locked 14-row **Stationery Sheet** (`~380px`) floats isolated in the upper half of the screen, leaving a massive, lifeless whitespace void across the bottom half of the display.

Furthermore, attaching photographs and videos creates tension between calligraphy aesthetics and visual keepsakes:
1. **Media Squishing vs. Page Waste**: In the active editor, attaching a photo has historically either squished images into ruled text line grids or forced the allocation of an entire blank continuation leaf just to host a single photo, interrupting the diarist's flow of prose.
2. **Disconnected Memory Pairing**: Diarists have no clear visual association between the specific thoughts written on a given sheet and the photographs captured alongside that moment ($Sheet\ N \leftrightarrow Photo\ N$).
3. **Folio & PDF Parity Breakdown**: When an entry contains multiple photos, reading views and exported PDFs struggle to balance large-format artwork display with sacred 14-row calligraphy grids, either shrinking fonts or breaking the classical bookbinding rhythm.
4. **Intrusive Prompt Clutter**: Diarists seeking a serene, private writing sanctuary find unsolicited placeholder prompt banners ("Ghost Prompts") or empty wireframe boxes intrusive when writing pure-text entries.

## Solution

Implement the **Tactile Split Desk Architecture** in the active authoring editor and pair it with the **Single-Page Folio Adaptive Showcase & Ephemera Overlay System** in the reading preview and PDF export:

1. **Tactile Split Desk Architecture (Editor)**:
   - **Upper Zone**: The 14-row integer-locked **Stationery Sheet** (`StationerySheet` · ~380px) is dedicated strictly to pure prose and front-matter, preserving 100% mathematical parity with the **Thread-Bound Folio** and vector PDF export.
   - **Lower Zone (Media & Keepsake Tray)**: The lower half of the scholar's desk mat houses a tactile **Media & Keepsake Tray** (`StationeryMediaTray`) displaying up to 3 photos/videos attached to the active sheet in an elegant horizontal snap-deck with paper matte framing, silk corner mounts, and caption display.
   - **Adaptive Scholar Centering (Text-Only Sheets)**: When a sheet has zero attached photos, the 14-row stationery card automatically centers vertically on the desk mat with the diarist's **Cinnabar Signature Seal** resting quietly below it. All intrusive "Ghost Prompts" and empty placeholder cards are eliminated.
   - **Auto-Collapsing Keyboard Dynamics**: When the software keyboard opens, the lower media tray smoothly slides downward beneath the keyboard; the 14-row writing card remains 100% stationary and non-scrolling, guaranteeing rock-solid typing stability and zero IME focus jitter.

2. **Single-Page Folio Preview & Ephemera Overlay (Reader & PDF)**:
   - **Page 1: Entry Cover (扉页画笺 · Adaptive Showcase)**: Dynamically synthesizes all $N$ photos attached across all content sheets into an authentic Chinese/Japanese album mounting layout:
     - **$N = 1$ (单幅立轴画心)**: Single full-height hero artwork with silk borders, brass pin, and centered caption.
     - **$N = 2$ (双屏对幅册页)**: Symmetrical 50/50 vertical diptych with individual silk borders and page tags (`P1·上卷`, `P2·下卷`).
     - **$N = 3$ (三景斗方拼贴)**: Asymmetrical album collage (60% hero leaf on left, two 40% stacked miniature leaves on right).
     - **$N \ge 4$ (主景画心 + 拾光集锦匣封套)**: Top 60% hero artwork ($P1$) + Bottom 40% stationery pocket sleeve container (*集锦匣*) with brocade header, photo counter badge, and fanned overlapping photo cards.
     - **Photo Sleeve Overview Drawer (`画匣总览`)**: Tapping the sleeve opens a full modal reel of all attached photos with capture dates, captions, and one-tap jump buttons to the corresponding diary page.
   - **Pages 2..N: Content Leaves (边角随文影札 · Ephemera Overlay)**:
     - Each subsequent content page mounts its paired photo as a non-destructive **Polaroid Mini-Card** (`~64px`–`72px`, aspect ratio ~3:4) in the **Ephemera Overlay Layer** above the paper substrate, preserving 100% of the underlying 14-row text grid.
     - Styled with an aged cream paper border, subtle drop shadow, antique brass paperclip, and gold washi tape corner strip.
     - If a sheet has 2–3 photos, renders an overlapping **fanned stack** pinned by a single brass clip.
     - **Zero-Obstruction Smart Anchoring**: Defaults to the **Top-Left corner** for vertical Right-to-Left scripts (`朱丝栏`), and **Bottom-Left corner** for horizontal scripts (`乌丝栏`).
     - **Interactive Mechanics**: Freeform drag-and-move anywhere on the leaf; tap-to-expand into Fullscreen Lightbox; snap-back reset button (`↺`) to restore smart corner; hide/restore toggle (`✕` / `👁️ 隐藏微笺`).
     - **Permanent Scrapbook Persistence**: User custom drag coordinates are permanently saved as normalized ratios (`overlay_x_ratio`, `overlay_y_ratio` from `0.0` to `1.0`) in SQLite `media_attachments`, rendering identically across reloads and vector PDF export.

## User Stories

1. As a diarist opening the editor on a modern tall smartphone, I want the screen designed as a scholar's writing desk with balanced tactile proportions, so that the canvas never feels like an awkward small box surrounded by dead white space.
2. As a diarist writing a pure-text entry with no photos, I want the 14-row **Stationery Sheet** centered gracefully on the desk screen with my **Cinnabar Signature Seal** resting quietly below it, so the page looks balanced, serene, and intentional.
3. As a diarist seeking a quiet personal writing sanctuary, I want unsolicited "Ghost Prompts" and artificial prompt suggestion cards removed, so my writing space remains completely private and undisturbed.
4. As a diarist attaching a photo to my active sheet via the **Writing Dock**, I want the 14-row text card to smoothly shift to the upper dock while the photo mounts into a dedicated **Media & Keepsake Tray** in the lower desk area, so my photo and words are presented harmoniously without squishing text lines.
5. As a diarist attaching a second or third photo to the same moment on Sheet 1, I want the lower **Media & Keepsake Tray** to present the photos as a smooth horizontal snap-deck with indicator dots, so I can capture multiple perspectives without being forced to create empty continuation text sheets.
6. As a diarist focusing on typing with photos attached, I want the lower **Media & Keepsake Tray** to smoothly slide downward beneath the software keyboard when the keyboard opens, so the upper 14-row writing card remains 100% stationary and non-scrolling.
7. As a diarist dismissing the software keyboard after typing, I want the lower **Media & Keepsake Tray** to glide smoothly back into view beneath the text card without any visual jarring or layout jump.
8. As a diarist tapping any photo in the editor's lower tray, I want it to expand seamlessly into a distraction-free **Fullscreen Lightbox** with pinch-to-zoom and full playback controls, so I can inspect captured details in high resolution without leaving the editor.
9. As a diarist typing past row 14 of Sheet 1 (which has an attached photo), I want **Auto-Spill** to advance seamlessly to Sheet 2 while keeping Photo 1 locked to Sheet 1, with Sheet 2 starting fresh in the centered text-only layout.
10. As a diarist opening a saved diary entry with 1 photo in the **Thread-Bound Folio**, I want Page 1 (Entry Cover) to display a single full-height hero artwork mounted with silk margins, an antique brass pin, and a centered caption strip.
11. As a diarist opening an entry with 2 photos in the **Thread-Bound Folio**, I want Page 1 (Entry Cover) to render a symmetrical 50/50 vertical diptych split with individual silk borders and independent page-tag badges (`P1·上卷`, `P2·下卷`).
12. As a diarist opening an entry with 3 photos in the **Thread-Bound Folio**, I want Page 1 (Entry Cover) to render an asymmetrical album collage with a 60% hero card on the left and two 40% stacked miniature leaves on the right.
13. As a diarist opening an entry with 4 or more photos in the **Thread-Bound Folio**, I want Page 1 (Entry Cover) to display the primary hero artwork in the top zone and a traditional stationery pocket sleeve (*集锦匣*) in the bottom zone with a counter pill (`📷 拾光画匣 · 已收录 N 枚随文影札`) and a fanned spread of overlapping photo cards.
14. As a diarist browsing the Page 1 pocket sleeve (*集锦匣*), I want clicking the sleeve to open the **Photo Sleeve Overview Modal (`画匣总览`)** with a complete visual reel of all photos, capture dates, captions, and one-tap jump buttons to their corresponding content pages.
15. As a diarist reading Content Page 2 in the **Thread-Bound Folio**, I want the photo attached to Sheet 1 rendered as a tactile **Polaroid Mini-Card** pinned to the page's whitespace corner with an aged paper border, antique brass paperclip, and gold washi tape.
16. As a diarist reading in vertical script mode (`朱丝栏`), I want the Polaroid mini-card anchored by default to the Top-Left whitespace corner, safely away from Right-to-Left text columns and the bottom-left seal.
17. As a diarist reading in horizontal script mode (`乌丝栏`), I want the Polaroid mini-card anchored by default to the Bottom-Left whitespace corner, opposite the bottom-right date and colophon.
18. As a diarist reviewing a content page where a photo was attached to that sheet, I want to freely touch and drag the mini-card to any position on the page, so I can reveal characters beneath it or arrange my keepsake collage manually.
19. As a diarist who dragged a mini-card, I want a small circular snap-back reset button (`↺`) to appear on the card, allowing me to return it to the smart default corner with a smooth spring animation.
20. As a diarist desiring an unencumbered reading view of the calligraphy, I want to tap the `✕` button on the mini-card to hide it with a subtle fade-and-scale effect, with a persistent top margin pill (`👁️ 隐藏微笺 / 📌 展开微笺`) available to restore it at any time.
21. As a diarist reading a content page with 2 or 3 attached photos, I want the mini-cards rendered as an overlapping fanned stack pinned together by a single brass clip with a page counter pill (`1/3`), tapping which opens the fullscreen lightbox carousel.
22. As a diarist customizing mini-card positions, I want my custom drag coordinates saved permanently in the local SQLite database, so my bespoke layout is remembered on every app launch and faithfully preserved in exported vector PDFs.
23. As a diarist exporting an entry to vector PDF, I want Page 1 to render the adaptive multi-image cover showcase and content pages to render the exact 14-row calligraphy layout with the pinned Polaroid mini-card at its saved coordinates.

## Implementation Decisions

### 1. Module Modifications & Elevation
- **Elevate Option A into Production `EditorPaperCanvas`**:
  - Replace the temporary prototype switcher in `EditorPaperCanvas` with the permanent **Split Desk Architecture**.
  - Deprecate `PrototypeVariantSwitcher`, `BreathingStrideCanvas`, and `ScreenAdaptiveCanvas`.
  - Maintain all existing freeze-prevention guarantees: deletion-gated continuation sheet collapse, focus-guarded metric synchronization, and post-frame navigation.
- **New Module: `StationeryMediaTray`**:
  - Located in `lib/features/editor/widgets/stationery_media_tray.dart`.
  - Responsible for rendering the lower desk keepsake container when photos/videos are attached to the active sheet.
  - Supports horizontal snap-scrolling for up to 3 media items with pagination dots, paper-toned matte styling, silk corner mounts, and tap-to-fullscreen lightbox.
- **Folio Enhancements: `FolioFrontispiecePage` & `FolioAdaptiveCoverShowcase`**:
  - Refactor `FolioFrontispiecePage` to dynamically delegate artwork rendering to `FolioAdaptiveCoverShowcase` based on total attachment count $N$ ($N=1, 2, 3, \ge 4$).
  - Implement `FolioPhotoSleeveModal` for the $N \ge 4$ pocket sleeve overview drawer.
- **Folio Content Leaves: `PolaroidMiniCardOverlay`**:
  - In `lib/features/timeline/widgets/folio/polaroid_mini_card_overlay.dart`.
  - Injected into `FolioContentLeafPage` as an overlay widget positioned via `Positioned` within the leaf bounds.
  - Handles gesture recognition (tap vs. pan), normalized coordinate computation, snap-back reset animation, and hide/restore state.

### 2. Schema Decisions (SQLite & Drift)
- Extend the `media_attachments` table with two optional normalized coordinate columns:
  - `overlay_x_ratio` (`REAL NULL`): Clamped between `0.0` and `1.0`, representing the horizontal anchor offset relative to page width.
  - `overlay_y_ratio` (`REAL NULL`): Clamped between `0.0` and `1.0`, representing the vertical anchor offset relative to page height.
- Default value is `NULL`, indicating that the client should compute the zero-obstruction smart default corner (Top-Left for vertical, Bottom-Left for horizontal).
- When the user drags the card, the new normalized ratio is written back to SQLite via `AppDatabase.updateMediaAttachmentOverlayPosition(id, xRatio, yRatio)`.
- Resetting via `↺` restores the values to `NULL`.

### 3. Data Flow & Interface Contracts

```dart
/// Normalized placement descriptor for a pinned ephemera mini-card on a Folio leaf
class EphemeraOverlayPlacement {
  final double? xRatio; // null = use smart default anchor
  final double? yRatio; // null = use smart default anchor
  final bool isHidden;

  const EphemeraOverlayPlacement({
    this.xRatio,
    this.yRatio,
    this.isHidden = false,
  });

  bool get isCustomPositioned => xRatio != null && yRatio != null;
}
```

```dart
/// Signature for media attachment update
abstract class MediaAttachmentRepository {
  Future<void> updateOverlayPlacement({
    required int attachmentId,
    required double? xRatio,
    required double? yRatio,
  });
}
```

### 4. Mathematical Geometry & Layout Invariants
- **Upper Stationery Card**: Height is locked to `innerFrameRect.bottom + 16.0px` with `maxRows: 14`. Row height is `24.0px` (or active template stride).
- **Text-Only Adaptive Centering**: When active sheet has 0 attachments:
  $$\text{topOffset} = \frac{\text{canvasHeight} - \text{cardHeight} - \text{sealHeight}}{2}$$
  The card and seal are vertically centered as a unified classical unit.
- **Split Desk Top Docking**: When active sheet has $\ge 1$ attachments:
  - Card top margin is clamped to `12.0px`.
  - Media tray occupies the remaining vertical space between card bottom and bottom navigation dock:
    $$\text{trayHeight} = \text{canvasHeight} - \text{cardBottom} - \text{dockHeight} - 16.0\text{px}$$
- **Keyboard Motion Curve**: Animated using `AnimatedCrossFade` and `AnimatedPositioned` with a `250ms` duration and `Curves.easeOutCubic`.

## Testing Decisions

### What Makes a Good Test
- **Behavioral & Black-Box Only**: Tests must verify observable widget rendering, layout positioning, touch gestures, and state changes. Tests must never inspect private controller variables or internal implementation details.
- **No Flaky Sleep Timers**: All animations and post-frame callbacks must be pumped deterministically using `tester.pumpAndSettle()`.

### The Primary Testing Seams
1. **Editor Authoring Seam (`EntryEditorScreen` / `EditorPaperCanvas`)**:
   - **Text-Only Centering Test**: Mount an editor with 0 photos; verify that the `StationerySheet` is vertically centered and `CinnabarSignatureSeal` is rendered below it without any ghost prompt containers.
   - **Attachment Mounting Test**: Attach 1, 2, and 3 photos; verify that the text card docks to top, the `StationeryMediaTray` mounts with the correct item count and horizontal snap behavior.
   - **Keyboard Toggle Simulation**: Trigger software keyboard appearance; verify that the `StationeryMediaTray` collapses and the text card remains fully visible without scrolling.
   - **Auto-Spill Integrity**: Rapidly type past line 14 on Sheet 1 (with attached photo); verify Sheet 2 allocates, cursor moves to Sheet 2, Photo 1 remains on Sheet 1, and the editor remains 100% interactive without freezing.
2. **Reading Preview Seam (`ThreadBoundFolioScreen` / `Folio3DStage`)**:
   - **Adaptive Cover Test**: Load entries with $N=1, 2, 3, 4$ photos; verify that Page 1 selects the corresponding layout variant (立轴, 对幅, 斗方, 集锦匣).
   - **Ephemera Overlay Test**: Load Content Page 2; verify `PolaroidMiniCardOverlay` mounts at the correct default corner without obstructing text.
   - **Drag & Snap Reset Test**: Perform a drag gesture on the mini-card; verify its position updates, the `↺` button appears, and tapping `↺` animates the card back to the default anchor.
   - **Persistence Test**: Drag the mini-card, exit the screen, re-open; verify that the custom coordinates persist from SQLite.

### Prior Art
- `test/features/editor/paper_heart_freeze_repro_test.dart`: Complete harness for keyboard entry auto-spill and navigation.
- `test/features/editor/paginated_editor_ephemera_and_folio_test.dart`: End-to-end integration test verifying attachment synchronization between editor and Folio preview.

## Out of Scope
- Freehand stylus drawing or vector handwriting recognition on the Polaroid card.
- Third-party cloud photo backup or remote image hosting ($0 build & runtime cost invariant).
- Video attachments exceeding the 60-second sandboxed video limit.
- Automatic AI object segmentation or cloud face-cropping.

## Further Notes
- **Zero Third-Party Cost**: Implemented using Flutter vector painters (`CustomPainter`), standard gesture detectors, and local SQLite SQLCipher storage.
- **Code Style Audit**: All new files must strictly adhere to the project ceiling of `< 450` LOC per file and zero single-letter variables in lambdas.

