---
id: SPEC-024
title: Five-Realm Shanshui Scenery Expansion (West Lake & Fenghuang) & Scene Visual Polish
status: ready-for-agent
created_at: 2026-11-23T23:58:00+08:00
---

# Specification: Five-Realm Shanshui Scenery Expansion (West Lake & Fenghuang) & Scene Visual Polish

## Problem Statement

While the **Shanshui Scenery Card** and **Contemplation View** currently offer three **Scenery Realms** (**Nature** `山水`, **Indoor** `室内`, and **Outdoor** `街市`), evaluating the current build against the latest interactive prototype reveals major gaps in cultural scene richness, visual fidelity, and geometric correctness:

1. **Missing Cultural Landmark Waterscapes (`西湖` & `凤凰`)**: The prototype introduces two iconic regional Chinese waterscapes—Hangzhou's **Ten Scenes of West Lake (`西湖`)** and Hunan Xiangxi's **Fenghuang Ancient Stilt Town (`凤凰`)**—with full 4-season, 4-time-of-day, and 5-weather dynamics that are absent from the app.
2. **Indoor Tea Hall (`室内`) Simplification & Occlusion Bug**: The current Indoor painter omits signature architectural and foreground furniture layers from the prototype (top woven bamboo chandelier, left floor palace lantern, Moon Gate twin swaying silk banners and horizontal slat railings, right circular Moon Archway with flowing cyan silk drapes, full-perspective rosewood tea table with twin conical terracotta incense burners and foreground painted plum-blossom table lantern), omits the ambient night/time wash and `screen`-blended candle halos, draws horizontal top-left text instead of bottom-right vertical calligraphy, and paints the live Moon Window *after* its cached frame—causing the sky and snow window view to overwrite its own dark-wood frame and winter snow sill.
3. **Outdoor Market Street (`街市`) Crowd Z-Order & Wall/Desk Collisions**: Behind-counter stall vendors and seated patrons are painted *after* the static cached stall counters—making people appear to stand *on top of* the counters—while several mid-ground and foreground figures sit at coordinates whose bodies or feet intersect building walls or table polygons. In addition, the Outdoor painter lacks multi-stop radial lantern gradients, dynamic warm shopfront window illumination at Dawn/Dusk/Rain, clipped directional street reflections, Paifang roof tile ribs, wind-billowing awnings, serene facial details, upward-pulsing summer fireflies, weather sky overlays, jagged stormy lightning bolts, and rain-spawned puddle ripples.
4. **Nature (`山水`) Particle & Calligraphy Polish Gaps**: The baseline Nature realm renders seasonal petals and maple leaves as plain dots rather than rotating elliptical petals or pulsing upward summer fireflies, lacks multi-segment stormy lightning bolts, and does not wrap long poetic couplets into punctuation-free vertical columns.

## Solution

Upgrade the **Shanshui Scenery Card**, **Contemplation View**, realm preference persistence, and journal situation detection to a cohesive **Five-Realm Architecture** while bringing every scene up to full visual and geometric fidelity:

1. **Five Scenery Realms (`ShanshuiRealm` & `SceneryRealmPreference`)**:
   - Expand **Scenery Realm** to five selectable realms: **Nature (`山水`)**, **West Lake (`西湖`)**, **Fenghuang (`凤凰`)**, **Outdoor (`街市`)**, and **Indoor (`室内`)**, keeping **Nature (`山水`)** as the neutral fallback default and preserving existing preference storage compatibility.
   - Surface all realms in the **Shanshui Scenery Card** 1-tap switcher sheet, collapsed `44dp` bamboo-slat bar, **Contemplation View** horizontal chips, Settings (`画卷场景`), offline `AudioSanctumService` soundscape pairing, and **Automatic (`自动`)** journal situation detection.
2. **Hangzhou West Lake (`西湖` · 浙江杭州西湖十景)**:
   - Render the 1500×1000 vector waterscape across all four seasons (`苏堤春晓`, `曲院风荷`, `平湖秋月`, `断桥残雪`) featuring northern hills with **Baochu Pagoda (`保俶塔`)**, wooded Xizhao Hill with 5-story octagonal **Leifeng Pagoda (`雷峰塔`)** and golden dusk backlight (`雷峰夕照`), **Su Causeway (`苏堤`)** with stone arch bridge and alternating willows/peach blossoms, **Pinghu Qiuyue (`平湖秋月`)** waterside pavilion, **Three Pools Mirroring the Moon (`三潭印月`)** hollow stone gourd pagodas with glowing round candle windows and water moon reflections, painted pleasure boat (`画舫`) and hand-rowed punt (`手划船`), foreground **Broken Bridge (`断桥残雪`)** with partially melted winter snow crown, stele pavilion, and silk-umbrella visitors, **Quyuan Lotus Cove** (blooming lotus vs. winter withered stems `留得枯荷听雨声`), and swaying weeping willow curtains (`柳浪闻莺`).
