---
id: SPEC-004
title: Three-Realm Scenery Variations (Nature, Indoor Tea Hall & Outdoor Market Street) & Journal Situation Detection
status: ready-for-agent
created_at: 2026-11-01T19:30:00+08:00
---

# Specification: Three-Realm Scenery Variations & Journal Situation Detection

## Problem Statement

While the existing **Shanshui Scenery Card** and **Contemplation View** reflect real-world calendar seasons, clock hours, and entry weather tags, they always depict a solitary mountain-and-lake wilderness (`林泉`). In practice, diarists write across very different daily situations:

1. **Missing Spatial Resonance**: Writing quiet late-night reflections at a study desk over warm tea, or capturing quick impressions while commuting and strolling through a lively street market, feels disconnected from a remote wilderness panorama.
2. **Privacy vs. Context Dilemma**: Dynamically matching scenery to the user's real-world indoor/outdoor situation via continuous GPS or geofencing would violate MemoDiary's non-negotiable **100% Local-First**, **Zero Tracking**, and **Zero Idle Battery Drain** invariants—while still failing to distinguish a living room sofa from an outdoor park bench.
3. **Lack of Transparent Control**: If an app infers context automatically from diary writing, users need clear visibility into *why* the scenery shifted and a frictionless way to override or lock their preferred realm whenever desired.

## Solution

Expand the **Shanshui Scenery Card** and **Contemplation View** into a cohesive **Three-Realm Architecture (`三境圆融`)** powered by a 100% offline, deterministic journal-situation inference engine:

1. **Three Scenery Realms (`Scenery Realm` / `ShanshuiRealm`)**:
   - **Nature (`nature` · 林泉)**: The existing solitary water-ink mountains, mirror lake, pavilions, ferryboat, and cranes—serving as the serene baseline default.
   - **Indoor (`indoor` · 雅室茶寮)**: A 3:2 classical scholar's tea hall featuring perspective rosewood floorboards, Xuan-plaster walls, rear translucent shoji lattice doors, a central circular moon gate with silk banners, a foreground tea table with curling incense smoke and tea steam, flickering lanterns, a winter charcoal brazier (`红泥小火炉`), volumetric sun/moon beams, and a left circular moon window (`月洞窗`) framing live outdoor seasons, celestial bodies, and precipitation.
   - **Outdoor (`outdoor` · 市井古街)**: A 3:2 ancient Chinese mountain market street featuring a towering Cunfa mountain peak, central four-pillar ceremonial Paifang gate (`牌坊`), flanking two-story eaved shopfronts (`重檐飞檐`), billowing fabric awnings, swaying red paper lanterns, steaming pastry and hot noodle stalls, wet stone-street reflections, and a time-aware townsfolk crowd lifecycle (0 walkers at Dawn, 22 bustling vendors and shoppers at Day/Dusk, 5 late-night figures at Night, carrying oiled-paper umbrellas in rain/snow).
2. **On-Device Journal Situation Detection (`随文入境`)**:
   - Scores the diarist's most recent *accessible* (non-deleted, unlocked, unsealed) diary entry's title and plain text against a curated Chinese and English spatial keyword lexicon (`indoor`, `outdoor`, `nature`) in `< 1ms` pure Dart.
   - Applies a **24-hour recency window**: entries created within the last 24 hours with a clear spatial signal dynamically attune the active **Scenery Realm**.
   - Gracefully falls back to **Nature (`林泉`)** whenever no recent entry exists, the latest entry is older than 24 hours, or the text is spatially neutral/ambiguous.
3. **Poetic Attribution & 1-Tap Override**:
   - Displays a subtle seal badge on the **Shanshui Scenery Card** (e.g. `随文入境 · 雅室` when inferred, or `雅室` / `市井` / `林泉` when pinned).
   - Tapping the realm badge opens a 1-tap realm switcher sheet (`[Auto (随文入境), Nature (林泉), Indoor (雅室), Outdoor (市井)]`), while tapping the canvas itself continues to open the fullscreen **Contemplation View**.
4. **Full-Subsystem Parity & Performance**:
   - Full support across the **Shanshui Scenery Card** (both expanded 16:9 and collapsed ~42px strip), fullscreen 3:2 **Contemplation View** (with realm switcher pills, realm-specific calligraphy colophons, interactive petal swirls and street puddle ripples, and paired procedural soundscapes), and Settings **"画卷境域 (Scenery Realm)"** preferences.
   - Modular `CustomPainter` implementations cache static architectural geometry into immutable `ui.Picture` layers so the 60 FPS ticker repaints only dynamic actors, preserving scroll-based ticker auto-suspension.

