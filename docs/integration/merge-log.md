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

## M-025 — 2026-10-18 · PR-6 gate documents countersigned (ladder resumes)
- Owner countersign batch (one round, three decisions):
  1. **ADR-7 accepted as drafted** (spoiler-cursor contract + Annex A = the S10-ES-3 normative sub-document, all seven elements source-anchored): *no-conversion-is-the-safe-conversion* doctrine — the inventory estimate (fraction × max_cursor) rejected as an unverifiable cursor; PR-6 ships the read-only STATUS surface + gated cursor machinery; claim/evidence/graph DETAIL stays disabled until a future countersigned verified chapter→unit calibration amendment.
  2. **ADR-3 direction: bundle with the app** — embedded engine + interpreter, offline day one (MirageV1.0 is pure-stdlib Python ≥3.11, no requirements.txt; packaging prerequisites verified from source).
  3. **OPE-001 countersigned (Class Δ)**: the 48-file covers-adjacent stub-hash family deletes in the PR-7 commit wave, census re-verified after.
- Engine inventory row keys pinned from `service.py:505-554` (no invented fields): `book_id / title / edition_id / units / claims / max_cursor / first_entity_id / created_at`, wrapped `{"books":[...]}` on the wire.
- PR-6 implementation under the accepted ADR: status surface (local map read, engine-verified verification, engine-attested counts with provenance labels, RT read-state line via the A.7 transduction table — no Mirage declaration transmitted), `MirageCursor` gate (`SPOILER-CURSOR-UNVERIFIED` / `SPOILER-PROBE-REJECTED` / `CURSOR-MISSING`), `MirageDetailQuery` disabled call-site, page-turn non-trigger pins. Test names exactly per the ADR's required list: `MirageCursorContractTests` / `MirageSpoilerProbeTests` / `MiragePageTurnNonTriggerTests` / `MirageStatusSurfaceTests`.
- Real-engine opt-in suite stays single-lifecycle (honest M-024 boundary); PR-6 appends a detail-free status phase to it.
- ADR-6 numbering collision acknowledged (PR-5's NEW-DE-5 discharge record vs the playbook's §17 ADR-6 feature-lifecycle seat): the discharge file renames to **ADR-6a** in the PR-7 commit wave; PR-7 then drafts the true feature-lifecycle ADR on the canonical seat.
- Push policy for the resumed ladder: commits accumulate on `merge/integration`; owner reviews and authorizes the push (no origin writes this session without explicit instruction).

## M-026 — 2026-10-18 · PR-6 executed — status surface + gated cursor machinery (ADR-7 implemented)
- **ADR-7 implemented as countersigned:** `MirageCursor.swift` (typed cursor value + `MirageCursorGate` + `MirageDetailQuery` disabled call-site; pinned codes `CURSOR-MISSING` / `SPOILER-CURSOR-UNVERIFIED` / `SPOILER-PROBE-REJECTED`; preflight refuses EVERY detail request before any compose, unconditionally — engine never contacted), `MirageStatusSurface.swift` (typed inventory decode verbatim from service.py:505-554 keys; status assembly; A.7 transduction rendering; sheet controller), `MirageAppImportMount.swift` (+ `MirageSupportPaths`, `acquireTransportClient`, `identityStore` exposure), `MirageAnalysisSheetView.swift` (+ read-only status section: local map state immediately; engine verification behind the explicit "Check with Mirage" gesture; counts with provenance labels; detail-disabled note always visible).
- **Flow refactor:** `engineVerifiedIdentityState` delegates to a new `engineVerifiedIdentityAndInventory` — ONE read-only `books_list` exchange serves BOTH presence semantics and the counts row (S10-ES-4 pin-1 discipline: a status check serves only `books_list`).
- **Tests:** the four ADR-7-named suites — `MirageCursorContractTests` (4), `MirageSpoilerProbeTests` (3, incl. never-contacted transport tripwire), `MirageStatusSurfaceTests` (10: decode/pin/orphan/unmapped-no-wire/local/transduction/provenance), `MiragePageTurnNonTriggerTests` (4: zero runner calls on init/reads/position, explicit refresh the only aperture, honest cancel copy). Census: **178 passed / 0 failed / 2 skipped** (baseline 157 + 21).
- **Fixture fidelity fix surfaced by the strict decode:** the PR-5 drift fixture's minimal `books_list` rows (`book_id`/`edition_id` only) were NOT real-engine shapes — the real export always carries `units/claims/max_cursor` too (service.py:505-554). Fixture updated to the full pinned row; presence semantics unchanged. Real-engine suite extended with Proof 5 (detail-free status) — still ONE lifecycle, ~2 s, green.
- **Census grep gate (PR-6):** `Features/Reader` carries Mirage references ONLY in `EPUBReaderScreen.swift` (the sheet mount) — page-turn code cannot reach Mirage by construction. `MirageStatusController`'s runner fires only from the explicit refresh gesture.
- Queue now: PR-7 (settings/lifecycle + ADR-6a rename + true ADR-6 feature-lifecycle draft + OPE-001 deletion + one-spawn defect root cause + rehearsals), then PR-8 per ADR-3 bundle direction.