3. **Xiangxi Fenghuang (`凤凰` · 湖南湘西凤凰古城)**:
   - Render the 1500×1000 Xiangxi riverside town across all four seasons featuring misty NanHua/Wuling karst ridges, emerald **Tuojiang River (`沱江`)** with shimmering golden/red stilt-house reflections, 7-tiered hexagonal white **Wanming Pagoda (`万名塔`)**, 3-arch **Hongqiao Wind & Rain Covered Bridge (`虹桥风雨楼`)**, left and right bank perspective rows of 10 multi-story wooden **Stilt Houses (`湘西吊脚楼群`)** with cedar stilts, cantilevered balconies, golden night roof-ridge lights, and corner red lanterns, drifting river mist, wooden punt boats (`乌篷船`), double-row red-sandstone **Tuojiang Stepping Stones (`跳岩`)** with foaming white water rapids and visitors in traditional **Miao silver headdresses (`苗族银饰头冠`)**, and floating pink lotus river lanterns (`沱江河灯`) at Dusk/Night.
4. **Indoor Tea Hall (`室内`) Full Overhaul**:
   - Achieve 1:1 visual parity with the reference Indoor composition, fixing the Moon Window frame/snow-sill occlusion bug and restoring all missing architectural elements, foreground furniture, multi-layer lighting (`ambientOverlay` + `BlendMode.screen` candle halo reinforcement), particle-based curling smoke/steam, sparkling indoor dust motes/petals, and bottom-right vertical calligraphy colophon.
5. **Outdoor Market Street (`街市`) Crowd Occlusion Fix & Visual Polish**:
   - Split crowd rendering around the foreground stall counters so behind-counter vendors and seated counter patrons render *behind* the counters, clamp/reposition all walking and standing figures onto open stone-avenue flagstones clear of walls and desks, and add multi-stop radial lantern gradients, dynamic shop window lighting, clipped linear street reflections, Paifang roof tile ribs, billowing awnings, facial expressions, pulsing summer fireflies, weather sky overlays, jagged stormy lightning bolts, and rain-spawned puddle ripples.
6. **Nature (`山水`) Visual Polish**:
   - Upgrade seasonal particles to rotating elliptical petals/leaves and pulsing upward summer fireflies, add multi-segment stormy lightning bolts, and format vertical poem colophons cleanly in punctuation-stripped vertical columns.

## User Stories