## User Stories

1. As a diarist, I want the **Shanshui Scenery Card** to support three distinct **Scenery Realms**—Nature (`林泉`), Indoor (`雅室`), and Outdoor (`市井`)—so that my timeline header reflects the full breadth of solitude, home study, and everyday human life.
2. As a homebound diarist writing about reading at my desk, brewing tea, or resting in my bedroom, I want the scenery to attune to the Indoor Tea Hall (`雅室`), so that the app mirrors my quiet interior sanctuary.
3. As an active diarist writing about commuting, walking downtown, visiting a café, or browsing a market, I want the scenery to attune to the Outdoor Market Street (`市井`), so that my timeline echoes the lively world around me.
4. As an outdoor diarist writing about hiking mountains, camping, or visiting a forest or lake, I want the scenery to attune to the Nature wilderness (`林泉`), so that my outdoor excursions are reflected in the ink landscape.
5. As a bilingual writer, I want journal situation detection to recognize both Chinese and English spatial keywords in my entry title and body text, so that realm inference works regardless of the language I journal in.
6. As a diarist who wrote an entry within the past 24 hours, I want my inferred **Scenery Realm** to remain active across app launches during that 24-hour window, so that today's mood persists naturally throughout my day.
7. As a diarist who has not written an entry in over 24 hours, I want the **Scenery Realm** to gracefully decay back to the default Nature (`林泉`) realm, so that stale entries from days ago do not permanently lock my timeline aesthetic.
8. As a reflective writer composing an abstract or emotionally neutral entry without spatial keywords, I want the resolver to fall back cleanly to Nature (`林泉`), so that the app never guesses arbitrarily.
9. As a privacy-conscious user with PIN-locked entries or sealed Time Capsules, I want situation detection to strictly skip locked, soft-deleted, and unrevealed Time Capsule entries, so that hidden entry contents never leak onto my timeline header.
10. As a privacy-conscious user, I want all situation inference to run 100% offline on my device without GPS permissions or network requests, so that my location and diary text remain completely private and battery-free.
11. As a curious user whose scenery shifted automatically based on a recent entry, I want to see a subtle `随文入境` attribution badge alongside the active realm name on the **Shanshui Scenery Card**, so that I understand why the scene changed.
12. As an empowered user, I want to tap the realm badge on the **Shanshui Scenery Card** to open a 1-tap realm switcher sheet (`Auto · 随文入境`, `林泉`, `雅室`, `市井`), so that I can instantly override an inference or lock my favorite realm without visiting Settings.
13. As a user scrolling my timeline, I want tapping the main canvas area of the **Shanshui Scenery Card** (outside the **Thought Spark Dock** and realm badge) to still open the fullscreen **Contemplation View**, so that navigation remains predictable and free of gesture conflicts.
14. As a minimalist user with the **Shanshui Scenery Card** collapsed into the ~42px status strip, I want the collapsed strip to reflect the active **Scenery Realm** seal and remain expandable in one tap, so that atmospheric context is preserved in compact mode.
15. As an admirer of the Indoor Tea Hall (`雅室`), I want the left circular moon window (`月洞窗`) to dynamically display the current season's courtyard tree, sun or moon, stars, lightning, rain streaks, or snow accumulation on the sill, so that the indoor room stays connected to real-world time and weather.
16. As an admirer of the Indoor Tea Hall (`雅室`), I want indoor lanterns, candles, and volumetric window light beams to adjust automatically across Dawn, Day, Dusk, Night, and stormy weather—and a warm red-clay charcoal brazier (`红泥小火炉`) to appear in Winter or snowy weather—so that the study feels alive and cozy.
17. As an admirer of the Outdoor Market Street (`市井`), I want crowd activity and market stalls to follow a realistic daily rhythm—0 walkers at tranquil Dawn, bustling vendors, shoppers, and steaming food stalls during Day and Dusk, and a quiet late-night noodle stall with glowing red lanterns and a few evening walkers at Night—so that the street breathes with the local clock.
18. As an admirer of the Outdoor Market Street (`市井`), I want townsfolk to carry oiled-paper umbrellas (`油纸伞`) during rainy, stormy, or snowy weather while stone flagstones reflect warm lantern light and raindrop ripples, so that weather changes transform the street atmosphere.
19. As a contemplative user in the fullscreen 3:2 **Contemplation View**, I want to preview and switch between all three **Scenery Realms** (`林泉`, `雅室`, `市井`) alongside Season, Time of Day, and Weather pills, so that I can explore every combination of artwork and poetry.
20. As an interactive user in the fullscreen **Contemplation View**, I want tapping the Indoor canvas to spawn swirling blossom petals and floating motes, and tapping the Outdoor street to spawn stone-puddle ripples and festive petals, so that every realm responds tactilely to my touch.
21. As a user previewing realms or weather in the **Contemplation View**, I want the `恢复实时` sync button to appear whenever the previewed realm or atmosphere diverges from my real-time resolved state and restore it in a single tap.
22. As a listener activating ambient audio in the **Contemplation View**, I want the paired offline soundscape to adapt contextually to both **Scenery Realm** and weather (e.g. `vintageLibrary` hearth room tone for Indoor, `gentleRain` during rain/storms, `bambooBreeze` for clear Nature/Outdoor), starting muted by default.
23. As a user customizing app preferences in Settings, I want a **"画卷境域 (Scenery Realm)"** setting offering `Auto (随文入境)`, `Nature (林泉)`, `Indoor (雅室)`, and `Outdoor (市井)` that stays synchronized with on-card overrides and resets cleanly when restoring real-time sync.
24. As a mobile user on battery power, I want static architectural layers in the Indoor and Outdoor painters to be cached via `ui.Picture` and the 60 FPS ticker to suspend automatically when scrolled off-screen or backgrounded, so that complex scenes never cause frame drops or battery drain.
25. As a user relying on screen readers or large system font sizes, I want all realm badges, switcher controls, and canvas overlays to expose descriptive `Semantics` labels and clamp horizontal chip text scaling (`<= 1.3`), so that the UI remains accessible and free of layout overflow down to 320px viewports.

