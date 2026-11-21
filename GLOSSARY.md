# MemoDiary (云皓日记)

Personal offline-first diary and travel keepsake application with classical Chinese ink-and-paper aesthetics.

## Language

**Shanshui Scenery Card**:
The animated Chinese ink-wash landscape header card displayed on the Personal Diary timeline, rendering mountains, waters, pavilions, and dynamic seasonal/weather atmospheres.
_Avoid_: Weather banner, thought spark card, landscape widget

**Bamboo Blind Pull-Cord**:
The hanging braided silk cord and tassel (竹帘流苏拉绳) on the Shanshui Scenery Card that unrolls the slatted bamboo blind (湘妃竹帘) to collapse the scenery window into a slim bamboo-slat bar.
_Avoid_: Collapse chevron, window toggle, curtain button

**Contemplation View**:
The full-screen interactive modal displaying the complete 3:2 living Shanshui painting with touch ripples, calligraphy colophon, and atmospheric controls.
_Avoid_: Fullscreen canvas, scenery dialog, zoom view

**Scenery Realm**:
The spatial setting dimension (`ShanshuiRealm`) rendered inside the Shanshui Scenery Card and Contemplation View across three domains—**Nature** (`山水`), **Indoor** (`室内`), and **Outdoor** (`街市`)—either inferred automatically from recent entries (`自动`) or pinned manually by the diarist.
_Avoid_: Scene mode, location theme, indoor/outdoor toggle, 随文入境, 林泉, 雅室, 市井

**Atmosphere Theme**:
The paired light-and-dark visual palette (`主题风格`) governing the app's woodwork, desk surfaces, and UI chrome—preset as **Yunhao** (`云皓`: `云岚昼` / `皓月夜`), **Classic** (`经典`: `宣纸胡桃` / `碑拓乌木`), or **Custom** (`自定义`: pairing any light palette `云岚昼`, `宣纸胡桃`, `淡墨暮岚` with any dark palette `皓月夜`, `碑拓乌木`, `清辉烟雨`, `花影灯火`). Orthogonal to system Appearance Mode (`跟随系统 / 浅色模式 / 深色模式`), the window's procedural Scenery Realm (`山水 / 室内 / 街市`), and entry stationery templates.
_Avoid_: Color skin, window theme, single-mode theme

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
The typographic header rendered directly onto the top of the Journal Sheet, presenting the entry date, weather, and mood as authentic diary stationery front-matter with tap-to-modify interactions. It always spans exactly four ruled rows at the top of the opening sheet's Paper Heart, whatever the row height, so its height is known before anything is drawn.
_Avoid_: Metadata bar, metadata chips, entry header strip

**Ghost Prompt**:
The subtle inspirational thought cue rendered as placeholder text directly inside the empty Journal Sheet, disappearing naturally upon user input and rotatable on demand without occupying persistent vertical container space.
_Avoid_: Thought spark container, prompt banner, inspiration card

**Writing Dock**:
The resting-desk bottom toolbar in the entry editor providing an expandable rich-text formatting ribbon, media collection, dictation, and thought sparks; collapsible to a brass restore tab and yielding to the Keyboard Accessory Row while typing.
_Avoid_: Editor toolbar, formatting strip, action bar

**Keyboard Accessory Row**:
The slim tool row resting directly above the open software keyboard in place of the Writing Dock, presenting the formatting ribbon toggle (`Tt`), dictation, and Writing Dock visibility control without disturbing writing focus. Its formatting ribbon openness stays unified with the Writing Dock across keyboard transitions.
_Avoid_: Input accessory bar, keyboard toolbar, quick bar

**Photo Text Match**:
A search result record (`PhotoTextMatch`) sourced from `media_fts` representing text recognized inside an entry attachment or album photo, paired with normalized line bounding boxes and parent context.
_Avoid_: OCR hit, image search result, reverse image match

**OCR Sentinel**:
The explicit empty marker (`ocr_text = ''` and `ocr_blocks_json = '[]'`) persisted when an image contains zero recognizable text or cannot be decoded, distinguishing already-scanned photos from unindexed (`NULL`) photos.
_Avoid_: Null OCR result, empty scan flag

