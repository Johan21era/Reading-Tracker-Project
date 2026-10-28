# 04 · Handoff

## Plain-language answers

This document answers the seven questions every close-out should answer, in plain language. It is written so that anyone — whether or not they have ever written code — can pick up the project and know exactly where things stand.

**Refreshed 2026-10-28: AsterismaV1.0 is released, merged, reorganized, CI-green, and now carries the Sentinel v2 first tranche.** The app is usable now. The remaining work is distribution hardening, owner visual acceptance of the reader polish, and the Sentinel holds recorded in SG7 (manual acceptance, v1 removal, localization, menu bar, accessibility, 10× benchmark).

---

## What was I doing?

First, the October audit era: verifying the app, fixing the freeze saga, and re-documenting it.

Then the **RT–Mirage merge campaign** (October 2026): integrating a separately owned EPUB analysis engine (“Mirage”) behind a typed, fail-closed boundary.

Then the **Bedrock program** (2026-10-24): fixing the audit-era correctness punch list, moving the live library to SQLite, adding Open-Meteo weather, wiring Behavior Context V3, and producing a signed local release candidate.

Next, the **Asterisma rebrand** (2026-10-24): renaming the product, project, targets, module, source folders, package, and user-facing copy to **AsterismaV1.0**, and moving the data root from `ReadTracker` to `Asterisma` without losing the library.

Then, the **ready close-out** (2026-10-26): the preservation-first repository reorganization, the GitHub CI runner correction, a green 229-test remote census, and a rebuilt signed package.

Then, the **Sentinel v2 first tranche** (2026-10-28): 138 probes across 15 domains, 25 verified repair plans, a Release Health Center, journal v2 with fingerprints and diagnoses, a launch card, opt-in notifications, and a redacted diagnostics export. SG7 is **HOLD** on manual owner acceptance, v1 removal, and localization.

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
| 12 | **R2 — repository reorganization:** app shell under `App/`, 48 flat tests into eight responsibility groups, 280-file baseline reconciled with zero content changes | `docs/reorganization/AV1-ROR-EXECUTION-2026-10-26.md` |
| 13 | **CI hardening + ready package:** `macos-26` / Xcode 26.6 census, Xcode 26.6 concurrency fix, rebuilt signed package, green remote receipt | GitHub run `40266848038`; `dist/AsterismaV1.0-1.0-arm64.zip` |
| 14 | **Sentinel v2 first tranche:** 138 probes / 15 domains / 25 repairs, Release Health Center, journal v2, launch card, notifications, diagnostics | `docs/audits/12-sentinel-v2-tranche-2026-10-28.md`; `docs/plans/sentinel/gates/` |

---

## Overarching goal

An app that can be trusted with years of reading history, with a change process that is receipt-driven end to end. AsterismaV1.0 adds a clean product identity and a faster SQLite-backed store without trading away the user’s existing library.

---

## What needs to happen next? (in order)

| # | Item | Estimate | Details |
|---|------|----------|---------|
| 0 | **Sentinel owner acceptance + SG7 close** | One focused session | Run the ten roadwork scenarios on a copied library, decide v1 removal, then close or narrow SG7. Localization, menu bar, accessibility, and the 10× benchmark remain separate holds. |
| 1 | **Distribution hardening** | Signing/account setup | Developer ID signing + notarization so first launch is a normal double-click. Today the build is ad-hoc signed and needs right-click → Open. |
| 2 | **Bundle ID migration** | One focused session | The sandbox ID is still `johan.Reading-Tracker`. Moving to an Asterisma ID requires copying the container to the new sandbox; do not change it casually. |
| 3 | **Swift 6 strict concurrency** | Multi-session arc | The attempt produced 148 actor-isolation errors; the project stays in Swift 5 mode until those surfaces are fixed. |
| 4 | **Reader selection highlights/quotes** | 1–2 sessions | Notes, tags, page anchors, and collections work; EPUB/PDF text-selection highlighting is not wired. |
| 5 | **Behavior evidence to SQLite** | 1 session | Evidence currently persists in a JSON archive; the behavior tables exist but are not the live store. |
| 6 | **Collection rename UI** | Small | Create/delete/membership work; rename has no UI. |
| 7 | **Legacy cleanup + remaining dead code** | 1 short session | Old P5-G `library.sqlite3`, `.migrated` files, graphify bulk, and zero-caller fragments remain; none are live. |
| 8 | **Mirage standing items** | Process, not code | TB-M0 observation cadence, a perf-budget report, and the engine-side backup-surface gap. The packaged app-embed exercise is done. |

CI runner alignment is complete (2026-10-26): `census` runs on `macos-26` / Xcode 26.6. The remote `census` is green on the Sentinel v2 tranche (run `40758619365`, `6aecdc3`): **379 test functions / 1,024 passing cases / 9 skips / 0 failures** locally, same suite in CI. The audit-era NEW-DE-1…NEW-DE-8 punch list is **fixed and pinned**; the old “open” block in the defect register is historical. Sentinel’s remaining holds are tracked in `docs/plans/sentinel/gates/SG7.md`, not in the old defect register.

