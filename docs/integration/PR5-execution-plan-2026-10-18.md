# PR-5 Execution Plan — Identity Map + One-Book Import (drafted 2026-10-18 evening)

## 0. Gate contract + pre-decided locks (nothing below may be silently renegotiated)

**S16-ES-1 gate (verbatim):** *PR-5 (identity + one-book import): explicit user-driven flow; mapping in its own stratum; RT persistence schema untouched; duplicate/changed/ambiguous/missing-file/cancel/crash cases pinned.*

Pre-decided by owner-accepted instruments:

| Lock | Source | Effect on PR-5 |
|---|---|---|
| Stratum file `…/ReadTracker/mirage/identity-map.json`, schema `mirage-identity-map@1`, written ONLY by the RT-side Mirage feature module (never engine / PersistenceWriter / DataStore / Sentinel), temp+rename atomic writes | ADR-5 Decision 1 (committed at PR-2) | Runtime file + tests pre-specified |
| Entry contract `{rtBookID: UUID, mirageBookID: String, mirageEditionID: String, sourceFingerprint: sha256-hex, sourceResumeHint: String?, createdAt, updatedAt, status: active|orphaned}`; one `active` per `rtBookID`; orphans carry reason | ADR-5 Decision 2 | Codable types pinned verbatim |
| Entry creation ONLY via confirmed user flow whose receipt is the engine's hash-verified `import_epub` result (`reused:true` or fresh `imported`) — no local-only hashing shortcut | ADR-5 Decision 3 | No mapping source other than the wire receipt |
| Drift rule: RT recomputes byte-hash vs `sourceFingerprint` → typed `identityDrift` refusal + `orphaned(source-changed)` + explicit re-import offer | ADR-5 Decision 4 | Read-path check + state machine |
| Missing edition: engine `not_found` (404) → `orphaned(edition-gone)`; no auto-cleanup/repair | ADR-5 Decision 5 | Read-path check |
| `degraded_import` receipt is REJECTED as mapping input (UI: source needs repair) | ADR-5 Decision 6 | Receipt validator |
| No title/author-based lookups anywhere; unmapped ⇒ `notImported` state, never suggestions | ADR-5 Decision 7 | UI doctrine |
| Unknown schema/malformed map file ⇒ feature degrades to disabled (`mapping-unreadable`), never guesses | ADR-5 Decision 8 | Fail-closed loader |
| Cursor/read-state transduction **NOT in PR-5** — S10-ES-3 sub-document + ADR-7 gate PR-6 | ADR-5 Decision 9 | Scope fence |
| RT never *infers* `mirageEditionID` (wire `import_epub`/`list_editions` only; RT's canonical action set has no `list_editions`, so `import_epub` is the sole creation route) — violation is `ID-SYNTH-9001`; receipt = `{mirageBookID, mirageEditionID, fingerprint, units_count?, warnings[]}` | Playbook §21 impossibility rule + W3 | Wire pin |
| Pre-flight before any `import_epub`: (a) user gesture recorded; (b) security-scoped bookmark resolved + sandbox file access verified; (c) file exists w/ stable stat (size+mtime pre/post compare); (d) UI declares "what will be created in Mirage's ledger" before dispatch; (e) cancel affordance live until Mirage's committed point; post-commit = new-state disclosure, never a rollback claim | S10-ES-1 | Orchestrator checklist + test IDs |
| Ledger path `…/ReadTracker/mirage/mirage.sqlite3`; `mirage/` dir exclusive write territory (identity-map.json lives there under the ADR-5 ownership carve-out); ledger content never replicated into RT UI beyond typed read-only queries | ADR-4 Decisions 1-3 | Directory bootstrap |

**Out of scope (deny-list):** bulk import, series ops, background automation, corrections, spoiler-cursor surfaces, RT schema movement, HTTP, migration.

## 1. Runtime file plan (feature-module only; RT store untouched)

| File | Duty |
|---|---|
| `MirageIdentityMap.swift` | Load/store stratum: schema pin + entry Codables; `one-active-per-book` invariant; atomic temp+rename writes; fail-safe degrade (`mapping-unreadable`) on unknown schema/malformed entries; orphan transitions with reasons |
| `MirageImportFlow.swift` | Orchestrator: idle → source-selection (security-scoped bookmark) → S10-ES-1 pre-flight (a)–(e) → supervisor acquire → dispatch `import_epub` → validate receipt (W3 keys + `degraded_import` rejection + `reused/imported` classification) → persist active entry → disclose new state; cancel per (e); crash-safe (map written once, atomically, after receipt) |
| Views (minimal) | Per-book explicit affordance + status badge: `notImported` / `importing` / `linked` / `orphaned(source-changed|edition-gone)` / `identityDrift` / feature `mapping-unreadable`. Placement quiz → owner (Q1 below); final polish belongs to PR-7 |

## 2. Wire interaction — the one unpinned fact to extract FIRST

PR-3 pinned action *names* and generic envelope shapes; PR-4 pinned transport. The exact `import_epub` **payload** schema (path vs bytes; optionality of `units_count`/`warnings`) must come from MirageV1.0 source, not be invented from RT convenience:

1. Read MirageV1.0 sidecar dispatch table (`service.py`) + import path + `readers/adapters.py` unit_indexes note
2. Record the contract in the merge log (M-022) with file:line anchors — envelope schema then pinned into `MirageWireTypes.swift` docs and covered by a conformance-row extension if it changes pins
3. Optional evidence booster: OPE-004 real-engine smoke (owner-gated, disposable DB) exercised against the import path before runtime work

## 3. Pinned-case matrix (the gate's seven)

| Case | Expected (fail-closed) |
|---|---|
| duplicate (same EPUB re-import) | engine `reused:true` → identical `mirageEditionID`, still exactly one `active` entry |
| changed (EPUB bytes change) | next use → `identityDrift`, request refused, entry `orphaned(source-changed)`, re-import offer |
| ambiguous | cancel/no default selection anywhere; no implicit mapping creates (S18-ES-2 row; `ID-AMBIG-5002` spirit) |
| missing-file | source gone between pick and dispatch → pre-flight (c) typed failure before any engine dispatch |
| cancel | map file byte-identical after cancel; ledger may hold the engine's edition → disclosed (never claimed rolled back) |
| crash | atomicity under interrupt injection: file is old-or-new, never half-written (ADR-5 test) |
| RT-schema floor | grep census: zero `DataStore`/`PersistenceWriter`/`Sentinel` imports in Mirage feature files; zero new RT store keys |

Named suites (ADR-5 pre-committed): `MirageIdentityMapContractTests` (schema pin; one-active invariant; temp+rename atomicity) + `MirageIdentityDriftTests` (byte-change, deleted-file, degraded_import, restoreState invariance). Flow pins live inside these suites (fake transport doctrine — no sidecar spawns in unit tests). Suites `.serialized`; builds on default DerivedData; real-engine contact stays env-gated.

## 4. Sequencing (next session, in order)

1. M-022: extract import contract from MirageV1.0 (anchors into merge log) — includes verifying RT's book record retains a source EPUB referent path (if not, flow requires user re-pick; design note applies) — **read-only inspection first**
2. `MirageIdentityMap.swift` + `MirageIdentityMapContractTests` (no wire, no UI)
3. Import flow + `MirageIdentityDriftTests` (fake transport; receipt fixtures from step 1)
4. Minimal UI surface + pre-flight implementations (bookmark/stat/disclosure)
5. Full census → M-023/M-024 → PR-5 commit on `merge/integration` (same staged-file discipline; owner docs untouched)

## 5. Owner questions reserved for the next session (do not decide silently)

- **Q1 (UI entry):** per-book detail page button vs context menu — PR-5 proposes a detail-view button + badge; PR-7 does placement polish + enable/disable semantics.
- **Q2 (EPUB referent):** confirm RT keeps a resolvable source path per book (RT store read-only check in step 1 decides whether re-pick is required).
- **Q3 (copy):** post-commit disclosure wording for cancel-after-commit (S10-ES-1(e)) — owner-approvable text at PR-5 UI time.

— End of plan.