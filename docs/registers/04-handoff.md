# 04 · Handoff

## Plain-language answers

This document answers the seven questions every close-out should answer, in plain language. It is written so that anyone — whether or not they have ever written code — can pick up the project and know exactly where things stand.

**Refreshed 2026-10-19: the RT–Mirage merge campaign is closed** — this handoff now covers the integration era plus the standing remediation plan.

---

## What was I doing?

First, the October audit era (already closed: verifying, fixing the freeze saga, and re-documenting the app — see the previous edition of this file in git history for that close-out).

Then, the **RT–Mirage merge campaign** (Oct 2026): integrating a separately-owned analysis engine ("Mirage") into Reading Tracker behind a typed, guarded boundary — eight terraced PRs (`PR-1`…`PR-8`) under a governing playbook, each closed on a green census, ending with an owner signing round and the opening of the post-merge "Titanium Bridge" era.

---

## Why?

1. **A capability, not a rewrite:** Mirage analyzes EPUB books (chapter analysis, provenance, spoiler-safety) as a *companion* engine — RT stays the parent app, its library and store untouched.
2. **Safety first, capability second:** the campaign's whole doctrine (ownership strata, fail-closed refusals, receipt-born entries, one-lifecycle-per-gesture) exists so the integration can never silently corrupt either side's data.
3. **A signed ending, not a drifting one:** every step was receipted; the ladder ends with an owner-signed acceptance, so the merge state is *evidenced*, not assumed.

---

## What did I end up doing?

| # | What | Evidence |
|---|------|----------|
| 1 | **PR-1…PR-3 — scaffolding + the typed wire + transport** | `docs/integration/merge-log.md` (M-014…) |
| 2 | **PR-4 — sidecar lifecycle machinery + campaign BUG-stripe with externalized repro receipts** | `docs/integration/PR4-defect-analysis-2026-10-18.md` |
| 3 | **PR-5 — identity map + one-book import + live real-engine identity proof** | same log + `PR5-execution-plan…` |
| 4 | **PR-6 — spoiler-safe status surface + the gated cursor contract (ADR-7)** | same log (M-025/M-026) |
| 5 | **PR-7 — feature lifecycle (one switch; disable-deletes-nothing, byte-proven) + the countersigned stub-file deletion + the boundary root-cause ladder** | same log (M-027) |
| 6 | **PR-8 — the packaged runtime: pinned staging, verified manifest, locator ladder, clean-machine gate, CI workflow, self-hosted spawn smoke** | same log (M-028) |
| 7 | **§18/§19/§15.4 — acceptance checklist, evidence bundle, operational handoff** + §22 founding docs (TiB charter + TB-M0 plan) | `docs/integration/final-acceptance-2026-10-18.md`, `evidence/`, `tib/` |
| 8 | **Owner signing round + branch consolidation + the first TB-M0 observation receipts** | same log (M-032…M-034) |
| 9 | **Post-merge documentation refresh** (this cleanup: README, project tree, testing strategy, registers, roadmap) | this commit |

---

## Overarching goal

Unchanged at its core: an app that can be trusted with years of reading history — now extended three ways: (a) it features a cleanly-owned optional analysis engine, (b) its change process is receipt-driven end-to-end (the census at every boundary), and (c) the repo now carries its own governance documents (stub playbook register, ADRs) so future decisions are recorded, not guessed.

---

## What needs to happen next? (in order)

| # | Item | Estimate | Details |
|---|------|----------|---------|
| 1 | **TB-M0 observation cadence (Mirage era)** | ~zero code | `scripts/tib/observe.py verify <stage-root>` daily for 7 consecutive days (day-one receipt already GREEN, plus an archived tamper-refusal drill); then the owner signs the M0 exit gate → TB-M1 opens. Re-staging is idempotent by pins, so a reclaimed temp dir is harmless — just re-run the staging script. |
| 2 | **Verify the CI receipt stream** | minutes | Actions enabled on GitHub? (Owner setting.) Every push (including this one) triggers `census.yml`; first green run = the CI census receipt + can exercise the packaged-runtime embed path. |
| 3 | **NEW-DE punch list (audit-era, all open)** | ~2–4 h | NEW-DE-2 → NEW-DE-5 → NEW-DE-4 → NEW-DE-3 → NEW-DE-1, per `02-defect-register.md` + README §5 |
| 4 | **Release blockers** | ~2–4 h + art | AppIcon artwork, WeatherKit entitlement, empty `CFBundleIdentifier` key, `ENABLE_USER_SELECTED_FILES=readonly` conflict |
| 5 | **Weather honesty set** | — | NEW-DE-7/8 |
| 6 | **Dead-code sweep** | ~3–5 h | zero-caller scaffolding, verified call-site by call-site |
| 7 | **Architectural tracks** | — | Store split (#3) → SQLite (#1) → Swift 6, per their blueprints |
| 8 | **Product decision** | — | BCE Phase-2: wire (~15–25 h) or delete (~4.2k LOC); the audit recommends delete |

Mirage-era deltas deliberately ledgered, not blocking: the perf-budget report, the backup-surface wire gap (engine-side duty, named owner), R1's remaining rollback rehearsals.

---

## What should the next person know to start instantly?

**Baseline:** `xcodebuild build` exit 0; default census **191 passed / 0 failed / 4 skipped**; working tree clean after this refresh; everything pushed to GitHub. Canonical census numbers via `xcrun xcresulttool get test-results summary`.

**Docs map:** start at `README.md` → `docs/registers/04-handoff.md` (this) → for anything Mirage, `docs/integration/` (the playbook is the law, the merge log is the history, the ADRs are the decisions).

**Standing constraints** (union of the app era and the merge era):
- Whole-file rewrites only for `BehaviorContextEngine2` and `BehavioralCategory`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — every background path needs explicit `nonisolated`
- Census green at every boundary; `-derivedDataPath` is forbidden on Desktop/iCloud checkouts (BUG-003)
- **Mirage rules:** never unify the two stores; entries are born only from validated receipts; one sidecar lifecycle per gesture; the spoiler detail surfaces stay disabled until a verified calibration amendment (ADR-7, fail-closed)
- During a freeze, run `sample <pid>` before reasoning about performance (`10-profiler-fix.md` is the proof)

**The envelope(s):** `docs/history/freeze.txt` + `docs/history/10-profiler-fix.md` for the freeze saga; `docs/integration/` (playbook, merge log, rehearsal log, evidence) for the whole merge campaign — keep both.

---

## Related documents

- `docs/registers/02-defect-register.md` — Everything known to be broken or risky (incl. the integration-era cross-reference block)
- `docs/registers/03-fix-log.md` — Everything that has been fixed, with proof (Stage M covers the merge era by reference)
- `docs/integration/RT_Mirage_Codebase_Merge_Playbook.md` — the merge-era constitution (§22 still executes the TiB era)
- `docs/audits/08-deep-audit.md` — The full independent audit (Oct 2026)