**Caption**:
The diarist's own words about a photo or video (`media_attachments.caption`, schema v7+), edited only in the fullscreen lightbox. Never OCR text and never indexed by `media_fts`.
_Avoid_: OCR text, photo text, annotation

**Backfill Indexer**:
The user-triggered, pauseable/resumable maintenance routine (`OcrQueueManager.runBackfill`) that scans historical unindexed photos (`ocr_text IS NULL`) sequentially without blocking launch or UI frames.
_Avoid_: Background library scanner, batch OCR job

**Scholar's Stationery Chest**:
The bottom modal drawer (`ScholarChestDrawer`) styled as a scholar's brocade box, consolidating the diarist's secondary editor tools under direct functional labels (`信纸`, `排版`, `背景音`, `定时锁`, `笔刷动画`).
_Avoid_: Tools drawer, utility tray, stationery menu, bottom sheet modal, 叠印花笺, 青花笔架, 桐木古琴, 古法鱼锁, 双管毛笔

**Stationery Artifact**:
An interactive skeuomorphic control inside the Scholar's Stationery Chest representing a functional subsystem (Fanned Stationery, Porcelain Brush Mountain, Guqin Zither, Brass Fish Lock, and Twin Bamboo Brushes).
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

**Thread-Bound Folio**:
The mobile single-page reading stage (`ThreadBoundFolioStage`) modeled after a traditional Chinese thread-bound volume, featuring 6-hole silk binding, brass corner protectors, stacked edge depth, and 3D cylindrical page-turning physics.
_Avoid_: Book preview, flipbook screen, folio widget

**Frontispiece Cover**:
The opening ceremonial leaf (`FolioFrontispiecePage`) of a diary entry in the Thread-Bound Folio, presenting the entry's date, weather, mood, an authentic center-mounted hero artwork (photo or procedural landscape with washi tape and silk mounts), and an interlinear reflection (`眉批夹注`).
_Avoid_: Book cover, title slide, entry splash page

**Tipped-In Ephemera Leaf**:
A dedicated illustration leaf (`TippedInEphemeraLeaf`) interleaved within the paginated Folio text flow, presenting an attached photo or video with paper-toned matte borders, classical silk corner mounts, and colophon captions.
_Avoid_: Image page, media slide, photo leaf

**Reading Perspective**:
The ephemeral, non-destructive presentation mode (`ReadingPerspective`) in the Thread-Bound Folio allowing the diarist to view an entry in alternative layouts (`朱丝竖排`, `方格竖排`, `暗夜横排`) while defaulting to the entry's saved stationery template (`原样`).
_Avoid_: Template editor, style picker, theme switcher, 忠实原貌, 朱丝古刻, 原稿墨格, 松烟夜卷

**Interlinear Sub-Note**:
A user-authored annotation (`夹注` / `批注`, written with `{夹注:...}` syntax) rendered either on the Folio cover or as two small parallel sub-columns in vertical calligraphy mode.
_Avoid_: Side note, footnote, inline comment, 双行夹注, 眉批夹注

**Stationery Sheet**:
The discrete, integer-locked editing page (`StationerySheet` · 信笺书页) inside the paginated entry editor, conforming to the active template's ruling capacity without infinite vertical scrolling.
_Avoid_: Editor page, paper screen, scroll card

**Auto-Spill**:
The deterministic pagination advance mechanism (`AutoSpill` · 溢行分叶) that automatically allocates and smoothly glides to a subsequent Stationery Sheet as soon as text exceeds the integer-locked line capacity of the active sheet.
_Avoid_: Auto scroll, page push, overflow wrap

**Spill-Back**:
The paired reverse pagination mechanism (`SpillBack` · 退行合叶) triggered by Backspace at the leading edge of a continuation Stationery Sheet, pulling content back onto the preceding sheet and collapsing an emptied trailing sheet.
_Avoid_: Reverse spill, sheet merge, backspace collapse

