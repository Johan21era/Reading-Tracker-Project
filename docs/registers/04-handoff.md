# 04 · Handoff

## Plain-language answers

This document answers the seven questions every close-out should answer, in plain language. It is written so that anyone — whether or not they have ever written code — can pick up the project and know exactly where things stand.

**Refreshed 2026-10-24: AsterismaV1.0 is released, merged, and pushed.** The app is usable now. The remaining work is hardening for wider distribution and a short list of clearly documented feature gaps.

---

## What was I doing?

First, the October audit era: verifying the app, fixing the freeze saga, and re-documenting it.

Then the **RT–Mirage merge campaign** (October 2026): integrating a separately owned EPUB analysis engine (“Mirage”) behind a typed, fail-closed boundary.

Then the **Bedrock program** (2026-10-24): fixing the audit-era correctness punch list, moving the live library to SQLite, adding Open-Meteo weather, wiring Behavior Context V3, and producing a signed local release candidate.

Finally, the **Asterisma rebrand** (2026-10-24): renaming the product, project, targets, module, source folders, package, and user-facing copy to **AsterismaV1.0**, and moving the data root from `ReadTracker` to `Asterisma` without losing the library.

---

## Why?

1. **Trust first:** the app holds years of reading history. The Bedrock work fixed data-ordering, crash-window, cache, onboarding, and cover bugs before adding anything new.
2. **A capability, not a rewrite:** Mirage analyzes EPUBs as a companion engine. It keeps its own ledger and never writes the app’s store.
3. **Receipts, not assumptions:** every gate closed on a green census, and the release has a package checksum plus a launch receipt.
4. **A real name:** the product is **Asterisma**; this MVP build is **AsterismaV1.0**. The internal sandbox bundle ID stayed `johan.Reading-Tracker` on purpose so the existing container and library were not orphaned.

---

## What did I end up doing?

| # | What | Evidence |
|---|------|----------|
| 1 | **G0 — safety baseline:** worktree, data snapshot, test isolation, benchmark | `docs/plans/bedrock/BASELINE.md` |
| 2 | **G1 — correctness:** fixed and pinned writer ordering, crash-window inflation, stale midnight cache, onboarding import bypass/goal clobber, spatial covers, RSVP cancellation | `gates/GATE-G1.md` |
| 3 | **G2/G2B — distribution + Mirage:** app icon, entitlements, shared scheme, ad-hoc package; 47 MB runtime embedded, signed, manifest-verified, bundle-smoke green | `gates/GATE-G2.md`, `GATE-G2B.md` |
| 4 | **G3A/B/C — SQLite:** GRDB schema, lazy summary store, real-library cutover, JSON retired to `.migrated`; load **5.06 ms** vs 493.7 ms | `gates/GATE-G3A.md`, `GATE-G3B.md`, `GATE-G3C.md` |
| 5 | **G4 — weather:** Open-Meteo provider, live session→snapshot→SQLite pipeline, no WeatherKit entitlement | `gates/GATE-G4.md` |
| 6 | **G5 — library intelligence:** EPUB genre/series/word count, Book Details, notes, tags, collections | `gates/GATE-G5.md` |
| 7 | **G6 — Behavior Context V3:** full report, Advanced Context window, evidence archive, history analysis | `gates/GATE-G6.md` |
| 8 | **G7 — debt:** removed 1,157 lines of dead code; Swift 6 attempted and deferred with an honest 148-error receipt | `gates/GATE-G7.md` |
| 9 | **G8 — release candidate:** full census, package, checksum, launch smoke, owner acceptance | `gates/GATE-G8.md` |
| 10 | **R1 — Asterisma rebrand + data migration:** live library moved in place, counts preserved | `docs/REBRAND-ASTERISMA.md` |
| 11 | **Merge + push:** fast-forwarded `main`, pushed `main` and all tags to GitHub | `main` at `aba8aa4`; tag `asterisma-v1.0-mvp` |

---

## Overarching goal

An app that can be trusted with years of reading history, with a change process that is receipt-driven end to end. AsterismaV1.0 adds a clean product identity and a faster SQLite-backed store without trading away the user’s existing library.

---

## What needs to happen next? (in order)

