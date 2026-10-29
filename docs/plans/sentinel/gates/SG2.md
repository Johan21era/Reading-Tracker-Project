# Gate SG2 — Runtime, snapshot, and probes v2

**Date:** 2026-10-28
**Branch:** `main`
**Base commit:** `6099e4e`
**Tree state:** committed in `16d6d16`; GitHub `census` green at `bed710a`

**Decision:** PASS — owner review still required.

---

## Delivered

| SG2 deliverable | State | Evidence |
|---|---|---|
| Serialized runtime actor with a single cycle lock | Done | `SentinelRuntime`; cycle-lock and overlap tests |
| Immutable snapshot with generation | Done | `SentinelSnapshot.capture`; generation guard tests |
| Per-probe time budgets and isolation | Done | `withTaskGroup` race + per-tier timeouts |
| Honest coverage model (ran / skipped / failed / required) | Done | `SentinelCoverage`; skipped probe test |
| Probe v2 contract with metadata, role, repair ID, copy | Done | `SentinelProbeV2`, `SentinelProbeDescriptor` |
| 138 probes across 15 domains | Done | `SentinelProbeCatalog.all()` |
| Probe tiers and cadences | Done | t0–t4 budgets; `.fast` / `.deep` scopes |
| App integration with live snapshot and repair bridge | Done | `SentinelDataBridgeV2`, `SentinelAppIntegration` |
| Health Center reads published state; views never run probes | Done | `SentinelViewModel`, `SentinelHealthCenterView` |

---

## Verification

| Check | Result |
|---|---|
| Registry size / domains / required count | **138 probes, 15 domains, 56 required** |
| Descriptor contract (all probes) | **138/138 passed** |
| Every probe silent on a clean install | **138 cases passed** |
| Every probe deterministic across two runs | **138 cases passed** |
| Every probe keeps user text out of safe output | **138 cases passed** |
| Runtime behaviour (cycle, dedupe, timeout, failure, lock) | **19/19 passed** |
| Fast pass on a 70-book / 21,000-page fixture | **1.31 ms** (budget < 50 ms) |
| Full unit census | **379 functions; 1,024 passed cases; 9 skipped; 0 failed** |

Fast-pass measurement is printed by `fastPassBudget` as `SENTINEL-FASTPASS-MS`.
Census receipt: `census-2026-10-28.md` (temporary `.xcresult` not retained)

---

## Known deltas

- **Main-thread I/O is not instrumented with runtime assertions.** Probes are written off-main and tested, but there is no Debug trap that fails a cycle if a probe touches the main thread.
- **The 10× fixture is not generated.** The fast-pass gate uses 70 books; deep-pass timing at 1.38 M timings is unmeasured.
- **Deep probes with large SQLite fixtures are contract-tested, not benchmarked.** SQL probes run against small temporary databases.
- **The 700-probe / 120-domain program target is not reached.** This tranche is 138 / 15; the catalog is structured to grow without changing the runtime.

---

## Rollback

Revert `Core/Sentinel/` runtime, catalog, probes, and app wiring. No schema change is required. The app falls back to the v1 engine if the v2 registration is removed.

---

## Next phase

SG3 — repair plans, verification, undo, and rollback.
