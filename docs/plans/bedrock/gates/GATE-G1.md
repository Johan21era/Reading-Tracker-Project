# Gate G1 — Correctness first

**Date:** 2026-10-24
**Status:** PASSED
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] Duplicate-achievement root cause fixed (`award` now inserts the kind).
- [x] One-time dedupe migration on `library.json` state load and archive restore.
- [x] Spatial cards use `book.coverImage` (CoverStore-aware).
- [x] Onboarding import goes through the shared facade + duplicate rejection; goal merge preserves annual/weekly/time/deadline fields.
- [x] PDF RSVP extraction is held/cancelled on dismissal.
- [x] PersistenceWriter now submits to the serial queue synchronously; queue is the executor, in call order. `saveImmediately` drains real work.
- [x] Crash-window recovery clamps open sessions to last page activity + 5 min; Sentinel orphan repair does the same.
- [x] AnalyticsCache signature includes a day bucket; dead `perBookSpeed` removed; Insights passes the real epoch.
- [x] Test isolation: unit/UI test hosts use a process-scoped temp store automatically (`RuntimeEnvironment`), unit tests use temp Sentinel journals and cover stores.

## Tests

- New pins: 6 tests in `G1CorrectnessPinsTests.swift`, all pass.
- Full unit census: **197 passed / 0 failed / 5 skipped** (202 cases; 5 skips = 4 opt-in Mirage + benchmark suite).
- Baseline was 191/0/4; +6 new tests, +1 benchmark skip.
- Test isolation script: **PASS** — real app-support byte-identical after unit census.
- Build: **BUILD SUCCEEDED**.

## Data receipt

- Benchmark copy: `DataStore` load **493.7 ms**, 7 books / 292 sessions / 138,459 page timings.
- Dedupe migration removed **582** stale achievement records on the copy (592 → 10 unique kinds).
- No real-store migration was forced manually; the next real app launch runs the same idempotent dedupe.

## Known issues / deltas

- Onboarding import bypass has no direct UI test yet; goal-merge has a unit pin.
- RSVP cancellation is code-reviewed, not yet exercised with a large PDF fixture.
- The full UI test suite is still template-only; it launches with an isolated store but asserts little.

## Rollback

```bash
git checkout bedrock-g0
```
or restore the pre-Bedrock snapshot at
`~/Desktop/ReadingTracker-Backups/2026-10-24-pre-bedrock/`.

## Decision requested

- [x] APPROVE
- [ ] APPROVE WITH CHANGES
- [ ] STOP