1. As a diarist, I want the **Shanshui Scenery Card** and **Contemplation View** to support five **Scenery Realms**—**Nature (`山水`)**, **West Lake (`西湖`)**, **Fenghuang (`凤凰`)**, **Outdoor (`街市`)**, and **Indoor (`室内`)**—so that my diary header reflects wilderness, classical Jiangnan lake heritage, Xiangxi river-town culture, lively markets, and cozy home study.
2. As a diarist writing about Hangzhou, West Lake, Broken Bridge, Leifeng Pagoda, or lotus ponds, I want **Automatic (`自动`)** mode to attune the scenery to **West Lake (`西湖`)** within 24 hours, so that my travel or lakeside memories resonate immediately in the window.
3. As a diarist writing about Fenghuang, Tuojiang River, stilt houses, stepping stones, river lanterns, or ancient river towns, I want **Automatic (`自动`)** mode to attune the scenery to **Fenghuang (`凤凰`)** within 24 hours, so that my ancient-town journeys appear visually above my timeline.
4. As a bilingual writer, I want journal situation detection to recognize both Chinese and English keywords for **West Lake (`西湖`)** and **Fenghuang (`凤凰`)** alongside existing realms, weighting title matches twice as strongly as body text.
5. As a diarist writing an entry with general outdoor words like mountains or hiking, zero spatial keywords, or entries older than 24 hours, I want **Automatic (`自动`)** mode to keep falling back cleanly to **Nature (`山水`)**, so existing expectations remain unbroken.
6. As a privacy-conscious user, I want soft-deleted entries, PIN-locked entries, and sealed future **Time Capsule** entries to remain strictly excluded from 5-realm journal inference.
7. As a user browsing the **Shanshui Scenery Card**, I want tapping the realm badge to open the 1-tap switcher sheet displaying all six options (`自动`, `山水`, `西湖`, `凤凰`, `街市`, `室内`) with clear Chinese subtitles.
8. As a user rolling down the **Bamboo Blind Pull-Cord**, I want the collapsed `44dp` bamboo-slat bar to preserve and display the active 5-realm seal badge (`春 · 苏堤`, `夏 · 摇橹`, etc.) and remain expandable in one tap.
9. As a user customizing app settings, I want the **"画卷场景"** dialog in Settings to offer all six options (`自动`, `山水`, `西湖`, `凤凰`, `街市`, `室内`), stay synchronized with on-card changes, and reset back to `自动` when resetting atmosphere overrides.
10. As a contemplative user in the **Contemplation View**, I want horizontal realm chips for all five realms (`山水`, `西湖`, `凤凰`, `街市`, `室内`) alongside Season, Time of Day, and Weather pills.
11. As a user switching to **West Lake (`西湖`)** or **Fenghuang (`凤凰`)** in the **Contemplation View**, I want the header title, poetic couplet, and 4-character cinnabar seal to update dynamically per season (e.g., `春 · 苏堤春晓柳如烟` / `苏堤春晓` in Spring, `冬 · 断桥残雪留荷影` / `断桥残雪` in Winter) and reveal `恢复实时` when diverging from real-time atmosphere.
12. As a listener activating ambient audio in the **Contemplation View**, I want **West Lake (`西湖`)** and **Fenghuang (`凤凰`)** to pair contextually with `gentleRain` during rain/storms, `vintageLibrary` at Winter/Night, and `bambooBreeze` during clear Spring/Summer/Fall daytime hours.
13. As an admirer of **West Lake (`西湖`)**, I want to see distant northern hills crowned by **Baochu Pagoda (`保俶塔`)**, **Leifeng Pagoda (`雷峰塔`)** glowing warmly at Dusk (`雷峰夕照`), **Su Causeway (`苏堤`)** with alternating peach blossoms and willows, and the **Pinghu Qiuyue (`平湖秋月`)** waterside pavilion.
14. As an admirer of **West Lake (`西湖`)**, I want the three hollow stone gourd pagodas of **Three Pools Mirroring the Moon (`三潭印月`)** to illuminate their round paper windows and cast three shimmering moon reflections onto the lake at Dusk, Night, and rainy/dim hours.
15. As an admirer of **West Lake (`西湖`)**, I want **Broken Bridge (`断桥残雪`)** to showcase snow blanketing its shaded slopes while leaving its sunlit crown bare in Winter or snowy weather, while Quyuan Lotus Cove transitions from blooming pink lotuses in Spring/Summer to poetic snow-dusted withered lotus stems (`留得枯荷听雨声`) in Winter.
16. As an admirer of **West Lake (`西湖`)**, I want foreground weeping willow curtains (`柳浪闻莺`) to sway gently in the wind, a carved pleasure boat (`画舫`) and sculling punt (`手划船`) to glide across the water, and Hanfu visitors with silk umbrellas (`西湖绸伞`) to follow the time-of-day crowd rhythm (empty at Dawn, bustling at Day/Dusk, sparse at Night).
17. As an admirer of **Fenghuang (`凤凰`)**, I want to see layered misty karst hills behind **Hongqiao Wind & Rain Covered Bridge (`虹桥风雨楼`)** and the 7-tiered white **Wanming Pagoda (`万名塔`)**, mirrored in the emerald **Tuojiang River (`沱江`)**.
18. As an admirer of **Fenghuang (`凤凰`)**, I want perspective rows of multi-story wooden stilt houses (`湘西吊脚楼群`) resting on cedar stilts above the riverbanks with warm lattice windows, corner red lanterns, and golden roof-ridge lights illuminating at Dusk and Night.
19. As an admirer of **Fenghuang (`凤凰`)**, I want wooden punt boats (`乌篷船`) gliding past drifting river mist, white foaming rapids washing past double-row red-sandstone **Tuojiang Stepping Stones (`跳岩`)**, visitors wearing traditional **Miao silver headdresses (`苗族银饰头冠`)** crossing the stones during open hours, and pink lotus river lanterns (`沱江河灯`) drifting downriver at Dusk and Night.
20. As an interactive user in the **Contemplation View**, I want tapping the water in **West Lake (`西湖`)** or **Fenghuang (`凤凰`)** to spawn expanding concentric water ripples clamped to the lake/river surface plus gentle drifting petal swirls.
21. As an admirer of the **Indoor (`室内`)** Tea Hall, I want the left elliptical Moon Window (`月洞窗`) to render live outdoor sky, stars, sun/moon, distant hills, courtyard mist, swaying multi-branch trees, and rain/snow *behind* its heavy rosewood frame, inner bevel highlight, and winter snow sill so the frame never gets painted over.
22. As an admirer of the **Indoor (`室内`)** Tea Hall, I want to see the full perspective rosewood tea table extending to the bottom foreground with its white-and-gold brocade runner, celadon tea set, twin ribbed conical terracotta incense burners (`螺纹塔香炉`) with curling smoke spheres, and the foreground painted plum-blossom table lantern (`前景梅花彩绘座灯`).
23. As an admirer of the **Indoor (`室内`)** Tea Hall, I want to see the top swaying woven bamboo chandelier (`顶部竹编彩绘吊灯`), the left tall wooden floor palace lantern (`左壁落地宫灯`), the center Moon Gate's upper lattice transom, lower slat railings (`卧棂栏杆`), background altar, and twin swaying cream-silk hanging banners (`双垂幔`), and the right circular Moon Archway carved cleanly out of vertical slats to reveal flowing cyan silk drapes (`青碧纱幔`) and an octagonal wall lantern.
24. As an admirer of the **Indoor (`室内`)** Tea Hall, I want indoor lighting to combine dual volumetric sun/moon beams, elliptical floor light pools, time-of-day ambient room washes, and `screen`-blended flickering candle halos so lanterns and the winter red-clay charcoal brazier (`红泥小火炉`) glow warmly at Dusk, Night, and in storms.
25. As a viewer of the **Outdoor (`街市`)** Ancient Market Street, I want behind-counter pastry and noodle vendors and counter-side patrons to be naturally occluded behind the wooden stall counters rather than appearing to stand on top of the desks.
26. As a viewer of the **Outdoor (`街市`)** Ancient Market Street, I want every strolling pedestrian and stall customer to stand cleanly with their feet inside the open stone-paved avenue trapezoid and clear of building walls and furniture edges.
27. As a viewer of the **Outdoor (`街市`)** Ancient Market Street, I want swaying red paper lanterns to glow with rich multi-stop radial gradients, shopfront lattice windows to warm up automatically at Dawn, Dusk, Night, and in rain, wet/night flagstones to catch directional clipped lantern reflections, fabric market awnings to billow gently in the wind, Paifang roofs to show subtle tile ribs, and townsfolk to display serene facial features.
28. As a viewer across **Outdoor (`街市`)**, **West Lake (`西湖`)**, **Fenghuang (`凤凰`)**, and **Nature (`山水`)**, I want Summer particles to drift upward as pulsing fireflies (`萤火虫`) during non-rainy weather, Spring petals and Fall maple leaves to tumble as rotating ellipses, stormy skies to flash with multi-segment jagged lightning bolts, and rainy streets/waters to spawn organic surface ripples.
29. As a reader admiring full-poem calligraphy in **Contemplation View**, I want every realm's vertical Chinese title, punctuation-free vertical poetic couplet, and 2×2 carved cinnabar seal to sit in its designated clear corner without colliding with architecture or overflowing the canvas.
30. As a mobile user on battery power, I want all four rich architectural/landscape realms (`西湖`, `凤凰`, `街市`, `室内`) to cache static geometry in immutable `ui.Picture` layers invalidated only on environment changes, and suspend the animation ticker whenever off-screen or backgrounded.
31. As a user relying on screen readers or large font scales, I want all new realm switcher options, chips, and badges to provide descriptive `Semantics` labels and clamp text scaling cleanly down to `320px` viewports without layout overflow.

