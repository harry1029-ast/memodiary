# Thread-Bound Folio Preview & Reading Perspective

## Context
The legacy diary detail viewer (`EntryDetailScreen`) suffered from three major design and architectural breakdowns:
1. **Nested Paper Abstraction Clash**: The screen wrapped diary content in an opaque `XuanPaperCard` on top of a `TemplateCanvasContainer` stationery canvas, creating a jarring "card floating on paper" sticker effect.
2. **Dark Mode Inversion Breakdown**: The stationery canvas rendered in light physical paper colors, but the card's background resolved dynamically to dark charcoal (`xuanPureLeaf` = `#242320`), floating a pitch-black box over white ruled paper, while hardcoded text typography (`#212121`) collapsed contrast to unreadable levels.
3. **Empty Entry Collapse**: Entries with 0 words collapsed into a giant dark void between the header and sign-off seal.
4. **Action Chrome Clutter**: Secondary utilities (PDF Export, Delete, Template switching, Lock) were duplicated across app bar icons, popup menus, and bottom button bars.

A web and Flutter prototype introduced the **Mobile Single-Page Thread-Bound Folio (手机单页线装展读台)**, delivering an authentic Chinese 6-hole silk thread-bound volume, 3D cylindrical page flips, reverse Xuan ink bleed-through, brass corner protectors, and an animated cinnabar seal. However, the prototype was a monolithic 2,832-line single file with hardcoded character matrices that could not accommodate real-world Quill Delta rich text, media embeds, or SQLite template invariants.

## Decision
We restructure the diary entry preview around the **Single-Page Thread-Bound Folio (单页线装展读台)** and an ephemeral **Reading Perspective (展阅视角)** system:

1. **Physical Scholar's Desk & Thread-Bound Chassis**:
   - The presentation metaphor transitions to a scholar's walnut desk (`#0A0908`) with ambient lamp glow.
   - The book chassis renders traditional 6-hole silk cord binding, antique brass corner protectors, stacked paper-block edges, and a physics-animated crimson silk bookmark ribbon.
   - Solves the dark mode conflict: the desk is naturally dark, and the paper is an authentic physical object.

2. **Ceremonial Frontispiece Cover (扉页封面 · Page 0)**:
   - Every diary entry opens with a museum-grade cover leaf featuring the lunar date, solar term, weather, and mood.
   - **Artwork Mount**: Dynamically mounts the entry's hero photo with gold washi tape and silk corner mounts. If no photos exist, it renders a procedural landscape matching the entry's seasonal **Scenery Realm** (Nature / Indoor / Market).
   - **Zero-Word Resilience**: Short or empty drafts display an elegant classical placeholder (*「此卷留白，静待泼墨」*), eliminating empty voids.

3. **Deterministic Folio Pagination Engine (`FolioPaginationEngine`)**:
   - Chunks Quill Delta into discrete integer-snapped paper leaves (14 horizontal lines or 10 vertical columns) without splitting words or characters across page boundaries.
   - **Tipped-In Ephemera Leaves (贴片插页)**: Photo and video attachments are rendered as dedicated full-leaf illustrations with paper borders and captions, preserving clean text pagination.
   - Attaches the animated Cinnabar Signature Seal and colophon to the final leaf.

4. **Reading Perspective (`展阅视角`) vs. Author's Intent**:
   - The preview defaults 100% faithfully to the entry's saved stationery template (`忠实原貌`), preserving paper texture, ruling lines, and fonts.
   - The bottom dock features a concise **`展阅视角 · Perspective`** drawer allowing ephemeral contemplation in alternative formats (`朱丝古刻` vermilion vertical, `原稿墨格` manuscript grid, `松烟夜卷` obsidian night).
   - Switching perspectives is strictly non-destructive and never mutates SQLite entry records. Minimalist labels avoid verbose flavor text.

5. **Consolidated Minimalist Chrome**:
   - **Top Bar**: Back button, centered diary title, and an Ambient Soundscape capsule paired with a single consolidated "More" (`...`) menu (Lock/Unlock, Export PDF, Plain Text Export, Soft Delete). All duplicate top-level icons are eliminated.
   - **Bottom Dock**: Three uncluttered actions (`展阅视角` Perspective, `分享` Share, `落墨修改` Edit Entry) with a subtle page counter indicator (`第 1 / 3 页`).

6. **Phased WYSIWYG Alignment**:
   - **Phase 1 (Current)**: Overhaul the detail preview with the 11-module Thread-Bound Folio architecture.
   - **Phase 2 (Immediate Follow-up)**: Refactor `EntryEditorScreen` from an infinite scroll view to discrete pagination sheets with border navigation arrows (`<` `>`) and line-capacity auto-spill, establishing 1:1 parity between writing and previewing.

7. **Strict Modularity Invariant (< 350 LOC per file)**:
   - Decompose the 2,832-line prototype into 11 discrete, single-responsibility files under `lib/features/timeline/widgets/folio/` and `lib/features/timeline/screens/`. Zero reduction in visual fidelity, animation math, or tactile polish.

## Consequences
- **Total Aesthetic Immersion**: Replaces a broken, generic card preview with an heirloom-grade thread-bound volume.
- **Flawless Dark Mode**: Completely eliminates white-on-black or black-on-white inversion bugs.
- **Architectural Modularity**: Keeps all files comfortably below the 450-line ceiling, eliminating AI streaming timeouts and keeping raster performance at 60 FPS.
- **Zero Schema Disruption**: Operates entirely on existing `entries`, `templates`, and `media_attachments` tables without migrations.

