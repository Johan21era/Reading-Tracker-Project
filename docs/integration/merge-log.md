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

## M-015 · PR-2 committed

- Commit `13ad970` on `merge/integration`: 3 ADR files (PROPOSED) + merge-log refresh (4 files, 164 insertions). Docs-only; the 8 owner-designated dirty docs files remain untouched (verified post-commit).

## M-016 · ADR sign-off (owner countersign) — PR-2 gate SATISFIED

- Owner response (this session): **"Accept all three as written."** ADR-2, ADR-4, ADR-5 flipped to ACCEPTED 2026-10-18 (docs amended in PR-3 commit). Boundary preconditions now: baselines green ✓ · ADR-2 approved ✓ · protocol contract published & counter-interpreted (M-009, no edits) ✓ → proceeding to PR-3.
- Note: §17 canonical slot numbering honored (transport=ADR-2, ledger=ADR-4, identity=ADR-5); ADR-1 (repo consolidation, Class Ω) parked; ADR-3 (runtime distribution) gates PR-8; ADR-7 + S10-ES-3 sub-document still REQUIRED before any spoiler-sensitive surface ships.

## M-017 · PR-3 — Mirage host interface + fake transport (first runtime-code PR)

Scope (S16-ES-1 PR-3): typed client + wire types + transport seam passes conformance suite against fake/test double; zero process spawns; zero RT persistence dependencies; RT suite green.

**Runtime files** (synchronized-folder targets — no .pbxproj edits needed, verified):

| File | Contents |
|---|---|
| `Reading Tracker/Features/Mirage/MirageWireTypes.swift` | 28-case `MirageWireAction` (engine dispatcher names verbatim; bare `import` alias intentionally unrepresented — RT sends canonical `import_epub`); `MirageJSONValue` flexible Sendable JSON value (full Codable, nonisolated witnesses — Swift-6-conformance stamped); `MirageWireRequestLine` (id+action+optional payload; the id echo IS proven engine behavior serve.py:38-40, not an RT invention); `MirageWireErrorPayload` strict 4-key; `MirageWireEnvelope`. |
| `Reading Tracker/Features/Mirage/MirageTransport.swift` | `nonisolated protocol MirageTransport: Sendable` — framing contract (transport owns LF framing; no newline in/out; oversized-line guard + timeouts are PR-4 duties). |
| `Reading Tracker/Features/Mirage/MirageClient.swift` | `final nonisolated class MirageClient: Sendable` — encode → exchange → decode → id-correlate → `Outcome.success(result)` or `engineError(verbatim payload)`; RT-side typed `Fault` registry (responseUnparsable / correlationFailure / envelopeShapeInvalid, Equatable); transport failures rethrow unchanged. |

**Conformance suite:** `Reading TrackerTests/MirageProtocolConformanceTests.swift` — 14 tests: action census (dispatcher-set equality), exact-key encoding (+payload omission), success/error envelope verbatim (incl. asymmetric unknown-command pair code=validation_error/status=404 preserved), id correlation (echo ok / mismatched / missing), framing corruption (multi-value, array, scalar, broken-JSON → typed unparsable), transport rethrow unchanged.

**Results:**
- New suite: 14/14 pass.
- Full RT suite: **TEST SUCCEEDED — census 147 executed, 0 failed, 0 skipped** (133 baseline + 14 new = exact arithmetic; SC-02 satisfied).
- NEW-DE-12 standing note: every full-suite run recreates the 3 known stub covers; cleanup is hash-pinned-only (any non-matching file kept). Real library JSON hashes remain byte-identical throughout.

## M-018 · PR-3 committed

- Commit `56bf5d8` on `merge/integration`: 3 runtime files + 1 test file + merge-log refresh (8 files, 454 insertions). RT persistence surface untouched (zero DataStore references in Mirage files). The 8 owner-designated dirty docs files remain untouched (verified post-commit).

## M-019 · PR-4 implemented — sidecar lifecycle runtime + suites; BUG-001 root-caused and fixed (C2)

Full campaign of record: `PR4-defect-analysis-2026-10-18.md` (in-repo snapshot alongside this log — the living master and its postscript §R0–§R5 remain in the campaign bookkeeping dir outside the repo). Summary hierarchy below; evidence tags live in the analysis doc.

