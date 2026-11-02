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

**Scenery Realm**:
The spatial setting dimension (`ShanshuiRealm`) rendered inside the Shanshui Scenery Card and Contemplation View across three classical domains: **Nature** (`nature` · 林泉 wilderness), **Indoor** (`indoor` · 雅室 scholar tea hall), and **Outdoor** (`outdoor` · 市井 ancient market street), either inferred automatically from recent accessible entries (`随文入境`) or pinned manually by the diarist.
_Avoid_: Scene mode, location theme, indoor/outdoor toggle

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

**Scholar's Stationery Chest**:
The bottom modal drawer (`ScholarChestDrawer`) modeled after an antique Chinese scholar's brocade box with crimson velvet lining, consolidating the diarist's secondary writing tools into tangible physical artifacts.
_Avoid_: Tools drawer, utility tray, stationery menu, bottom sheet modal

**Stationery Artifact**:
An interactive skeuomorphic vector control inside the Scholar's Stationery Chest representing a functional subsystem (Fanned Stationery, Porcelain Brush Mountain, Guqin Zither, Brass Fish Lock, and Twin Brushes placeholder).
_Avoid_: Drawer button, tool icon, chest item

**Integer-Row Height Snapper**:
The deterministic layout mechanism (`GridSnappedEmbedContainer`) that clamps media embed heights and margins to integer multiples of `rowHeight` ($H_{\text{total}} = N \times \text{rowHeight}$), mathematically protecting ruled baseline alignment across insertions.
_Avoid_: Image padding adjuster, grid snap wrapper

**Tipped-In Ephemera Card**:
The physical photographic print presentation style for image and video embeds in classical stationery, featuring paper-toned matte borders, soft drop shadows, and inline video playback.
_Avoid_: Media box, photo embed container, image card

**Keepsake Scroll View**:
The read-only full-screen presentation mode that renders diary entries in classical right-to-left columnar calligraphy (`vertical-rl`) with decorative colophons and seals.
_Avoid_: Vertical reader, print preview screen, calligraphy viewer

**Cinnabar Signature Seal**:
The diarist's personalized 2–4 character colophon stamp whose text is a persistent user signature, rendered in relief (朱文) or intaglio (白文) according to the active stationery template.
_Avoid_: Signature stamp, red seal widget, colophon watermark

**Paper Heart**:
The strictly bounded, integer-snapped rectangular area (`innerFrameRect` · 版心) within the Journal Sheet that encloses all ruling geometries and text flow, isolating content from Heaven and Earth margins.
_Avoid_: Text viewport, inner canvas, content area

**Heaven and Earth Margins**:
The traditional top (Heaven · 天头, $\ge 52\text{px}$) and bottom (Earth · 地脚, $\ge 44\text{px}$) border zones flanking the Paper Heart, reserving dedicated structural space for front-matter and colophons without introducing fractional phase shifts into line strides.
_Avoid_: Header padding, footer margin, canvas insets

**Double Outer Border**:
The classical stationery framing format (`文武双栏` / 四周双栏) composed of an outer heavier stroke and inner lighter stroke enclosing the Paper Heart, preventing ruling lines from bleeding to screen edges.
_Avoid_: Canvas border, frame border, sheet outline

**Interlinear Sub-Note**:
The classical Chinese annotation format (`双行夹注` · Jiāzhù) rendering commentary as two parallel sub-columns of small-scale characters within a single column stride, parsed from `{夹注:...}` syntax.
_Avoid_: Side note, footnote, inline comment