## Implementation Decisions

### 1. Atmospheric & Realm Domain Model (Derived from Prototype)
- Extend the immutable atmospheric state model with a first-class **Scenery Realm** dimension (`ShanshuiRealm`) and source attribution (`isJournalInferred`), defaulting `realm` to `ShanshuiRealm.nature` so all existing callers remain backward-compatible:

```dart
// Derived from prototype seasonal indoor/outdoor metadata & realm taxonomy
enum ShanshuiRealm {
  nature(id: 'nature', shortNameZh: '林泉', nameEn: 'Nature'),
  indoor(id: 'indoor', shortNameZh: '雅室', nameEn: 'Indoor Tea Hall'),
  outdoor(id: 'outdoor', shortNameZh: '市井', nameEn: 'Ancient Market Street');
  // ...
}

enum SceneryRealmPreference { auto, nature, indoor, outdoor }

class ShanshuiAtmosphereState {
  final ShanshuiRealm realm;
  final ShanshuiSeason season;
  final ShanshuiTimeOfDay timeOfDay;
  final ShanshuiWeather weather;
  final bool isJournalInferred;
  final bool isManualPreview;
  // ...
}
```

- Each `(ShanshuiSeason, ShanshuiRealm)` pair resolves realm-specific classical Chinese titles, poetic couplets, and 4-character cinnabar seal inscriptions from the prototype:
  - **Indoor (`雅室`)**: Spring `春 · 桃夭茶寮` (`春风入室`), Summer `夏 · 翠竹听荷` (`夏木阴阴`), Fall `秋 · 霜枫品茗` (`秋水长天`), Winter `冬 · 瑞雪温炉` (`瑞雪迎春`).
  - **Outdoor (`市井`)**: Spring `春 · 桃李春风集` (`春和景明`), Summer `夏 · 翠峰槐夏市` (`碧山晴夏`), Fall `秋 · 霜峰丹枫街` (`金秋盛景`), Winter `冬 · 瑞雪岁朝集` (`万山飞雪`).
  - **Nature (`林泉`)**: Preserves existing `SPEC-001` titles, couplets, and seals verbatim.

