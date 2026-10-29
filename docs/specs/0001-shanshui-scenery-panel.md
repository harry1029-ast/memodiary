---
id: SPEC-001
title: Shanshui Scenery Card with Embedded Thought Spark Dock
status: ready-for-agent
created_at: 2026-10-29T20:20:00+08:00
---

# Specification: Shanshui Scenery Card with Embedded Thought Spark Dock

## Problem Statement

Diarists opening MemoDiary to the Personal Diary screen (`TimelineScreen`) currently encounter a standalone, static textual prompt card ("Thought Spark") in the timeline header. While functional for writing prompts, it lacks emotional resonance, natural connection to the user's immediate time of day and season, and a meditative visual anchor that makes opening a personal diary feel like unfurling a classical thread-bound scholar's journal. 

Furthermore, a standalone prompt card consumes vertical screen space without visual delight, leaving users with a fragmented header experience that pushes diary entries downward without offering a moment of quiet reflection.

## Solution

A living, interactive Chinese water-ink landscape (**Shanshui Scenery Card**) that replaces the standalone prompt card in the timeline header. 

1. **Dynamic Real-World Reflection**: The card automatically mirrors the diarist's real-world environment:
   - **4 Seasons**: Spring (peach blossoms, willow sprouts, pink petals), Summer (emerald crags, lotus pads, fireflies), Fall (crimson maples, amber foliage, falling leaves), Winter (snow-capped ridges and roofs, warm window hearth glow, snowflakes).
   - **4 Times of Day**: Dawn (rose-gold horizon aurora, morning mist), Day (bright sky, cinnabar sun), Dusk (golden amber glow, lantern on ferryboat prow), Night (deep teal sky, moon with ink wash craters, twinkling stars, glowing paper windows).
   - **5 Weather Modes**: Sunny (clear sky), Cloudy (heavy drifting mountain mists), Rainy (slanting rain streaks, water ripple rings), Stormy (sheet lightning flash, jagged thunderbolt in crags, wind gusts), Snowy (drifting white snowflakes).
2. **Embedded Thought Spark Dock**: A semi-transparent frosted Xuan-paper bottom overlay rests across the lower edge of the 16:9 card, preserving zero-friction access to daily prompts, refresh rotation, and the "由此题落墨" write shortcut into the entry editor.
3. **Contemplation View (`沉浸画卷`)**: Tapping the landscape expands into a full-screen 3:2 modal with tactile lake touch ripples, vertical poetic couplet colophon, manual atmosphere preview pills with a 1-tap *"恢复实时 (Sync Real Time)"* button, and optional paired procedural soundscapes from `AudioSanctumService`.
4. **Minimalist Collapsed Mode**: Users who prefer a text-dense timeline can collapse the card into a slender ~42px Xuan status strip showing atmospheric badges (`[春 · 桃夭]`, `[旭日 · 晴空]`), a one-line prompt, and an expand chevron.
5. **Zero-Overhead Lifecycle**: 100% native Flutter `CustomPainter` with automatic ticker suspension when scrolled off-screen or backgrounded, maintaining 60 FPS and 0% idle battery drain.

## User Stories

