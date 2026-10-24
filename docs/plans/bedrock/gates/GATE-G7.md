# Gate G7 — Debt retirement, Swift 6, cleanup

**Date:** 2026-10-24
**Status:** DEBT PASS; Swift 6 DEFERRED
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] Deleted the zero-reference legacy `LibraryView.swift` (~243 LOC).
- [x] Deleted recommendation V1/V2 engines + models (~879 LOC); V3 is the only
  live engine and builds/tests still pass.
- [x] Removed unused `HoverIntent` enum.
- [x] Renamed `AsterismaApp 2.swift` → `AsterismaApp.swift`.
- [x] Corrected stale headers: AnalyticsCache existence, DataIntegrityValidator
  save claim, LibraryExplorer wiring status, dead LibraryView comments.

## Swift 6 attempt (honest delta)

Flipping `SWIFT_VERSION = 6.0` + `SWIFT_STRICT_CONCURRENCY = complete` produced
**148 actor-isolation errors**, concentrated in DataMaturityEngine and the
BehaviorContext/MainActor-default surfaces. The compiler settings were reverted
to the proven Swift 5 mode. Swift 6 is a dedicated follow-up, not a silent
half-migration.

## Verification

- `xcodebuild build-for-testing`: **TEST BUILD SUCCEEDED** after the deletions
  and rename.
- Full census: **212 passed / 0 failed / 9 skipped** (see G8 receipt).

## Remaining debt (documented, not hidden)

- Weather adapters, importer plugins, `restoreSession`, `ReadingComplexityHints`,
  and other small zero-caller fragments remain.
- `graphify-out/` is still large; prune/regenerate on the next structural change.
- Old P5-G `library.sqlite3` and `.migrated` artifacts remain in app-support.

## Rollback

```bash
git checkout bedrock-g6
```