### 2. Journal Situation Detection Contract
- Expose situation resolution directly through `ShanshuiAtmosphereResolver.resolve(...)` by accepting optional context from the latest accessible diary entry (creation/entry timestamp, optional title, plain text, and realm preference), avoiding any extra public service seam.
- **Privacy Filter**: Callers on the timeline must select the newest entry where `isDeleted == false`, `isLocked == false`, and `unlockAt == null || !unlockAt.isAfter(now)` before passing text to the resolver. Locked or sealed Time Capsule entries must never influence the displayed realm.
- **Resolution Precedence**:
  1. Explicit `SceneryRealmPreference` (`nature`, `indoor`, or `outdoor`): sets `realm` directly with `isJournalInferred = false`.
  2. `SceneryRealmPreference.auto` with an accessible entry within the **24-hour recency window** (`now.difference(entryTimestamp) <= Duration(hours: 24)`): scores normalized Chinese substrings and word-bounded English keywords across `indoor`, `outdoor`, and `nature` lexicons (weighting title matches 2x body matches). If a single realm holds a strictly highest positive score, selects that realm with `isJournalInferred = true`.
  3. **Fallback**: If no accessible entry exists within 24 hours, or top lexical scores are zero or tied, resolves `ShanshuiRealm.nature` with `isJournalInferred = false`.
- **Soundscape Pairing**:
  - Rainy or Stormy weather across any realm -> `SoundscapePreset.gentleRain`.
  - `ShanshuiRealm.indoor` (non-rainy) -> `SoundscapePreset.vintageLibrary` (warm hearth & quiet study tone).
  - `ShanshuiRealm.nature` or `ShanshuiRealm.outdoor` in Winter or Night -> `SoundscapePreset.vintageLibrary`; otherwise `SoundscapePreset.bambooBreeze`.

### 3. Encrypted Preference Persistence
- Extend `ScenerySettingsService` with a dedicated secure-storage key (`memodiary_scenery_realm_preference`) storing `SceneryRealmPreference` (`auto` by default).
- Selecting a realm from either the **Shanshui Scenery Card** 1-tap realm switcher sheet or Settings **"画卷境域 (Scenery Realm)"** writes to the same preference key; resetting atmosphere overrides in Settings also resets the realm preference back to `auto`.

### 4. Modular Painters, Static Layer Caching & Phased Delivery
- Keep the three realms cleanly separated behind modular `CustomPainter` implementations orchestrated by `ShanshuiSceneryPainting`:
  - **Nature**: Existing `ShanshuiCanvasPainter`.
  - **Indoor (`AncientRoomPainter`)**: Renders rear translucent shoji doors, perspective Xuan walls, ceiling beams, rosewood floorboards, right wooden slat partition with cyan silk alcove and octagonal lantern, center circular moon gate with swaying cream silk banners, volumetric window/gate `BlendMode.screen` light rays, porcelain flowerpots, embroidered floor cushions, conditional winter charcoal brazier, rosewood tea table with celadon tea set, conical incense burners with rising smoke/steam wisps, painted plum-blossom table lantern, bamboo chandelier, floating dust motes/petals, and the left elliptical moon window clipping live outdoor sky, celestial body, courtyard tree, seasonal particles, lightning, and rain/snow.
  - **Outdoor (`OutdoorStreetPainter`)**: Renders sky/celestial/clouds/birds, Cunfa central mountain peak and ridges, perspective flagstone avenue with wet/night lantern reflections and puddle ripples, four-pillar ceremonial Paifang gate, flanking two-story eaved shopfronts with vertical red couplet banners and slanted fabric awnings, foreground pastry/fruit and hot noodle stalls with rising steam, swaying red paper lanterns, precipitation, and time-filtered townsfolk crowd (derived from prototype crowd rules: Dawn = 0 figures; Day & Dusk = full bustling market of walkers and vendors; Night = sparse evening walkers plus open late-night noodle stall; rainy/stormy/snowy walkers carry oiled-paper umbrellas).
- **Static `ui.Picture` Layer Caching**: Complex static architectural and furniture geometry in `AncientRoomPainter` and `OutdoorStreetPainter` is recorded once per `(canvasSize, season, timeOfDay, weather)` tuple into a cached `ui.Picture` (disposed properly on cache invalidation and widget unmount), while dynamic actors (lantern sway/glow, smoke/steam, walkers, particles, precipitation, ripples, calligraphy toggle) paint per frame on top.
- **Interaction Separation**:
  - On `TimelineScreen`, tapping the realm seal badge opens the 1-tap realm switcher modal bottom sheet; tapping the painting canvas opens **Contemplation View**.
  - Inside **Contemplation View**, tapping the canvas triggers realm-appropriate interactive feedback (lake ripples in Nature, swirling petal/mote bursts in Indoor, stone-street ripples and petal sparks in Outdoor), and horizontal switcher pills include a **Scenery Realm** row alongside Season, Time of Day, and Weather.