## Implementation Decisions

### 1. Five-Realm Domain Model & Metadata (Derived from Prototype)
- Extend `ShanshuiRealm` and `SceneryRealmPreference` to encode the five realms while preserving existing IDs (`nature`, `indoor`, `outdoor`) and adding `westLake` and `fenghuang`:

```dart
// Derived from prototype scene switcher & seasonal metadata
enum ShanshuiRealm {
  nature(id: 'nature', shortNameZh: '山水', nameEn: 'Nature'),
  westLake(id: 'westLake', shortNameZh: '西湖', nameEn: 'West Lake'),
  fenghuang(id: 'fenghuang', shortNameZh: '凤凰', nameEn: 'Fenghuang'),
  indoor(id: 'indoor', shortNameZh: '室内', nameEn: 'Indoor Tea Hall'),
  outdoor(id: 'outdoor', shortNameZh: '街市', nameEn: 'Ancient Market Street');
}

enum SceneryRealmPreference { auto, nature, westLake, fenghuang, indoor, outdoor }
```

- Extend `ShanshuiSeason`'s realm lookup helpers (`nameZhFor`, `nameEnFor`, `poemFor`, `sealTextFor`, `sealBadgeZhFor`) for `ShanshuiRealm.westLake` and `ShanshuiRealm.fenghuang`:
  - **West Lake (`西湖`)**:
    - Spring: `春 · 苏堤春晓柳如烟` (`Spring · Su Causeway Dawn & Peach Blossoms`) / `间株杨柳间株桃，水光潋滟晴方好` / Seal `苏堤春晓` / Badge `春 · 苏堤`
    - Summer: `夏 · 曲院风荷碧连天` (`Summer · Breeze-Ruffled Lotus at Quyuan`) / `接天莲叶无穷碧，映日荷花别样红` / Seal `曲院风荷` / Badge `夏 · 风荷`
    - Fall: `秋 · 平湖秋月雷峰晚` (`Fall · Autumn Moon & Leifeng Pagoda Sunset`) / `雷峰夕照金波涌，三潭印月桂子香` / Seal `平湖秋月` / Badge `秋 · 秋月`
    - Winter: `冬 · 断桥残雪留荷影` (`Winter · Melting Snow on Broken Bridge`) / `晴雪初消断桥石，留得枯荷听雨声` / Seal `断桥残雪` / Badge `冬 · 残雪`
  - **Fenghuang (`凤凰`)**:
    - Spring: `春 · 烟雨桃花映沱江` (`Spring · Misty Peach Blossoms on Tuojiang`) / `江水初平翠黛低，吊脚楼前桃花溪` / Seal `湘西春晓` / Badge `春 · 沱江`
    - Summer: `夏 · 沱江碧水听摇橹` (`Summer · Emerald Tuojiang & Rowing Skiffs`) / `两岸吊脚悬碧水，一舟摇碎满江星` / Seal `沱江清夏` / Badge `夏 · 摇橹`
    - Fall: `秋 · 丹枫尽染虹桥晚` (`Fall · Crimson Maples at Hongqiao Evening`) / `万名塔下秋波静，虹桥风起落丹枫` / Seal `边城秋色` / Badge `秋 · 虹桥`
    - Winter: `冬 · 雪落凤凰万家灯` (`Winter · Snowfall & Stilt-House Lanterns`) / `跳岩雪映红灯影，吊脚楼头暖火明` / Seal `凤城瑞雪` / Badge `冬 · 凤凰`
