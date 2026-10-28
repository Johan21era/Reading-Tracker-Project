# Gate SG3 — Repair engine v2

**Date:** 2026-10-28
**Branch:** `main`
**Base commit:** `6099e4e`
**Tree state:** working tree, uncommitted

**Decision:** PASS — owner review still required.

---

## Delivered

| SG3 deliverable | State | Evidence |
|---|---|---|
| Typed repair actions and plans | Done | `SentinelRepair.swift`, `SentinelRepairCatalog.swift` |
| 25 implemented repairs across sessions, library, files, system | Done | `SentinelRepairCatalog.implementedIDs` |
| Preview before mutation | Done | Health Center preview sheet; `previewRepair` |
| Ten-step executor contract | Done | `SentinelRepairExecutor.execute` |
| Autonomy classes A0–A3 and risk classes R0–R3 | Done | `SentinelAutonomy`, `SentinelRiskClass` |
| Safety snapshot required before every mutation | Done | Step 5; snapshot-failure test |
| Generation and exact-subject re-read | Done | Steps 3–4; stale-generation and changed-book tests |
| Quiescence while reading | Done | `hasRecentReadingActivity`; must-not-interrupt tests |
| Verification by re-running the owning probe | Done | Step 6; verified apply test |
| Rollback on failed verification | Done | Restores `LibraryState`, books, and quarantined files |
| Undo of a verified repair | Done | `undoRepair`; byte-equal restore test |
| Receipts with before/after hashes, no user text | Done | `SentinelRepairRecord`; journal privacy pins |
| R3 never executed in one click | Done | Executor refusal test |

---

## Verification

| Check | Result |
|---|---|
| Executor contract (off, autonomy, R3, empty, quiescence, generation, changed subject, snapshot, verify, rollback) | **10/10 passed** |
| Catalog plan builders (clamp, timing, collections, deadlines, chapters, notes, speed, cover) | **10/10 passed** |
| Runtime repair path (auto-safe, generation guard, quiescence, snapshot, rollback, undo, observe refusal) | **19/19 runtime tests passed** |
| Implemented repair IDs | **25** |
| False automatic fixes observed in the suite | **0** |
| Rollback/undo failures observed in the suite | **0** |

Census receipt: `census-2026-10-28.md` (temporary `.xcresult` not retained)

---

## Known deltas

- **Fault injection is generic plus targeted.** The executor's snapshot, generation, quiescence, verification, and rollback paths are exercised for representative plans; not every one of the 25 repairs has its own injected failure test.
- **Concurrent external saves are caught by the generation check, not by a per-row compare-and-swap.** The bridge refuses stale book/library-state values, but there is no stress test with a writer racing during apply.
- **REP-021/REP-022 (backup/temp quarantine) are catalog-tested; live file-tree scenarios are not owner-verified.**
- **No repair has been exercised on a real owner library in this session.** Manual owner scenarios remain pending.

---

## Rollback

Disable autonomy (A0) to make the engine inert. Revert the repair catalog/executor and the bridge; repair records and plans remain readable. Undo is available for already-verified repairs before that revert.

---

## Next phase

SG4 — Release Health Center, launch card, settings, and notifications.