1. As a diarist, I want the timeline header to display a living Shanshui water-ink landscape reflecting my current calendar season, so that opening my diary feels harmonious with the natural world outside.
2. As a diarist, I want the scenery painting to automatically change its lighting and celestial bodies according to my local device clock (Dawn, Day, Dusk, Night), so that morning reflections feel fresh and evening journaling feels calm and cozy.
3. As a diarist, I want the weather in the painting to reflect my most recent diary entry's weather tag (or default to sunny), so that my past entries visually ripple into my current app atmosphere.
4. As a writer seeking inspiration, I want the daily Thought Spark prompt to be clearly legible in a semi-transparent dock over the bottom of the painting, so that I can discover reflective writing questions without cluttering my screen.
5. As a writer seeking inspiration, I want to tap a refresh button on the Thought Spark Dock to cycle through different prompts, so that I can explore multiple topics before writing.
6. As a diarist ready to write, I want to tap "由此题落墨" on the Thought Spark Dock to immediately open the entry editor prefilled with the chosen prompt, so that I can seamlessly capture my thoughts without retyping.
7. As a reader scrolling through my timeline, I want the Shanshui Scenery Card to occupy a balanced 16:9 aspect ratio, so that my diary entries remain prominently visible below it.
8. As a contemplative user, I want to tap the scenery area of the card to open an expansive 3:2 full-screen Contemplation View, so that I can pause and appreciate the art and calligraphy in full detail.
9. As an interactive user in the Contemplation View, I want to tap on the lake surface to create expanding ink ripples, so that the painting feels tactile and responsive to my touch.
10. As an exploratory user, I want to manually preview any combination of season, time of day, and weather in the Contemplation View, so that I can see the artwork across all possible atmospheres.
11. As a user who tested different atmospheres, I want to see a clear "恢复实时 (Sync Real Time)" button whenever my preview differs from actual time, so that I can restore the real-world clock with a single tap.
12. As a user who prefers a specific atmosphere (e.g. Winter Night), I want a preference setting in Settings to permanently lock my favorite aesthetic, so that the app always greets me in my preferred mood.
13. As a mindful user meditating in the Contemplation View, I want an ambient soundscape toggle that pairs contextually with the active season and weather (e.g. rain, wind in bamboo, or library hearth), so that I can enjoy a multisensory experience.
14. As a user sensitive to unexpected sounds, I want the Contemplation View soundscape to be muted by default, so that audio never plays without my explicit consent.
15. As a minimalist diarist who prioritizes vertical reading density, I want to tap a collapse button to reduce the scenery card to a slender ~42px Xuan status strip, so that my diary entries move higher up on the screen.
16. As a user with the card collapsed, I want the slim status strip to display my current seasonal seal, time/weather badge, and a one-line prompt, so that I still retain atmospheric context and a writing trigger.
17. As a user who collapsed the card, I want to tap an expand chevron on the status strip, so that I can restore the full 16:9 painting whenever I wish.
18. As a diarist returning to the app, I want my collapsed or expanded preference to persist across app launches, so that I don't have to re-collapse it every time I open the app.
19. As a mobile phone user on battery, I want the painting's animation loop to automatically suspend when the card scrolls out of the viewport, so that the app doesn't drain my battery while I read long entries.
20. As a user switching apps, I want the animation ticker and soundscape to pause when MemoDiary enters the background, so that device resources are conserved.
21. As an admirer of classical typography, I want the 16:9 card to feature an elegant seasonal title and cinnabar seal in the sky margin, so that the visual framing feels authentic to traditional Chinese woodblock books.
22. As an admirer of poetry, I want the full 3:2 Contemplation View to display the complete vertical classical poetic couplet, so that I can appreciate the literature behind each seasonal painting.

## Implementation Decisions

### 1. Module Structure & Responsibility
- **`ShanshuiAtmosphereResolver`**: Pure Dart value object and deterministic resolver. Maps `DateTime` (hour and month) and optional entry weather string into the active `ShanshuiAtmosphereState`.
- **`ShanshuiSceneryCard`**: Composite widget for `TimelineScreen` header. Encapsulates the 16:9 canvas view, the collapsed ~42px status strip, animation ticker lifecycle, and gesture routing.
- **`ThoughtSparkDock`**: Frosted glassmorphic Xuan-paper overlay docked at the bottom of the 16:9 card. Contains prompt text, refresh icon, and "由此题落墨" write button.
- **`ShanshuiCanvas`**: Flutter `CustomPainter` rendering 11 visual layers:
  1. Sky & Xuan paper gradient with weather overlay.
  2. Celestial body (Dawn sun, Day sun, Dusk sun, or Night moon with crater wash) and stars/lightning.
  3. Distant layered misty mountains (Far Mountain 1 & 2).
  4. Midground karst peaks with Cunfa (斧劈皴法) rock cleavage strokes and animated cascading waterfall.
  5. Center island with Two-Tiered Grand Pavilion, glowing lattice windows, and balustrade.
  6. Mirror lake with sun/moon shimmer reflection column and soft vertical ink-wash reflections.
  7. Left waterside two-story pavilion and arched wooden bridge on timber stilts.
  8. Right waterside warm study pavilion with seated scholar silhouette.
  9. Ancient cliff pines with pine needle fans and seasonal trees (peach blossoms in spring, lotus in summer, crimson maple in fall, snow-covered boughs in winter).
  10. Animated flying cranes (hero cranes with red crowns, rising flock, water-skimming cranes).
  11. Animated ferryboat with sculling oar, passenger canopy, boatman, lantern, and angler skiff.
  12. Atmospheric particles (petals, fireflies, maple leaves, snow) + rain/storm/snow precipitation.
  13. Traditional calligraphy colophon and carved cinnabar seal stamp.
  14. Xuan paper vignette edge softening.
