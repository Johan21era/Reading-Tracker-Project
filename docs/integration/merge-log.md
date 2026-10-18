# RT ← Mirage Integration — Merge Log

> Authoritative session log for the RT/Mirage codebase merge.
> Governed by: `RT_Mirage_Codebase_Merge_Playbook.md` v1.3 (in this folder).
> Doctrine: append-only; every record carries evidence labels per §1.3.

---

## M-001 · Authorization record (supersedes §21.0 non-execution charter for this session)

**Date:** 2026-10-18
**Recorded by:** Integration lead (GLM agent session, supervised)
**Authorization statement (human maintainer, verbatim intent):** The §21.0 Non-execution charter was authored during the preparation phase as a precautionary concept. The engineering team is now present and actively supervising. Full authority to proceed has been granted; the session may be terminated in an emergency.

**Conditions retain binding force regardless of authorization (per playbook):**
- Class Ω operations (force-push, history rewrite, repo deletion/archive, remote rewrite) still require **explicit owner countersign in this log before execution** — "full authority to proceed" is read as authorization for the standard phase ladder, NOT for Ω-class actions. (§21.5 S4-ES-3)
- Class Δ operations (reset --hard, clean -fd, branch deletion) require a pre-operation block in this log.
- Every baseline/build/test run is recorded with `(repo, SHA, env, command, result, operator)` per §21.7 S6-ES-1.
- Stop conditions SC-01…SC-12 remain in force; supervisors may waive/pause at any time.

## M-002 · Pinned source revisions (§6.1)

| Repo | Canonical path | Branch | Pinned HEAD SHA | Committed | Tree state |
|---|---|---|---|---|---|
| Reading Tracker (RT) | `~/Desktop/Reading Tracker Main ` (trailing space in name) | `main` (tracks `origin/main`) | `8fbd5357677a0bde6729454e565e12ba4c0ba9fc` | 2026-10-17 18:05:01 -0400 · "docs: rename every MD file with a concise ID'd title" | **DIRTY** — 8 modified docs files, 0 untracked |
| MirageV1.0 | `~/Desktop/MirageV1.0` | `main` (tracks `origin/main`) | `81422613610701d81956394d9601bcb61e2938e9` | 2026-10-17 17:12:20 -0400 · "Initial import: MirageV1.0, deterministic classical extraction pipeline…" | **CLEAN** · tag `v1.0.0` · local branch `backup/pre-scrub-history` |

RT dirty census (`git status --porcelain`, verbatim):
```
 M README.md
 M docs/01-project-tree.md
 M docs/method/07-testing-strategy.md
 M docs/registers/02-defect-register.md
 M docs/registers/03-fix-log.md
 M docs/registers/04-handoff.md
 M docs/roadmap/05-remediation-roadmap.md
 M docs/roadmap/06-rsvp-feature-plan.md
```
→ SC-01 / §4.3-1 check: dirty state must be explained by owner before branch creation. **OPEN — pending owner decision.**

## M-003 · Environment tuple (§6.1, S6-ES-1)

| Item | Value |
|---|---|
| OS | macOS 26.6.1 (Build 25G76) |
| Toolchain (RT) | Xcode 27.1 (Build 27A9275) — matches README-reported Xcode 27.1 |
| Python | 3.14.8 |
| Rust | rustc 1.98.1 (48a229cea 2026-09-01, Homebrew) · cargo 1.98.1 (797e8a9bc 2026-08-05) |
| Operator | GLM agent session under active human supervision |
| Notes | RT dirty-tree delta vs HEAD: 859 insertions / 1,717 deletions across 8 docs files (docs-only, no Swift) |

## M-005 · Phase 0 governance record (§5) — CLOSED

**Date:** 2026-10-18 · **Approver:** Johan Rembeci (owner, all six roles): RT owner · Mirage owner · Integration lead · Test/quality owner · Security/privacy reviewer · Release owner.

