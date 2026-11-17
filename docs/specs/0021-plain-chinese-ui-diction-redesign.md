---
id: SPEC-021
title: Plain Modern Chinese UI Diction Redesign
status: ready-for-agent
created_at: 2026-11-17T23:30:00+08:00
adr: ADR-0012
---

# Specification: Plain Modern Chinese UI Diction Redesign

## Problem Statement

Across the application, nearly every screen, button, tooltip, setting, dialog, and empty state is written in dense, archaic literary Chinese (e.g., `设置与守拙`, `岁暮拾遗`, `复墨还案`, `焚稿归尘`, `即时拓影`, `古法鱼锁`, `砚池墨渧`) paired with redundant English subtitles (e.g., `加粗 · Bold`, `收集箱 · Collection Box`, `全部时日 · All Time`). Instead of feeling refined, the copy is bloated and forces the diarist to decode metaphors before understanding what a control does or what a screen represents.

## Solution

Redesign all user-facing UI diction across the app under a two-tier **Plain Controls, Minimal Aesthetic Nouns** policy (ADR-0012):

1. **Plain Modern Chinese for 100% of Functional UI:** Rewrite every button, menu item, tooltip, accessibility label, dialog, snackbar, permission description, filter chip, timestamp, empty state, and statistic in clear, concise, everyday Chinese.
2. **Short Recognizable Nouns Only for Visual Presets:** Keep brief traditional names strictly where the diarist is selecting a visual stationery, album theme, seal style, or calligraphy brush preset (e.g., `朱丝宣纸`, `冷金暖笺`, `水墨丹青`, `朱文 / 白文`, `狼毫 / 兼毫 / 羊毫` with plain stiffness hints), while deleting all poetic descriptions.
3. **Single-Language Chinese Cleanup:** Strip all redundant inline English tags and English section subtitles across the UI in preparation for a separate English UI revamp later.
4. **Preserve Visual Artwork & Future Hooks:** Keep seasonal poems inside Shanshui and cover illustrations, keep the current brand name (`拾光日记`) and default signature seal (`心迹安放`) ahead of the upcoming aesthetic overhaul, preserve `{夹注:...}` inline markup syntax, and keep existing lunar day/range helpers intact for a future app-wide lunar date format toggle.

## User Stories

### Global Diction & Language Consistency
1. As a diarist, I want every interactive button, menu, dialog, and tooltip to use everyday modern Chinese, so that I immediately understand what tapping it will do without decoding literary metaphors.
2. As a diarist, I want redundant mixed English labels (such as `· Bold`, `· Collection Box`, and English section subheaders) removed from the Chinese interface, so that the UI reads cleanly in one language.
3. As a visually impaired diarist using a screen reader, I want every updated control's accessibility label and tooltip to match the new plain Chinese terminology, so that spoken navigation matches what is shown on screen.
4. As a diarist, I want poetic filler sentences and decorative slogans removed from functional screens and empty states, so that the visual design breathes without cluttered text.

### Chronicle Desk Timeline & Date Index
5. As a diarist viewing the **Chronicle Desk**, I want the header, entry count, filter button, and empty/error states to say `日记`, `共 N 篇`, `筛选`, `暂无日记`, and `加载失败` / `重试`, so that browsing my diary feels effortless.
6. As a diarist filtering entries with the **Date Index Tray**, I want the ten-day period chips to display `上旬 (1–10日)`, `中旬 (11–20日)`, and `下旬 (21日–月底)` by default, while keeping lunar range formatting available for a future lunar calendar option.
7. As a diarist scanning the timeline spine, I want day badges to show numeric Gregorian days (`1日 … 25日 … 31日`) by default, while preserving the traditional lunar day formatter (`初一 … 廿五 … 三十`) for future lunar-mode support.
8. As a diarist looking at a locked **Time Capsule** entry, I want clear status labels (`时间胶囊`, `待解锁`, `将于 YYYY年M月d日 解锁`, `还有 N 天解锁`), so that I immediately know when it opens.
9. As a diarist using the mood/weather filter sheet, I want the sheet title and filter chips to use plain mood and weather names (`心情`, `天气`, `全部`, `清除筛选`), so that filtering matches the editor tags.

