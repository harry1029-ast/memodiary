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

**Journal Sheet**:
The full-bleed writing canvas in the entry editor where the chosen template background, paper texture, ruled lines, and typography fill the entire viewport without letterboxing or floating card containers.
_Avoid_: Editor box, paper card, canvas container

**Journal Letterhead**:
The typographic header rendered directly onto the top of the Journal Sheet, presenting the entry date, weather, and mood as authentic diary stationery front-matter with tap-to-modify interactions.
_Avoid_: Metadata bar, metadata chips, entry header strip

**Ghost Prompt**:
The subtle inspirational thought cue rendered as placeholder text directly inside the empty Journal Sheet, disappearing naturally upon user input and rotatable on demand without occupying persistent vertical container space.
_Avoid_: Thought spark container, prompt banner, inspiration card

**Writing Dock**:
The consolidated, de-duplicated bottom toolbar in the entry editor providing contextual rich-text formatting, media attachments, and ambiance controls in a single streamlined dock.
_Avoid_: Editor toolbar, formatting strip, action bar

**Photo Text Match**:
A search result record (`PhotoTextMatch`) sourced from `media_fts` representing text recognized inside an entry attachment or album photo, paired with normalized line bounding boxes and parent context.
_Avoid_: OCR hit, image search result, reverse image match

**OCR Sentinel**:
The explicit empty marker (`ocr_text = ''` and `ocr_blocks_json = '[]'`) persisted when an image contains zero recognizable text or cannot be decoded, distinguishing already-scanned photos from unindexed (`NULL`) photos.
_Avoid_: Null OCR result, empty scan flag

**Backfill Indexer**:
The user-triggered, pauseable/resumable maintenance routine (`OcrQueueManager.runBackfill`) that scans historical unindexed photos (`ocr_text IS NULL`) sequentially without blocking launch or UI frames.
_Avoid_: Background library scanner, batch OCR job
