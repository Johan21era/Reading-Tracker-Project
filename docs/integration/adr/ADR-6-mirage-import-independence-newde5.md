# ADR-6 — Mirage import-path independence from RT's onboarding-import bypass (NEW-DE-5)

Status: **DECISION-REQUIRED (drafted 2026-10-18; awaiting owner countersign to gate PR-5's commit)**

## Context

Playbook NEW-DE-5 (S8-ES-2 disposition: FIX-FIRST **or** a formal decoupling ADR; stated verbatim at
RT_Mirage_Codebase_Merge_Playbook.md:1596): "PR-5 must not proceed until RT-side facade bypass is
resolved **or** a DECISION-REQUIRED ADR documents why the two paths are confidently independent
(e.g., Mirage import validates against ledger, not RT's goals)."

The RT-internal defect (pre-dating integration, evidence-extracted in phase 1):
`Reading Tracker/Features/Onboarding/OnboardingView.swift:195-217` — onboarding `importBook()`
calls `BookImporter.importBook(from:)` (`BookImporter.swift:58`) directly, **bypassing**
`ImportIntelligenceFacade` (`BookImporter.swift:748`) and RT's duplicate-import notice
(RA-002 / ROADMAP 2.2 in `NewContentView.swift:18-20`), then `dataStore.addBook(book)` (:212);
`commitGoal()` (:219-226) rewrites the entire `ReadingGoalSet` via `updateGoalSet` (the
goal-overwrite hazard). The main-path import (`NewContentView`) does route through the facade.

## Decision (the independence argument, path-anchored)

The PR-5 Mirage import flow (`Reading Tracker/Features/Mirage/MirageImportFlow.swift`) shares **no
code path, no call target, and no persistence state** with the bypassed onboarding route:

1. **Different destinations.** The flow's only writes are (a) the engine's ledger, via the
   `import_epub` wire call — validated engine-side against `editions.edition_fingerprint`
   (MirageV1.0 `api/service.py:106-113`), with digest-lineage dedupe delivered as `reused:true`
   (`:119-124`, §36.1) — and (b) `mirage/identity-map.json`, the flow's own stratum under ADR-4
   (ADR-5 Decisions 1/3). It never reaches `DataStore3`, `PersistenceWriter`, or the RT store at
   `library.json`.
2. **It creates no books.** The flow does not call `dataStore.addBook`, `BookImporter.importBook`,
   or `ImportIntelligenceFacade`; the mapping attaches to a book that **already exists** in RT
   (chosen by the user), so it cannot inject duplicates into RT's library.
3. **It invokes no goal machinery.** Neither `commitGoal` nor `updateGoalSet` is reachable from
   any Mirage feature file; the goal-overwrite hazard is unreachable from the Mirage path.
4. **Duplicate protection has its own pinned guard.** One active mapping per book is enforced by
   `MirageIdentityMapFile.activating` (superseded-orphan transition) and pinned by
   `MirageIdentityMapContractTests/oneActiveInvariantSupersedesPriorEntry` and
   `MirageIdentityDriftTests/duplicateImportIsIdempotentWithoutAnotherWrite`; the engine layer
   independently refuses fingerprint collisions (`ValidationError`, `service.py:108-113`).
5. **The only RT borrow is read-only referent resolution.** `Book.resolveURL()`
   (`Book2.swift:122`) is used for the S10-ES-1(c) pre-flight stat; it mutates nothing.

Therefore the RT-side facade bypass **cannot transmit through the Mirage import path** — the two
paths are independent by construction, which is stronger than the playbook's example threshold
("Mirage import validates against ledger, not RT's goals"), and holds for both: RT's goals and
RT's library both lie entirely outside the Mirage flow's write surface.

## Boundaries (what this ADR is NOT)

- It does **not** fix the RT-internal onboarding bypass. That fix touches RT's onboarding/import
  code, stays tracked under NEW-DE-5 in the defect register, and is out of the Mirage
  integration's change surface. RT may adopt it separately at any time without touching this
  integration (and fixing it first only *further* strengthens RT's internal hygiene).
- It does **not** loosen NEW-DE-5's own FIX-FIRST disposition for RT's internal repair.
- ADR-6 governs PR-5's one-book import flow only. If any later PR replaces the flow with a bulk
  or automated importer, this ADR's argument must be re-validated (bulk paths re-open the
  duplicate question RT's facade exists to answer).

## Structural-census gate (verified each merge-log census, first at M-024)

Mirage feature files (`Reading Tracker/Features/Mirage/*.swift`) must contain **zero** references
to: `ImportIntelligenceFacade`, `BookImporter`, `addBook`, `updateGoalSet`, `commitGoal`,
`OnboardingView`. The PR-5 census records this grep as part of its evidence.

## Countersign

- [x] **Owner countersigned 2026-10-18 (accepted in-session via explicit owner answers):**
      (1) UI entry = book detail page; (2) post-commit cancel wording = the plain-and-honest copy;
      (3) ADR-6 accepted as drafted — the NEW-DE-5 block on PR-5 is discharged with the RT-internal
      bypass remaining tracked under NEW-DE-5 (kept out of the integration's change surface).
      PR-5's commit is cleared to proceed under this ADR.
