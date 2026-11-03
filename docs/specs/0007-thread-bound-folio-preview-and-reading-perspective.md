---
id: SPEC-007
title: Thread-Bound Folio Preview, Frontispiece Cover & Reading Perspective
status: planned
created_at: 2026-11-03T19:10:00+08:00
---

# Specification: Thread-Bound Folio Preview, Frontispiece Cover & Reading Perspective

## Problem Statement

When users tap on a diary entry from the personal timeline, the current detail viewer (`EntryDetailScreen`) produces a distorted, broken preview:

1. **Nested Paper Abstraction Clash**: The screen wraps entry content inside an opaque, rounded `XuanPaperCard` placed directly on top of `TemplateCanvasContainer`. This produces a jarring "paper card pasted on another paper canvas" effect that clips underlying ruling frames.
2. **Severe Dark Mode Theme Inversion**: The stationery template paints a bright cream/white paper canvas (`#FFFDF8`) with red rules, but `XuanPaperCard` dynamically pulls its background from theme tokens (`xuanPureLeaf` = `#242320`), floating a pitch-black box over white paper. Furthermore, Quill text typography defaults to near-black (`#212121`), collapsing contrast to ~1:1 against the dark card.
3. **Empty Draft Collapse**: Entries containing 0 words collapse into a giant dark void between the header and sign-off seal.
4. **Action Chrome Clutter & Duplication**: Secondary tools (PDF export, soft delete, template switcher, and entry lock) are duplicated across top app bar icons, popup menus, and bottom button bars.

A 2,832-line prototype demonstrated an authentic **Mobile Single-Page Thread-Bound Folio (手机单页线装展读台)** with 3D cylindrical page flips, 6-hole silk cord binding, reverse Xuan ink bleed-through, and brass corner protectors. However, its monolithic single-file structure and hardcoded character grids cannot directly support real-world Quill Delta rich text, media attachments, or SQLite template invariants.

## Solution

Overhaul the entry preview into an authentic, highly polished **Single-Page Thread-Bound Folio (`ThreadBoundFolioStage`)** paired with a non-destructive **Reading Perspective (`ReadingPerspective`)** engine:

1. **Physical Scholar's Desk & Thread-Bound Chassis**:
   - The stage rests on a dark walnut desk (`#0A0908`) with an ambient warm lamp vignette and floating dust motes.
   - The book chassis renders traditional 6-hole silk cord binding, antique brass corner protectors, stacked paper-block edge depth, and a physics-animated crimson silk ribbon bookmark.
   - Solves the dark mode conflict at the root: the desk is naturally dark, and the stationery is an authentic physical object.

2. **Ceremonial Frontispiece Cover (`FolioFrontispiecePage` · Page 0)**:
   - Opens every entry with an authentic cover leaf featuring the lunar date, solar term, weather, and mood.
   - **Artwork Mount**: Dynamically mounts the entry's hero photo with gold washi tape and silk corner mounts. If no photos exist, it renders a procedural seasonal landscape from the entry's **Scenery Realm** (Nature / Indoor Tea Hall / Market Street).
   - **Zero-Word Resilience**: Short or empty drafts display an elegant classical placeholder (*「此卷留白，静待泼墨」*), eliminating the empty void completely.

3. **Deterministic Folio Pagination Engine (`FolioPaginationEngine`)**:
   - Chunks Quill Delta into discrete integer-snapped paper leaves (14 horizontal lines or 10 vertical columns) without cutting words across page boundaries.
   - **Tipped-In Ephemera Leaves (`TippedInEphemeraLeaf`)**: Embedded photos and videos are rendered as dedicated full-leaf illustrations with paper borders, silk corner mounts, and captions.
   - Automatically attaches the animated Cinnabar Signature Seal and colophon to the final leaf.