**D1 · Dirty-tree disposition (SC-01 / §4.3-1):** KEEP DIRTY, proceed alongside. The 8 modified docs files are treated as authoritative current truth; RT's git state is otherwise untouched; this dirty-tree census is hereby recorded as explained. Normative registers for Phase 3 = on-disk (dirty) versions.
**D2 · Owners:** Johan Rembeci holds all six roles (recorded above). Decision pattern: agent prepares evidence/drafts → owner signs gates.
**D3 · Scope contract (§5.2) — APPROVED as stated:** first milestone = (1) Mirage feature entry point + enable/disable setting in RT; (2) sidecar process lifecycle (launch/handshake/shutdown/crash isolation); (3) protocol handshake + version/compatibility enforcement; (4) identity mapping RT-book ↔ Mirage-edition (explicit, evidence-classed, no title-guessing); (5) ONE read-only spoiler-safe query path with fail-closed cursor behavior; (6) one-book EPUB import flow (user-initiated); (7) integration + failure-isolation tests. OUT: series editing UI, corrections UI, bulk import automation, repo consolidation, RT persistence/SQLite changes, Swift 6, CloudKit, App Store formalities.
**D4 · Git strategy (§4.3-2):** integration branch `merge/integration` created from pinned RT HEAD `8fbd5357`; merge log (this document) is committed on that branch; dirty docs files remain uncommitted working changes. Class-Ω actions remain excludable by owner countersign requirement (M-001).

## M-006 · Custody & backup record (§4.3-3/4, S4-ES-5)

| Item | Value |
|---|---|
| RT pre-merge recoverable reference | SHA `8fbd5357…` + mirror clone `Merge Phase/backups/rt-main.git` |
| Mirage pre-merge recoverable reference | SHA `81422613…` + mirror clone `Merge Phase/backups/mirage-main.git` |
| Branch created | `merge/integration` (Class Π, approved D4) |

## M-007 · Command & baseline register (S4-ES-3 pre-op blocks; §6)

| # | Command (scope) | Class | Result |
|---|---|---|---|
| C-01 | `git checkout -b merge/integration` (RT) | Π | pending |
| C-02 | `git clone --mirror` RT → backup | Π | pending |
| C-03 | `git clone --mirror` Mirage → backup | Π | pending |
| C-04 | RT baseline build `xcodebuild build` (§6.2) | candidate procedure, pre-run block below | ✅ **BUILD SUCCEEDED** at SHA `8fbd5357…` on `merge/integration` (log: `evidence/phase1/rt-baseline.log`). Pre-flight: real container hashed before run (library.json `2f7c1d97…`, library-state `f0274c8f…`, 39 covers). |
| C-05 | RT baseline tests (§6.2) | candidate procedure | ⚠️ README-documented target name `ReadingTrackerTests` **WRONG** — xcodebuild error "isn't a member of the specified test plan or scheme." Actual target: `Reading TrackerTests` (with space; verified in project.pbxproj). §6.2 prediction ("confirm scheme names first") validated — README drift logged for PR-1 correction. |
| C-05b | RT baseline tests, corrected: `xcodebuild test … -only-tested via -only-testing:"Reading TrackerTests"` at SHA `8fbd5357…` | candidate procedure (verified command) | ✅ **TEST SUCCEEDED — census (xcresult metrics): testsCount 133, failed 0, skipped 0, errorCount 0, 5 compiler warnings (Swift-6-mode macro warnings, pre-existing).** NOTE: README claims "~160+ executed cases"; true count is 133 — small census drift, not a defect. Evidence: `evidence/phase1/rt-baseline-test.log` + xcresult `Test-Reading Tracker-2026.10.18_14-57-57--0400.xcresult`. Operator: agent under M-007 pre-run block. |
| C-06 | Mirage baseline `python3 -m unittest discover -s tests` (§6.3) | candidate procedure | ✅ **Ran 316 tests in 4.881s — OK (all pass). Census matches README exactly.** Repo SHA `81422613…`, Python 3.14.8. Note: suite prints import-receipt JSON lines to stdout at end (output hygiene observation). |
| C-07 | Mirage Rust `cargo test` (§6.3) | candidate procedure | ✅ **3 tests passed in `src/lib.rs`:** `cache_key_distinguishes_values`, `cursor_key_is_stable`, `default_policy_has_one_analysis_job`. Census matches README (3). Note: `tail` misread — main.rs + doc-tests run 0; initial false alarm. |