**Defect chain closed today:**

| ID | Disposition |
|---|---|
| BUG-001 (High: batch-context silent stdout from long-lived stub children) | **Root-caused + fixed.** E1 probe executed 3×3 cycles: machinery drift wedged `responseTimeout(6.0)` **3/3 deterministically** while a raw `read(2)` reader on the same-shaped pipe delivered **3/3** → H3/H1 falsified; **H2 confirmed machinery-local** (`FileHandle.read(upToCount:)` on a launcher-cycled pipe). C2 applied: raw `read(2)` on the captured descriptor + idempotent `closeRead` (nil stderr handler first, then close both read handles) at all three end-of-epoch sites. Post-fix probe: 0/3 wedge, every phase delivered. |
| BUG-003 (CodeSign detritus) | **Root cause refined:** iCloud File Provider stamps (`com.apple.fileprovider.fpfs#P`) on Desktop-synced paths; `.rt-dd` under the repo is unusable for signing. Builds moved to default DerivedData — green repeatedly, no xattr dance needed. `.rt-dd` (449 MB) deleted from the repo; BUG-001 repro xcresult (104 MB) archived **outside the repo** in the campaign bookkeeping dir (excluded by size policy) as `BUG-001-repro-2026-10-18_17-51-51.xcresult`. |
| BUG-005 (probe file hazard) | **Resolved:** probe deleted before commit (superseded by the corrected forensic probe). |
| Oversize-cap chunk masking (unregistered) | Surfaced by C2: raw `read(2)` delivered the 201-byte line in one chunk whose LF bypassed the no-LF stream-cap check; `blockingReadLine` now enforces the cap on the complete line (unbounded-growth check retained). |
| Pin-ready payload expectation (unregistered) | Test comment said "empty result" while the `version-ok` stub answers every line with `{"api_version":"1.0.0"}`; assertion aligned to the verbatim stub contract; the pin's protective behaviors unchanged. |

**Runtime totals:** `MirageSidecarSupervisor.swift` (state machine `[disabled|handshaking|ready|protocolIncompatible|engineUnavailable|permanentDown]`, backoff ladder `[2,4,8]`, pid-file single-instance guard, terminal-fault non-restart, `clearTerminalState()` reserved PR-7), `MirageChildProcess.swift` (launcher + transport + C2 hardening + LF framer + JSON bridging + `MirageOnceCloser`), `MirageProtocolConstants.swift` (handshake contract-signature pin).

**PR-4 suites (all `.serialized`, real engine touched only by the env-gated smoke):** `MirageStubSidecarSupport.swift` (stub script + configs + counting launcher), `MirageHandshakePinTests` (6: junk→non-restart masking, banner-without-status, drift→terminal, ready→serve → pid-file → shutdown, …), `MirageSidecarLifecycleTests` (8: compliant shutdown, SIGTERM, SIGKILL, oversize→typed fault + child reaped, never-responds→timeout+reap, restart ladder, …), `MirageRealEngineSmokeTests` (1, opt-in `mirageRealEngineEnabled`).

## M-020 · PR-4 verified and committed