- Extend `SceneryRealmPreference` icon mapping so each realm displays a distinct icon in the switcher sheet and Settings dialog.

### 2. Journal Situation Auto-Inference & Soundscape Pairing
- Extend `ShanshuiAtmosphereResolver` to score accessible entries (within 24 hours, non-deleted, unlocked, unsealed **Time Capsule**) across all five realms using curated Chinese substring and word-bounded English lexicons (title weighted 2× body):
  - **West Lake (`西湖`)**: `西湖`, `杭州`, `断桥`, `残雪`, `苏堤`, `白堤`, `雷峰塔`, `保俶塔`, `三潭印月`, `曲院风荷`, `平湖秋月`, `柳浪闻莺`, `画舫`, `荷塘`, `荷花`, `莲叶`, `枯荷`, `west lake`, `hangzhou`, `leifeng`, `lotus pond`, `willow causeway`.
  - **Fenghuang (`凤凰`)**: `凤凰`, `湘西`, `沱江`, `吊脚楼`, `虹桥`, `跳岩`, `万名塔`, `边城`, `苗寨`, `苗服`, `银饰`, `河灯`, `乌篷船`, `摇橹`, `古镇`, `水乡`, `fenghuang`, `tuojiang`, `stilt house`, `ancient town`, `river lantern`, `stepping stones`.
  - Existing `nature`, `indoor`, and `outdoor` keywords remain intact so general wilderness words continue to resolve `nature`, and ties or zero scores still fall back to `nature` (`isJournalInferred = false`).
- Extend `ShanshuiAtmosphereResolver.resolveSoundscape` for `westLake` and `fenghuang`: `gentleRain` on Rainy/Stormy weather, `vintageLibrary` in Winter or Night, and `bambooBreeze` otherwise.
- Persist `SceneryRealmPreference` (`westLake`, `fenghuang`, etc.) seamlessly via the existing encrypted `ScenerySettingsService` preference key (`memodiary_scenery_realm_preference`).

