# Gate SG6 — Dedupe, diagnosis, and honest health

**Date:** 2026-10-28
**Branch:** `main`
**Base commit:** `6099e4e`
**Tree state:** committed in `40bc922`; GitHub `census` green at `6aecdc3`

**Decision:** PASS — owner review still required.

---

## Delivered

| SG6 deliverable | State | Evidence |
|---|---|---|
| Fingerprint ignores time, count, severity, and evidence order | Done | Domain tests |
| One persistent issue across 100 detections | Done | `dedupeAcrossCycles`, diagnoser 100-cycle test |
| Regression when a repaired condition returns | Done | Diagnoser regression tests |
| Lifecycle edges: open → acknowledged/snoozed/ignored/resolved | Done | `SentinelLifecycle`, status tests |
| Snooze expiry reopens; ignore survives re-detection | Done | Diagnoser tests |
| Owner/contributor/corroborator evidence grouping | Done | Evidence-only tests; owner references |
| Root-cause correlation without merging issues | Done | `SentinelDiagnosis.correlate` |
| Coverage-honest band: skipped/failed ≠ healthy | Done | Skipped-probe runtime test; Health Center copy |
| Evidence cap and duplicate collapse | Done | Diagnoser evidence tests |
| Worst-first ordering and issue cap | Done | Diagnoser ordering/cap tests |
| Journal-backed identity rebuild | Done | Persistence tests |
| Trend vocabulary (new, persistent, worsening, improving, regressed, repaired) | Done | `SentinelTrend` |

---

## Verification

| Check | Result |
|---|---|
| 100 cycles, one condition | one issue; occurrence count grows |
| Resolved condition returns | regression, not duplicate |
| Snooze/ignore/acknowledge edges | legal transitions only |
| Skipped probe never closes an issue | passed |
| Failed probe never closes an issue | passed |
| Corroborator never opens an issue | passed |
| Full unit census | 379 functions; 1,024 passed cases; 0 failed |

Census receipt: `census-2026-10-28.md` (temporary `.xcresult` not retained)

---

## Known deltas

- **Trend vocabulary is not surfaced as a trend chart.** The model and lifecycle are tested; the Health Center shows history rows, not a time-series visualization.
- **Correlation is advisory and rule-based by root cause.** It does not infer causality across domains.
- **Issue retention (90 days resolved) is configured/documented but not exercised by an aging test.**

---

## Rollback

Delete the issue store and journal; the runtime rebuilds identity from the next cycle. Health bands recompute from scratch; no user data is touched.

---

## Next phase

SG7 — hardening, full test tranche, Release sweep, and owner acceptance.