### Thread-Bound Folio & Reading Perspectives
10. As a diarist reading an entry in the **Thread-Bound Folio**, I want the timestamp to display standard 24-hour `HH:mm` time (`2026.11.23 · 21:15`) instead of ancient Shichen/Ke (`亥时初刻`), so that I can tell the exact time an entry was written.
11. As a diarist viewing an entry that includes an **Interlinear Sub-Note** (`{夹注:...}`), I want the Folio cover to display `批注：` instead of `眉批夹注：`, while continuing to parse `{夹注:...}` in my saved entries.
12. As a diarist switching **Reading Perspective**, I want concise layout names (`原样`, `朱丝竖排`, `方格竖排`, `暗夜横排`) with short plain descriptions (`按日记原信纸显示`, `竖排红线`, `竖排方格`, `深色横排`), so that I know how each mode changes the page layout.
13. As a diarist opening the Folio page-jump index or attached-photo sleeve modal, I want clear labels (`目录跳转`, `封面`, `正文第 N 页`, `插图页`, `共 N 张照片`, `查看大图`, `跳至该页`), so that navigating a multi-page entry is straightforward.

### Entry Editor, Toolbar, Scholar's Stationery Chest & Media Tray
14. As a diarist using the **Writing Dock** and **Keyboard Accessory Row**, I want plain Chinese tooltips (`加粗`, `斜体`, `下划线`, `删除线`, `一级标题`, `二级标题`, `引用`, `无序列表`, `有序列表`, `夹注`, `插入图片`, `插入短视频`, `语音听写`, `字体排版`, `信纸模板`, `背景音`), so that every formatting tool is unmistakable.
15. As a diarist opening the **Scholar's Stationery Chest**, I want the five tool compartments labeled directly by function (`信纸`, `排版`, `背景音`, `定时锁`, `笔刷动画`) rather than antique names (`叠印花笺`, `青花笔架`, `桐木古琴`, `古法鱼锁`, `双管毛笔`), so that I can find the right setting in one glance.
16. As a diarist adjusting typography inside the **排版** panel, I want clear control labels (`字体`, `字号`, `行距`, `文字颜色`, `居中对齐`, `黑色`, `朱红`, `墨绿`), so that styling text feels intuitive.
17. As a diarist playing ambient audio inside the **背景音** panel, I want recognizable sound names (`雨声`, `竹林微风`, `书房白噪音`, `键盘敲击`, `关闭背景音`) instead of cryptic idioms like `砚池墨渧` or `芸窗缃帙`.
18. As a diarist scheduling a time-locked entry inside the **定时锁** panel, I want clear presets and status text (`定时解锁`, `1个月后`, `到元旦`, `1年后`, `自定义日期`, `解除锁定`, `未锁定`), so that I never misconfigure an unlock date.
19. As a diarist configuring **Ink Choreography** inside the **笔刷动画** panel, I want plain mode names (`逐笔书写`, `同时书写`, `仅墨迹`, `无动画`), plain cadence/sound toggles (`0.5x 慢速`, `1.0x 标准`, `1.8x 快速`, `书写音效`), and concise brush presets (`狼毫 (偏硬)`, `兼毫 (适中)`, `羊毫 (偏软)`), so that animation behavior is immediately clear.
20. As a diarist picking mood and weather on the **Journal Letterhead**, I want everyday Chinese options (`低落`, `疲惫`, `平静`, `开心`, `喜悦` and `晴天`, `多云`, `下雨`, `大风`, `下雪`) without English subtitles, so that tagging how I feel is natural.
21. As a diarist managing collected photos and videos in the **Staging Handscroll** and **Tucked Prints** overlay, I want clear media labels (`待选照片`, `本页照片`, `照片`, `视频`, `添加到本页`, `移回待选`, `收起本页照片`, `移除`), so that mounting media onto sheets is self-explanatory.

### Stationery Templates & Custom Template Editor
22. As a diarist choosing a stationery template, I want short recognizable style names (`朱丝宣纸`, `冷金暖笺`, `竹青方格`, `松烟暗夜`) and plain material/ink/seal tags (`宣纸`, `洒金`, `素白`, `牛皮纸`, `暗夜`, `朱文`, `白文`, `不加盖`) with zero poetic filler descriptions.
23. As a diarist creating or editing a custom template, I want plain Chinese form labels and color names (`新建信纸` / `编辑信纸`, `保存`, `信纸名称`, `纸张颜色`, `行距`, `左右边距`, `默认字体`, `系统默认`, `线条样式`, `纸张质感`, `线条颜色`, `印章样式`, and `纯白`, `象牙白`, `米黄`, `牛皮纸色`, `淡绿`, `浅蓝`, `浅粉`, `浅紫`, `浅灰`), so that customizing paper requires no guesswork.