### 3. Outdoor Market Street (`街市`) Crowd Occlusion & Placement Contract
- Fix both Z-order occlusion and geometric placement bugs in `OutdoorStreetCrowd` and the Outdoor painter:
  - **Counter Z-Order Separation**: Tag stall figures sitting or working behind counters (`isBehindCounter = true` — specifically the left pastry vendor, mid-ground left baker, right noodle shopkeeper, and left-side counter stool patron) so they paint **before** the foreground wooden stall tables, aprons, merchandise, crates, and bowls. Foreground customers (`baseX: 322` shifted cleanly clear of crates if needed, seated right-side patron, and all avenue walkers) paint **after** the stall counters. Because the foreground stall counters must occlude behind-counter vendors while not occluding avenue walkers, render the static sky/mountain/avenue/Paifang/shopfronts/awnings into the cached `ui.Picture`, then draw `behindCounterFigures` → `foregroundStallCountersAndGoods` → `foregroundCustomersAndAvenueWalkers` → `lanterns`.
  - **Open-Flagstone Footprint Invariant**: Define the stone avenue bounds (`x_left(y) = 560 * (940 - y) / 360`, `x_right(y) = 940 + 560 * (y - 580) / 360` for `580 <= y <= 940`, and `[0, 1500]` for `y > 940`) and exclude foreground stall table polygons. Reposition out-of-bounds figures (such as mid-ground walkers previously clipping into left/right shopfront walls or seated/standing patrons overlapping the counter top or side walls) so every walker's feet `(baseX, baseY + 88 * scale)` and shoulder span sit strictly on open stone flagstones clear of walls and desks.
- Apply the 6 Outdoor visual polish upgrades:
  1. Multi-stop `RadialGradient` red paper lantern silk bodies and warm halos.
  2. Dynamic shopfront lattice window warm glow driven per-frame by effective `lanternLevel > 0.3` (illuminating at Dawn, Dusk, Night, and Rainy/Stormy weather rather than baked solely on `isNight`).
  3. Clipped directional `LinearGradient` warm reflections inside the stone avenue polygon when lanterns are lit or the street is wet.
  4. Perspective tile ribs on Paifang roofs (`!hasSnowCover`) and per-frame wind-billowing on the 6 fabric market awnings (drawn dynamically or with animated edge offsets).
  5. Serene facial features (eyes and smile arc) and white-soled cloth shoes on `TownsfolkWalker`.
  6. Upward-drifting pulsing Summer fireflies, sky weather tint overlay (`weather.skyOverlay`), randomized multi-segment jagged stormy lightning bolts, and automatic rain-spawned puddle ripples on the street.

### 4. Indoor Tea Hall (`室内`) 1:1 Overhaul
- Reorganize `AncientRoomPainter` and `AncientRoomStaticArchitecture` into the prototype's exact 13-layer ordering (`1500×1000` vector space):
  - **Static `ui.Picture` Layer**: Perspective ceiling timber, left Xuan plaster wall framing, right alcove backdrop, radiating rosewood floorboards, rear courtyard shoji doors + foliage silhouettes + inner room altar table, center partition transom/lintels/horizontal slat railings, right wall vertical slats + waist rail carved with an **even-odd inverse clip** (`PathFillType.evenOdd`) for the circular Moon Archway (`cx=1405, cy=515, r=235`) plus alcove pillar, emerald banner, and corner flowerpot, left floor palace lantern wooden stand & pedestal, fluted porcelain bonsai pots (`(240, 725)`, `(18, 855)`), right dark ceramic magnolia vase (`(985, 575)`), 3 perspective embroidered floor cushions on wooden plinths, and the full-perspective long rosewood tea table (`(575,632)–(715,632)–(645,1000)–(210,1000)`) with white-and-gold brocade runner, celadon tea vessels, tea tray/cups, and twin ribbed conical terracotta incense burners (`(542, 832)`, `(612, 855)`).
  - **Dynamic Moon Window Layer (Fixing Occlusion)**: Clip the live courtyard inside the perspective ellipse (`cx=65, cy=435, rx=175, ry=278, rot=-0.04`) and paint sky gradient, `weather.skyOverlay`, stormy lightning flashes/bolts, stars, celestial sun/moon + halo, distant courtyard mountain silhouette, drifting mist, swaying multi-branch seasonal tree with 5 foliage clusters, outdoor particles/fireflies, and rain/snow precipitation. Immediately **after** restoring the clip, paint the heavy rosewood Moon Window casing, inner bevel highlight, and Winter/Snow bottom-sill snow accumulation **on top** so the frame and snow sill are never occluded.
  - **Dynamic Indoor Elements Layer**: Swaying cyan silk drapes (`青碧纱幔`) inside the right Moon Archway, twin swaying cream-silk hanging banners (`双垂幔`) with medallions flanking the Moon Gate, dual `BlendMode.screen` volumetric light beams + 2 elliptical floor pools, flickering flame & `RadialGradient` glow for the inner shoji lantern, octagonal right wall lantern, left tall floor palace lantern (with red tassels), foreground hero painted plum-blossom table lantern (`(465, 835)` with hand-painted ink branch & red blossoms), top swaying woven bamboo chandelier (`(720, 215)`), conditional Winter/Snow red-clay charcoal brazier (`(760, 740)`), particle-sphere curling incense smoke & tea steam wisps, `roomPalette.ambientOverlay` + `weather.indoorRoomDimming` + stormy flash, `BlendMode.screen` re-reinforcement of the 4 candle halos over dark ambient overlays, sparkling golden dust motes + rotating elliptical indoor petals, bottom-right vertical calligraphy colophon (`x=1430, y=680`, 2-column vertical couplet, 2×2 carved cinnabar seal at `x=1420, y=915`), and soft radial vignette.

