# Handoff — Reading Tracker

Plain-language answers, per the project's close-out contract.

## What was I doing?
Executing **Phase 1 — Foundation Strike** of the production roadmap: protecting the
working tree in version control, verifying the baseline, and permanently eliminating
every Critical and High defect in the current audit register — each fix paired with a
deterministic regression pin.

## Why?
The previous session made the app trustworthy-by-inspection; this phase made that
trust *provable and durable*. Nothing ships or gets wired (Phase 2) onto foundations
with known crash/data-loss paths.

## What did I end up doing?
1. **Stage 0 — Protection:** committed the long-uncommitted tree as two clean commits
   (`9f7c619` reorg frozen pre-fix, `608868e` full remediation session + hygiene).
   Added `.gitignore` (.DS_Store, xcuserdata, profraw, graphify-out). Verified baseline:
   BUILD SUCCEEDED + TEST SUCCEEDED before touching anything.
2. **Six fixes, six pins** (all verified by clean build + full green suite after each):
   - **F-01 (Critical):** Annual Reports calendar crash guarded; parameterized
     non-Gregorian test matrix added.
   - **F-03 (High):** numeric HTML entity destruction removed at the source;
     extraction fixtures prove true decoding end-to-end.
   - **F-04 A+B (High):** state file now backed up before reset; Book/LibraryState
     decode tolerantly across schema versions (legacy JSON accepted, round-trip lossless).
   - **F-05 (Medium):** LocationProvider continuation queue — overlapping requests can no
     longer hang forever (inspection-verified; documented honestly).
   - **F-07 (Medium):** observer double-registration gate; launch-style double-start now
     provably records exactly one evidence event.
   - **F-02 (High):** New-Year celebration rebuilt on an extracted, testable timeline with
     owned cancellable tasks — the old orphaned-Timer race is dead by construction and
     pinned by fake-clock tests. Stale "unwired" claims corrected everywhere they lived.
3. **Docs synced:** `fix-log.md` Phase-1 section (full protocol format),
   `CURRENT_AUDIT.md` revision note + per-finding statuses, `tree.md` regenerated,
   Graphify map refreshed via `graphify update .`.

## What's the overarching goal?
Unchanged: an app that can be trusted with years of reading history — never silently
lose data, never crash on edge-case users, catch its own regressions automatically.
Phase 1 closed every known path that violated that.

## What needs to happen next, how, and why?
**Phase 2 IS COMPLETE** (Environment Engine + Explorer + Filtering model layer live; §8.2 gate closed; Import Intelligence surfaced; F-06 fixed+pinned — see fix-log Phase 2). Next: **Phase 3 — Feature Production** (RSVP speed-reading plan read → implement; reader UX; BCE V3 activation with its UI). Then Phase 4 debt (D6 pruning, async writes, O-6), Phase 5 niche polish (F-08–F-13).

### Prior plan (superseded)
**Phase 2 — The Great Wiring (~30% of remaining effort),** in this internal order:
1. Shared-engine refcount design BEFORE wiring Environment Engine (§8.2 predicts the
   naive multi-consumer start/stop freeze).
2. Environment Engine → Spatial Library → Progressive Filtering wiring, integration
   tests per system.
3. Import Intelligence keep-or-delete verdict (~250 lines, zero callers).
4. Harden BehaviorContext Phase-2 (incl. F-06 fatigue-analyzer tautology) BEFORE
   activating `analyzeWithIntelligence`.
Then Phase 3 features (RSVP speed-reading plan awaits protocol-read), Phase 4 debt
(D6 pruning, async writes, O-6), Phase 5 niche polish (F-08–F-13).

## What should the next AI or human know to start instantly?
- **Read `CURRENT_AUDIT.md` first** — it is the live defect/risk register (statuses updated).
- Baseline discipline is law: build+test opens every session. Suite is green right now.
- Version control is clean — work from commit history, not zip files.
- `graphify-out/` holds a fresh code graph; `graphify update .` refreshes it cheaply,
  `graphify affected <symbol>` answers impact questions before edits.
- File naming like Book2/DataStore3 is versioned-canonical. Leave it alone.
- Don't trust status comments without checking — two have been caught lying; both are
  now corrected, but the rule stands.
- The protocol loop: read fully → prove the bug → state Finality ("if I make THIS change,
  THIS bug is fixed") → edit → rebuild → log. No Finality, no touch.
