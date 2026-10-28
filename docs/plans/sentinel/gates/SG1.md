# Gate SG1 — Domain foundation

**Date:** 2026-10-28
**Branch:** `main`
**Base commit:** `6099e4e`
**Tree state:** committed in `40bc922`; GitHub `census` green at `6aecdc3`

**Decision:** PASS WITH KNOWN DELTAS — owner review still required.

---

## Delivered

| SG1 deliverable | State | Where |
|---|---|---|
| Typed domain model (issue, evidence, subjects, copy, diagnosis, trend) | Done | `Core/Sentinel/SentinelDomain.swift` |
| Stable fingerprint that ignores time, count, and severity | Done | `SentinelFingerprint`; pinned by `SentinelDomainTests` |
| Journal v2 segments, checksums, rotation, retention, v1 import | Done | `SentinelJournal.swift`; `SentinelPersistenceTests` |
| Issue store with torn-file fallback and journal rebuild | Done | `SentinelIssueStore.swift` |
| Configuration v2 with legacy-key migration and clamped loading | Done | `SentinelConfiguration.swift` |
| Deterministic copy registry (no generated prose) | Done | `SentinelRules.swift` |
| Root-cause grouping and trend vocabulary | Done | `SentinelDiagnosis.correlate`, `SentinelTrend` |
| Injected clock, file, defaults, and capacity environment | Done | `SentinelEnvironment.swift` |
| No `Date()` / `UserDefaults.standard` / `FileManager.default` inside probe bodies | Verified by search and review | `Core/Sentinel/SentinelProbes*.swift` |

---

## Verification

| Check | Command | Result |
|---|---|---|
| Domain laws | `-only-testing:…/SentinelDomainTests` | **28/28 passed** |
| Persistence, journal, migration | `-only-testing:…/SentinelPersistenceTests` | **25/25 passed** |
| Lifecycle and diagnosis | `-only-testing:…/SentinelDiagnoserTests` | **21/21 passed** |
| Full unit census | `./scripts/census.sh --unit-only` | **379 test functions; 1,024 passed cases; 9 skipped; 0 failed** |
| Release compile | `xcodebuild build -configuration Release` | exit 0 |

Census receipt: `census-2026-10-28.md` (temporary `.xcresult` not retained)

---

## Known deltas

- **v1 engine is retained.** `SentinelEngine` still serves the Debug Developer Console and its SG0 tests. It is not on the app's active cycle path, but SG7's "v1 removed" criterion is therefore **not met**.
- **Shadow parity is pinned, not dual-run.** SG0 pins prove the retained v1 rules behave; there is no simultaneous v1/v2 comparison harness.
- **Localization is not extracted.** Copy is centralized in the registry, but the String Catalog work is deferred.
- **The trend vocabulary is modeled and tested; it is not yet visualized** in the Health Center beyond the journal history.

---

## Rollback

Source-only; no data migration was removed. Revert the `Core/Sentinel/` domain/journal/store files and their tests. Existing v1 journals remain readable through the import path.

---

## Next phase

SG2 — runtime actor, snapshot generation, probe v2 registry, and budgets.