---

## What should the next person know to start instantly?

**Baseline:** `main` carries the original release merge at `aba8aa4` plus the owner-accepted reader build, the preservation-first repository reorganization, CI hardening, and the Sentinel v2 first tranche (`6099e4e` plus this working tree); ready tag `asterisma-v1.0-ready-2026-10-26`, release tag `asterisma-v1.0-mvp`. Latest local unit census (2026-10-28): **379 test functions / 1,024 passed cases / 9 skipped / 0 failed**; Release build exit 0; test isolation byte-identical. Package `dist/AsterismaV1.0-1.0-arm64.zip` SHA-256 `786832c8049e38ebe03d6220ae0a39b3a0005b010bdce4675e440cea65ef4643`. Canonical census numbers come from `xcrun xcresulttool get test-results summary`; Sentinel evidence is indexed in `docs/plans/sentinel/gates/README.md`.

> **Owner-test authority:** the owner's personal test results are the absolute source of truth and override every benchmark, census, gate receipt, and documentation claim. See `docs/12-owner-test-authority.md`; record sessions in `docs/owner-test-results/`.

**Live data:** `~/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/Asterisma/` — **1 book / 3 sessions / 77 page timings** after the owner’s deliberate erase/reset and acceptance test. The owner deleted the local backup snapshots on 2026-10-24, so the live library is currently the only copy; rely on Time Machine or an external backup before risky work.

**Docs map:** start at `README.md` → this handoff → `docs/reorganization/` for the final structure audit → `docs/plans/bedrock/` for the release gates → `docs/design/READER-POLISH-2026-10-25.md` for the current reader polish → `docs/integration/` for anything Mirage.

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
- `docs/registers/03-fix-log.md` — everything fixed, with proof (Stages B/R cover Bedrock/Asterisma and the ready close-out)
- `docs/plans/bedrock/` — G0–G8 gate record, baseline, plan, distribution notes
- `docs/reorganization/` — preservation-first structure audit, baseline manifest, relocation ledger, and execution report
- `docs/design/READER-POLISH-2026-10-25.md` — Apple Books benchmark and Phase 1 reader/library polish record
- `docs/REBRAND-ASTERISMA.md` — rename and data-root migration record
- `docs/integration/RT_Mirage_Codebase_Merge_Playbook.md` — the merge-era constitution (§22 still executes the TiB era)
- `docs/audits/08-deep-audit.md` — the full independent audit (October 2026)

---

## Session close — 2026-10-25

**Delivered:** Apple Books-style reader appearance panel and library polish.
Candidate package `a8ebf2ec…17009` (code `3bff002`, tag
`asterisma-v1.0-polish-1`).

**Verification:** Debug/Release builds green; package signature and bundle
smoke green; `ReaderAppearanceTests` 5/5. Full UI-inclusive census remains
blocked by the macOS UI-test automation bootstrap.

**Cleanup:** removed ~2.9 GB of Xcode DerivedData, 91 temporary test/build
artifacts, all `.DS_Store` files, and two empty legacy project folders. Kept
the signed release zip, the staged Mirage runtime, and graphify deliverables.
`.obsidian/` is now ignored as local vault configuration.

**Next:** owner visual retest of the Appearance panel and book plate. The next
polish batch is in-book search/bookmarks/highlights, vertical scroll, and
per-theme custom settings.

---

## Session close — 2026-10-26

**Delivered:** preservation-first repository reorganization (app shell under
`App/`, 48 flat tests into eight responsibility groups), GitHub CI correction
to `macos-26` / Xcode 26.6, the Xcode 26.6 `nonisolated` subscript fix, and a
rebuilt signed ready package.

**Verification:** Debug build green; repository baseline reconciliation
280/280 with zero content changes; local unit census **220 passed / 0 failed /
9 skipped**; GitHub unit census **229 tests / 10 deliberate skips / 0 failures**
(run `40266848038`); package signature, sandbox entitlements, embedded-Mirage
smoke, and Gatekeeper-rejection expectation re-verified.

**Ready package:** `786832c8049e38ebe03d6220ae0a39b3a0005b010bdce4675e440cea65ef4643`
(app code `1c88ae5`, tag `asterisma-v1.0-ready-2026-10-26`).

**Cleanup:** graphify refreshed at the ready tree; generated `.DS_Store` and
temporary build/test residue removed. The signed zip, staged Mirage runtime,
and historical graphify outputs were preserved.

**Next:** owner visual retest of the Appearance panel and book plate on the
ready package. If accepted, record owner acceptance and promote milestone 004
from candidate to accepted. Then resume the polish backlog: in-book search,
bookmarks/highlights, vertical scroll, per-theme settings, library shelf/grid,
and the accessibility/responsive matrix.
