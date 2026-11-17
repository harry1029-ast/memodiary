---
status: accepted
---

# Plain Modern Chinese UI Diction Policy

To eliminate comprehension friction across interactive controls while preserving the app's classical visual craft, all functional UI copy (buttons, tooltips, settings, permissions, dialogs, filters, timestamps, empty states, and metrics) uses crisp, plain modern Chinese, and all redundant inline English labels (`· Bold`, `· Collection Box`, English settings subheaders) are removed until a dedicated English UI localization is built separately. Short, self-explanatory traditional nouns are retained **only** for tangible stationery/theme/seal/brush presets (e.g., `朱丝宣纸`, `朱文 / 白文`, `水墨丹青`, `狼毫 / 兼毫 / 羊毫`) with zero poetic descriptions, while seasonal poems inside the Shanshui and cover illustrations, the brand name `拾光日记`, and the default seal `心迹安放` remain untouched ahead of a future aesthetic overhaul (`云皓日记`).

## Considered Options

- **Full strip of all classical terms everywhere**: Considered replacing even stationery and theme names with generic labels (e.g., `红线信纸`), but rejected so the visual paper/ink presets keep recognizable material identity without hurting usability.
- **Simultaneous `.arb` / `AppLocalizations` extraction**: Considered migrating every string into Flutter l10n tables during the diction rewrite, but rejected so copy cleanup stays fast and decoupled from a future English UI revamp.

## Consequences

- Gregorian dates and timestamps become numeric by default (`HH:mm`, numeric day spine, `1–10日 / 11–20日 / 21日–月底`), while `formatTraditionalChineseDay` (`初一 … 廿五 … 三十`) and lunar range constants remain preserved for a planned app-wide lunar date format toggle.
- User-authored `{夹注:...}` inline markup syntax and existing persisted diary/weekly-review titles are left untouched; newly generated weekly review titles default to `第N周复盘`.
- Updating UI strings across features will require updating corresponding `find.text(...)` widget test assertions per module.
