# Bedrock Gate Log

| Gate | Status | Date | Commit/tag | Receipt | Owner decision |
|---|---|---|---|---|---|
| G0 — Baseline & safety | PASSED | 2026-10-24 | — | `BASELINE.md` | pre-approved |
| G1 — Correctness first | PASSED | 2026-10-24 | — | `gates/GATE-G1.md` | pre-approved |
| G2 — Local distribution baseline | PASSED | 2026-10-24 | — | `gates/GATE-G2.md` | pre-approved |
| G2B — Mirage embedding | PASSED | 2026-10-24 | — | `gates/GATE-G2B.md` | pre-approved |
| G3A — SQLite foundation | FOUNDATION PASSED | 2026-10-24 | — | `gates/GATE-G3A.md` | pre-approved |
| G3B — SQLite summary + lazy page timings | PASSED | 2026-10-24 | — | `gates/GATE-G3B.md` | pre-approved |
| G3C — Real-data cutover / JSON retirement | PASSED | 2026-10-24 | — | `gates/GATE-G3C.md` | pre-approved |
| G4 — Weather | PROVIDER/PIPELINE PASSED | 2026-10-24 | — | `gates/GATE-G4.md` | pre-approved |
| G5 — Library intelligence | CORE PASS (reader highlights deferred) | 2026-10-24 | — | `gates/GATE-G5.md` | pre-approved |
| G6A — BCE V3 engine | PASSED | 2026-10-24 | — | `gates/GATE-G6.md` | pre-approved |
| G6B — BCE V3 UI | PASSED | 2026-10-24 | — | `gates/GATE-G6.md` | pre-approved |
| G7 — Debt & Swift 6 | DEBT PASS (Swift 6 deferred) | 2026-10-24 | — | `gates/GATE-G7.md` | pre-approved |
| G8 — Acceptance | ACCEPTED / MERGED | 2026-10-24 | `6da2d81` / `asterisma-v1.0-mvp` | `gates/GATE-G8.md` | owner accepted |
| R1 — Asterisma rebrand | PASSED / SHIPPED | 2026-10-24 | `6da2d81` / `asterisma-v1.0-mvp` | `../REBRAND-ASTERISMA.md` | owner accepted |

**Final merge:** `main` fast-forwarded to `aba8aa4` and pushed to
`origin/main`; all seven release/Bedrock tags pushed. The merged worktree
re-ran the census at **213 passed / 0 failed / 9 skipped**.

**Owner-test authority:** from 2026-10-24 onward, the owner's personal test
results are the **absolute source of truth** and override all gate receipts,
censuses, benchmarks, and documentation claims above. See
`docs/12-owner-test-authority.md`; policy tag `owner-test-authority-2026-10-24`.

**Owner-test fixes:** the first owner runs found four defects (packaged
entitlements, onboarding dead end, folder-form EPUBs, windowed toolbar/zoom). Fixed on top of the
accepted release at `3281450`, tag `asterisma-v1.0-import-fix`; candidate
package SHA-256 `ade4a54e3cbe233e14b809c32988422f4ace4aed7e9c855a9bcb269d20f58a96`.
Owner retest is the acceptance gate.

**Snapshot note:** the owner deleted all local backup snapshots on 2026-10-24.
Rollback paths recorded in older gate receipts are historical; no local data
snapshot remains. Use Time Machine or an external backup if one exists.

**Standing rule:** no gate advances without an explicit owner APPROVE / CHANGES / STOP.
