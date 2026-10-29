# MemoDiary (拾光日记)

Personal offline-first diary and travel keepsake application with classical Chinese ink-and-paper aesthetics.

## Language

**Shanshui Scenery Card**:
The animated Chinese ink-wash landscape header card displayed on the Personal Diary timeline, rendering mountains, waters, pavilions, and dynamic seasonal/weather atmospheres.
_Avoid_: Weather banner, thought spark card, landscape widget

**Thought Spark Dock**:
The semi-transparent Xuan-paper bottom overlay docked on the Shanshui Scenery Card, presenting the rotating reflective writing prompt and the "由此题落墨" action.
_Avoid_: Prompt banner, inspiration card

**Contemplation View**:
The full-screen interactive modal displaying the complete 3:2 living Shanshui painting with touch ripples, calligraphy colophon, and atmospheric controls.
_Avoid_: Fullscreen canvas, scenery dialog, zoom view

**Photobook Document**:
The canonical document model (`AlbumStudioDocument`) representing an editable travel photobook, containing ordered studio pages, layout slot assignments, background styling, and unplaced photo tray references.
_Avoid_: Album spread list, photobook layout JSON, scrapbook model

**Photobook Spread**:
A two-page visual unit (`BookSpreadData`) representing facing leaves in the overview feed, flipbook viewer, and bound PDF export, flanked by Front Cover and Epilogue colophon bookends.
_Avoid_: AlbumSpread, spread pair
