# Gate G3C — Real-data cutover and JSON retirement

**Date:** 2026-10-24
**Status:** PASS
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] Production `AsterismaApp` creates `DataStore(storageEngine: .sqlite)`.
- [x] On an empty DB, the app imports legacy JSON/state transactionally and
  keeps JSON as fallback if the import fails.
- [x] Real library migrated and verified:
  - **7 books**
  - **292 sessions**
  - **138,459 page timings**
  - 10 achievements
  - 1 collection
- [x] `library.json` and `library-state.json` renamed to
  `*.migrated-2026-10-24`; the app relaunched successfully from SQLite alone.
- [x] Production DB: `ReadTracker/library.grdb.sqlite3` (~48 MB).
- [x] SQLite-safe backup: `Backups/library-2026-10-24_022606.sqlite3` (~48 MB);
  daily marker + newest-10 rotation.
- [x] Archive export/import preserves page timings from SQLite.
- [x] Sentinel pre-repair snapshot now uses SQLite backup.
- [x] WAL checkpointed to zero after the cutover (`TRUNCATE`).

## Verification

- App launched with the JSON files renamed; library still showed all books.
- DB counts match the JSON snapshot exactly.
- SQLite load **5.06 ms** (vs 493.7 ms JSON).
- No JSON writes after cutover; JSON mtime remained Oct 19.
- Full census: **208 passed / 0 failed / 9 skipped**.

## Rollback

1. Quit the app.
2. Rename `library.json.migrated-2026-10-24` back to `library.json` and the
   state sidecar back to `library-state.json`.
3. Check out `bedrock-g3a` or the pre-Bedrock snapshot.
4. The pre-Bedrock snapshot at
   `~/Desktop/AsterismaV1.0-Backups/2026-10-24-pre-bedrock/` is the last-resort
   restore.

## Known deltas

- The abandoned P5-G `library.sqlite3` remains on disk as a dead artifact; the
  live DB is `library.grdb.sqlite3`.
- The old `library.migrated` / `library-state.migrated` artifacts remain; clean
  up in G7.