### Shanshui Scenery & Book Intro Cover
24. As a diarist switching **Scenery Realm**, I want clean labels (`自动`, `山水`, `室内`, `街市`) with short plain descriptions (e.g., `根据最近日记自动切换`), and plain time/weather chips (`清晨`, `白天`, `傍晚`, `夜晚`; `晴天`, `多云`, `小雨`, `雷雨`, `下雪`), while keeping the classical poem and seal inside the painting intact.
25. As a diarist opening the 3D Book Intro, I want clean navigation labels (`左滑翻开`, `选择栏目`, `私人日记`, `旅行相册`, `进入`) while keeping the book cover title and seasonal cover verse intact until the future aesthetic overhaul.

### Search, Weekly Review, Analytics, Recycle Bin & Settings
26. As a diarist searching entries and photos, I want plain search UI copy (`搜索日记、心情或照片文字`, `全部`, `日记`, `照片文字`, `筛选条件:`, `全部时间`, `本周`, `本月`, `自定义日期范围...`, `按心情筛选`, `按天气筛选`, `含照片`, `每周复盘`, `重置筛选`, `找到 N 篇日记 · M 处照片文字`, and plain empty states), so that search feedback is direct.
27. As a diarist using **Weekly Review**, I want plain labels (`每周复盘`, `本周每日记录`, `写本周复盘`, `查看复盘`, `今日暂无记录`, `已完成`, `本周概览`, `篇日记`, `字`, `写作天数`, `本周总结`, `分享`, `继续编辑`), and I want newly created weekly debriefs to default to `第N周复盘` without altering already-saved entries.
28. As a diarist checking **Writing Analytics**, I want plain metrics (`写作统计`, `总篇数`, `总字数`, `当前连续写作`, `最长连续写作`, `年度写作热力图`, `心情分布`) and clean shared summary text.
29. As a diarist managing deleted entries in the **Recycle Bin**, I want plain destructive-action clarity (`回收站`, `清空回收站`, `确定彻底删除全部 N 篇日记？删除后无法恢复。`, `恢复`, `彻底删除`, `N 天后自动清除`, `删除于 YYYY年M月d日 · HH:mm`, `回收站为空`), so that I never trigger an irreversible action by misunderstanding a euphemism.
30. As a diarist adjusting **Settings**, **Backup**, **OCR Backfill**, and **Permissions**, I want plain section headers and descriptions (`设置`, `隐私保护`, `开卷动画`, `外观主题`, `签名印章`, `存储与清理`, `写作提醒`, `导入与导出`, `权限管理`, `相机`, `语音听写`, `相册与文件`, `离线文字识别索引`, `导出加密备份 (.mdbak)`, `从备份恢复`, `导入文本`, `导出日记`), so that privacy, backup, and storage controls are crystal clear.

### Travel Albums & Photobook Studio
31. As a diarist organizing travel albums, I want plain labels (`旅行相册`, `新建相册`, `编辑相册`, `封面印章（选填）`, `路线（选填）`, `相册简介（选填）`, `照片备注`, `暂无备注`, `浏览画册`, `进入排版`, `导出画册 PDF`, `收集箱`, `封底`, `封面`) with `山河沿路，笔底留痕` removed from default placeholders.
32. As a diarist picking a photobook theme, I want concise theme names (`水墨丹青`, `东方花苑`, `留白青瓷`, `盛夏海风`, `拾光彩虹`) with poetic multi-sentence descriptions removed.

## Implementation Decisions

- **Diction Policy & Glossary Alignment (ADR-0012):** All copy updates follow the canonical terms and `_Avoid_` lists documented in `GLOSSARY.md`. No implementation of `AppLocalizations` / `.arb` i18n infrastructure is performed here; strings are cleaned up in-place across feature modules and feature string constant tables.
- **Preserved Data, Syntax, and Future Hooks:**
  - Persisted SQLite rows (existing entry titles, weekly review titles, user seal text, `{夹注:...}` inline tags) are not mutated by migration or cleanup.
  - The traditional day formatter (`初一 … 廿五 … 三十`) and lunar ten-day period ranges (`初一–初十`, `十一–二十`, `廿一–晦日`) remain preserved as callable helpers alongside the new Gregorian defaults (`numeric day`, `1–10日 / 11–20日 / 21日–月底`), ready for a future user setting to toggle lunar date display app-wide.
  - Brand name `拾光日记`, default seal `心迹安放`, and classical verses rendered inside the Shanshui painting and Book Intro cover remain untouched pending a dedicated future aesthetic overhaul.
