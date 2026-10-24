# Gate G3B — SQLite summary DataStore + lazy page timings

**Date:** 2026-10-24
**Status:** PASS
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] `DataStore.StorageEngine` (`json` / `sqlite`) with the existing public API
  unchanged.
- [x] SQLite mode loads **session summaries**, not 138k page-timing rows.
- [x] `Book.cachedSecondsPerPage` and `ReadingSession.cachedAverageSecondsPerPage`
  preserve exact speed/analytics values without the raw rows.
- [x] `AnalyticsEngine.readingSpeed` / `crossBookReadingSpeed` use the cache
  when page timings are lazy.
- [x] `LibraryDatabase.saveAll` writes incrementally: books/sessions/state are
  upserted; only sessions carrying page timings in memory replace their
  `page_times` rows.
- [x] Bootstrap from legacy JSON when the SQLite DB is empty; falls back to JSON
  if migration fails.
- [x] SQLite writes on a dedicated serial queue; `saveImmediately` is a true
  flush.
- [x] SQLite archive export rehydrates full page timings; import round-trips them.
- [x] Dangling collection IDs are filtered instead of failing the FK.
- [x] Sentinel repairs snapshot the active SQLite store before mutation (S2).

## Verification

| Check | Result |
|---|---|
| Synthetic SQLite DataStore round trip | PASS |
| Legacy JSON → SQLite bootstrap | PASS |
| Real-library JSON↔SQLite parity | PASS |
| Archive export/import with page timings | PASS |
| Sentinel pins (6) | PASS |
| Real library size | 7 books / 292 sessions / 138,459 timings |
| **SQLite summary load** | **5.06 ms** |
| JSON baseline load | 493.7 ms |
| Per-book speed parity | within 0.01 s/page |
| Full census | **208 passed / 0 failed / 9 skipped** |

## Deliberate delta

- Sessions themselves (292) remain in memory; the **page-timing monolith**
  (138,459 rows) is lazy. That is the source of the 100× load improvement.
  Full per-book session laziness can be layered on later if a library grows
  enough to justify it.

## Rollback

```bash
git checkout bedrock-g4
```
Production JSON fallback remains at `library.json.migrated-2026-10-24` plus the
pre-Bedrock snapshot.