## M-027 — 2026-10-18 · PR-7 executed — settings/lifecycle governance (§11/PR-7 gate) + OPE-001 + machinery-boundary root-cause campaign + §15 rehearsal start
- **Feature governance (ADR-6 canonical seat drafted, ADR-6a resolved):** `MirageSettings.swift` (one switch `mirage.enabled`; default ON — real availability is the engine gate's job; OFF = no engine, no spawn), `MirageSettingsPane` in SettingsRootView (native Toggle = accessibility by construction; availability row: dev-checkout vs "not available on this Mac yet"; disable-deletes-nothing stated verbatim), sheet disabled-state copy (honest card naming Settings ▸ Mirage; starts nothing), flow-level gates (defense in depth). **ADR-6a**: the PR-5 NEW-DE-5 discharge record renamed out of the country seat (git mv) + status corrected to ACCEPTED. ADR-6a/ADR-6 both `documents/integration/adr/`.
- **disable-deletes-nothing VERIFIED:** `MirageFeatureLifecycleTests` (4 green) — default-ON pin; disabled ⇒ runner never fires + no engine status; stratum bytes byte-identical across an enable/disable cycle + side artifact preserved; copy pins (never claims deletion; no removal verbs).
- **Machinery boundary root-cause campaign (M-024's open defect):** 4-rung instrument ladder, ALL CLEAN — (1) bare Foundation-Process double-spawn probe (no RT machinery): banners instant on both spawns; (2) two clean supervisor lifecycles in one test: green; (3) lifecycle 1 carrying a full real-engine import epoch before lifecycle 2: green; (4) the two-test-case shape AND the full-census-tail heavy context (MirageZBootDiagnostic sorts last in the Mirage band): green. **Conclusion: the boundary does not exist under the current production path**; the original permanentDown observation is most plausibly a machine-stress artifact of its night. Standing opt-in regression probe stays: `MirageZBootDiagnosticTests` (needs real engine dir + `MIRAGE_BOOT_DIAGNOSTIC=1`; census shows it as skip nodes). The single-lifecycle doctrine on the real-engine suite is UNCHANGED (its pinned design; not weakened by the finding).
- **OPE-001 EXECUTED (Class Δ countersign, M-025):** 38 stub-hash cover files (<32 B placeholders; the family drifted from the ledgered 48 as more census runs repeated the stub pins) deleted from the app container's `covers/`; the 19 real covers untouched; zero stubs remain; deleted-file list archived as evidence (`OPE-001-deleted-stub-list-2026-10-18.txt`).
- **§15 rehearsals STARTED (S15-ES-3 artifacts, in-repo `docs/integration/rehearsals/rehearsal-log-2026-10-18.md`):** R1 code rollback — PR-6→PR-5 target-state rehearsal EXECUTED LIVE (detached worktree at `0842b2b`, full census TEST SUCCEEDED, 0 failing tests outside iCloud-desktop stamps, artifact recorded); remaining individual rollbacks scheduled per PR close (protocol recorded). R2 crash recovery / R3 failed-init / R4 invalid-mapping — test-anchored with tonight's live census + real-engine receipts. R5 backup-restore discipline VERIFIED FROM SOURCE: Mirage's approved path = `Ledger.backup()` (SQLite online backup API + PRAGMA integrity_check, ledger.py:2235-2252); engine's own content round-trip test re-pinned live (0.021 s OK); system-level disposable-data rehearsal run (integrity ok, schema carried on restore); documented gap: no wire/CLI surface for backup (named-owner gap; RT never hot-copies).
- **ADR-3 drafted on the countersigned direction (bundle with the app):** source-anchored comparative analysis (pure-stdlib embeddable engine; system-python rejected; native crates route parked), PR-8 implementation charter (pinned python-build-standalone runtime + verbatim engine tree + signed bundle layout, locator ladder replacement, clean-machine gate, CI with owner-toggle prerequisite). `docs/integration/adr/ADR-3-packaged-runtime-distribution.md`.
- **Census (default, standing):** **182 passed / 0 failed / 4 skipped** (PR-6 baseline 178 + 4 lifecycle tests; skips = the two opt-in suites' gates incl. the new diagnostic suite). Opt-in-engaged run earlier: 186/0/0.
- Queue: PR-8 (bundle staging per ADR-3 + signing/codesign + clean-machine script + CI workflow (+owner Actions toggle) + runtime-swap rehearsal) → §15 ladder continuation → §19 evidence assembly → §20 item 12 (repo-consolidation decision record).

## M-028 — 2026-10-18 · PR-8 executed — packaged runtime (ADR-3 implemented: locator ladder + staging + clean-machine + CI) 
- **THE BUNDLE WORKS — proven live:** `scripts/stage-mirage-runtime.sh` ran end-to-end — pinned python-build-standalone fetch (sha256 `5a9cdbb8536839a83edae3e41eb44161b640d78181fec083e07c668ba796a875` now the script's refusal pin), interpreter 3.12.7, engine tree VERBATIM at pinned SHA `81422613610701d81956394d9601bcb61e2938e9`, 47 MB bundle + `RUNTIME-MANIFEST.json` (checksums recorded). Spawn smoke FROM the bundle, self-hosted with the bundle's own `bin/python3.12`: banner `ready`, `version` + `books_list` exchanged, clean SIGTERM (`exit -15`). Fixture-fidelity: the bundle reproduces the engine's OWN src layout so the pinned sidecar bootstrap (`<script>/../src`) works UNMUTATED (byte-verbatim copy discipline).
- **Swift locator ladder:** `MirageRuntimeLocator.swift` — bundled channel (layout + strict manifest decode + SHA-256 spot-checks of `bin/python3.12` and the sidecar; tree digest = staging-side truth, documented), dev channel (PR-5 gate verbatim), else nil; `MirageAnalyzeSession(engineCheckout:interpreterURL:)` gains the interpreter parameter (nil = locator fallback, dev unchanged); sheet + status controller + Settings pane wired to the ladder; pane availability row now names the channel (bundled / development checkout / not available).
- **Tests:** `MirageBundledRuntimeTests` (9 green) — strict manifest decode incl. wrong-typed keys refused; sha round-trip; bundled resolves when bindings verify; tampered digest / missing manifest / missing interpreter REFUSED (fail closed); ladder: verified bundle wins, unverifiable bundle falls to dev, neither = nothing. Census: **191 passed / 0 failed / 4 skipped** (default standing).
- **Clean-machine gate:** `scripts/verify-clean-machine.sh` (stage → self-hosted smoke via `scripts/bundle_smoke.py` → full default census; refuses on any stage; disposable ledgers only — the real ledger untouched). CI: `.github/workflows/census.yml` (macOS runner, default census + receipt artifact; OWNER TOGGLE: enabling Actions on the repo is the one machine-side prerequisite, recorded as inert-until-toggled elsewhere too — ADR-3).
- **§15 R6 rehearsals:** staging + spawn smoke = live receipts (in-repo rehearsal log updated); runtime-swap procedure recorded (atomic dir replacement → re-smoke → census → mv-back); app-embed step exercised at first CI run or operator stage-into-app (explicit honest gap, owner toggle pending).
- Queue: owner review round (ADR-6 ratification + ADR-3 implementation acceptance + push authorization) → §15 ladder continuation (R1 rollbacks per PR + S15-ES-4 handoff bundle final) → §19 evidence assembly + §18 final acceptance → §22 Titanium Bridge era begins (ADR-12 charter is the first §22 document).

## M-029 — 2026-10-18 · §18 final acceptance + §19 evidence bundle + §15.4 operational handoff (ladder-complete tail) 
- **§18 final acceptance checklist filled with receipts:** `docs/integration/final-acceptance-2026-10-18.md` — every product/architecture, data-safety, stability/testing, security/release, and governance row carries its one-pointer receipt (ADR set, census standings, wire conformance, spoiler contract, OPE-001 deletion artifact, per-PR rehearsal rows). Five LEDGERED honest deltas, none acceptance-blocking: (1) app-embed of the staged runtime awaits the owner Actions toggle / operator stage-into-app; (2) R1's remaining three rollbacks (procedure recorded, scheduled per PR close); (3) the backup wire-exposure gap (named owner, engine-side duty meanwhile); (4) the dedicated Mirage perf-budget report (§20-next; no regression receipts known); (5) large-library soak beyond fixtures.
- **§19 evidence bundle assembled:** `docs/integration/evidence/README.md` — all eleven §19 items mapped to in-repo evidence (ADRs, protocol extraction, pinned SHAs, per-PR census receipts, real-engine proofs + boot-diagnostic ladder, perf notes, security posture, packaging receipts, known-issue list, rehearsal record, the §18 checklist). **User-data policy verified synthetically:** no user library content anywhere in the bundle; the only deletion artifact is OPE-001's list-of-deleted-STUB-file-names.
- **§15.4 operational handoff bundle drafted:** `docs/integration/evidence/handoff-bundle-2026-10-18.md` — path-anchored operator answers with honest verification status per row: pid file + census, handshake version triple (`api_version`/`schema_version`/`db`/`status`), ledger location + write-ownership discipline, the verified-state-of-source backup path (`Ledger.backup()`, wire gap named), feature toggle + failure states (mapUnreadable fail-closed, typed EOF → fresh epoch), packaged-runtime manifest paths + swap procedure + clean-machine gate.
- Census standing unchanged at commit time: **191/0/4** (docs-only tail commit; no code touched).

## M-030 — 2026-10-18 · §22 era opens on paper — ADR-12 TiB charter + TB-M0 gate plan (both DRAFT, countersign pending; non-execution charter honored) 
- **ADR-12 drafted:** `docs/integration/adr/ADR-12-titanium-bridge-charter.md` — adopts the §22 charter (the 4:00→4:01 PM promise, two rings, SLO/hops/tortures/retention BY REFERENCE to §22.0–§22.19 — no amendments), generation-model inviolability (old-or-new, never a third thing), the subset manifest SEEDED from tonight's PR-8 bundle layout, owner key custody, fail-closed refusals, and explicit per-milestone gate signatures — nothing executes until the owner countersigns ADR-12 and each milestone gate (§21.0 binds §22). Declined-countersign path recorded: the merge stands either way; §22 stays ESCALATED-DESIGN.
- **TB-M0 gate plan drafted:** `docs/integration/tib/TB-M0-gate-plan.md` — observe-mode only (manifest + full verify + daily drift sensor + 7-day observation ledger; NO swap machinery built); exit bar verbatim from §22.19.1 (7 consecutive ledger days, 0 false-green verifies, an archived tamper-drill receipt proving the red side); the PR-8 manifest + locator spot-checks named as the seeds that already exist and are verified.
- **Honest status:** zero TB instruments were built or executed tonight — the §21.0 non-execution charter forbids it pre-countersignature; both docs are decisions/plans only. The 'TiB era' in the session summary therefore means: founding documents drafted, era execution awaits owner signatures.

## M-031 — 2026-10-18 · §17 register completed — ADR-8 repository strategy (the last informal assumption recorded)
- **ADR-8 drafted:** `docs/integration/adr/ADR-8-repository-strategy.md` — §17.1's Register seat, recording the strategy the entire ladder embodied de facto: two canonical repositories (Mirage upstream-canonical, pinned by SHA; RT canonical for the app), RT's copy a VERIFIED VENDOR (byte-verbatim at copy time, digest-re-verifiable via RUNTIME-MANIFEST bindings + staging-script refusal pins, re-pinned at PR time until ADR-12's TiB gates take over), monorepo/submodule/consolidation alternatives REJECTED with reasons (consolidation = its own future owner ADR per §16's separate-decision rule). Countersign joins the closing owner round (ADR-6 ratification + ADR-3 acceptance + push authorization + CI toggle).
- §18 final-acceptance repository-governance rows and the §19 evidence-bundle ADR list updated to name ADR-8. Census stands (docs-only).

## M-032 — 2026-10-18 · Closing owner round — four signatures executed; TB-M0 opens with its first receipts 
- **Owner round results (2026-10-18, session close):** (1) ADR-6 RATIFIED as written; (2) ADR-3 implementation ACCEPTED (app-embed delta named in the ADR's status block); (3) ADR-8 + ADR-12 COUNTERSIGNED both — ADR-8's two-canonical-repositories/verified-vendor strategy is now the owner's recorded decision; ADR-12 adopts the TiB charter with "the era opens at TB-M0" (opening ≠ exit: each milestone's EXIT gate still signs against evidence per decision 6); (4) PUSH authorized + Actions toggle committed-to by the owner (repo-side UI action; machine push executed below).
- **TB-M0 OPENED (first authorizing signatures → first instruments):** `scripts/tib/observe.py` (std-lib verify instrument; the staging pipeline's tree-digest command reproduced VERBATIM as a subprocess so xargs-split behavior is identical by construction), canonical generation `subset-manifest.gen-0001.json` sealed in-repo from the proven staged bundle, and the append-only `observe-ledger.md` seeded with its day-one receipts: **verify = OBSERVE GREEN** (all three bindings: interpreter fe2572aa…, sidecar dfb19552…, tree b5ca1d35…) and **tamper drill = DRILL OK** (one flipped byte in `bin/python3.12` → digest refusal `498dad45… ≠ fe2572aa…`, sacrificial copy only, no false-green). TB-M0's remaining exit bar: 7 consecutive ledger days (operator-daily; re-staging is idempotent-by-pins so temp reclamation is harmless) — then the owner's exit signature.
- **Push executed per authorization:** `merge/integration` → origin (`0842b2b` → `c487986`, 6 commits). CI (`census.yml`) live once the owner enables Actions.

## M-033 — 2026-10-18 · Branch consolidation — single-branch protocol adopted (owner instruction); main carries the whole ladder 
- **Owner instruction:** one branch, main, up to date. The ladder-branch protocol (accumulate on `merge/integration`, main frozen as the review surface) had served its terrace purpose through the 8-PR ladder and owner round; the owner now elected single-branch continuity.
- **Executed:** verified `merge-base = main` tip (`0842b2b`) ⇒ pure fast-forward, no history rewrite, zero orphaned commits, no open PRs; checkout carried the 8 owner-dirty working files over byte-unharmed (confirmed identical committed blobs between branches BEFORE the move); `main` fast-forwarded `0842b2b → 82598e5` (37 files, 3,211 insertions — the entire PR-6…§22 record), pushed, then `merge/integration` retired BOTH remote (`(deleted)`) and local (`was 82598e5` = now main's own tip). One branch remains on GitHub: `main`.
- **Effect:** all future campaign work continues directly on `main`. The CI workflow's `push: branches: [main, merge/integration]` trigger now fires on main pushes — the M-033 docs push, and every future push, is a census-trigger point (receipt appears once the owner's Actions toggle is on).

## M-034 — 2026-10-18 · Archive migration — the Merge Phase folder's unique masters reland in main; folder retirement made safe (owner-decision item recorded) 
- **Inventory verdict across the folder's contents:** merge-log master + rehearsal-log master + PR4/PR5 plan masters all have canonical committed twins in main (rehearsal master was STALE — the repo copy is newer by tonight's R6); the two bare mirror clones (backups/{rt-main,mirage-main}.git — mirror:true clones OF THE DESKTOP REPOS' refs at ~15:00, pre-ladder) are redundant insurance since no history was ever rewritten (all their objects also live in the working repos; RT additionally on GitHub); the BUG-001 repro .xcresult (~110 MB of the folder's 146 MB) is externalized evidence of a FIXED defect — keep-or-retire is the owner's call, and its companion LogStoreManifest.plist was migrated so the receipt's metadata survives either decision.
- **Migrated into main:** `docs/integration/RT_Mirage_Codebase_Merge_Playbook.md` (the playbook itself — previously EXISTED NOWHERE ELSE, and it remains the governing document of the §22/TiB era), `docs/integration/Twin-READMES-2026-10-18.md` (README authoring record, no twin), `docs/integration/evidence/BUG-001-LogStoreManifest-2026-10-18.plist` (BUG-001 receipt metadata).
- **After this commit:** deleting `/Users/johanrembeci/Desktop/Merge Phase` loses NOTHING unique except the xcresult bulk (owner's call; a notarized retirement row follows if it goes).

## M-035 — 2026-10-19 · Post-merge documentation refresh — the whole MD estate updated; graphify regenerated; campaign folder retired by the owner 
- **Owner executed the folder deletion** (`/Users/johanrembeci/Desktop/Merge Phase` gone; playbook + merge-log kept by the owner as root snapshots). The BUG-001 repro `.xcresult` (104 MB) retirement is hereby receipted: its metadata already survives at `docs/integration/evidence/BUG-001-LogStoreManifest-2026-10-18.plist`; the PR4-analysis citation remains accurate as a historical pointer. The owner's kept copies were verified (playbook byte-identical to the tracked canon; merge-log = the pre-refinement master, tracked copy holds the legacy-fix refinements) and `.gitignore`d at root as FROZEN snapshots — from this row forward, **the tracked copy `docs/integration/merge-log.md` IS the master**; appends land only here.
- **The MD estate refreshed (all on main):** README.md (full rewrite — Mirage in the TL;DR/§1/§2/§3.5, fresh counts: 114 files · 42,569 LOC · 34 test files · 192 @Test · census 191/0/4, doc map carries docs/integration/, build section carries the mirage opt-in env + the DerivedData rule); 01-project-tree.md (Mirage feature group, integration chapter table, root-snapshot note); 07-testing-strategy.md (full rewrite to current practice — census discipline, house conventions, the 8-band Mirage taxonomy + opt-in engagement); 02-defect-register.md (refresh note + ID-space disambiguation — audit NEW-DE vs merge NEW-DE are DIFFERENT ledgers — + integration cross-reference block incl. the xcresult retirement); 03-fix-log.md (Stage M: the whole merge era recorded by reference, no duplication); 04-handoff.md (full rewrite: post-merge seven answers, next-session order starts at TB-M0 cadence); 05-remediation-roadmap.md (era note + parallel-track statuses — RSVP SHIPPED P5-B2, Mirage campaign closed); 06-rsvp-feature-plan.md (SHIPPED status header; preserved as the design record).
- **Graphify regenerated in-repo** (`graphify-out/`, deliverables now tracked, ephemera ignored): corpus 197 files / ~293k words (158 code + 39 docs); AST pass 4,122 nodes / 11,773 edges; semantic pass 2 chunks / 278 nodes / 478 edges (37 docs cached); final graph **3,953 nodes / 10,769 edges / 178 communities** (post-build), graph.html + GRAPH_REPORT.md + manifest + cost tracker committed. **Honest health note:** 18 dangling-endpoint edges (semantic-chunk IDs without AST counterparts — chunk references to code symbols the AST pass doesn't name identically); collapsed-edge counts (1,424/1,462) are the benign MultiDiGraph→Graph aggregation.
- **CI:** this push is the next census trigger once the owner's Actions toggle lands.