- **Phased Execution**:
  - **Phase A**: Domain model (`ShanshuiRealm`, `SceneryRealmPreference`), journal situation detection in `ShanshuiAtmosphereResolver`, `ScenerySettingsService` persistence, `AncientRoomPainter` (Indoor Tea Hall), and end-to-end Card, **Contemplation View**, and Settings integration.
  - **Phase B**: `OutdoorStreetPainter` (Outdoor Market Street) with `ui.Picture` architectural caching, dynamic crowd lifecycle, umbrella weather states, and full regression certification.

## Testing Decisions

### What Makes a Good Test
- Assert external user-observable behavior, state transitions, privacy boundaries, and persisted preferences at high-level seams—never private `CustomPainter` helper coordinates, internal particle array indices, or `ui.Picture` cache handles.
- Guard all widget tests against repeating animation deadlocks using bounded `tester.pump(duration)` steps and verify scroll-based ticker suspension (`isVisible`).

### Seams & Modules Tested
1. **`ShanshuiAtmosphereResolver` & `ScenerySettingsService` (Domain & Persistence Seam)**:
   - Chinese and English keyword inference across `indoor`, `outdoor`, and `nature` entries, title weighting, tie/neutral fallback to `nature`, and 24-hour recency expiration boundary (`<= 24h` active vs `> 24h` fallback to `nature`).
   - Precedence of `SceneryRealmPreference` manual locks over `auto` inference, realm-specific seasonal titles/poems/seals, realm-aware `SoundscapePreset` pairing, and `ScenerySettingsService` round-trip persistence.
2. **`TimelineScreen` (End-to-End Timeline Widget Seam)**:
   - Rendering the inferred realm and `随文入境` badge from recent accessible SQLite entries; excluding soft-deleted, PIN-locked, and sealed Time Capsule entries from inference.
   - Opening the 1-tap realm switcher sheet from the realm badge, overriding/persisting a realm or restoring `Auto`, preserving collapsed strip realm seals, navigating to **Contemplation View** on canvas tap, and suspending the ticker when scrolled off-screen.
3. **`ContemplationViewScreen` (Fullscreen Interactive Widget Seam)**:
   - Rendering and switching across all three **Scenery Realms** (`林泉`, `雅室`, `市井`), displaying realm-specific titles, couplets, and seals, triggering `恢复实时` when realm preview diverges from real-time state, updating `AudioSanctumService` presets on realm change, and handling interactive canvas taps across viewports without layout overflow.
4. **`SettingsScreen` (Preferences Widget Seam)**:
   - Selecting `[Auto (随文入境), Nature (林泉), Indoor (雅室), Outdoor (市井)]` under **"画卷境域 (Scenery Realm)"** and verifying persistence and reset synchronization.

### Prior Art
- Existing resolver and secure-storage unit tests in `shanshui_atmosphere_resolver_test.dart`.
- Existing fullscreen contemplation widget tests in `contemplation_view_screen_test.dart`.
- Existing header card, scroll suspension, and settings override tests in `timeline_screen_test.dart` and `settings_screen_test.dart`.

## Out of Scope

- Continuous or foreground OS GPS, geofencing, Wi-Fi SSID scanning, or pedometer hardware permissions (deliberately excluded to uphold zero-permission privacy and zero battery drain).
- Bundled neural/LLM text-embedding models for entry classification (curated deterministic lexicon keeps binary size and latency at zero).
- Custom user-configurable fallback realm beyond `Nature (林泉)` when `Auto` has no recent spatial match (reserved for a future default-scenery customization enhancement).
- Side-by-side dual-canvas comparison mode or 4-season quad grid mode from the desktop web prototype (those existed purely as prototype inspection scaffolding).

## Further Notes

- Strictly preserves MemoDiary's **Decoupled Content & Presentation** invariant: `ShanshuiRealm` is purely ambient timeline/contemplation presentation state and never mutates `entries` rows or Quill Delta JSON.
- Strictly upholds **Manifest Defense & Network Quarantine**: 100% vector canvas and pure-Dart lexical matching with zero network imports or OS permissions.
