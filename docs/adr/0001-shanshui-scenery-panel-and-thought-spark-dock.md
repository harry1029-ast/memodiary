# Shanshui Scenery Card with Embedded Thought Spark Dock

## Context
The Personal Diary timeline header previously displayed a standalone Xuan paper card containing the "灵感火花 · Thought Spark" prompt. We wanted to introduce a living, interactive Chinese water-ink landscape reflecting real-world seasons, times of day, and weather without crowding the vertical timeline or losing the daily reflective writing trigger.

## Decision
We replace the standalone Thought Spark card with a unified **Shanshui Scenery Card** rendered via a pure Flutter `CustomPainter`. In the timeline feed, the card adopts a 16:9 aspect ratio with a glassmorphic **Thought Spark Dock** resting across its lower edge, preserving prompt rotation and the "由此题落墨" write shortcut. Tapping the landscape expands into a full 3:2 **Contemplation View** with interactive ripples, vertical poetic calligraphy, atmospheric switchers, and paired procedural soundscapes from `AudioSanctumService`. The animation ticker automatically suspends when off-screen to preserve 60 FPS performance and zero idle battery drain.

## Consequences
- Preserves timeline reading flow while introducing a rich living Shanshui aesthetic.
- Zero paid SDKs, zero external asset bloat: 100% vector canvas and procedural offline audio synthesis.
- Clear separation of touch targets between aesthetic contemplation and diary entry creation.