4. **Reading Perspective (`展阅视角`) vs. Author's Intent**:
   - The preview defaults 100% faithfully to the entry's saved stationery template (`忠实原貌`), preserving paper texture, ruling lines, and fonts.
   - The bottom dock features a concise **`展阅视角 · Perspective`** drawer allowing ephemeral contemplation in alternative formats (`朱丝古刻` vermilion vertical, `原稿墨格` manuscript grid, `松烟夜卷` obsidian night).
   - Switching perspectives is strictly non-destructive and never mutates SQLite entry records.

5. **Consolidated Minimalist Chrome**:
   - **Top Bar**: Back navigation, centered diary title, and an Ambient Soundscape capsule paired with a single consolidated "More" (`...`) menu (Lock/Unlock, Export PDF, Plain Text Export, Soft Delete). All duplicate top-level icons are eliminated.
   - **Bottom Dock**: Three uncluttered actions (`展阅视角` Perspective, `分享` Share, `落墨修改` Edit Entry) with a subtle page counter indicator (`第 1 / 3 页`).

6. **Phased WYSIWYG Alignment**:
   - **Phase 1 (This Ticket)**: Overhaul the detail preview with the 11-module Thread-Bound Folio architecture.
   - **Phase 2 (Immediate Follow-up)**: Refactor `EntryEditorScreen` from an infinite scroll view to discrete pagination sheets with border navigation arrows (`<` `>`) and line-capacity auto-spill, establishing 1:1 parity between writing and previewing.

7. **Strict Modularity Invariant (< 350 LOC per file)**:
   - Decompose the 2,832-line prototype into 11 discrete, single-responsibility files under `lib/features/timeline/widgets/folio/` and `lib/features/timeline/screens/`. Zero reduction in visual fidelity, animation math, or tactile polish.

## User Stories

1. As a diarist tapping an entry card on the timeline, I want the entry to open into an authentic **Thread-Bound Folio** on a warm walnut scholar's desk, so that reading my diary feels like opening a physical heirloom rather than inspecting an app card.
2. As a diarist opening an entry, I want the first page to be a ceremonial **Frontispiece Cover** displaying the lunar date, solar term, weather, mood, and a center-mounted artwork, setting a serene tone before I read the text.
3. As a diarist whose entry has photo attachments, I want the first photo mounted on the Frontispiece Cover with gold washi tape and silk corner mounts, celebrating my captured visual memory.
4. As a diarist whose entry has no photos, I want the Frontispiece Cover to dynamically render an ink-wash landscape matching the entry's date, season, and **Scenery Realm** (Nature / Indoor Tea Hall / Market Street).
5. As a diarist opening an empty draft or 0-word entry, I want the Frontispiece Cover to gracefully display an elegant classical placeholder (*「此卷留白，静待泼墨」*), completely eliminating ugly empty dark voids.
6. As a diarist turning pages in the Folio, I want to experience 3D cylindrical page-turning physics (`Matrix4` perspective depth, specular arch highlights, and ambient occlusion cast shadow) by dragging the bottom-right dog-ear corner or tapping the screen border.
7. As a diarist flipping past a leaf, I want the reverse side of the turning page to reveal authentic **Xuan Paper Ink Bleed-Through** (`ink-bleed-ghost`), reinforcing the tangible materiality of Chinese paper arts.
8. As a diarist reading an entry with embedded photos or videos, I want media presented as dedicated **Tipped-In Ephemera Leaves** with paper-toned borders and classical silk mounts, rather than disrupting ruled text baselines.
9. As a diarist who composed an entry with a specific stationery template, I want the preview to default 100% faithfully to my saved template (`忠实原貌`), preserving my chosen paper texture, ruling lines, and typography.
10. As a diarist wishing to contemplate my diary in classical Chinese formats, I want a `展阅视角 · Perspective` button on the bottom dock that allows me to temporarily switch to `朱丝古刻` (Vermilion Vertical Columns), `原稿墨格` (Genkō Manuscript Grid), or `松烟夜卷` (Obsidian Gold Night) without altering my underlying diary.
11. As a diarist reviewing the preview UI, I want the top and bottom action bars to be clean, elegant, and devoid of duplicate icons or bloated flavor text.
12. As a diarist listening to ambient writing chimes, I want the top Ambient Soundscape capsule (`砚边琴韵`) to remain 1 tap away and pulse gently when playing.
13. As a diarist wishing to lock, export to PDF, or delete an entry, I want those actions consolidated cleanly inside a single "More" (`...`) menu without cluttering the main reading view.
14. As a diarist on any phone model (from small 360px displays to tall 20:9 screens), I want the book chassis to scale responsively with comfortable desk margins and zero `RenderFlex` overflow errors.
15. As a diarist reaching the final page of my entry, I want to witness the personalized **Cinnabar Signature Seal** land with an animated pop, shockwave ripple, and tactile haptic feedback.
16. As a diarist ready to continue writing, I want a prominent `落墨修改 · Edit Entry` button on the bottom dock that opens the entry editor directly.

