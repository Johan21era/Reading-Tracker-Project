# Gate G5 — Library intelligence (metadata, notes, collections)

**Date:** 2026-10-24
**Status:** CORE SURFACE PASS; reader highlights/quotes deferred
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] EPUB OPF `dc:subject` → `ReadingGenre` mapping.
- [x] Series extraction (EPUB3 `belongs-to-collection`, Calibre `calibre:series`).
- [x] `wordCountEstimate` now stored on EPUB import.
- [x] Book Details inspector reachable from every library row’s context menu.
- [x] Genre picker, series editor, favorite toggle.
- [x] Notes: add/edit/delete, tag, optional page, Markdown-rendered body.
- [x] Collections: create, delete, membership toggles; Book Details surface.
- [x] Quick “Mark Favorite” row action.
- [x] Metadata/notes/collections persist in SQLite summary mode.

## Verification

- `GenreMappingTests`: 7 mappings.
- `LibraryMetadataPinsTests`: genre/series/favorite/notes/collections survive
  SQLite reopen.
- Full build: **TEST BUILD SUCCEEDED**.

## Known deltas

- Reader selection highlights/quotes (EPUB/PDF text selection) are not yet
  wired. The note model and Markdown rendering are ready; the reader anchor
  layer is the remaining work.
- Collection rename has no UI yet; create/delete/membership do.
- The Book Details inspector is a sheet, not a macOS `.inspector` pane.

## Rollback

```bash
git checkout bedrock-g3c
```
