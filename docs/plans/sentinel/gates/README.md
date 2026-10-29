# Sentinel gate index

**As of:** 2026-10-28
**Branch:** `main` at `29dd4f6` (SG8); pre-SG8 tip `76e8a23`; tranche commit `16d6d16`
**Census:** 432 tests · 671 runs · 9 skipped · 0 failed (local, after SG8)

> **History note (2026-10-28):** published `main` was rewritten to remove AI
> co-author trailers from five commits. Commit contents are byte-identical;
> SHAs were remapped (`40bc922`→`16d6d16`, `fd524cd`→`5a369e9`,
> `6aecdc3`→`bed710a`, `2f40a43`→`310b9d3`, `ae4ee36`→`76e8a23`). CI run
> receipts that name an old SHA now name its replacement.
**Census receipt:** [census-2026-10-28.md](census-2026-10-28.md) (the temporary `.xcresult` bundle was not retained)

| Gate | Subject | Status | Receipt |
|---|---|---|---|
| SG0 | Truth and guardrails | Passed (historical; probe counts superseded) | [SG0.md](SG0.md) |
| SG1 | Domain foundation | Pass with known deltas | [SG1.md](SG1.md) |
| SG2 | Runtime, snapshot, probes v2 | Pass | [SG2.md](SG2.md) |
| SG3 | Repair engine v2 | Pass | [SG3.md](SG3.md) |
| SG4 | Release Health Center | Pass with known deltas | [SG4.md](SG4.md) |
| SG5 | Data-system coverage | Pass with known deltas | [SG5.md](SG5.md) |
| SG6 | Dedupe, diagnosis, honest health | Pass | [SG6.md](SG6.md) |
| SG7 | Hardening and Release sweep | **HOLD** — v1 removal and localization unmet | [SG7.md](SG7.md) |
| SG8 | Auto-extending surface coverage | Pass (executable scope); owner acceptance still SG7 | [SG8.md](SG8.md) |

## What "pass" means here

A pass means the gate's executable criteria were verified and recorded. It does not mean the
program target (700+ probes, 120 domains, 350+ repairs) is reached; this is the first tranche:
**140 probes, 15 domains, 25 repairs** (138 at SG7, plus SQL-016 and SELF-011 at SG8).

## Honest limitations carried across gates

1. **v1 engine retained.** It serves the Debug Developer Console and older pins only; the active
   path is `SentinelRuntime`. This fails SG7's "v1 removed" criterion.
2. **English only.** Copy is centralized but not extracted into a String Catalog.
3. **Menu bar absent.** A `MenuBarExtra` implementation hung the test host and was removed rather
   than shipped; no dead toggle remains.
4. **Manual owner acceptance pending.** The ten scenarios in the roadwork need a human and a copied
   real library.
5. **No 10× SQLite fixture.** Fast pass is measured at 70 books (1.31 ms); deep SQL timing at
   1.38 M rows is unmeasured.
6. **No automated accessibility pass.** Labels and native layout are present; VoiceOver and
   largest-Dynamic-Type checks were not run.
7. **Surface coverage is structural.** SQL-016 proves every inventoried table exists, is readable,
   and has a primary key. Preferences and notification names are advisory only; they are counted,
   not executed. The manifest is CI-fresh, not build-phase-fresh.

These are recorded in the individual receipts with rollback steps and next actions. Nothing above
is claimed as verified when it was not.