**Staging Handscroll**:
The single entry-wide media tray resting below the Stationery Sheets, holding collected photos (`照片`) and videos (`视频`) not yet added to a specific sheet (`待选照片`).
_Avoid_: Media tray, global tray, upload queue, gallery, 待贴画卷, 影札, 短影

**Tucked Prints**:
The up to three mounted photos or videos (`本页照片`) belonging to one Stationery Sheet, tucked behind its top edge outside the Paper Heart so line capacity never changes.
_Avoid_: Sheet Mount Strip, Media & Keepsake Tray, sheet tray, attachment bar, 夹页影札

**Collect**:
To bring a new photo or video into the Staging Handscroll (`添加到待选`), accompanied by the Brush Reveal.
_Avoid_: Upload, import, attach, 入卷

**Mount / Unmount**:
To move an item from the Staging Handscroll onto a Stationery Sheet (`添加到本页`), or return it from the sheet back to the handscroll (`移回待选`). An item is mounted on at most one sheet at a time.
_Avoid_: Assign, pin, link, copy, 贴至本页, 揭回画卷, 揭回

**Brush Reveal**:
The one-time splash-ink animation (泼墨显影) in which a brush paints a newly collected item into the Staging Handscroll, first as monochrome ink wash and then blooming into full colour.
_Avoid_: Paint animation, loading effect, reveal transition

**Scholar's Desk**:
The walnut writing surface (文房书案) on which the Stationery Sheets and the Staging Handscroll rest. Its colouring follows the app's light or dark appearance, never the entry's stationery template.
_Avoid_: Editor background, canvas backdrop, desk theme

**Page Corner**:
The curling folded corner (折角) at the foot of a Stationery Sheet that turns to the previous or next sheet when tapped.
_Avoid_: Chevron, page arrow, next button

**Desk Workstation**:
The bamboo mat (案头画案) docked at the foot of the Scholar's Desk holding the Staging Handscroll (resting closed as a brocade scroll when empty). Starts collapsed if the desk lacks height, collapses into the Restore Pill when put away, and steps aside while the software keyboard is open.
_Avoid_: Bottom tray, media dock, staging mat

**Restore Pill**:
The small walnut-and-brass tab (展案签) resting at the foot of the Scholar's Desk while the Desk Workstation is put away, showing how many items wait in the Staging Handscroll and bringing the workstation back.
_Avoid_: Expand button, show-tray chip, workstation toggle

**Lunar Date Seal**:
The carved cinnabar seal (岁时印) in the Journal Letterhead giving the entry's true lunar year (stem-branch) and seasonal month. Distinct from the Cinnabar Signature Seal, which carries the diarist's name.
_Avoid_: Date stamp, calendar badge, lunar chip

**Weather Charm / Mood Charm**:
The vertical tags hanging in the Journal Letterhead showing and setting weather (`晴天`, `多云`, `下雨`, `大风`, `下雪`) and mood (`低落`, `疲惫`, `平静`, `开心`, `喜悦`).
_Avoid_: Weather chip, mood chip, metadata tag, 天时笺, 心绪笺, 沉郁, 倦怠, 静穆, 怡然, 欢欣, 晴明, 阴翳, 润雨, 朔风, 凝雪

**Window Sill Ledge**:
The carved wooden sill and brass-bracketed ledge (窗台案沿) separating the upper Shanshui Scenery Card window from the lower Chronicle Desk, bearing the four study ornaments (pine bonsai, brush stand, brass candlestick, and celadon incense burner).
_Avoid_: Divider bar, desk lip, ornament shelf

**Home Shell**:
The root screen the diarist lands in after the opening cover, holding two tabs—日记 (the timeline) and 相册 (album collections)—that keep their state while switching. The cover's doors replace themselves with it, and it never goes back to the cover except through `返回封面` in the Diarist Panel.
_Avoid_: Main page, tab host, dashboard, 首页

**Tab Rail**:
The woodwork bottom bar on the Home Shell (`日记 · [Scroll Roller Button] · 相册`), coloured by the active Atmosphere Palette, that slides away while scrolling down and returns while scrolling up. Absent on the cover and on every screen opened from a tab.
_Avoid_: Bottom nav, navigation bar, tab bar, sill bar

