# Gate G3A — SQLite foundation (GRDB)

**Date:** 2026-10-24
**Status:** FOUNDATION READY; DataStore integration is G3B
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] GRDB.swift 7.11.1 added as the second SPM dependency, pinned in `Package.resolved`.
- [x] `LibraryDatabase` with WAL, foreign keys, busy-safe GRDB pool.
- [x] Schema v1: books, sessions, page_times, library_state, collections,
  book_collections, notes, achievements (unique kind), weather_snapshots,
  audio_profiles, behavior_events, application_sessions, inactivity_records,
  device_state_events, meta.
- [x] Indexes on book/session/time/note/weather/behavior query columns.
- [x] Transactional JSON→SQLite import.
- [x] Full Book payload kept as G3A parity source; normalized rows written
  alongside for the G3B lazy/aggregate rewrite.
- [x] Synthetic round-trip pin: books, sessions, page timings, notes,
  collections, achievements, goals.
- [x] Real-library parity pin (opt-in copy).

## Verification

| Check | Result |
|---|---|
| Synthetic round trip | PASS |
| Real-library parity | **PASS** |
| Real books | 7 |
| Real sessions | 292 |
| Real page timings | 138,459 |
| Migration duration | **5.16 s** on the real copy |
| Achievement dedupe during import | 582 stale records removed on copy |
| Counts match | books, sessions, page timings all match |

## Deliberate delta

- DataStore is still JSON-backed by default. G3A proves the schema and migration;
  G3B is the lazy-loading + SQL-aggregate + DataStore switch. We did **not**
  cut over or touch the real store.
- The `books.payload_json` parity payload still includes full sessions. G3B
  replaces it with summaries + on-demand session reads.

## Rollback

```bash
git checkout bedrock-g2b
```
Remove `.mirage-runtime/` and `dist/` if reverting the packaging work.

## Decision requested

- [ ] APPROVE FOUNDATION / PROCEED TO G3B
- [ ] APPROVE WITH CHANGES
- [ ] STOP