**Pre-run block for C-04..C-07 (per Appendix F.5):** intent = reproduce baseline health at pinned SHAs; expected effect = build artifacts + test results only, no repo mutation (compiler output in DerivedData; test DBs in temp dirs); recovery = none required (read-only wrt repo state); approver = owner (M-005 D2, supervising session).

```bash
# C-06 output:
Ran 316 tests in 4.881s
OK
# census: executed 316, failed 0, skipped 0 → matches declared census (README: 316 Python tests green)
# environment: Python 3.14.8, macOS 26.6.1, repo SHA 81422613610701d81956394d9601bcb61e2938e9 (clean)

# C-07 output:
test tests::cache_key_distinguishes_values ... ok
test tests::cursor_key_is_stable ... ok
test tests::default_policy_has_one_analysis_job ... ok
test result: ok. 3 passed; 0 failed
# census: executed 3, failed 0 → matches README (3 Rust tests green)
# environment: rustc/cargo 1.98.1 (Homebrew), repo SHA 81422613...
```

## M-008 · RT normative-document extraction — principal findings (Phase 1/2 evidence)

Full extraction artifact: `evidence/phase1/rt-normative-docs-extraction.md` (12 documents read in full from the on-disk dirty tree). Headline findings with anchors:

1. **Runtime data path (SOURCE-verified in README, container form):** `~/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/ReadTracker/` holding `library.json` (29.6 MB real), `library-state.json`, `covers/` (39 files), `Backups/` (10-deep), `sentinel-journal.jsonl`. The Twin-READMEs' plain `~/Library/Application Support/johan.Reading-Tracker/` path is WRONG (App Store sandbox container form is authoritative). Confirmed live: real library present, hashed pre-baseline (`2f7c1d97…`).
2. **NEW-DE register discrepancy (playbook-relevant):** the on-disk dirty defect register contains NO NEW-DE entries and no Appendix D; the NEW-DE-1..13 items with file:line evidence live in `docs/audits/08-deep-audit.md:135-180` (§7). All NEW-DE items + 4 release blockers are OPEN. Resolution duty (audit's own rule): merge NEW-DE IDs into the register "by the next fix session."
3. **Handoff prescribes fix order:** NEW-DE-2 → NEW-DE-5 → NEW-DE-4 → NEW-DE-3 → NEW-DE-1 (ordering surgery last). RT's own next-step rule: "the first action of any future fix session should be a baseline build and test before touching code" — C-04/C-05 satisfy this.
4. **Binding RT constraints for integration code:** fix-finality triad (Finality statement + fix-log entry + pinned test; green at every boundary); all background paths need explicit `nonisolated` (MainActor-default isolation is compiler-enforced; the P6-HOTFIX v2 post-mortem documents the 1M-serialized-hops freeze); single write path contract via `PersistenceWriter`; Sentinel S1–S7 apply to any new writer; feature-module isolation doctrine proven by RSVP ("one fully self-contained module — zero dependency on other features"); tests are Swift Testing (`@Test`/`#expect`), named for the defect they guard; tests must not side-effect real user dirs (NEW-DE-12 notes CoverStorePinsTests does today — pre-flight hash snapshot taken to verify no user-data mutation during baseline).
5. **RT coverage hazards relevant to Mirage:** NEW-DE-1 (PersistenceWriter stale-overwrite window — Mirage integration must not enqueue writes through any path that widens it), NEW-DE-5 (onboarding import bypass + goal clobber — the RT-side import into Mirage must NOT inherit this bypass), NEW-DE-4 (AnalyticsCache midnight staleness if Mirage results ever cache), NEW-DE-3 (crash-window idle inflation — cursor/session sync must not worsen), plus 4 release blockers (packaging gates §14.3).
6. **Cross-doc conflicts to resolve in PR-1:** (a) register "open" section is stale (fix-log + audit say F-x fixed); (b) 28 vs 108 test count drift (108 is current); (c) handoff claims clean tree vs current dirty state; (d) NEW-DE IDs missing from the register that the handoff says they should be folded into. Additional live census refinement: README "~160+ executed cases" vs measured **133** (C-05b) — approximate-claim drift, recorded, not a defect.

## M-009 · Mirage wire-protocol contract — principal findings (verification of §21.3 S2-ES-4 vs reality)

Full artifact: `evidence/phase1/mirage-protocol-extraction.md`. The playbook's S2-ES-4 sketch correctly anticipated the sidecar shape; the proven contract refines it:

1. **Transport (PROVEN):** pure stdio NDJSON — sidecar = `python3 mirage_sidecar.py DB_PATH`; `serve()` prints a health banner as stdout line 1, then one request/response per line; `flush` per line; process exits 0 at EOF. **No HTTP anywhere on the default path** (web UI is opt-in, 127.0.0.1-only — kept out of RT per S12-ES-3).
2. **Envelope (PROVEN):** `{"ok": true, "result": …}` / `{"ok": false, "error": {type, code, status, message}}`; codes `mirage_error`/400, `validation_error`/422, `not_found`/404; unknown command → `unknown command: X` (code validation_error, status 404). Optional `id` echoed verbatim (serve.py:38-40).
3. **NO protocol-version field exists on the wire (PROVEN ABSENT).** RT's handshake MUST be operational: call `version` (expect `api_version "1.0.0"`) and `health` (expect `status "ready"`), and validate banner line 1 parses to `status: ready` before dispatching. Compatibility enforcement lives in RT's client, not the engine's envelope. (Flagged for ADR — inventing a version field on the wire would be a protocol change to Mirage.)
4. **Action set (PROVEN, 28):** health, version, import|import_epub, analyze, projection, search (fail-closed — requires edition_id+query+cursor_unit_index), checkpoint, verify_checkpoint, reconstruct, verify_deltas, export_graph, cited_claims, neighborhood, edge_detail, history, books_list, edition_remove, book_remove, search_eligible, series_create/list/candidates/attach/detach/read_state/breakdown/remove, translate. Removals confirm-gated.
5. **Ledger truth:** SQLite WAL, `SCHEMA_VERSION ledger@0.0.10` (m0001–m0016); migrate() REFUSES newer schemas (`PRAGMA user_version`) → RT must pin engine version compatibility; `backup()` exists in-process only, NOT a wire action (BLOCKED — do not assume RT can trigger ledger backup over NDJSON).
6. **Import identity (PROVEN):** sha256(file bytes) → `edition_<16hex>`/`book_<16hex>`; re-import identical bytes = idempotent `reused:true`; same edition_id + different bytes = collision REFUSAL. RT must persist the explicit (RT Book.id ↔ Mirage book_id/edition_id) pair at import time — never title-derived.
7. **Spoiler safety (PROVEN):** fail-closed predicate (mission §25.1, I-SP1/I-SP2); cursor = Mirage unit index, NOT RT page numbers (RT EPUB pages are wordCount/250 estimates — mapping MUST go through Mirage's `readers/adapters.py` position resolver); `full_book_gated` never a default.
8. **Privacy (PROVEN by test):** engine paths open zero sockets (test_webserve.py:175-213 socket-denial patch); local-first doctrine; ADR-0001 deterministic classical-only; ADR-0002 Rust core demoted (do not integrate the crate).

## M-010 · Touchpoint inventory — the five hard constraints (full artifact: `evidence/phase1/touchpoint-inventory.md`)

1. **MainActor-default isolation (compiler-enforced):** entire RT tree is MainActor unless explicitly opted out (pbxproj `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`); the three sanctioned idioms: PersistenceWriter serial queue (disk), `Task.detached` + `await MainActor.run` handback, explicit `nonisolated`. Any Mirage glue violating this repeats the P6-HOTFIX v2 1M-hop freeze class.
2. **Single-writer discipline:** `library.json`/`library-state.json` mutate ONLY via DataStore → `PersistenceWriter.shared` (serial utility queue, drainSync barrier). Sidecar and the Mirage feature must NEVER write library files directly, never enqueue non-library data through PersistenceWriter, never call `saveImmediately()` off-MainActor.
3. **Sandbox scope:** sandboxed app; NO `com.apple.security.inherit` → spawned children run unsandboxed but CANNOT reuse security-scoped bookmarks; RT process owns all scoped EPUB reads (resolveURL + start/stop balancing) and must pass bytes or an exported copy per command.
4. **Cursor semantics:** RT page numbers (PDF 0-based index; EPUB synthetic estimate) ≠ Mirage unit indexes; adapter resolver is mandatory (else spoiler boundary_key corruption + dangling `position_mappings`).
5. **Data residency:** Mirage ledger → `…/ReadTracker/mirage/mirage.sqlite3` (beside monolith, never inside `Backups/`, never `<bundle-id>/` root); one sidecar per ledger; archive/restore coupling undecided (touchpoint 16 — needs ADR).

## M-011 · Baseline side-effect census & owner disposition request (NEW-DE-12 witnessed live)

- Test run C-05b mutated NO library data (library.json + library-state.json hashes byte-identical pre/post) ✅.
- BUT `covers/` file count went 39 → 42: `CoverStorePinsTests` wrote 3 tiny stub covers into the REAL app container (file names UUID.jpg, sizes 6/3/7323 bytes, mtimes 2026-10-18 14:58, sha256 recorded). This is NEW-DE-12's "test hygiene set" item, confirmed live. Files are content-addressed orphans ignored by the library (no book references them).
- Disposition options recorded in session; awaiting owner decision: (a) delete the 3 orphans (precise cleanup of our own test side-effect), or (b) leave them (harmless; repairs belong to a NEW-DE-12 remediation session).

| File (covers/) | sha256 (prefix) | size |
|---|---|---|
| D3F7FAD0-D310-4B05-80DB-748C7B5F8491.jpg | fc16d7dc… | 6 |
| 280A0949-EDBC-453E-834F-8EF456FB28DA.jpg | 6e568e1f… | 3 |
## M-012 · PR-1 committed (§6.2 documentation record)

- Commit `ef198c5` on branch `merge/integration` (parent `8fbd5357…`), 6 files, 360 insertions, DOCS-ONLY (no runtime code). Paths: `docs/integration/merge-log.md` + `docs/integration/phase1/{rt-normative-docs-extraction.md, mirage-protocol-extraction.md, touchpoint-inventory.md, rt-baseline.log, rt-baseline-test.log}`.
- Verified post-commit: the owner-designated 8 dirty docs files remain uncommitted and byte-untouched (git status census unchanged).
- Merge-log parity note: the committed copy under RT's `docs/integration/` is a snapshot at commit time; the working master remains `Merge Phase/merge-log.md` (append-only, re-committed in later PRs).

## M-013 · Covers cleanup executed (owner-approved disposition)

The 3 test-generated orphan covers were deleted: each file's sha256 re-verified against the pinned pre-hash immediately before deletion (hash-mismatch = abort path, not taken); container verified restored to exactly 39 covers. First cleanup attempt aborted by a shell-quoting fault (path never reached — no files touched); second attempt was the verified-delete. Class Δ operated with owner countersign.

## M-014 · ADR drafts — PROPOSED (§9/§17, S17-ES-1 content contracts) — SIGN-OFF PENDING

Canonical numbering note: the playbook's ADR slots are fixed by §17 (S17-ES-1): ADR-1 = repo consolidation (Class Ω, parked), ADR-2 = transport+protocol, ADR-3 = runtime distribution (gates PR-8 packaging), ADR-4 = data dirs/ledger/backup, ADR-5 = identity mapping, ADR-7 = spoiler-cursor contract + S10-ES-3 sub-document. Drafts below land in the canonical slots; ADR-3 and ADR-7 are intentionally deferred to their own draft batches (ADR-7 gates any spoiler-sensitive surface — until countersigned, read-only status surfaces only).

| ADR | File (docs/integration/adr/) | Decision |
|---|---|---|
| ADR-2 | ADR-2-transport-and-protocol.md | Managed stdio NDJSON sidecar (one child: `python3 mirage_sidecar.py <abs db path>`); operational handshake (banner line 1 `status:"ready"` + `version`→`api_version "1.0.0"` pinned + contract hash); no invented wire fields; typed `protocol_incompatible` masking; single-instance supervision + bounded restart (≤3 attempts, 2/4/8 s backoff); HTTP/web surface never started by RT; pipe I/O off-MainActor, no ≥5 ms MainActor blocks. |
| ADR-4 | ADR-4-ledger-placement-and-backup-ownership.md | Ledger at `…/ReadTracker/mirage/mirage.sqlite3` (absolute; RT-owned dir created on enablement); `mirage/` = exclusively Mirage-write territory; RT backups/archive exclude ledger (backup is engine doctrine; wire `backup` action BLOCKED today); Sentinel never touches `mirage/`; RT restore has no effect on ledger; nothing auto-deletes. |
| ADR-5 | ADR-5-identity-mapping.md | Own stratum `…/ReadTracker/mirage/identity-map.json` (schema `mirage-identity-map@1`, atomic write); entries `(rtBookID, mirageBookID, mirageEditionID, sourceFingerprint, status)`; created only via user-initiated import receipt (idempotent `reused:true` or fresh `imported`); byte-hash drift ⇒ `identityDrift` refusal + orphaning (fail-closed); missing edition ⇒ `edition-gone`; `degraded_import` never mapped; RT persistence schema untouched; no title-guessing anywhere. |

Alternatives rejected are documented inside each ADR (in-process embedding; HTTP loopback; Rust core; Book-field schema change; title fuzzy-mapping; etc.) with evidence-based rejection reasons. Status flip to ACCEPTED happens in the docs at owner sign-off, recorded here.

| Phase | § | Status | Gate evidence |
|---|---|---|---|
| 0 Governance | §5 | **CLOSED** | M-005 (owners, scope, git strategy, dirty-tree) |
| 1 Baselines | §6 | **CLOSED** | M-007 C-04/C-05b/C-06/C-07 — RT build ✅, tests TEST SUCCEEDED 133/0, Mirage 316✅+3✅; census arithmetic satisfied at both pinned SHAs |
| 2 Discovery | §7 | **CLOSED** | M-008 + three full extraction artifacts in `evidence/phase1/` (RT normative docs; Mirage protocol contract; touchpoint inventory) |
| 3 Defect triage | §8 | IN PROGRESS | consolidation draft pending owner review (inputs: M-008 NEW-DE table + M-009/M-010 constraints) |
| 4 Boundary | §9 | pending | — |
| 5 Adapter | §10 | pending | — |
| 6 Feature | §11 | pending | — |
| 7 Security | §12 | pending | — |
| 8 Testing | §13 | pending | — |
| 9 Packaging | §14 | pending | — |
| 10 Rollback | §15 | pending | — |