**Scroll Roller Button**:
The raised scroll-roller centre button in the Tab Rail's notch, whose label and action follow the active tab: `写日记` on 日记, `新建相册` on 相册.
_Avoid_: FAB, write button, plus button, 发布

**Diarist Panel**:
The casement-woodwork side panel (`我的`) slid out from the left of the Home Shell, by the header's cloud-avatar button or a left-edge drag in the upper band. It holds a placeholder profile, the `日记 · 相册 · 收藏` stats strip, and rows for `写作统计`, `回收站`, `导入与备份` and `返回封面`.
_Avoid_: Drawer, sidebar, profile page, user page, 个人中心

**Chronicle Desk**:
The lower timeline workspace surface (`日记`) housing the Date Index Tray, mood/weather filter (`筛选`), and vertical timeline spine of diary entries.
_Avoid_: Bottom container, entry list box, timeline background, 案头卷匣, 案头卷宗, 素宣待书, 笺签筛选

**Date Index Tray**:
The three-row chronological filter and sorter header docked at the top of the Chronicle Desk, filtering by Year, Month, and Ten-Day Period (`上旬`, `中旬`, `下旬` — `1–10日`, `11–20日`, `21日–月底` by default, or `初一–初十`, `十一–二十`, `廿一–月底` in lunar mode).
_Avoid_: Date navbar, calendar filter bar, date chips, 案头岁时检目, 纪年, 月令, 三旬

**Wet-Mounted Thumbnail**:
The silk-brocade bordered media preview with mitered corner seams displayed inside a timeline entry card.
_Avoid_: Photo thumbnail, Polaroid preview, image box

**Twin Bamboo Brushes**:
The pair of bamboo calligraphy brushes in the Scholar's Stationery Chest (`笔刷动画`) governing live writing choreography, bristle stiffness (`狼毫 (偏硬)`, `兼毫 (适中)`, `羊毫 (偏软)`), and writing cadence.
_Avoid_: Twin brushes placeholder, brush toggle, animation menu, 双管毛笔

**Ink Choreography**:
The live stroke-by-stroke wet-ink and brush writing animation (`逐笔书写`, `同时书写`, `仅墨迹`, `无动画`) that draws newly written characters onto a Stationery Sheet. Distinct from Brush Reveal, which unveils collected media in the Staging Handscroll.
_Avoid_: Brush Reveal, typing effect, text animation, stroke effect, 单笔连绵, 并笔齐书, 见墨不见笔, 敛锋静书

**Airborne Silk Trace**:
The faint dashed ink filament and lifted brush arc connecting the final stroke of one character to the opening stroke of the next during continuous single-brush writing.
_Avoid_: Transit line, cursor trail, jump path

**Trial Rice-Grid**:
The miniature rice-paper practice square inside the Twin Bamboo Brushes compartment of the Scholar's Stationery Chest for testing stroke choreography and bristle feel on sample characters.
_Avoid_: Focus stage, magnifier box, preview widget

**Recycle Bin**:
The soft-delete holding area (`回收站`) retaining deleted entries for 30 days before permanent purge (`恢复`, `彻底删除`, `清空回收站`).
_Avoid_: 岁暮拾遗, 复墨还案, 焚稿归尘, 焚稿净匣

**Time Capsule**:
An entry locked until a chosen future unlock date (`时间胶囊` / `定时解锁`, state `待解锁`).
_Avoid_: 岁月锦囊, 封缄书, 古法鱼锁

**Weekly Review**:
The weekly reflection summary and 7-day activity overview (`每周复盘` / `本周每日记录`, default title `第N周复盘`).
_Avoid_: 周志复盘, 一候七日, 节候律动

**Writing Analytics**:
Quantitative writing metrics (`写作统计`: `总篇数`, `总字数`, `当前连续写作`, `最长连续写作`).
_Avoid_: 研墨统计, 挥毫字数, 当下连墨, 最长持砚
