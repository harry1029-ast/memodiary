---
status: accepted
---

# Home Shell Navigation, Diarist Panel and App Icon Provenance

The 3D book cover is no longer the app's navigation hub. Once the diarist passes the cover (or skips it with `showIntroOnLaunch` off), they land in a root **Home Shell** holding two tabs, 日记 (timeline) and 相册 (album collections), switched by a woodwork **Tab Rail** whose centre **Scroll Roller Button** follows the tab (`写日记` / `新建相册`). The cover's doors *replace* it with the Home Shell on the matching tab, and the cover returns only through `返回封面` in the new left-side **Diarist Panel** (`我的`), which also takes `写作统计`, `回收站` and `导入与备份` out of Settings. Because the Home Shell is a root route, iOS has no swipe-back to fight the panel's left-edge drag. On Android we reserve an upper left-edge band (≤ 200dp, the platform's per-edge cap) from the system Back gesture through a small native method channel, leaving the rest of the edge as normal Back.

## Considered Options

- **Keep the cover as hub and push tabs on top of it**: Rejected because the cover stays underneath. iOS swipe-back and Android Back would then compete with the panel's edge drag and pop to the cover unexpectedly.
- **Five-slot bar (日记 · 相册 · 写 · 复盘 · 搜索) emptying the timeline header**: Rejected for now. The diarist wants the bar as a quick diary/album switch, and the header's 每周复盘 / 搜索 / 设置 stay where users know them.
- **A fixed `写日记` centre button on every tab**: Rejected in favour of a tab-following centre action, so creating an album is as close as writing an entry. The album screen's own create buttons are removed so there is exactly one way to create each.
- **Stock `Scaffold` drawer**: Rejected because its edge drag spans the full screen height, which collides with Android's gesture Back everywhere along the edge.
- **Gesture-only panel**: Rejected as undiscoverable and unreliable on Android. A header avatar button always opens it.

## Consequences

- One root Navigator. Every screen opened from a tab or the panel covers the Home Shell and Tab Rail. Android Back on the shell goes panel → 相册-to-日记 → exit, never to the cover.
- SPEC-022's timeline-header `返回封面` emblem and its pop-or-replace routing are superseded by the panel row.
- The Diarist Panel's profile block is a display-only placeholder (`云皓主人`, `记录今日，也收藏远方`, drawn cloud avatar), and `收藏` shows a dimmed dash. Neither implies a profile or favourites model, which belong to a future spec.
- **App icon provenance:** the launcher icon is a painting supplied by the diarist (the project owner), who confirmed they hold the rights to ship it. It is a first-party asset, not a third-party exception to the $0 FOSS rule, so GEMINI.md's two documented exceptions are unchanged. Icons are generated at build time by a free (MIT) dev-only tool, and the Android 13 monochrome silhouette is drawn in Dart.