- **`ContemplationViewScreen`**: Full-screen modal presenting the 3:2 Shanshui Canvas, seasonal/weather switcher pills, touch ripple listener, "恢复实时" button, and audio soundscape toggle.
- **`ScenerySettingsService`**: Manages persistence of header collapse state and optional pinned atmosphere override using `FlutterSecureStorage`.

### 2. Atmospheric Data Model (Derived from Prototype)
```dart
enum ShanshuiSeason { spring, summer, fall, winter }
enum ShanshuiTimeOfDay { dawn, day, dusk, night }
enum ShanshuiWeather { sunny, cloudy, rainy, stormy, snowy }

class ShanshuiAtmosphereState {
  final ShanshuiSeason season;
  final ShanshuiTimeOfDay timeOfDay;
  final ShanshuiWeather weather;
  final bool isManualPreview;

  const ShanshuiAtmosphereState({
    required this.season,
    required this.timeOfDay,
    required this.weather,
    this.isManualPreview = false,
  });
}
```

### 3. Audio Sanctum Pairing
- Seamlessly reuses [`AudioSanctumService`](file:///home/harry1029/projects/memodiary/lib/features/editor/services/audio_sanctum_service.dart) for offline procedural audio buffers:
  - Rainy / Stormy weather $\to$ `SoundscapePreset.gentleRain`
  - Spring / Summer / Cloudy $\to$ `SoundscapePreset.bambooBreeze`
  - Winter / Night $\to$ `SoundscapePreset.vintageLibrary`
- Audio playback starts muted by default and stops automatically when closing the modal or backgrounding the app.

### 4. Ticker Suspension & Performance
- The `ShanshuiSceneryCard` tracks scroll offset and viewport visibility.
- When scrolled out of the visible screen area or when `AppLifecycleState.paused` is triggered, the `AnimationController` stops ticking, reducing canvas redraw operations to 0 FPS.
- Mobile particle pool size is capped at 32-45 particles to maintain a steady 60 FPS UI frame rate.

## Testing Decisions

A good test validates external user-observable behavior and contracts, not private canvas coordinates or internal painter variables.

### Seams & Modules Tested
1. **`TimelineScreen` Widget Integration** (`test/features/timeline/timeline_screen_test.dart`):
   - Verifies `ShanshuiSceneryCard` renders in place of the old Thought Spark card.
   - Verifies the prompt displays inside `ThoughtSparkDock`; tapping refresh cycles prompts; tapping "由此题落墨" navigates to `EntryEditorScreen` with prefilled text.
   - Verifies tapping the collapse button switches to the ~42px status strip and tapping expand restores the card.
   - Verifies tapping the landscape painting pushes `ContemplationViewScreen`.
2. **`ContemplationViewScreen` Widget Test** (`test/features/scenery/contemplation_view_screen_test.dart`):
   - Verifies rendering the 3:2 canvas, weather badges, and calligraphy.
   - Verifies switching seasons, times of day, or weather modes updates the active atmosphere and displays the "恢复实时" button.
   - Verifies tapping "恢复实时" restores real-time clock state.
   - Verifies tapping the lake surface registers interactive ripples without throwing unhandled exceptions.
   - Verifies soundscape toggle initiates audio via `AudioSanctumService`.
3. **`ShanshuiAtmosphereResolver` Unit Test** (`test/features/scenery/shanshui_atmosphere_resolver_test.dart`):
   - Verifies hour brackets for Dawn (05:00-07:00), Day (07:00-17:00), Dusk (17:00-19:00), and Night (19:00-05:00).
   - Verifies calendar month mapping into 4 seasons.
   - Verifies fallback resolution for entry weather tags.

### Prior Art
- `test/features/timeline/timeline_screen_test.dart`: Timeline feed harness with memory SQLite database and mock media service.
- `test/features/intro/book_intro_screen_test.dart`: Canvas animation loop and ticker lifecycle testing without timeout.
- `test/features/editor/audio_sanctum_test.dart`: Procedural audio synthesizer verification and modal interaction.

## Out of Scope
- Custom freehand stylus drawing or altering the rich-text editor's internal canvas.
- Third-party online weather API integration (violates zero-cloud, 100% offline, $0 cost core invariants).
- Heavy external animation runtimes (Rive, Lottie, video playback).

## Further Notes
- **Aesthetic Decoupling**: The Xuan paper background (`#F6F2E9`) and ink wash tones remain decoupled from system dark mode, preserving the physical feel of Chinese woodblock printing across all lighting conditions.
- **Accessibility**: All interactive elements (refresh button, "由此题落墨", collapse chevron, atmospheric switcher pills) carry semantic labels and minimum 44px touch targets.
