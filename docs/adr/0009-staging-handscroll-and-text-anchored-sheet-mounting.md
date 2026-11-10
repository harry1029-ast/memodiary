---
status: accepted
---

# Staging Handscroll & Text-Anchored Sheet Mounting

Photos and videos in the entry editor are no longer placed directly onto a sheet. They are first **collected** into a single entry-wide **Staging Handscroll** (待贴画卷) with a one-time **Brush Reveal**, then **mounted** by the diarist onto a **Stationery Sheet** (max 3 per sheet), shown outside its Paper Heart (SPEC-010's Sheet Mount Strip band, replaced in SPEC-011 by **Tucked Prints** peeking above the sheet's top edge; the marker model is unchanged). A mounted item is anchored by an invisible, zero-height marker embed inserted into the entry's Quill Delta at the end of that sheet's text. The marker is the single source of truth for mounting, so an item follows the passage it was mounted beside when text reflows across virtual sheets (ADR 0008), and the editor, Thread-Bound Folio and PDF export can never disagree about which sheet owns a photo.

This replaces the inline row-snapped media embeds of ADR 0005 as an authoring path (existing inline embeds remain render-only), and replaces SPEC-009's order-based `Sheet N ↔ Photo N` pairing with marker-based pairing.

## Considered Options

- **Persisted sheet index** (`sheet_index` column): simplest, but sheets are virtual partitions of one continuous Delta, so any edit above a sheet silently re-pairs its photos with different text. Rejected.
- **Stable paragraph/block IDs**: Quill Delta has no stable block identity; we would have to invent and maintain one across every edit. Rejected.
- **Per-sheet trays with direct attach** (the pre-existing `StationeryMediaTray` model): the in-memory sheet pairing was never persisted and was redistributed first-fit on reload. Rejected in favour of an explicit collect-then-mount flow.
- **Mount strip inside the Paper Heart**: would consume integer-locked rows (10 / 14 lines), so mounting a photo would spill text onto the next sheet. The strip lives outside the Paper Heart instead.

## Consequences

- **Overflow**: reflow can bring a fourth marker onto a sheet. Extras display on the following sheet; on the last sheet they are unmounted back to the Staging Handscroll (never deleted, never an empty photo-only sheet).
- **Marker lifecycle**: deleting text that contains a marker unmounts its item to the handscroll; undo restores it; clipboard copy/paste strips markers; markers are excluded from `plain_text` and FTS; markers referencing a missing attachment are stripped on save.
- **Unmounted state is implicit**: an attachment with no marker is in the Staging Handscroll. It is persisted with the entry but excluded from the Folio and PDF export. Leaving the editor with staged items prompts keep / discard / stay.
- **Legacy entries**: on first open, existing unanchored attachments are mounted first-fit (matching the old partitioner) and markers are written into the Delta, in Dart rather than in a SQL migration.
- **Captions** move from `ocr_text` to a dedicated `caption` column in the same schema change, so user captions stop polluting OCR search. Existing values are moved (OCR fields reset to unindexed) only for rows without OCR blocks (`ocr_blocks_json` NULL, or `'[]'` with non-empty text from the old in-app caption editor).