| # | Item | Estimate | Details |
|---|------|----------|---------|
| 1 | **Distribution hardening** | Signing/account setup | Developer ID signing + notarization so first launch is a normal double-click. Today the build is ad-hoc signed and needs right-click → Open. |
| 2 | **Bundle ID migration** | One focused session | The sandbox ID is still `johan.Reading-Tracker`. Moving to an Asterisma ID requires copying the container to the new sandbox; do not change it casually. |
| 3 | **Swift 6 strict concurrency** | Multi-session arc | The attempt produced 148 actor-isolation errors; the project stays in Swift 5 mode until those surfaces are fixed. |
| 4 | **Reader selection highlights/quotes** | 1–2 sessions | Notes, tags, page anchors, and collections work; EPUB/PDF text-selection highlighting is not wired. |
| 5 | **Behavior evidence to SQLite** | 1 session | Evidence currently persists in a JSON archive; the behavior tables exist but are not the live store. |
| 6 | **Collection rename UI** | Small | Create/delete/membership work; rename has no UI. |
| 7 | **Legacy cleanup + remaining dead code** | 1 short session | Old P5-G `library.sqlite3`, `.migrated` files, graphify bulk, and zero-caller fragments remain; none are live. |
| 8 | **Mirage standing items** | Process, not code | TB-M0 observation cadence, a perf-budget report, and the engine-side backup-surface gap. The packaged app-embed exercise is done. |
| 9 | **CI runner alignment** | Release-pipeline item | Local census is authoritative until the CI runner matches the local Xcode/macOS pair. |

The audit-era NEW-DE-1…NEW-DE-8 punch list is **fixed and pinned**; the old “open” block in the defect register is historical.

---

## What should the next person know to start instantly?

**Baseline:** `main` carries the original release merge at `aba8aa4` plus the owner-test fixes at `a0035d1` (tag `asterisma-v1.0-owner-test-fixes-2`); census **213 passed / 0 failed / 9 skipped**; release tag `asterisma-v1.0-mvp`; package `dist/AsterismaV1.0-1.0-arm64.zip` with SHA-256 `57a4113e3d135b573edc48b19ac127f4dc0200d48c68b34c49a8a5068745c422`. Canonical census numbers come from `xcrun xcresulttool get test-results summary`.

> **Owner-test authority:** the owner's personal test results are the absolute source of truth and override every benchmark, census, gate receipt, and documentation claim. See `docs/12-owner-test-authority.md`; record sessions in `docs/owner-test-results/`.

**Live data:** `~/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/Asterisma/` — 7 books / 292 sessions / 138,459 page timings. The owner deleted the local backup snapshots on 2026-10-24, so the live library is currently the only copy; rely on Time Machine or an external backup before risky work.

**Docs map:** start at `README.md` → this handoff → `docs/plans/bedrock/` for the release gates → `docs/integration/` for anything Mirage.

**Standing constraints:**
- Whole-file rewrites only for `BehaviorContextEngine2` and `BehavioralCategory`.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — every background path needs explicit `nonisolated`.
- Census green at every boundary; `-derivedDataPath` is forbidden on Desktop/iCloud checkouts (BUG-003).
- **Owner results outrank the census.** A personal test failure is a real failure even if the suite is green; record it and fix it.
- Data root is `Application Support/Asterisma/`; the legacy `ReadTracker/` name is migration-only.
- The bundle ID is intentionally stable for this MVP; changing it needs a container migration.
- **Mirage rules:** never unify the two stores; entries are born only from validated receipts; one sidecar lifecycle per gesture; spoiler detail surfaces stay disabled until a verified calibration amendment (ADR-7, fail-closed).
- During a freeze, run `sample <pid>` before reasoning about performance (`10-profiler-fix.md` is the proof).

**Fresh-clone build:** stage the gitignored Mirage runtime first:
`./scripts/stage-mirage-runtime.sh "$PWD/.mirage-runtime"`.

---

## Related documents

- `docs/registers/02-defect-register.md` — everything known to be broken or risky (the NEW-DE block is historical; F-series items remain the source of truth)
- `docs/registers/03-fix-log.md` — everything fixed, with proof (Stage B covers Bedrock/Asterisma)
- `docs/plans/bedrock/` — G0–G8 gate record, baseline, plan, distribution notes
- `docs/REBRAND-ASTERISMA.md` — rename and data-root migration record
- `docs/integration/RT_Mirage_Codebase_Merge_Playbook.md` — the merge-era constitution (§22 still executes the TiB era)
- `docs/audits/08-deep-audit.md` — the full independent audit (October 2026)