### 5. West Lake (`西湖`) & Fenghuang (`凤凰`) Modular Painters
- Create dedicated color palette helpers, static architectural layers (`ui.Picture` cached per `(season, timeOfDay, weather)` environment), and 60 FPS dynamic `CustomPainter` implementations for both new realms, dispatched cleanly from `ShanshuiSceneryPainting`:
  - **West Lake (`西湖`) Painter**: Static layer caches distant northern hills with Baochu Pagoda, Xizhao Hill with foliage and 5-story octagonal Leifeng Pagoda, West Lake water base gradient, Su Causeway embankment & arch bridge with alternating willow/peach trees, Pinghu Qiuyue waterside pavilion, and Broken Bridge masonry + winter melting-snow slopes + balustrade posts + stele pavilion. Dynamic layer renders sky gradient, `skyOverlay`, stars, celestial body (shifted over Leifeng Pagoda at Dusk for `雷峰夕照`, open lake otherwise), stormy lightning bolts, shimmering lake celestial + Leifeng golden reflections, Three Pools Mirroring the Moon (`三潭印月`) gourd pagodas with glowing round candle windows & 3 rippling water-moon reflections, gliding painted pleasure boat (`画舫`) and sculling punt (`手划船`), time-filtered Hanfu visitors on Broken Bridge (0 at Dawn, 5 at Day/Dusk, 2 at Night, carrying silk umbrellas), seasonal Quyuan Lotus Cove (blooming pink lotus vs. winter withered stems), interactive + rain-spawned lake ripples, swaying foreground weeping willow curtains (`柳浪闻莺`), seasonal particles/fireflies, precipitation, top-right vertical calligraphy colophon + cinnabar seal, and radial vignette.
  - **Fenghuang (`凤凰`) Painter**: Static layer caches layered NanHua/Wuling karst ridges, emerald Tuojiang River base gradient, 7-tiered hexagonal white Wanming Pagoda (`万名塔`), 3-arch Hongqiao Wind & Rain Covered Bridge (`虹桥风雨楼`), riverbank trees, and perspective rows of 10 multi-story wooden stilt houses (`吊脚楼群`) with cedar stilts, diagonal braces, cantilevered balconies, and golden night roof-ridge lights. Dynamic layer renders sky, `skyOverlay`, stars, celestial body, stormy lightning bolts, shimmering Tuojiang bridge/sun/moon/stilt-house reflections, swaying corner red lanterns under stilt-house eaves, drifting river mist at Dawn/Cloudy/Wet weather, gliding wooden punt boats (`乌篷船`), double-row red-sandstone Tuojiang Stepping Stones (`跳岩`) with foaming white water rapids and time-filtered Miao silver-headdress visitors (0 at Dawn, 6 at Day/Dusk, 2 at Night, carrying oiled-paper umbrellas in rain/snow), floating pink lotus river lanterns (`沱江河灯`) at Dusk/Night/lit states, interactive + rain-spawned river ripples, foreground overhanging branches, seasonal particles/fireflies, precipitation, top-right vertical calligraphy colophon + cinnabar seal, and radial vignette.
- **Interactive Tap Feedback in `ShanshuiSceneryPainting`**: Tapping `westLake` or `fenghuang` spawns expanding water ripples clamped below the water horizon (`y >= 520` for West Lake, `y >= 555` for Fenghuang) alongside gentle drifting petal/mote swirls.