- **Affected Feature Modules:**
  - *Intro & Scenery*: Book intro stage, scenery realm switcher, and scenery atmosphere badge/time/weather getters (leaving painting poems intact).
  - *Timeline & Folio*: Chronicle desk header, empty states, filtered empty state, date index tray, timeline date spine item, time capsule card, charm filter sheet, folio metadata formatter, reading perspectives & sheet, page jump sheet, photo sleeve modal, content leaf headers, and polaroid mini-card.
  - *Editor & Scholar's Chest*: Writing dock, keyboard accessory row, editor toolbar, formatting ribbon, journal letterhead mood/weather options, staging handscroll & tucked prints controls, scholar chest artifact labels and sub-panels (stationery fan, brush mountain, guqin zither, fish lock, twin bamboo brushes / ink choreography labels & trial rice-grid).
  - *Templates*: Built-in stationery suite definitions, substrate/ink/seal labels, switcher sheet/cards, delete dialog, and custom template editor + color swatches.
  - *Search, Weekly Review, Analytics, Recycle Bin, Settings, Import/Export*: Search header bars, filter chips, results list, empty states, OCR photo viewer, natural-language search parser display summaries (keeping keyword matching compatible with both plain and legacy mood/weather words), weekly review list & detail screens, analytics dashboard & heatmap/mood cards, recycle bin screen & dialogs, settings screen, notification settings card, OCR backfill dialog, PDF export preview screen.
  - *Travel Albums & Photobook Studio*: Album studio string constants, album theme catalog, collections screen, workspace screen, book overview, page editor, flipbook, creation/edit sheet, photo annotation sheet, ingestion progress dialog, studio drawers, and PDF export preview sheet.
- **Accessibility Parity:** Every `Semantics` label and `tooltip` paired with a renamed button or panel is updated to use the same plain Chinese phrasing so automated accessibility audits and screen readers remain consistent.

## Testing Decisions

Good tests in this redesign verify **user-visible labels, accessibility semantics, and behavioral outcomes** at the highest existing seams—never private helper methods or widget internals:

1. **Highest-Seam Widget & Screen Tests (Existing Feature Test Suites):**
   - Drive screens, drawers, sheets, and dialogs (`SettingsScreen`, `RecycleBinScreen`, `ChronicleDesk` / `TimelineScreen`, `SearchScreen`, `WeeklyReviewScreen`, `AnalyticsDashboardScreen`, `ScholarChestDrawer`, `CustomTemplateEditorScreen`, `ThreadBoundFolio`, `AlbumCollectionsScreen` / `AlbumWorkspaceScreen`) at their existing `pumpWidget` seams.
   - Update existing `find.text(...)` / `find.byTooltip(...)` / `find.bySemanticsLabel(...)` assertions to expect the new plain Chinese labels and verify zero mixed-English remnants or regressions in control behavior (e.g., restoring/purging in Recycle Bin, switching Reading Perspective, toggling Soundscape presets, filtering Search).
2. **Domain Formatter & Catalog Unit Tests:**
   - Exercise `FolioMetadataFormatter` (`HH:mm` Gregorian formatting, `批注：` extraction from `{夹注:...}`, preserved `formatFullLunarDate`), `formatTraditionalChineseDay` (preserved lunar-mode day formatting), `JournalLetterhead` mood/weather options, `StationerySuites`, `ReadingPerspective`, `AlbumThemeCatalog`, and `NaturalLanguageSearchParser` (verifying plain mood/weather filter parsing and backward-compatible keyword matching).
3. **Repository-Wide Diction Regression Check:**
   - Run a static grep/audit over UI widget files during verification to confirm no mixed `Chinese · English` UI tags or retired `_Avoid_` archaic phrases from `GLOSSARY.md` remain outside preserved artwork poems, code comments, and preserved lunar helpers.

## Out of Scope

- Full Flutter `AppLocalizations` / `.arb` extraction and creating a separate English UI.
- Renaming `拾光日记` to `云皓日记` or executing the upcoming visual/theme overhaul.
- Adding the settings UI and state wiring for switching the entire app to lunar date format (only the underlying traditional day/range formatters are preserved).
- Migrating or altering existing user-written entries, saved titles, or `{夹注:...}` markup stored in SQLite.
- Refactoring internal Dart symbol names, class names, or doc comments unless directly misleading.

## Further Notes

- Canonical domain and UI terminology mappings live in `GLOSSARY.md`.
- Rationale and trade-offs for the Option 2 boundary are recorded in `docs/adr/0012-plain-chinese-ui-diction.md`.