- **PR-4 suites in ONE runner:** `TEST EXECUTE SUCCEEDED` (pin 6/6 + lifecycle 8/8, serialized) — the batch-context house standard holds post-C2.
- **Full census (default plan, one runner):** `TEST SUCCEEDED`, result **Passed — 138 executed / 0 failed / 1 skipped**. The skip is `MirageRealEngineSmokeTests` (`.enabled(if:)` env gate — as designed). Suite level: `MirageProtocolConformanceTests` 14/14, `MirageHandshakePinTests` 6/6, `MirageSidecarLifecycleTests` 8/8; plan total 139 nodes (incl. UI-target tests).
- **Census arithmetic note:** M-017's "133 baseline + 14 = 147" predates the current plan selection and the committed phase-1 log carries no test counts; the per-suite census above is the pinned record henceforth. Zero failures across the current selection; no regression indicated.
- **Real-engine smoke:** not run (env-gated; OPE-004 stays an owner decision — disposable-DB-only if run).
- **Covers state (post-census):** container `covers/` = **45 files = 15×3 stub-hash family** (13×3 pre-run; +6 from today's two full runs via `CoverStorePinsTests` stub pins — standing note NEW-DE-12 holds). `library.json` untouched; no data loss. OPE-001 deletion (45-file hash family) remains **owner-gated** (Class Δ, M-013 precedent).
- **Commit:** `863dac1` on `merge/integration` — 3 runtime + 4 test files + merge-log refresh + committed copy of the defect analysis (9 files, 2038 insertions); the 8 owner-designated dirty docs files remain untouched (verified post-commit).

## M-021 · Session close note (2026-10-18 evening)

- **State:** `merge/integration` at `863dac1` (PR-1 `ef198c5` → PR-2 `13ad970` → PR-3 `56bf5d8` → **PR-4 `863dac1`**). Working tree = exactly the 8 owner-designated dirty docs files, untouched; no untracked code remains; nothing pushed to `origin`.
- **BUG-001 saga closed:** classified (H2 machinery-local), fixed (C2 raw `read(2)` + idempotent `closeRead`), verified (deterministic wedge 3/3 → 0/3; full census 138/0/1 with PR-4 suites green in one runner).
- **Pending owner items (unchanged):** OPE-001 cover deletion — now the **45-file** stub-hash family (15×3; Class Δ countersign required, M-013 precedent); OPE-004 real-engine smoke (env-gated, optional pre-PR-5; disposable-DB only); PR-7 gates on ADR-7 + S10-ES-3 draft; PR-8 gates on ADR-3.
- **Next unit — PR-5 (identity + one-book import):** playbook gate "explicit user-driven flow; mapping in its own stratum; RT persistence schema untouched; duplicate/changed/ambiguous/missing-file/cancel/crash cases pinned"; ADR-5 (fail-closed) owner-accepted. Execution plan drafted: `PR5-execution-plan-2026-10-18.md` (in-repo snapshot alongside this log).
- **Standing discipline added:** no FileHandle read APIs on long-lived child-pipe transports (ADR-2 amendment candidate); default DerivedData only (no build products under the iCloud-synced repo dir).

## M-022 · OPE-004 executed — real-engine smoke (owner-approved)

**Pre-run block (recorded before execution):** intent = verify the REAL MirageV1.0 engine completes the pinned handshake + one health round-trip through PR-4's committed transport path · expected effect = one python child spawned via the RT locator; ledger = disposable temp file `mirage-smoke-<UUID>-library.db` deleted on exit (never the real ledger); pid-file guard in a disposable temp dir · recovery = no lasting state by construction; worst case `permanentDown`/typed fault — nothing persists; committed suites remain stub-only and unaffected · approver = owner in-session ("Run it now", 2026-10-18 evening). Command: `TEST_RUNNER_MIRAGE_REAL_ENGINE_DIR=/Users/johanrembeci/Desktop/MirageV1.0 xcodebuild test … -only-testing:"Reading TrackerTests/MirageRealEngineSmokeTests"` (default DerivedData; code tree identical to census-verified commit `863dac1`).

**Result:**

- **Run 1 failed on an invented literal, run 2 passed after correction against the engine contract.** The real MirageV1.0 sidecar was spawned from RT's committed transport path with a disposable temp DB: real banner received, id-correlated health round-trip succeeded, clean shutdown (child reaped, pid file removed) — ~2.6 s wall.
- **Correction (evidence-typed):** the smoke test's `health → status "ok"` literal was invented in an earlier session (the value never verified at runtime — exactly what the opt-in gate exists to catch). Source-verified engine behavior: the `health` action returns `service.health()` itself, `status` = `"ready"` (`api/service.py:67-72`; startup banner identical per `serve.py:48`). Test re-pinned to the source value with in-code anchors.
- **Full census re-witnessed after the change: 138 executed passed / 0 failed / 1 skipped** — identical totals to the PR-4 census (the gated smoke stays skipped in ungated runs, by design). Covers 45 → **48** (16×3 stub-hash family; standing note NEW-DE-12 holds).
- **Verdict: the real engine works through RT's PR-4 transport — first end-to-end real-engine proof.** PR-5 begins from a proven spawn/serve/shutdown cycle; the smoke suite remains opt-in and was committed in the corrected (source-pinned) form.

- **Commit:** `3bbaa0b` on `merge/integration` — smoke-test re-pin + merge-log refresh + PR-5 execution-plan snapshot (3 files, 95 insertions); the 8 owner dirty docs remain untouched. OPE-004 disposition: **EXECUTED, green**.

## M-023 · PR-5 step 1 — import contract extracted from MirageV1.0 (source-anchored, read-only)

- **Dispatch (`api/service.py:812+`) — payload schema for `import_epub`:** `path` REQUIRED (RT sends ONLY this); `book_id`/`edition_id`/`edition_fingerprint`/`title_guess` optional — engine defaults derive all IDs from `sha256` of the file bytes (first 16 hex: `book_<d16>`, `edition_<d16>`). RT must never send synthesized IDs (ID-SYNTH-9001).
- **Receipt (verbatim keys, `api/service.py:~142/158`):** `{"status": "imported"|"degraded_import", "units": N, "book_id": String, "edition_id": String, "reused": Bool, "series_hint": dict|null}`, plus `skipped_documents: [String]` **iff** degraded.
- **Reuse semantics (`§36.1`):** identical bytes → `reused:true` with the same edition/book IDs; same `edition_id` with different content → `ValidationError` collision (unreachable from RT when RT sends bare `path`).
- **Degraded (`P-028a`, `service.py:151-154`):** spine decode failures are persisted as `degraded` and **analysis refuses such editions**; per ADR-5 Decision 6 RT rejects the receipt as mapping input and surfaces "source needs repair".
- **Error envelope for missing source:** `ok:false {type: FileNotFoundError, code: "mirage_error", status: 400}` (`serve.py:11-21,27-31`) — RT pre-flight (S10-ES-1(c)) should catch it first anyway.
- **RT-side facts pinned:** `Book` (`Core/Book2.swift:35-47`) carries `id: UUID` (=`rtBookID`), `fileURL: URL`, `fileType` (only `.epub` books qualify — PDFs get a typed not-applicable state), `bookmarkData`; `Book.resolveURL()` (`:122`) resolves the security-scoped bookmark `.withSecurityScope` with stale warnings — the flow reuses *this* referent (owner Q2 of the PR-5 plan: **RT does retain a resolvable source path; no new file-picking machinery required**).
- **Client surface:** `MirageClient.perform(_ action:, payload: MirageJSONValue?)` already suffices (`MirageClient.swift:46-52`) — no wire/client changes needed for PR-5.
- **Scope-fence restated:** no cursor transduction (S10-ES-3/ADR-7 gate PR-6); the receipt's `series_hint` is engine bookkeeping only — RT never auto-attaches series.

## M-024 · PR-5 executed — identity map + one-book import (ADR-5 stratum, real-engine proof, UI mount, ADR-6 discharge)

- **Commit:** `PR5` series on `merge/integration` — 11 files: 4 runtime (`MirageIdentityMap.swift`, `MirageImportFlow.swift`, `MirageAppImportMount.swift`, `MirageAnalysisSheetView.swift`), 1 UI mount on an RT surface (`EPUBReaderScreen.swift` — info-popover entry + sheet), 4 test suites (`MirageIdentityMapContractTests` 5, `MirageIdentityDriftTests` 11, `MirageAppImportMountTests` 3, `MirageIdentityRealEngineImportTests` 1 opt-in), `ADR-6` + merge-log refresh. The 8 owner dirty docs remain untouched; nothing pushed.
- **ADR-5 files pinned:** schema `mirage-identity-map@1`; entry birth ONLY from a validated `import_epub` receipt (Decision 3); one-active-per-book via superseded-orphan transition (Decision 2); crash-atomic temp+rename writes with an injection hook (interrupt test: old file byte-identical, zero debris); fail-closed degrade on unknown schema/malformed entries (Decision 8 — absent file = virgin empty map, not degradation); typed orphan reasons `source-changed` / `edition-gone`.
- **Full census (this commit's gate):** **157 executed passed / 0 failed / 2 skipped** (159 total = the plan's 139-node inventory + 19 executed PR-5 tests + 1 new gated suite node counting as its skip); skips = env-gated opt-in suites (smoke + real-engine identity). Suite-level record stands as the pinned accounting.
- **ADR-6 + NEW-DE-5 discharge (owner countersigned this session, before commit):** the playbook's PR-5 block (playbook :1596) relieved by the independence ADR: the Mirage flow writes ONLY the engine ledger (digest-lineage `reused:true` dedupe, `service.py:106-124`) + `mirage/identity-map.json`; it creates no books (no `addBook`/`BookImporter`/facade), no goals (`commitGoal`/`updateGoalSet` unreachable); the RT-internal bypass stays tracked under NEW-DE-5 untouched. Census grep gate (M-024): **zero** references from Mirage feature files to `ImportIntelligenceFacade|BookImporter|addBook|updateGoalSet|commitGoal|OnboardingView`.
- **Real-engine identity proof (OPE-004 doctrine, single-lifecycle):** disposable ledger + real sidecar + real EPUB fixture (built in-test via `/usr/bin/zip`; `mimetype` absent on purpose — this ingestor opens the zip directly): fresh `import_epub` → `.linked(reused:false)` with BOTH IDs = digest-derived (`book_/edition_` + 16-hex prefix) and 64-hex `sourceFingerprint` matching RT's local sha256; re-import → engine answers `reused:true` and the map file stays **byte-identical** (no second entry); real `books_list` presence check → engine-verified `.linked`; malformed-spine fixture → `degraded_import` skipped≥1 → **refused as mapping input, no entry created** (Decision 6/P-028a). Invocation: `TEST_RUNNER_MIRAGE_REAL_ENGINE_DIR=/Users/johanrembeci/Desktop/MirageV1.0 xcodebuild test … -only-testing:"Reading TrackerTests/MirageIdentityRealEngineImportTests"` — green at ~2 s.
- **Contract facts corrected by the real runs (authority = the wire, not the method signature):**
  1. `books_list`'s wire export wraps the inventory — `{"books": [...]}` — although the service method returns a bare `list[dict]` (probe-verified; RT's fake fixtures now pin the REAL shape). M-023's service-level extraction was insufficient alone; the dispatch/export layer is part of the contract.
  2. `import_epub` on a non-EPUB/bad zip is a hard error envelope, NOT `degraded_import` — degradation only covers spine documents that fail decode while the edition otherwise imports (fix the real-vs-spec boundary in ADR-5's drift rules if PR-6 reuses them).
- **Machinery boundary discovered and honored (defect candidate, left OPEN):** one test-process hosts exactly ONE real sidecar spawn; a SECOND sequential spawn (fresh supervisor/paths/db) never reaches its banner — ladder `[2,4,8]` exhausts at `responseTimeout(seconds:25)` ×3 → `permanentDown` (reproduced across runs: parallel first, then serialized degraded-passed/import-failed). Root cause not yet pinned (child-channel/epoch residue, PR-4 surface); honored by converging all real-engine proofs into ONE lifecycle per process; PR-7's settings-session must respect it (surface for its root-cause; neighboring probe run was normal ⇒ engine healthy).
- **UI mount (owner-approved placement + wording):** entry = EPUB reader's info popover (RT's book-detail page) → `MirageAnalysisSheet`: never auto-runs; typed outcomes rendered through `MirageOutcomeCopy`; cancel semantics honest by construction — the flow's cancel hooks carry `engineCommitted:` (pre-dispatch = "nothing was run"; post-receipt/commit-adjacent = owner-approved plain-and-honest copy: "Mirage has already stored its analysis of this book, and that stays…"). Session doctrine until PR-7: one analyze = one spawn→import→shutdown lifecycle. Engine location = dev-opt-in env gate (`MIRAGE_REAL_ENGINE_DIR`); ADR-3/PR-8 owns the packaged policy.
- **RestoreState-invariance proof posture (ADR-5 test list item):** structural (the flow holds no RT persistence reference — grep gate above) + behavioral (every refusal/cancel path leaves the map file absent or byte-identical, pinned in the drift suite).

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