### 6. Nature (`山水`) Visual Polish
- Update `ShanshuiCanvasPainter` to render Spring petals and Fall maple leaves as rotating tilted ellipses, Summer particles as upward-floating pulsing fireflies (`萤火虫`) when non-rainy, multi-segment jagged stormy lightning bolts, and punctuation-stripped vertical poetic couplets wrapped cleanly into two vertical columns when `fullPoem == true` so long verses never collide with the horizon or water.

### 7. Scenery UI Surface Integration
- Update `ShanshuiSceneryCard` realm badge switcher (`showSceneryRealmSwitcherSheet`), `ContemplationViewScreen` realm chip row, and `SettingsScreen` realm selection dialog (`_showRealmPreferenceDialog`) to expose all five realms cleanly with `Semantics` labels and `<= 1.3` clamped text scaling so no horizontal or vertical overflow occurs down to `320px` width.

## Testing Decisions

### What Makes a Good Test
- Test external observable behavior, state resolution contracts, geometric invariants, rendering resilience, and user interactions at the highest relevant seam—never private painter helper methods, internal array indices, or `ui.Picture` cache internals.
- Use bounded `tester.pump(duration)` steps rather than `pumpAndSettle` on screens running repeating animation tickers, and verify ticker auto-suspension via `isVisible`.

### Seams & Modules Tested
1. **Domain, Resolver, Crowd Geometry & Persistence Seam (`ShanshuiAtmosphereResolver`, `ScenerySettingsService`, `ShanshuiSeason`, `OutdoorStreetCrowd`)**:
   - All 5 `ShanshuiRealm` titles, poems, cinnabar seals, and compact badges across 4 seasons.
   - Bilingual keyword inference for `westLake` and `fenghuang` alongside `nature`, `indoor`, and `outdoor`; 24-hour recency decay; tie/neutral fallback to `nature`; exclusion of soft-deleted, locked, and sealed **Time Capsule** entries; contextual `SoundscapePreset` pairing; and encrypted preference persistence round-trips.
   - **Outdoor (`街市`)** geometric footprint invariant: assert every figure in `OutdoorStreetCrowd` (across all times of day) has a clear footprint `(baseX, baseY + 88 * scale)` strictly inside the open stone-avenue trapezoid and clear of building walls, and verify behind-counter figures (`isBehindCounter == true`) are cleanly separated from foreground figures.
2. **Painting & Interactive Canvas Seam (`ShanshuiSceneryPainting` and all 5 Realm Painters)**:
   - Offscreen `ui.PictureRecorder` rendering matrix across all 5 realms × 4 seasons × 4 times of day × 5 weathers at both 16:9 and 3:2 sizes without errors or assertion failures, including `recordStaticPicture` cache usage.
   - Touch interaction tests on `ShanshuiSceneryPainting` verifying water ripples (clamped to water horizons in `westLake` and `fenghuang`) and petal swirls.
3. **Widget & Screen Seam (`ShanshuiSceneryCard`, `ContemplationViewScreen`, `SettingsScreen`)**:
   - Realm switcher bottom sheet on `ShanshuiSceneryCard` and Settings realm dialog listing and persisting all 6 options (`自动`, `山水`, `西湖`, `凤凰`, `街市`, `室内`).
   - `ContemplationViewScreen` displaying all 5 realm chips, updating header metadata/seal/soundscape on realm switch, revealing/restoring via `恢复实时`, and rendering cleanly down to `320px` width without overflow.

### Prior Art
- Existing resolver, palette, painter, card, contemplation screen, and settings realm unit/widget test suites in the scenery and settings test groups.

## Out of Scope

- Desktop web comparison UI scaffolding (4-season quad grid view, side-by-side dual-scene split view, manual candle override toggle button, and auto-cycle play/pause timer—the mobile app resolves time, lighting, and candles automatically from the real-time clock or atmospheric preview chips).
- Mouse hover parallax tracking (mobile touch devices use tap-ripple/petal interactions instead).
- Bundled raster textures or third-party graphics assets (everything remains 100% pure Flutter `CustomPainter` vector rendering at `$0` cost).

## Further Notes

- Strictly preserves MemoDiary's **Decoupled Content & Presentation** invariant: the expanded five **Scenery Realms** remain purely visual presentation and never alter `entries` SQLite rows or Quill Delta JSON.
- Strictly upholds MemoDiary's **Local-First & Zero Network** constraints: zero network calls, zero GPS/location permissions, and 100% deterministic offline keyword matching and procedural vector rendering.
