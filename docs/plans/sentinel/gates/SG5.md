# Gate SG5 — Data-system coverage

**Date:** 2026-10-28
**Branch:** `main`
**Base commit:** `6099e4e`
**Tree state:** committed in `40bc922`; GitHub `census` green at `6aecdc3`

**Decision:** PASS WITH KNOWN DELTAS — owner review required.

---

## Delivered

| SG5 deliverable | State | Evidence |
|---|---|---|
| SQLite probes over real tables, read-only | Done | `SQL-001…014`, `SES-015…017` |
| Orphan timing/session detection | Done | `SES015OrphanTimingRows`, `SES016OrphanSessionRows` |
| Duplicate timing indices and timestamp sanity | Done | `SES-017`, `SQL-011/012` |
| Payload/schema checks and fail-closed load context | Done | `SQL-003/006/007/008/013` |
| Backup presence, freshness, unreadable, restore drill | Done | `BAK-001…004` |
| File probes (missing, bookmark, duplicate, cover, permissions, budget) | Done | `FILE-001…012` |
| Weather subsystem probes | Done | `WX-001…007` |
| Work file/app-state/subsystem probes | Done | `Core/Sentinel/SentinelProbesSubsystems.swift` |
| File and cover repairs with quarantine | Done | `REP-012/013/021/022/025` |
| 25+ repairs in this slice | Done | 25 implemented IDs |
| SENT-001 regression fixture | Done | SQL fixture test creates dangling rows and asserts `SES-015/016` |

---

## Verification

| Check | Result |
|---|---|
| Registry | **138 probes / 15 domains / 25 repairs** |
| SQL fixture: clean database is silent; dangling rows are found | passed |
| Every probe returns evidence-shaped findings on a damaged fixture | passed |
| Every probe is silent on a clean install (or reports unavailable honestly) | 138 cases passed |
| Privacy scan across all probes | 138 cases passed |
| Repair catalog coverage of data rules | SQL/backup/file rules map to implemented plans where declared |

Census receipt: `census-2026-10-28.md` (temporary `.xcresult` not retained)

---

## Known deltas

- **The 10× data gate is not run.** A 70-book fast-pass fixture exists; no 1.38 M-timing library was generated for deep SQL timing and memory measurement.
- **`EXPLAIN QUERY PLAN` index assertions are not automated.** Probes use indexed joins by construction, but there is no test that fails on a full scan.
- **Backup restore drill is exercised as a probe contract, not on a real backup corpus.** Corrupt/truncated fixtures are covered by unit tests.
- **The full 700-probe / 120-domain target remains open.** This is the Phase 5 slice, not the program ceiling.

---

## Rollback

Probes are read-only. Remove their descriptors from the registry to disable them; no schema migration is introduced by Sentinel. Repairs that quarantine files are undoable from History while the receipt lives.

---

## Next phase

SG6 — dedupe, root-cause grouping, coverage-honest bands, and trends.