## Implementation Architecture

```
lib/features/timeline/
├── screens/
│   └── entry_detail_screen.dart (delegates to / wraps ThreadBoundFolioScreen)
└── widgets/folio/
    ├── thread_bound_folio_screen.dart         (~250 LOC - Scaffold, desk surface, auto-hiding chrome, audio/DB integration)
    ├── folio_chassis_painter.dart             (~180 LOC - 6-hole silk cord binding, brass corners, stacked edges)
    ├── folio_silk_bookmark_painter.dart       (~70 LOC  - Crimson ribbon bookmark with spring rotation physics)
    ├── folio_substrate_painter.dart           (~120 LOC - Xuan paper fibers, Cold Gold flecks, breathing shimmer)
    ├── folio_silk_ruling_painter.dart         (~160 LOC - Vermilion vertical columns, genkō yōshi grid, horizontal rules)
    ├── folio_shanshui_art_painter.dart         (~220 LOC - Procedural ink landscapes: rain pavilion, crane ferry, tea courtyard)
    ├── folio_cinnabar_seal_widget.dart        (~150 LOC - Seal stamp landing pop, shockwave ripple ring, haptics)
    ├── folio_corner_curl_widget.dart          (~160 LOC - Dog-ear curl painter, hover expansion, interactive drag gesture tracking)
    ├── folio_3d_stage.dart                    (~320 LOC - Matrix4 cylindrical flip, specular arch lighting, reverse bleed-through)
    ├── folio_frontispiece_page.dart           (~260 LOC - Cover page with mounted photo/artwork, washi tape, metadata ribbon)
    ├── folio_content_leaf_page.dart           (~280 LOC - Paginated text rendering inside the integer-locked paper heart frame)
    ├── folio_reading_perspective_sheet.dart   (~140 LOC - Minimalist bottom sheet for non-destructive perspective switching)
    └── folio_pagination_engine.dart           (~220 LOC - Pure-Dart Quill Delta / text to folio pages tokenizer)
```

## Verification Plan

1. **Visual Parity Audit**:
   - Compare the overhauled screen against the prototype's HTML and Dart implementation.
   - Verify 3D cylindrical flip angle math, lighting specular arch, reverse ink bleed-through, and seal landing animation.
2. **Contrast & Theme Quarantine**:
   - Test preview in both Light and Dark system themes.
   - Verify that the walnut desk background maintains comfortable dark contrast, the paper leaf renders with authentic physical color, and text is 100% legible across all substrates.
3. **Quill Delta Pagination & Media Tipping**:
   - Test entries with 0 words (empty draft placeholder).
   - Test entries with short text (1 leaf).
   - Test entries with long text (> 500 words, multi-leaf pagination).
   - Test entries with image and video embeds (verifying dedicated `TippedInEphemeraLeaf` rendering).
4. **Action & Persistence Integrity**:
   - Verify `ReadingPerspective` switches are strictly non-destructive and do not mutate SQLite `templates` or `entries`.
   - Verify Edit, Share, PDF Export, Soft Delete, and Lock Entry actions function cleanly from the consolidated chrome.
5. **Responsiveness & Modularity Audit**:
   - Verify zero layout overflows on viewports down to 360px.
   - Run `code_style_audit_test.dart` to verify all files are under the modularity ceiling (< 450 LOC).

