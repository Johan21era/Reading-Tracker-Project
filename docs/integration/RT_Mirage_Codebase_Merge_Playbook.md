<a id="top"></a>

# Reading Tracker + Mirage — Safe Codebase Integration Playbook

**Document type:** Engineering execution plan, architecture decision framework, migration runbook, and acceptance checklist  
**Primary application:** Reading Tracker (RT), native macOS Swift/SwiftUI  
**Integrated capability:** MirageV1.0, local-first literary intelligence engine  
**Status:** Draft for engineering review; source-code verification is mandatory before implementation  
**Source basis:** `Twin READMES.md`, containing the supplied Reading Tracker and MirageV1.0 README material  
**Purpose:** Integrate Mirage as an optional feature consumed by RT while preserving RT as the parent application and preserving Mirage's domain guarantees  
**Important limitation:** The source provided for this task is a combined README, not the two full source repositories or all internal documents referenced by those READMEs.

> **Path rule.** References to MirageV1.0's own docs and scripts are plain text in this document; backticked paths are claims about this repository.

---

<a id="nav"></a>

# 🧭 Navigation Hub — read this first

> **What this is:** the governing playbook for integrating MirageV1.0 into Reading Tracker as an optional, isolated feature — plus a §21 technical-escalation layer and reference appendices.
> **How to treat it:** an engineering specification, **not a script**. No command in this document is authorized for execution by an automated agent or AI session — see the [Non-execution charter (§21.0)](#sec-21-0). Every command is a *candidate procedure* requiring a human operator, a recorded environment, and an approved branch.
> **Version:** v1.3 (2026-10-18) — original playbook → §21 escalation addendum → navigation & reference pass → §22 Titanium Bridge. Full history: [Appendix G](#app-g).

<a id="nav-map"></a>

## Document map

| Block | Sections | One-line summary | Open here when… |
|---|---|---|---|
| **Charter & contracts** | [§0](#sec-0) [§1](#sec-1) [§2](#sec-2) | Parent/child product hierarchy, hard non-goals, evidence rules, architecture & protocol contract | scoping work; reviewing architecture; drafting an ADR |
| **Data & identity** | [§3](#sec-3) | Ownership strata, identity mapping, cursor/spoiler adapter semantics | touching data, imports, or reading position |
| **Repos & governance** | [§4](#sec-4) [§5](#sec-5) | Git-safety risk classes, repo strategy, owners, scope contract, stop conditions | before **any** Git operation or scope decision |
| **Phase execution** | [§6](#sec-6)–[§11](#sec-11) | Baselines → discovery → defect isolation → boundary → adapter → feature | executing the merge, phase by phase |
| **Hardening & release** | [§12](#sec-12)–[§15](#sec-15) | Security/privacy, testing calculus, packaging, rollback & recovery | releasing anything |
| **Delivery & acceptance** | [§16](#sec-16)–[§20](#sec-20) | PR ladder, ADR register, acceptance checklist, evidence bundle, next actions | reviewing PRs; signing gates |
| **Escalation layer** | [§21](#sec-21) | Every §0–§20 topic re-derived at ≥21× technical density (`S#-ES-#` blocks) | implementing; writing tests/ADRs; deep dives |
| **Titanium Bridge** | [§22](#sec-22) | Continuous-convergence subsystem: any Mirage change lands in RT's vendored runtime within 60 s — same bytes, same behavior, same performance profile (`TB-*` codes) | runtime sync; hot-swap; parity proofs; bridge ops |
| **Reference** | [App. A](#app-a)–[App. G](#app-g) | Commands, open questions, invariants, audit method, **glossary**, **quick reference**, **revision log** | looking anything up |

<a id="nav-roles"></a>

## Reading paths by role

| Role | Path (in reading order) |
|---|---|
| **New engineer, day 1** | this hub → [§0](#sec-0) → [Glossary](#app-e) → [§5.2 Scope](#sec-5-2) → [§13.3 E2E catalog](#sec-13-3) |
| **RT owner** | [§0](#sec-0) · [§1.1](#sec-1-1) · [§3.1](#sec-3-1) · [§5.1](#sec-5-1) · [§8](#sec-8) · [§14.3](#sec-14-3) · [§18](#sec-18) |
| **Mirage owner** | [§0](#sec-0) · [§1.2](#sec-1-2) · [§2.3](#sec-2-3) · [§2.4](#sec-2-4) · [§3.4](#sec-3-4) · [§3.6](#sec-3-6) · [§12.1](#sec-12-1) · [§17](#sec-17) |
| **Integration lead** | [§0](#sec-0) · [§2](#sec-2) · [§5](#sec-5) · [§6](#sec-6) · [§7](#sec-7) · [§9](#sec-9) · [§16](#sec-16) · [§20](#sec-20) |
| **Test / quality owner** | [§6.5](#sec-6-5) · [§9.5](#sec-9-5) · [§10.5](#sec-10-5) · [§13](#sec-13) · [§18](#sec-18) |
| **Security / privacy reviewer** | [§2.3](#sec-2-3) · [§9.2](#sec-9-2) · [§9.3](#sec-9-3) · [§12](#sec-12) · [§14.3](#sec-14-3) · [§14.4](#sec-14-4) · [App. C](#app-c) |
| **Release / operations owner** | [§4](#sec-4) · [§14](#sec-14) · [§15](#sec-15) · [§18](#sec-18) · [§19](#sec-19) |

<a id="nav-toc"></a>

## Table of contents

**Part I — Charter & contracts**

1. [§0 Executive directive](#sec-0) — hierarchy, non-goals, required outcome · [0.1](#sec-0-1) · [0.2](#sec-0-2)
2. [§1 Source-derived baseline & confidence rules](#sec-1) — [RT baseline](#sec-1-1) · [Mirage baseline](#sec-1-2) · [evidence labels](#sec-1-3)
3. [§2 Product & architecture contract](#sec-2) — [parent/child](#sec-2-1) · [component layout](#sec-2-2) · [transport](#sec-2-3) · [protocol](#sec-2-4) · [feature behavior](#sec-2-5)

**Part II — Data, repositories, governance**

4. [§3 Data ownership, identity, synchronization](#sec-3) — [truth domains](#sec-3-1) · [identity mapping](#sec-3-2) · [import](#sec-3-3) · [cursor](#sec-3-4) · [series](#sec-3-5) · [corrections](#sec-3-6)
5. [§4 Repository strategy & GitHub safety](#sec-4) — [inventory](#sec-4-2) · [safe Git procedure](#sec-4-3) · [consolidation](#sec-4-4)
6. [§5 Phase 0 — Governance, scope, stop conditions](#sec-5) — [owners](#sec-5-1) · [scope](#sec-5-2) · [stop conditions](#sec-5-3)

**Part III — Phase execution**

7. [§6 Phase 1 — Baselines](#sec-6) — [RT commands](#sec-6-2) · [Mirage commands](#sec-6-3) · [normative docs](#sec-6-4) · [exit gate](#sec-6-5)
8. [§7 Phase 2 — Discovery & contract extraction](#sec-7) — [interface inventory](#sec-7-2)
9. [§8 Phase 3 — Pre-existing RT risks](#sec-8)
10. [§9 Phase 4 — Integration boundary](#sec-9) — [lifecycle](#sec-9-2) · [validation](#sec-9-3) · [boundary tests](#sec-9-5)
11. [§10 Phase 5 — Book/edition & cursor adapter](#sec-10) — [cursor contract](#sec-10-3) · [sync timing](#sec-10-4)
12. [§11 Phase 6 — Optional RT feature](#sec-11) — [entry point](#sec-11-1) · [query UX](#sec-11-2) · [data controls](#sec-11-4)

**Part IV — Hardening & release**

13. [§12 Phase 7 — Security, privacy, local-first](#sec-12)
14. [§13 Phase 8 — Testing & quality gates](#sec-13) — [E2E catalog](#sec-13-3) · [failure injection](#sec-13-4) · [budgets](#sec-13-6)
15. [§14 Phase 9 — Packaging & release engineering](#sec-14) — [signing/entitlements](#sec-14-3) · [CI](#sec-14-4) · [release gate](#sec-14-5)
16. [§15 Phase 10 — Rollback, recovery, handoff](#sec-15)

**Part V — Delivery & acceptance**

17. [§16 PR plan](#sec-16) · 18. [§17 ADR register](#sec-17) · 19. [§18 Final acceptance](#sec-18) · 20. [§19 Evidence bundle](#sec-19) · 21. [§20 Immediate next actions](#sec-20)

**Part VI — Technical escalation addendum**

22. [§21 addendum](#sec-21) — [21.0 charter & non-execution](#sec-21-0) · [21.1 §0](#sec-21-1) · [21.2 §1](#sec-21-2) · [21.3 §2](#sec-21-3) · [21.4 §3](#sec-21-4) · [21.5 §4](#sec-21-5) · [21.6 §5](#sec-21-6) · [21.7 §6](#sec-21-7) · [21.8 §7](#sec-21-8) · [21.9 §8](#sec-21-9) · [21.10 §9](#sec-21-10) · [21.11 §10](#sec-21-11) · [21.11b §11](#sec-21-11b) · [21.12 §12](#sec-21-12) · [21.13 §13](#sec-21-13) · [21.14 §14](#sec-21-14) · [21.15 §15](#sec-21-15) · [21.16 §16](#sec-21-16) · [21.17 §17](#sec-21-17) · [21.18 §18](#sec-21-18) · [21.19 §19](#sec-21-19) · [21.20 §20 + App. A–D](#sec-21-20) · [21.21 footer](#sec-21-21)

24. [§22 Titanium Bridge](#sec-22) — [22.0 contract & SLO](#sec-22-0) · [22.1 generations](#sec-22-1) · [22.2 rings & direction](#sec-22-2) · [22.3 manifest & transport](#sec-22-3) · [22.4 classifier](#sec-22-4) · [22.5 60-s pipeline](#sec-22-5) · [22.6 atomic swap](#sec-22-6) · [22.7 revival & quiesce](#sec-22-7) · [22.8 performance parity (PPC)](#sec-22-8) · [22.9 migrations](#sec-22-9) · [22.10 bridge ledger](#sec-22-10) · [22.11 failure registry](#sec-22-11) · [22.12 anti-tamper](#sec-22-12) · [22.13 threat model](#sec-22-13) · [22.14 storms & skew](#sec-22-14) · [22.15 human controls](#sec-22-15) · [22.16 ADR-12 & governance](#sec-22-16) · [22.17 interop matrix](#sec-22-17) · [22.18 formal model](#sec-22-18) · [22.19 milestones](#sec-22-19) · [22.20 parked branches](#sec-22-20)

**Part VII — Reference appendices**

23. [App. A Commands](#app-a) · [App. B Open questions](#app-b) · [App. C Safety invariants](#app-c) · [App. D Multi-pass audit](#app-d) · [App. E Glossary](#app-e) · [App. F Quick reference](#app-f) · [App. G Revision log](#app-g)

<a id="nav-conventions"></a>

## Conventions & code registries

**Evidence labels (§1.3):** `SOURCE-VERIFIED` · `TEST-VERIFIED` · `README-REPORTED` · `INFERRED` · `DECISION-REQUIRED` · `BLOCKED` — plus **`ESCALATED-DESIGN`** (§21 only): a draft specification awaiting ADR review; **not** a claim of existing behavior.

**Directive strength:** **must / never** = binding gate · **should** = strong default, skipping requires written justification · **may** = discretionary.

| Code family | Meaning | Defined in |
|---|---|---|
| `SC-01…SC-12` | stop conditions | [§21.6 (S5-ES-3)](#sec-21-6) |
| `INT-01…INT-20` | end-to-end integration scenarios | [§21.13 (S13-ES-3)](#sec-21-13) |
| `NEW-DE-1…5` + release blockers | RT's known defects | [§1.1](#sec-1-1) · [§21.2](#sec-21-2) |
| `AU-1…AU-4` | merge fallacies (what "merge" does NOT mean) | [§21.1 (S0-ES-2)](#sec-21-1) |
| `NG-1…NG-12` | contained non-goals with enforcement | [§21.1 (S0-ES-5)](#sec-21-1) |
| `PR-1…PR-8` | pull-request ladder | [§16](#sec-16) |
| `PR- / TC- / TX- / LC- / ID- / CU- / PV- / OP-` | host-side typed error-code families | [§21.10 (S9-ES-5)](#sec-21-10) |
| `TB-*` | Titanium Bridge error codes, typed by pipeline hop (detect/fetch/verify/assembly/preswap/quiesce/swap/revive/smoke/parity/drift/GC/pin/ledger) | [§22.11](#sec-22-11) |
| Class `Ω / Δ / Π` | Git operation risk classes | [§21.5 (S4-ES-3)](#sec-21-5) |
| `ADR-1…ADR-11` | integration decision slots | [§17](#sec-17) · [§21.17](#sec-21-17) |
| `S#-ES-#` | escalation block for playbook §# | [§21](#sec-21) |

**Navigation:** every `##` section and `###` subsection has an explicit anchor (`#sec-<n>`, `#sec-<n>-<m>`, `#app-<x>`); `[⤴ back to top](#top)` follows each major section. Note: the SHA-256 footers in [Appendix D](#app-d) authenticate the **original 1,171-line body only** — they predate §21 and this navigation pass ([Appendix G](#app-g)).

---

<a id="sec-0"></a>

## 0. Executive directive

[⤴ back to top](#top)

Reading Tracker is the parent application. Mirage is an optional literary-intelligence capability available from within Reading Tracker. The merge must preserve that product relationship in architecture, user experience, data ownership, build/release processes, and repository governance.

Do not interpret “merge” as permission to combine every file, unify every data store, rewrite both applications, remove either command-line interface, or delete either GitHub repository. The desired outcome is a reliable integration, not maximal file movement. Repository consolidation may eventually be appropriate, but it is a separate decision from runtime architecture and must not dictate unsafe code or data coupling.

RT remains the owner of the macOS app lifecycle, app navigation, reading library, reading sessions, RT analytics, goals, achievements, covers, and existing RT persistence. Mirage remains the owner of literary analysis, its evidence ledger, claim history, graph projection, provenance, uncertainty, identity resolution, corrections overlay, and cursor-based spoiler eligibility. RT may invoke Mirage, present its results, and provide carefully defined reading-context inputs; RT must not silently become the source of truth for Mirage's internal claims.

**Release principle:** preserve existing RT behavior first; establish an isolated integration boundary second; enable Mirage behind an explicit feature entry point third; expand only after the boundary is verified. A green test suite for either project alone is necessary but not sufficient to prove the integrated product safe.

<a id="sec-0-1"></a>

### 0.1 Required outcome

A user opens Reading Tracker, uses existing RT functionality as before, and can choose to open a Mirage-powered literary-intelligence experience. When enabled, RT communicates with Mirage through a versioned, validated interface. Mirage answers must obey its spoiler policy, retain provenance and uncertainty, and avoid exposing material beyond the user's explicitly declared reading position. When Mirage is unavailable, disabled, unhealthy, or incompatible, RT must continue to function as a reading tracker and explain the optional feature's status without corrupting the user's library or blocking normal reading.

<a id="sec-0-2"></a>

### 0.2 Explicit non-goals

Unless a separately approved decision changes scope, this project does **not** authorize:

- Replacing RT's SwiftUI application with Mirage's browser UI, CLI, Python package, or future Tauri/React UI.
- Rewriting RT persistence as part of the Mirage integration.
- Moving RT's `library.json`, `library-state.json`, cover store, weather SQLite database, backup rotation, or Sentinel journal into Mirage's SQLite ledger.
- Treating Mirage's SQLite ledger as authoritative storage for RT goals, sessions, achievements, page-turn timings, or other RT-owned data.
- Replacing Mirage's evidence ledger with RT's JSON persistence.
- Turning every RT book import or page turn into a full Mirage analysis job.
- Automatically linking books into series solely because metadata names overlap.
- Guessing a Mirage cursor from a page number, page-turn count, reading percentage, or title match when the mapping is not proven.
- Automatically accepting uncertain literary claims, merging uncertain identities, or promoting user correction suggestions into book truth.
- Deleting, archiving, renaming, transferring, or making read-only either GitHub repository as a side effect of the code integration.
- Claiming that security, privacy, quality, or performance risks are resolved merely because the README reports green tests.
- Treating a documentation-only audit as proof of implementation behavior.

Every deviation from these non-goals must be documented in an Architecture Decision Record (ADR), reviewed by both system owners, and tested before adoption.

---

<a id="sec-1"></a>

## 1. Source-derived baseline and confidence rules

[⤴ back to top](#top)

This section records what the supplied README states. It is not a substitute for inspecting the actual repositories and their referenced documentation.

<a id="sec-1-1"></a>

### 1.1 Reading Tracker baseline stated in the README

The supplied README describes RT as a macOS application built with Swift and SwiftUI. It reports three targets, a macOS deployment target of 26.5, Swift 5 language mode, MainActor-default isolation through `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, and one pinned third-party dependency, ZIPFoundation 0.9.20.

The README reports approximately 120 Swift files, 39,900 raw application lines of code, 108 `@Test` functions with approximately 160 or more executions under parameterization, and Xcode 27.1 as the toolchain used for its reported build and test results. These are dated README assertions, not independently reproduced results for a future merge branch.

RT's described persistence is layered. The primary library is a debounced, pretty-printed JSON monolith named `library.json`, containing books, sessions, and page-turn timings. A sidecar `library-state.json` stores goals, achievements, and collections. Weather snapshots use keyed SQLite access; covers use a content-addressed file store with NSCache; backups rotate to a depth of ten with hash gating; `.readingarchive` v1 supports export/import; and Sentinel writes an append-only JSONL journal with 500-line rotation. Analytics are described as pure static-namespace engines; `AnalyticsCache` memoizes five whole-library reductions behind a mutation-epoch counter; `PersistenceWriter` owns disk writes on a utility queue; and `DataMaturityEngine` gates intelligence claims behind evidence floors with an injected clock.

The README reports a fresh Debug build and unit-test run succeeding on October 17, 2026. It also reports a test-suitability score of 0.68/1.0, with strong defect-focused test depth but limited coverage of views, reader flows, and network/discovery behavior. Those stated limitations matter because the integration adds user-interface, process-lifecycle, and cross-language behavior that existing unit tests may not cover.

The README identifies unresolved RT issues that must be treated as pre-existing risks, not hidden by integration work:

- **NEW-DE-1:** `PersistenceWriter` gates writes but reportedly does not serialize the full encode/write work, leaving a stale-overwrite window.
- **NEW-DE-2:** Explore/spatial card views reportedly read a legacy embedded-cover field, causing real covers not to appear after migration.
- **NEW-DE-3:** A crash and relaunch within 24 hours can reportedly convert idle time into reading time; the documented Sentinel repair threshold is also described as imperfect.
- **NEW-DE-4:** `AnalyticsCache` reportedly omits a day component from its signature, allowing streak or trend results to go stale across midnight.
- **NEW-DE-5:** Onboarding import reportedly bypasses the import-intelligence facade and duplicate check, and its goal commit may overwrite a full existing goal set.
- **Release blockers:** empty AppIcon set; missing WeatherKit entitlement; mismatch between `ENABLE_USER_SELECTED_FILES=readonly` and the read-write entitlements file; and an empty-string `CFBundleIdentifier` key in a custom plist.
- Other reported issues include row-level weather confidence hardcoded to 1.0, location-denied weather describing New York, non-cancellable RSVP text extraction tasks, dormant code, and insufficient view-flow testing.

The README also says the normalized SQLite core, split `@Observable` stores, Swift 6 strict mode, BCE V3 UI activation, CloudKit, and App Store submission remain incomplete or deliberately deferred. The merge must not silently turn these separate roadmap items into prerequisites unless the team records and approves that scope change.

<a id="sec-1-2"></a>

### 1.2 Mirage baseline stated in the README

The supplied README describes MirageV1.0 as a local-first, spoiler-safe literary knowledge graph, with docs/literary_intelligence_mission_statement.md identified as the normative source of truth. It reports package name `miragev10`, product version 1.0.0, CLI command `mirage`, and ledger schema version `ledger@0.0.10`, with migrations m0001–m0016.

The documented architecture includes typed domain contracts and enums under `src/miragev10/domain/`; a versioned SQLite ledger; append-only claim history; CHECK-constrained vocabularies; crash-safe transactions; standard-library EPUB ingestion with security guards and content-hash unit identity; incremental and idempotent `analyze_edition` processing; heuristic extraction with entity typing, speaker attribution, epistemic status, and a candidate/accepted gate; exact identity resolution; evidence-gated identity merges; cursor-safe spoiler eligibility; graph projection with canonical content hashes; and a D-010 corrections overlay described as audited, append-only, reversible user suggestions that cannot become book truth.

The README lists three embedding surfaces: the Python API (`MirageService`), CLI, and optional sidecar, alongside a unified NDJSON serve/sidecar protocol and a local-only browser UI exposed by `mirage --serve-web`. It also lists a reference Rust core under `crates/mirage-core`, explicitly demoted under ADR-0002. The Rust core must not be assumed to be the production runtime or a required part of the RT integration without source and ADR verification.

Mirage's stated invariants are foundational: the ledger is truth and the graph is a projection; spoiler visibility is deterministic by cursor and source evidence, not plausibility; only one analysis job runs at a time under an 8 GB target budget; extraction is deterministic and classical by default; established facts carry provenance and uncertainty; and normal page turns must not trigger full-book analysis.

The README reports 316 passing Python tests and three passing Rust tests. It also reports a quality/calibration process over adversarial books, a 63-real-book EPUB sweep, an evaluation harness, benchmark harness, torture-MD runner, and cohort calibration harness. These counts and claims must be reproduced against the exact source commit selected for integration rather than copied forward as permanent truth.

<a id="sec-1-3"></a>

### 1.3 Evidence labels required throughout this project

Use these labels in merge issues, ADRs, review notes, and the final handoff:

- **SOURCE-VERIFIED:** directly checked in source code, configuration, tests, or canonical project documentation, with a path and line/symbol reference where practical.
- **TEST-VERIFIED:** demonstrated by a repeatable test or command on a recorded commit and environment.
- **README-REPORTED:** asserted in the supplied README but not independently reproduced during this task.
- **INFERRED:** a plausible architectural conclusion that needs confirmation.
- **DECISION-REQUIRED:** a choice that must be made and recorded by authorized maintainers before implementation.
- **BLOCKED:** cannot be implemented safely until a named dependency, contract, permission, or piece of evidence is supplied.

Do not change a README-reported statement into a source-verified statement merely by repeating it in this playbook. Each verification record must identify the commit SHA, environment, command or inspection method, outcome, and reviewer.

---

<a id="sec-2"></a>

## 2. Product and architecture contract

[⤴ back to top](#top)

<a id="sec-2-1"></a>

### 2.1 Parent-child relationship

RT is the application shell and product owner. Mirage is a capability RT can launch, configure, query, and present. This hierarchy must be visible in implementation, not merely in product language.

RT owns navigation into and out of Mirage, settings for enabling/disabling it, host-side feature status, mapping from RT library items to Mirage editions, and host-specific user prompts. Mirage owns its internal analysis lifecycle, ledger transactions, claim history, graph projection, evidence interpretation, and spoiler eligibility. Neither side should directly mutate the other side's private persistence formats.

The team must define a small integration module in RT—provisionally named `MirageIntegration`—that hides process management, message encoding, protocol validation, identity mapping, and error translation from SwiftUI. This is a proposed name, not a claim that such a module exists. The UI should depend on a host-owned interface, not raw JSON dictionaries, shell commands, process handles, or Mirage database paths.

<a id="sec-2-2"></a>

### 2.2 Proposed logical component layout

The following is conceptual and must be adapted to actual repository conventions. Do not create every directory mechanically.

```text
Reading Tracker
├── Existing RT application
│   ├── SwiftUI navigation and views
│   ├── RT library / reader / sessions
│   ├── RT analytics, goals, achievements
│   ├── RT persistence and backups
│   └── Existing Sentinel and diagnostics
│
├── Mirage integration boundary (new, host-owned)
│   ├── Feature availability and user settings
│   ├── Process lifecycle manager
│   ├── Versioned NDJSON client / transport adapter
│   ├── Request and response schema validation
│   ├── RT-book ↔ Mirage-edition identity mapping
│   ├── Reading-position / spoiler-cursor adapter
│   ├── Error mapping, timeout, cancellation
│   └── Integration diagnostics and tests
│
└── Mirage runtime (separate logical subsystem)
    ├── Python package and domain contracts
    ├── EPUB ingestion and analysis pipeline
    ├── SQLite ledger and migrations
    ├── Spoiler-safe graph projection and query
    ├── Corrections overlay
    ├── CLI / NDJSON serve interface
    └── Evaluation, benchmark, and regression harnesses
```

This layout describes ownership boundaries, not a mandatory physical monorepo layout. Whether Mirage lives inside the same Git repository is a separate governance decision.

<a id="sec-2-3"></a>

### 2.3 Integration transport: evaluate before choosing

**Leading candidate:** a managed local sidecar process using Mirage's documented NDJSON serve/sidecar boundary, with stdin/stdout or the exact transport defined by docs/embedding.md. RT launches and supervises the process, sends versioned requests, validates responses, and terminates or restarts it under defined lifecycle rules. This is a candidate because the README explicitly describes an NDJSON serve/sidecar protocol and an embedder example; the actual message contract and process semantics still must be read in full.

Do not guess command names, JSON fields, framing rules, or whether a given sidecar mode uses stdin/stdout. Inspect docs/embedding.md, the example sidecar, CLI parser, service implementation, and tests. Record the exact request envelope, response envelope, error envelope, initialization handshake, shutdown behavior, maximum message size, cancellation behavior, and protocol version before writing the Swift client.

Alternatives requiring an explicit ADR:

1. **Direct Python embedding in the macOS process.** This can complicate Python runtime packaging, ABI compatibility, signing/notarization, environment management, and crash isolation. Do not select it just because `MirageService` exists.
2. **Local HTTP/browser UI.** The README describes `mirage --serve-web` at `127.0.0.1:8747`, but RT should not depend on a browser server unless the team approves that UX and verifies authentication, binding, origin, request validation, lifecycle, port conflicts, and shutdown. A local-only service is not automatically safe against every local threat.
3. **CLI invocation per request.** Starting a fresh command for every query may add startup overhead and complicate cancellation/state. Use only if measurement and contract inspection justify it.
4. **Native reimplementation of Mirage logic in Swift.** Do not duplicate extraction, identity, ledger, or spoiler logic in RT. That would create two sources of truth and undermine Mirage's invariants.

The ADR must compare alternatives on packaging complexity, security boundary, latency, reliability, testability, portability, operational burden, and fidelity to Mirage's supported embedding contract. This document does not approve any option by itself.

<a id="sec-2-4"></a>

### 2.4 Protocol rules

The integration protocol must be versioned and documented. It must not rely on the accidental shape of current internal Python objects or human-readable CLI output.

At minimum, define:

- Protocol version and capability negotiation.
- A request identifier for correlation and diagnostics.
- A command/operation name from a closed, documented set.
- Typed input fields and explicit optionality.
- A response envelope with unambiguous success/failure.
- A stable machine-readable error code and safe user-facing explanation.
- Maximum request and response size.
- Character encoding, newline framing, and handling of partial reads/writes.
- Timeout and cancellation semantics.
- Startup handshake and readiness state.
- Shutdown request and forced-termination escalation.
- Version compatibility rules for RT and Mirage.
- Redaction rules for logs and diagnostics.
- Handling of malformed JSON, unknown fields, unsupported protocol versions, duplicate request IDs, and unexpected output on the protocol channel.

If NDJSON is used, one complete JSON value per line is the framing contract only if Mirage's implementation documents that. Standard output must not be polluted by banners, progress bars, debug prints, or tracebacks. Human-oriented diagnostics should use a separate channel, normally standard error, after verifying that the chosen sidecar contract permits it. Swift must tolerate partial pipe reads; one read is not guaranteed to contain a complete line.

Do not silently retry a non-idempotent mutation. Retry rules must be operation-specific. Queries may be retried only after semantics are verified. Mutations need idempotency keys or another verified deduplication mechanism if retry after an ambiguous timeout could apply an operation twice.

<a id="sec-2-5"></a>

### 2.5 Optional feature behavior

Mirage must be optional at runtime and must not be a hard dependency for launching RT, opening the library, reading a book, saving a session, or using ordinary RT analytics.

The UI should distinguish at least: disabled by user; not installed/unavailable; starting; ready; busy/analyzing; request failed; protocol incompatible; data needs attention; and stopping. Choose exact states only after checking actual capabilities and the error model.

When disabled, RT must not spawn Mirage or perform surprise background analysis. When enabled but unavailable, RT should show a contained status and preserve all non-Mirage functionality. When Mirage is busy, RT should remain responsive and allow cancellation where supported. When the process crashes, the host must not crash with it, lose RT data, or loop through unbounded automatic restarts.

The feature should be discoverable through a clear RT navigation entry or book-context action, not a second competing top-level application shell. Exact placement is a product decision to be reviewed in the running app.

---

<a id="sec-3"></a>

## 3. Data ownership, identity, and synchronization

[⤴ back to top](#top)

<a id="sec-3-1"></a>

### 3.1 One system of truth per domain

Do not create a shared universal database simply because both systems store information about books. Similar concepts do not prove equivalent semantics.

RT's `library.json`, `library-state.json`, cover store, weather SQLite data, backups, and Sentinel journal remain RT-owned. Mirage's versioned SQLite ledger remains Mirage-owned. RT must not read/write Mirage tables directly unless Mirage explicitly exposes a supported storage API and an ADR approves that dependency. Mirage must not write RT's JSON files or infer that an RT save has committed merely because a host request was sent.

The first integration should prefer a narrow adapter and explicit mapping over a broad persistence rewrite. RT's normalized SQLite core is a separate planned architectural arc in the supplied README; it must not be combined with this merge by default. The prior RT SQLite engine attempt is described as reverted with a preserved post-mortem, so read that record before proposing another storage migration.

<a id="sec-3-2"></a>

### 3.2 Identity mapping is a first-class subsystem

The README says Mirage uses content-derived identity and distinguishes book/edition identifiers. RT has its own library records. The identifiers must not be assumed interchangeable, even when titles, authors, ISBNs, filenames, or covers match.

Create an explicit mapping record with fields required by the actual models. A conceptual record may include:

- RT's stable book identifier.
- Mirage's book and edition identifiers, separately defined by Mirage's actual contracts.
- A content fingerprint or source identity used for reconciliation, if supported.
- The identity method and evidence used to create the mapping.
- Mapping status: unlinked, proposed, confirmed, stale, ambiguous, or failed.
- Creation/update timestamps and a schema version.
- The reason for any user-confirmed override.
- A safe way to invalidate or rebuild the mapping without deleting canonical records.

These are proposed integration fields, not existing Mirage schema claims. Confirm identifiers and constraints from `src/miragev10/domain/`, ingestion code, migrations, and API contracts before implementation.

Do not link two books automatically on title-only similarity. Use actual content fingerprint and identity rules where available; if a confident mapping cannot be established, ask the user to confirm or leave the item unlinked. A wrong link can contaminate analysis, confuse editions, and apply the wrong spoiler cursor.

<a id="sec-3-3"></a>

### 3.3 Importing a book into Mirage

A user should be able to enable Mirage and import or analyze a supported book through an explicit RT workflow. Inspect Mirage's EPUB ingestion path, supported file types, content hashing, idempotency behavior, and removal semantics first.

The workflow must distinguish these actions:

1. RT knows a book exists in its library.
2. The user authorizes Mirage to process a specific source file.
3. Mirage imports or recognizes the corresponding edition.
4. RT confirms and persists the mapping between the RT book and Mirage identifiers.
5. Mirage analysis is requested explicitly or according to a transparent, user-controlled policy.
6. RT presents progress and result status without claiming completion before Mirage confirms it.

Do not automatically analyze every RT library item at first launch. Do not treat an RT metadata-only record as proof that Mirage has the full EPUB. Do not make destructive removal from Mirage part of an ordinary RT unlink action.

The import flow must handle duplicate files, changed files, missing files, corrupt/malformed EPUBs, unsupported formats, cancellation, insufficient disk space, and process termination. Each outcome must be represented without overwriting unrelated RT goals, sessions, or library data. In particular, RT's README reports an onboarding-import defect where bypassing the import-intelligence facade and duplicate check can overwrite existing goal state; integration work must not reuse or deepen that unsafe path.

<a id="sec-3-4"></a>

### 3.4 Reading position and spoiler cursor

This is the highest-risk semantic boundary. Mirage's spoiler eligibility is described as deterministic and cursor-safe, with dependency closure and fail-closed behavior. RT tracks page-turn timings and reading sessions, but the README does not establish that RT's current position is equivalent to Mirage's cursor units.

The adapter must not convert a page number or percentage into a Mirage unit index without a verified mapping. EPUB reflow, font size, window size, edition differences, and parser normalization can make page numbers unstable. A mapping must be based on source-unit identity or another contract Mirage explicitly recognizes, and must be tested against the exact imported edition.

If RT cannot establish a valid cursor for a request, the integration must fail closed: show only content permitted by Mirage's documented safe default, or refuse the spoiler-sensitive operation with a clear explanation. It must never guess a later cursor to make the UI convenient. A missing cursor is not permission to show the whole book.

The host must define how user reading state maps to Mirage's declared state vocabulary. The README shows declarations such as `read`, `reading@2`, and `unread`; do not assume these examples are the complete grammar. Read the canonical domain contracts and mission statement. A book marked “read” in RT should map to Mirage's “read” state only if user-facing semantics and product policy agree. A book being open in the RT reader is not necessarily equivalent to a verified chapter cursor.

Decide whether Mirage spoiler state follows RT automatically, follows only after user confirmation, or is separately managed in Mirage. Until that decision is approved and tested, the safe default is no automatic advancement beyond the last explicitly confirmed safe cursor. Synchronization must be visible, explainable, reversible where supported, and tested for unread, reading, completed, unknown, stale mapping, edition mismatch, and cursor regression.

<a id="sec-3-5"></a>

### 3.5 Series and cross-book context

Mirage's README explicitly says series detection proposes candidates and the user disposes; shared-name overlaps do not auto-link. Preserve that rule inside RT. Do not infer a series link and silently expose content from later books.

Series creation, edition ordering, reading-state declarations, and pooled breakdowns must use Mirage's supported API/protocol. RT may offer convenient UI, but the adapter must preserve Mirage's validation and confirmation semantics. Any pooled answer must retain per-book attribution and apply each book's individual spoiler eligibility rules.

<a id="sec-3-6"></a>

### 3.6 Corrections and user suggestions

Mirage's D-010 corrections overlay is described as audited, append-only, reversible, and unable to become book truth. RT must present corrections as suggestions or overlay state, not direct edits to source evidence or accepted literary truth.

If RT offers a correction UI, show the scope of the change, affected book/claim, whether the suggestion is pending or accepted under Mirage's rules, and how to undo it when supported. The host must not silently rewrite a correction into the underlying EPUB, ledger history, or RT library metadata.

---

<a id="sec-4"></a>

## 4. Repository strategy and GitHub safety

[⤴ back to top](#top)

<a id="sec-4-1"></a>

### 4.1 Decide runtime integration before repository consolidation

A single repository is not required for RT to consume Mirage. Integration can be developed with two repositories, with one repository containing two independently built components, or with a carefully controlled monorepo. The choice must follow build, ownership, release, and contributor requirements rather than an assumption that “merge” means “delete one repo.”

Recommended default during integration: **keep both original repositories intact and recoverable** while the team prototypes the boundary and validates end-to-end behavior. If a monorepo is later chosen, perform repository migration as a separately reviewed workstream with a documented history-preservation plan.

<a id="sec-4-2"></a>

### 4.2 Repository inventory before any migration

For each repository, record canonical URL, owner/organization, default branch, active branches, tags, releases, latest known-good commit, protected-branch rules, required checks, CODEOWNERS, collaborators/teams, open issues and PRs, GitHub Actions workflows, secrets and variables, environments, deployment targets, package registries, release automation, webhooks, Pages configuration, submodules, Git LFS usage, signed commits/tags, and external systems that reference the repository URL.

Record which items the team can inspect and which require an administrator. Do not copy secret values into the playbook, issues, shell history, test fixtures, or logs. Record secret name/owner/purpose/rotation procedure—not the secret itself.

Inventory ignored files, generated artifacts, large binaries, and data that must not be committed. The READMEs identify `graphify-out/` and `codegraph-out/` as transient/ignored artifacts, but verify actual ignore rules and repository status. Do not add regenerated analysis outputs simply because they exist locally.

<a id="sec-4-3"></a>

### 4.3 Safe Git procedure

Before editing either codebase:

1. Confirm repository URL, branch, current commit, and working-tree status. Stop if uncommitted or untracked changes are unexplained.
2. Create a named integration branch from a recorded base commit. Never develop directly on the protected default branch.
3. Create a recoverable reference to the pre-merge commit and record its SHA in the merge log.
4. Verify that backup/mirror procedures preserve required Git refs, tags, and Git LFS objects. A ZIP of the working tree is not a complete Git-history backup.
5. Verify that the repository can be restored or cloned from the backup before relying on it.
6. Establish required status checks and reviewer approvals before integration PRs begin.
7. Keep commits small enough to review and revert. Each commit should have a narrow purpose, test result, and issue/plan reference.
8. Never force-push a shared branch or rewrite published history without explicit owner approval and a coordinated recovery plan.
9. Never run destructive cleanup, history rewrite, bulk rename, database migration, or repository deletion merely because it appears in a copied script. Review command effects first.
10. Do not commit real user libraries, personal EPUBs, RT runtime data, Mirage production ledgers, secrets, signing material, or unredacted logs.

For every high-risk operation, write down preconditions, expected effects, recovery method, and approver. The operator should be able to stop without leaving the default branch, production data, or teammates' work in an ambiguous state.

<a id="sec-4-4"></a>

### 4.4 If the repositories are eventually consolidated

If the team selects a monorepo, define a target tree and history strategy before moving files. One possible layout is:

```text
repository-root/
├── apps/
│   └── reading-tracker-macos/
├── components/
│   └── mirage-runtime/
├── integration-contracts/
├── docs/
│   └── integration/
├── scripts/
└── .github/
```

This is illustrative only. Do not adopt it if it conflicts with RT's Xcode project assumptions or Mirage packaging layout. The target tree must preserve Xcode project references, Swift build settings, Python package discovery, test discovery, resource paths, CLI packaging, corpus references, migration paths, and documentation links.

Before moving anything, prove both projects build and test from the proposed tree. Verify relative paths, package build contexts, working-directory assumptions, generated-artifact ignores, release workflows, and scripts that expect repository root. Preserve history where required by governance and audit needs. If using subtree or history-filtering techniques, test exact commands on disposable clones and compare resulting refs before applying them to the real destination.

After migration, do not delete the original repositories immediately. Update remotes and CI references, verify old links and package consumers, communicate the canonical location, retain a rollback window, and archive old repositories only after owner sign-off. Deletion is a separate explicit decision, not routine cleanup.

<a id="sec-4-5"></a>

### 4.5 Repository-level acceptance checklist

- [ ] Both original repositories and base SHAs are recorded.
- [ ] Backups/mirrors are recoverable and include required refs and LFS objects.
- [ ] Working trees and ignored/generated files have been reviewed.
- [ ] Branch protection and required checks are active.
- [ ] Ownership, secrets, permissions, releases, packages, and deployment references are inventoried.
- [ ] Repository strategy ADR is approved.
- [ ] No repository is deleted or archived as a side effect of integration.
- [ ] If consolidation is approved, a disposable migration rehearsal has passed.
- [ ] Post-migration builds, tests, package publishing, links, and workflows are verified.
- [ ] Original repositories remain recoverable until the migration acceptance gate is signed.

---

<a id="sec-5"></a>

## 5. Phase 0 — Governance, scope, and stop conditions

[⤴ back to top](#top)

<a id="sec-5-1"></a>

### 5.1 Assign accountable owners

Name one RT owner, one Mirage owner, one integration lead, one test/quality owner, one security/privacy reviewer, and one release/operations owner. One person may hold multiple roles on a small team, but responsibilities must still be explicit. The integration lead coordinates sequencing; domain owners retain authority over their invariants.

The RT owner approves changes to SwiftUI behavior, RT persistence, app lifecycle, existing analytics, and reading semantics. The Mirage owner approves changes to the ledger, ingestion, identity, extraction, graph projection, spoiler policy, correction overlay, and protocol. The security/privacy reviewer checks process boundaries, local file access, logs, user data, and release packaging. The release owner validates CI, signing, entitlements, package distribution, and rollback readiness.

<a id="sec-5-2"></a>

### 5.2 Define scope and acceptance in writing

Create an issue/milestone stating the goal: “Reading Tracker remains the parent macOS app and exposes Mirage as an optional, isolated literary-intelligence feature without weakening either project's data or spoiler guarantees.”

Define the first delivery narrowly: feature entry point, process lifecycle, protocol handshake, one safe read-only query path, identity mapping, cursor-safe behavior, failure isolation, and automated integration tests. Keep optional enhancements—series editing, correction UI, broad import automation, additional analytics, repository consolidation, RT persistence migration, CloudKit, Swift 6 conversion, and App Store release formalities—outside the first milestone unless owners explicitly add them.

Set measurable acceptance criteria. At minimum: RT builds and existing tests pass; Mirage tests pass; the integration contract is documented/tested; a supported book can be mapped without identity guessing; a spoiler-sensitive query fails closed when cursor evidence is absent; process failure cannot corrupt RT persistence; disabling Mirage prevents launch; and RT remains usable without Mirage installed.

<a id="sec-5-3"></a>

### 5.3 Stop conditions

Pause and return to owners if any of the following occurs:

- Selected source commit or repository identity cannot be established.
- A baseline test unexpectedly fails and the failure cannot be attributed.
- Sidecar protocol/lifecycle cannot be established from implementation and tests.
- A proposed change requires unreviewed mutation of RT or Mirage persistence.
- A query can reveal content beyond the confirmed spoiler cursor.
- The host cannot distinguish unknown mapping from verified mapping.
- A crash/timeout can cause an ambiguous mutation to be repeated.
- RT cannot launch or read books when Mirage is disabled/unavailable.
- A build/release step requires unauthorized secrets or permissions.
- A migration has no verified rollback path.
- A new dependency, network call, background job, or data collection behavior appears without approval.
- An implementation contradicts Mirage's normative mission statement or an existing ADR without a new approved ADR.

Do not waive a stop condition because the schedule is tight. Record evidence, reproduce the problem, identify the smallest safe next step, and obtain the appropriate owner's decision.

---

<a id="sec-6"></a>

## 6. Phase 1 — Establish and verify both baselines

[⤴ back to top](#top)

<a id="sec-6-1"></a>

### 6.1 Freeze exact source revisions

For RT and Mirage, record commit SHA, branch, tags, dirty/clean status, operating system, architecture, toolchain, dependency versions, and commands used. Preserve exact base revisions before modifying either tree. If a repository has uncommitted work, identify its owner and decide whether to commit, stash, or exclude it; never discard it to make the tree appear clean.

The supplied README reports RT's successful build and unit test on October 17, 2026, using Xcode 27.1 and macOS 26.5 target. It reports Mirage's 316 Python tests and three Rust tests. Treat these as baseline targets, not substitutes for running commands on the exact source commit. Record failures as failures even if a README says a previous run was green.

<a id="sec-6-2"></a>

### 6.2 RT baseline commands

The README provides these commands. Run them from the repository and environment for which the project is configured, and preserve complete logs with secrets and personal paths redacted as needed.

```bash
xcodebuild build \
  -project "Reading Tracker.xcodeproj" \
  -scheme "Reading Tracker" \
  -configuration Debug \
  -destination 'platform=macOS'

xcodebuild test \
  -project "Reading Tracker.xcodeproj" \
  -scheme "Reading Tracker" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -only-testing:"ReadingTrackerTests"
```

Do not assume the scheme name, project path, destination, or test target remains unchanged after a repository move. Confirm the actual Xcode structure and schemes first. If the baseline command differs, record the exact verified command and why.

Inspect test reports/build logs for skipped tests, unexpected warnings, unavailable destinations, retries, or tests that did not execute. A zero exit code is important evidence but does not prove every intended test ran. Record actual test counts and compare them with expected counts for the commit.

<a id="sec-6-3"></a>

### 6.3 Mirage baseline commands

The README provides these checks:

```bash
python3 -m unittest discover -s tests

cd crates/mirage-core
cargo test
```

The README also shows a source-tree CLI invocation:

```bash
PYTHONPATH=src python3 -m miragev10 --init-db --db mirage.sqlite3 --schema-version
```

Use a disposable test database for initialization and schema checks. Do not point exploratory commands at a user's real ledger. Confirm correct working directory and that test discovery includes all intended tests. Capture Python version, Rust toolchain, dependency state, and exact results.

Do not run a full analysis against the user's real library merely to establish a baseline. The README says the final robustness point is bound to a day-2 real library; that is a stated project constraint. Obtain the authorized fixture, required procedure, and evidence from Mirage's canonical records before executing it. If it cannot be run safely or the fixture is unavailable, mark the gate blocked rather than substituting synthetic data and calling it equivalent.

<a id="sec-6-4"></a>

### 6.4 Read normative documents before implementation

For RT, inspect the full `docs/audits/08-deep-audit.md`, `docs/registers/02-defect-register.md`, `docs/registers/03-fix-log.md`, `docs/registers/04-handoff.md`, relevant roadmap, test methodology, and store-split/SQLite blueprints. The README says the full audit contains file-and-line evidence and the fix log establishes engineering standards. These documents are required for changes touching persistence, imports, concurrency, or app lifecycle.

For Mirage, inspect at minimum docs/literary_intelligence_mission_statement.md, docs/embedding.md, docs/problems.md, docs/fixlog.md, docs/testing.md, docs/product_era_plan.md, docs/completion_plan.md, docs/p17-record.md, ADR-0001, ADR-0002, ledger migrations, and source implementing the chosen service/sidecar surface. Follow references when they define required evidence or safety behavior.

The team must read every relevant document in full, not only search snippets or headings, before relying on its requirements. For a domain's source-of-truth document, record that it was read completely and identify the commit SHA. If a document references another binding policy or ADR, follow it before implementing governed behavior.

<a id="sec-6-5"></a>

### 6.5 Baseline exit gate

- [ ] Exact source SHAs and working-tree state recorded.
- [ ] RT Debug build succeeds or every baseline failure is documented.
- [ ] RT unit tests complete with actual executed/skipped counts recorded.
- [ ] Mirage Python suite completes with actual results recorded.
- [ ] Mirage Rust tests complete if required by selected project policy.
- [ ] Runtime versions and environment recorded.
- [ ] Existing failures separated from integration regressions.
- [ ] Required audit registers, mission statement, embedding contract, and ADRs read in full.
- [ ] Real-library robustness constraint understood and authorized test path recorded.
- [ ] No implementation branch declared ready while unexplained baseline failures remain.

---

<a id="sec-7"></a>

## 7. Phase 2 — Source-code discovery and contract extraction

[⤴ back to top](#top)

<a id="sec-7-1"></a>

### 7.1 Inventory actual code, not just READMEs

Generate fresh, reproducible source inventories for both repositories at the recorded baseline commits. Identify source files, tests, resources, project files, build scripts, package metadata, migrations, fixtures, generated artifacts, configuration, docs, and ignored files. Use the inventory to orient the team, not to replace line-by-line inspection of files governing the integration.

For RT, trace the full flow from user action to SwiftUI view, view model/observable store, library model, persistence boundary, background work, and error presentation. Identify where books are imported, how active reader position is represented, how sessions are saved, where runtime paths are derived, and how MainActor-default isolation affects process and file I/O. Find all places where import or session-close events might trigger Mirage.

For Mirage, trace the supported entry point from command/API/sidecar through request parsing, domain validation, ingestion/query service, ledger transaction, spoiler predicate, projection, and response serialization. Confirm which layer owns transaction boundaries and how errors are returned. Determine whether the service API can be reused directly by the sidecar, whether the sidecar is persistent, and whether it supports graceful shutdown and cancellation.

<a id="sec-7-2"></a>

### 7.2 Create an interface inventory

Document each intended RT-to-Mirage operation with user purpose, caller, input schema, validation, side effects, persistence writes, idempotency, timeout, cancellation, output schema, error mapping, and test location. Mark operations read-only, state-changing, expensive, or destructive.

Start with the smallest useful set: readiness/version handshake; list or resolve known Mirage books/editions; import/link a single user-selected EPUB; request analysis for a specific edition; request a spoiler-safe query/projection at an explicit cursor; and obtain structured health/status. Include only operations the existing API actually supports. Do not invent a command and assume Mirage implements it.

Do not expose the entire CLI to the UI as arbitrary command text. Define a narrow allowlist of supported operations. A typed Swift interface should prevent views from constructing unvalidated protocol messages.

<a id="sec-7-3"></a>

### 7.3 Inspect persistence and migration boundaries

RT persistence is described as a JSON monolith plus sidecars and separate stores; Mirage uses a versioned SQLite ledger. Determine exact paths, schema versions, migration order, locking, transaction behavior, recovery behavior, backup/restore guarantees, and concurrent-open behavior from source. Identify whether Mirage opens a single ledger per library and whether a running sidecar retains a database handle during shutdown.

Never run a schema migration as a side effect of a read-only UI query unless that is the explicit documented initialization contract and the user has consented to the data changes. Prefer explicit initialization/migration with pre-migration backup, schema-version checks, transaction guarantees, and failure recovery.

<a id="sec-7-4"></a>

### 7.4 Publish three review artifacts

Before the first code change, publish:

1. **Architecture map:** verified component boundaries, runtime entry points, persistence owners, and trust boundaries.
2. **Protocol contract draft:** exact message envelopes and operations supported by the chosen Mirage entry point.
3. **Risk register:** each risk with severity, likelihood, owner, evidence, mitigation, test, and release gate.

Each artifact must distinguish verified facts from assumptions. Both domain owners must review them before implementation begins.

---

<a id="sec-8"></a>

## 8. Phase 3 — Fix or isolate pre-existing RT risks

[⤴ back to top](#top)

<a id="sec-8-1"></a>

### 8.1 Do not bury known defects in the merge

The RT README lists open defects and release blockers. The integration team must decide with the RT owner which defects must be fixed first, which can remain separately tracked, and which directly affect the new feature. The merge must not make an existing defect harder to reproduce or claim the entire app is release-ready while listed blockers remain open.

At minimum, NEW-DE-1 is relevant because new integration work may create more writes/concurrent work and RT's library history must remain safe. NEW-DE-5 is relevant because the book-import workflow must not bypass duplicate detection or overwrite goals. NEW-DE-4 is relevant if Mirage results are cached or surfaced through RT analytics. NEW-DE-3 is relevant if reading sessions and active cursors are synchronized. App lifecycle, file-access entitlements, bundle identifier, and WeatherKit issues must be handled according to release scope, not silently ignored.

<a id="sec-8-2"></a>

### 8.2 Define a pre-existing-defect policy

For each defect, choose: fixed before integration; explicitly isolated from integration scope; or blocks release. Attach defect ID, reproduction steps, evidence, owner, and regression test. If fixed, follow RT's stated standard: a Finality statement, fix-log entry, and pinned regression test, with the suite green at each phase boundary.

Do not bundle unrelated cleanup, dead-code retirement, store splitting, Swift 6 conversion, SQLite normalization, CloudKit, and Mirage integration into one giant PR. These changes have different risk profiles and rollback needs. Keep changes independently reviewable so the team can identify which change introduced a regression.

<a id="sec-8-3"></a>

### 8.3 Protect RT's concurrency model

RT's README identifies MainActor-default isolation as a defining build setting and links it to a previous freeze bug. Process launch, pipe reads/writes, JSON encoding/decoding, database access, and long-running analysis must not block SwiftUI's main actor. Use concurrency mechanisms compatible with the actual Swift language mode and project settings; do not assume Swift 6 strict-concurrency APIs are available merely because they are convenient.

Keep UI state changes on the actor/isolation context required by RT, but perform blocking process/file work away from the UI actor. Use explicit cancellation and bounded queues. Avoid unbounded tasks for every page turn or query. Test window opening/closing, navigation, and app termination while the sidecar is starting, busy, or failing.

<a id="sec-8-4"></a>

### 8.4 Phase exit gate

- [ ] Every known RT finding triaged as fix-before-integration, isolated, or release-blocking.
- [ ] Persistence ordering and import safety have owners and tests.
- [ ] MainActor-sensitive work is explicitly scheduled and measured.
- [ ] No unrelated architectural rewrite is hidden in the merge.
- [ ] RT remains buildable and testable at the phase boundary.

---

<a id="sec-9"></a>

## 9. Phase 4 — Build the integration boundary first

[⤴ back to top](#top)

<a id="sec-9-1"></a>

### 9.1 Implement a host-owned service abstraction

Create a small RT-facing abstraction such as `MirageClient` or `MirageServiceClient`; use project conventions for the final name. It should expose typed operations and typed results, not process handles or raw protocol strings.

The abstraction should be usable by SwiftUI without requiring a view to know whether Mirage runs in a child process, a test double, or another approved transport. This permits injected fake clients and UI/view-model tests without launching the real engine for every test.

The interface should express asynchronous work, cancellation where supported, and typed failures. It must not present “request sent” as “analysis completed.” Each operation returns a result only after a valid correlated response is validated, or a typed error after a defined timeout/failure.

<a id="sec-9-2"></a>

### 9.2 Implement lifecycle management

The process manager must define when Mirage launches, how it becomes ready, how standard streams are handled, how stderr is captured/bounded, how requests are serialized or multiplexed, and how shutdown works. Verify whether the sidecar supports multiple simultaneous requests before allowing concurrency; Mirage's “one analysis job at a time” principle constrains analysis work but does not specify every protocol concurrency rule.

Prevent duplicate launches and orphan processes, cap diagnostic buffers, close pipes, terminate the child on app shutdown according to the documented policy, and handle crashes. Restart attempts must be bounded and must not occur in a tight loop. If a response times out after a state-changing request, treat the outcome as ambiguous until safely reconciled; do not blindly replay the mutation.

Do not execute shell command strings assembled from user-provided paths or titles. Launch the executable with a controlled argument vector and validated environment, using actual platform APIs and the packaged executable layout. Treat paths as data, not shell syntax. Validate that the executable resolves to the expected bundled/approved location, and do not silently execute a different `mirage` binary found earlier on the user's PATH.

<a id="sec-9-3"></a>

### 9.3 Validate every message

Decode protocol messages into typed structures and validate required fields, version, identifier, command, enum values, sizes, and invariants before acting on them. Do not trust a local child process's output as automatically valid; bugs, stale versions, corrupted output, or unexpected diagnostic text can violate the contract.

Reject malformed or oversized responses without crashing. Log a redacted diagnostic and surface a useful error. Do not dump entire EPUB contents, full literary claims, user library records, or raw database rows into routine logs. Parser failures must not trigger fallback behavior that exposes more spoiler content.

<a id="sec-9-4"></a>

### 9.4 Keep UI independent

The UI should request operations through the host service and display loading, ready, unavailable, and error states. It should not run shell commands, open SQLite directly, construct NDJSON by string concatenation, or infer request success from a progress indicator.

Make the initial UI small: an entry point to Mirage, a status surface, a book/edition context, a safe query/projection flow, and an explanation when a required cursor is unavailable. Avoid building a second full application navigation system inside RT. Mirage's web UI remains optional and must not become a mandatory dependency by accident.

<a id="sec-9-5"></a>

### 9.5 Integration-boundary tests

Test process-not-found, launch failure, successful handshake, incompatible version, malformed JSON, partial line delivery, extra stdout noise, stderr flooding, oversized response, unexpected request ID, timeout, cancellation, crash during query, crash during mutation, duplicate request, graceful shutdown, forced termination, and disabled-feature behavior.

Where possible, test the protocol parser independently from process management. Use a fake child process or injected transport that deliberately fragments messages, delays responses, returns malformed data, and exits at controlled points. Verify that all failures leave RT's library, goals, sessions, and backups unchanged.

---

<a id="sec-10"></a>

## 10. Phase 5 — Implement the book/edition and cursor adapter

[⤴ back to top](#top)

<a id="sec-10-1"></a>

### 10.1 Start with one explicit user-selected book

Do not begin with background batch import of the entire RT library. Start with a user-selected, supported EPUB available on disk and authorized for processing. Verify that RT can access the file under the app's sandbox/entitlement configuration and that the path remains valid during import.

Show which book is being sent to Mirage, what operation is requested, and whether it can create/update Mirage ledger state. Allow cancellation before a destructive or expensive action when supported. If cancellation cannot stop an operation already committed by Mirage, explain the resulting state and reconcile it on the next status check.

<a id="sec-10-2"></a>

### 10.2 Verify identity after import

After Mirage reports import success, validate returned identifiers and schema before persisting the RT-to-Mirage mapping. If a response lacks an expected identifier, refers to an unsupported edition, or does not match the requested operation, mark the mapping unresolved and show an error. Do not create a synthetic ID as a substitute for a missing canonical ID.

Test repeated import of the same content, changed files, identical titles with different editions, same content at different paths, and a file whose content fingerprint conflicts with RT metadata. Expected outcomes must follow Mirage's actual content-identity contract, not a guessed rule.

<a id="sec-10-3"></a>

### 10.3 Establish the cursor contract

Before exposing spoiler-sensitive queries, write down the mapping from RT reading state to Mirage cursor state. Identify source of each field, conversion algorithm, edition identity requirement, invalidation conditions, and behavior when data is missing. If mapping cannot be proven, ship with spoiler-sensitive queries disabled or restricted to a safe mode rather than approximating.

Test cursor advancement/regression, book completion, unread/unknown state, changed EPUB, re-import, duplicate edition, stale mapping, and a user who declines automatic synchronization. Verify that Mirage's spoiler predicate remains the authority for visibility. RT may provide cursor inputs, but must not independently decide a claim is spoiler-safe using its own heuristic.

<a id="sec-10-4"></a>

### 10.4 Synchronization timing

Do not invoke full-book analysis on ordinary page turns. Mirage explicitly states that normal page turns must not trigger full-book analysis. The integration may update a lightweight reading-state/cursor declaration if the API supports it, but only under a measured bounded policy and after the semantic mapping is proven.

Prefer explicit actions or debounced low-cost synchronization over analysis triggered by every navigation event. Define when a cursor update is durable, whether it is coalesced, how out-of-order updates are rejected, and how the host reconciles a crash between an RT session save and a Mirage cursor update. Do not claim a cross-database atomic transaction unless one exists; document the consistency model.

<a id="sec-10-5"></a>

### 10.5 Adapter acceptance gate

- [ ] One user-selected EPUB can be processed through the supported Mirage interface.
- [ ] Identity mapping is explicit, validated, and recoverable.
- [ ] Duplicate and changed-file behavior is tested.
- [ ] Cursor units and conversion are verified against implementation.
- [ ] Missing or stale cursor information fails closed.
- [ ] Series linking remains user-confirmed under Mirage's existing rule.
- [ ] Page turns do not trigger full-book analysis.
- [ ] RT and Mirage persistence remain separately owned.
- [ ] Failure between host save and Mirage update is reconciled without false claims of atomicity.

---

<a id="sec-11"></a>

## 11. Phase 6 — Expose Mirage as an optional RT feature

[⤴ back to top](#top)

<a id="sec-11-1"></a>

### 11.1 Feature entry point and settings

Add one clear entry point within RT's existing navigation or book-context UI. Review exact placement in the running app. The label should communicate that this is a Mirage-powered literary-intelligence feature, not a replacement reader or a second app.

Provide a setting to enable/disable Mirage. Disabling must prevent new launches and new background work. Decide and document whether disabling merely stops the process or also offers explicit data removal; do not delete the Mirage ledger as a side effect of toggling a setting.

The app must work if Mirage is not installed, the bundled runtime cannot launch, the protocol is incompatible, or the ledger is unavailable. Show a restrained status and actionable explanation; do not put stack traces or Python tracebacks in the primary UI.

<a id="sec-11-2"></a>

### 11.2 Query experience

The initial query experience should be narrow. The UI supplies selected book/edition and a verified cursor where needed; Mirage enforces its own eligibility policy and returns structured results with provenance and uncertainty. RT must render the response without rewriting uncertain claims into certain statements.

Every result should preserve source/book attribution and epistemic status required by Mirage's domain model. If the response contains citations/evidence references, validate the schema and render them as structured evidence rather than flattening them into unattributed prose. If the response says a result was withheld by the spoiler gate, RT must not issue a second, less-restricted query to obtain it.

Do not use a language-model or external-service fallback to answer a query Mirage cannot answer unless separately designed, disclosed, approved, and proven not to bypass spoiler/provenance guarantees. The supplied README states that no network is used at runtime and deterministic classical extraction is the default; preserve those constraints unless a formal change is approved.

<a id="sec-11-3"></a>

### 11.3 Loading, errors, and accessibility

Display progress only when it corresponds to a real operation status. Distinguish “waiting for process,” “analyzing,” “querying,” “cancelled,” “failed,” and “complete” when the protocol can establish those states. Do not invent percentage progress if the engine does not report it.

Keep the interface responsive, keyboard navigable, and consistent with RT's existing design. Ensure large result sets are bounded/paginated according to the protocol and that the UI does not render unbounded graph output at once. Test the feature at minimum supported window size and under project accessibility/VoiceOver conditions.

<a id="sec-11-4"></a>

### 11.4 User-facing data controls

Explain where Mirage's ledger is stored, how it relates to RT's library, what is imported, and what unlinking a book does. Offer explicit, confirmed removal only if the supported Mirage operation exists and the user is shown what data will be removed. Mirage's README describes book removal as explicit and confirmed with per-table audit counts; preserve that behavior if exposing removal through RT.

Do not equate “unlink from RT” with “delete from Mirage.” Unlinking should remove/deactivate the mapping only, unless the user separately requests supported deletion and confirms consequences. The UI must not imply that deleting an RT book automatically deletes Mirage data or vice versa.

---

<a id="sec-12"></a>

## 12. Phase 7 — Security, privacy, and local-first guarantees

[⤴ back to top](#top)

<a id="sec-12-1"></a>

### 12.1 Preserve local-only operation

The Mirage README states that runtime operation does not use the network and describes a socket-denial install drill. The RT README describes an ATS-clean network configuration and a Discovery feature. Do not assume those facts combine into a single network policy. Verify actual network behavior for the selected integration path and confirm that launching Mirage does not introduce network access.

For the initial integration, the preferred behavior is local literary processing with no transmission of book text, claims, reading history, or library metadata to remote services. If network access is proposed, stop and require explicit privacy/security review, threat model, user-facing disclosure, and approved architecture change. Do not add telemetry containing book content or reading behavior without an explicit reviewed policy.

<a id="sec-12-2"></a>

### 12.2 File and process boundary

The process manager must use a known executable path and constrained environment. It must not inherit arbitrary environment variables that can change Python module loading, dynamic library resolution, file paths, or logging unless intentionally required and validated. Inspect packaging before deciding how Python and optional Rust artifacts are bundled.

Validate paths and identifiers received from UI/protocol. Avoid path traversal, accidental writes outside the app's intended support directory, and shell interpolation. Restrict files Mirage can read to the user-authorized EPUB and approved data directory to the extent platform sandbox/runtime architecture permits.

Do not treat a localhost HTTP listener as equivalent to an in-process trusted call. If the browser UI/HTTP surface is used, verify loopback binding, origin checks, request validation, port-conflict handling, and whether other local processes can invoke sensitive operations. Prefer the sidecar protocol if it avoids an unnecessary network listener.

<a id="sec-12-3"></a>

### 12.3 Logs and diagnostics

Diagnostics must help engineers identify lifecycle/protocol failures without recording unnecessary literary content. Log operation type, request ID, duration, status, error category, protocol version, and redacted identifiers as appropriate. Avoid logging full request payloads, EPUB text, full query text, unredacted titles if treated as sensitive, user file paths, or full claim text by default.

Bound log size and retention. Keep RT diagnostics separate from Mirage's ledger and append-only correction history. If a crash report includes process arguments, file paths, or user content, redact it before sharing. Never place real library files, ledger databases, answer keys, or corpus material in public CI artifacts unless licensing/privacy status explicitly permits it.

<a id="sec-12-4"></a>

### 12.4 Dependency and supply-chain checks

The README describes RT as having one pinned dependency, ZIPFoundation 0.9.20, and Mirage as standard-library-first with a reference Rust core. Verify actual manifests and lockfiles at chosen commits. Do not add a large runtime dependency, install-time network fetch, or unpinned package as a convenience shortcut.

If integration requires bundling Python, a wheel, a Rust binary, or other executables, define their source, version, hash, build provenance, license review, signing, update mechanism, and supported architecture. Release must not download and execute an unverified runtime on first launch. If distribution cannot be reproducible and supportable, the release gate remains blocked.

---

<a id="sec-13"></a>

## 13. Phase 8 — Testing strategy and quality gates

[⤴ back to top](#top)

<a id="sec-13-1"></a>

### 13.1 Preserve independent test suites

Run RT and Mirage suites independently before the integration suite. Do not merge their counts into one reassuring number that hides failure in one project. Record actual count, failures, skipped tests, environment, and commit for each suite.

The integration needs its own tests because neither existing suite alone proves cross-language process behavior, RT navigation, cursor mapping, and failure isolation. A test that mocks Mirage proves host logic under the mock contract; it does not prove the real sidecar implements that contract. Both fake-transport contract tests and real-sidecar smoke tests are required.

<a id="sec-13-2"></a>

### 13.2 Unit tests

RT-side unit tests should cover protocol encoding/decoding, schema validation, error mapping, identity mapping, cursor conversion, state transitions, settings, and operation idempotency policy. Mirage-side tests should preserve invariants for ingestion, incremental analysis, ledger history, identity resolution, correction overlays, and spoiler eligibility. Add Mirage tests for protocol behavior the host relies upon but which is not pinned already.

Use fixed fixtures and deterministic clocks where time affects state. Never make a test depend on a user's real library, current weather, uncontrolled network behavior, or an unpinned external service. Keep test databases in temporary directories and assert no unexpected files are written to the developer's home directory.

<a id="sec-13-3"></a>

### 13.3 Integration tests

At minimum, cover these end-to-end scenarios:

1. RT starts with Mirage disabled; no sidecar launches and normal reading flows work.
2. RT starts with Mirage enabled and a valid runtime; handshake succeeds and status becomes ready.
3. Sidecar is absent or cannot launch; RT remains usable and presents optional-feature status.
4. RT/Mirage protocol versions are incompatible; feature is disabled safely and no mutation is attempted.
5. A valid EPUB is imported; Mirage returns canonical identifiers and RT records a verified mapping.
6. Same EPUB imported again; duplicate behavior follows the actual idempotency contract and does not create a false second mapping.
7. Two editions with similar metadata remain distinct unless Mirage identity rules establish otherwise.
8. A query with valid cursor returns only eligible results and preserves provenance/uncertainty.
9. Query with missing, invalid, stale, or mismatched cursor evidence fails closed.
10. A series with read, in-progress, and unread editions applies each edition's spoiler policy and retains book attribution.
11. Sidecar crashes during a read-only query; RT reports failure without corrupting persistent state.
12. Sidecar crashes/times out during mutation; RT does not blindly retry and reconciles the outcome.
13. User cancels a supported operation; UI and engine state converge according to cancellation contract.
14. User disables Mirage; no new process/analysis starts and RT remains functional.
15. User unlinks a book; mapping changes without silently deleting the Mirage ledger entry.
16. Explicitly confirmed deletion, if implemented, invokes supported operation and reports returned audit/count accurately.
17. RT termination closes child process or follows documented shutdown escalation.
18. Large responses and stderr output remain bounded and do not freeze MainActor.
19. Existing RT imports, goals, sessions, achievements, archives, covers, weather, Sentinel, and backups pass relevant regression tests.
20. Packaged app works on a clean test machine without developer PATH, Python environment, or local checkout.

<a id="sec-13-4"></a>

### 13.4 Regression and failure injection

Introduce controlled faults: malformed JSON, truncated output, delayed response, process exit, locked database, failed migration, corrupt ledger copy, disk-full simulation where practical, invalid file access, duplicate request, and stale cursor mapping. Verify errors remain contained and the user can recover without manually editing databases.

Test realistic data volumes, including a larger RT library and authorized Mirage robustness fixture. The RT README estimates that the JSON monolith can become very large at million-record scale and identifies MainActor re-analysis and write ordering as risks. Do not assume Mirage's one-analysis-job and 8 GB target mean RT can launch analysis without measuring memory/responsiveness. Measure process startup, query latency, analysis latency, memory peak, response size, cancellation latency, and idle overhead.

<a id="sec-13-5"></a>

### 13.5 UI and accessibility testing

The RT README explicitly notes gaps in view-flow coverage. Add UI tests for opening Mirage, changing books, displaying status, query loading/errors, cursor-unavailable states, and returning to ordinary reading. Test keyboard navigation, focus restoration, window closing while busy, and existing developer-console/window behavior where relevant.

A unit test for a view model is not a substitute for verifying the actual SwiftUI hierarchy and window lifecycle. Use available UI test infrastructure and document any untested platform flow. The integration is not complete if only parser/service layers are tested.

<a id="sec-13-6"></a>

### 13.6 Performance budgets

Set explicit budgets after establishing a baseline rather than inventing numbers from the README. RT and Mirage owners should agree on acceptable sidecar startup delay, simple query latency, analysis latency, memory overhead, idle CPU, and UI responsiveness. Record baseline and integration measurements under the same conditions.

Normal reading and page turns must not synchronously wait for full-book analysis. If analysis is expensive, run it as a controlled operation and show status. Ensure a slow or failed Mirage request does not stall RT's library save path or block MainActor. Use measured evidence, not a subjective statement that the UI “feels fine.”

---

<a id="sec-14"></a>

## 14. Phase 9 — Build, packaging, and release engineering

[⤴ back to top](#top)

<a id="sec-14-1"></a>

### 14.1 Decide how Mirage is distributed with RT

Choose and document whether the RT release bundles a compatible Mirage runtime, installs it through an approved separate mechanism, or requires a user-managed runtime. The README's `pipx install ./dist/miragev10-1.0.0-py3-none-any.whl` is a developer/user installation path; it does not prove suitability for distribution inside a signed macOS app.

A bundled runtime can improve predictability but increases packaging, signing, notarization, and architecture complexity. A user-managed runtime reduces bundle size but creates version drift/support problems. Decide using a clean-machine prototype and actual distribution target. Do not assume the developer's Python, Cargo, environment variables, or source tree exists on a user's machine.

<a id="sec-14-2"></a>

### 14.2 Reproducible build process

Pin the selected Mirage version/commit and record matching protocol version. Build/package runtime reproducibly in CI. Verify the package contains required Python modules, data files, SQL migrations, templates/assets, and native artifacts. Do not omit migrations or runtime assets merely because they are not Python source files.

The packaged RT app must locate the correct runtime without PATH-dependent ambiguity. Validate runtime version at startup and refuse incompatible versions with a safe explanation. The update procedure must not downgrade ledger schema without an approved recovery process.

<a id="sec-14-3"></a>

### 14.3 macOS signing, sandbox, and entitlements

RT's README reports an empty AppIcon set, missing WeatherKit entitlement, mismatch in user-selected-file access settings versus entitlements, and empty-string bundle identifier in a custom plist. Recheck these against the actual project. A merge must not introduce a second bundle identifier or entitlements file without understanding existing packaging.

Verify final app bundle identifier, Info.plist, signing identity, sandbox entitlements, user-selected file access, executable permissions, embedded runtime signing, and notarization requirements for the intended distribution channel. A child executable may require its own signing/packaging treatment. Test the actual packaged artifact, not only Xcode Debug from a developer checkout.

<a id="sec-14-4"></a>

### 14.4 CI design

Create separate CI jobs for RT build/tests, Mirage Python tests, Mirage Rust tests if required, protocol contract tests, integration tests, packaging smoke tests, and security checks. Cache dependencies only in ways that preserve lockfile correctness/reproducibility. A successful RT job must not mask a failed Mirage job or vice versa.

Protect release jobs/signing secrets with least privilege. Never print secrets in logs. Ensure pull requests from untrusted forks cannot access release credentials. Store test artifacts only when safe to publish; sanitize logs and do not upload real libraries or production ledgers.

<a id="sec-14-5"></a>

### 14.5 Release gate

- [ ] Clean-machine build and launch passes.
- [ ] Runtime packaging and protocol version are recorded.
- [ ] RT, Mirage, and integration test jobs all pass.
- [ ] Signing, sandbox, entitlements, file access, and app identity are verified.
- [ ] App works when Mirage is absent or disabled.
- [ ] No network access has been added without explicit approval.
- [ ] Performance budgets are measured and met.
- [ ] Rollback and data recovery have been rehearsed.
- [ ] Known RT release blockers are resolved or explicitly prevent production release.
- [ ] Owners approve exact release commit and artifact.

---

<a id="sec-15"></a>

## 15. Phase 10 — Rollback, recovery, and operational support

[⤴ back to top](#top)

<a id="sec-15-1"></a>

### 15.1 Code rollback and data rollback are different

Reverting integration code does not automatically reverse a Mirage ledger migration or remove data Mirage imported. Restoring an RT Git commit does not restore runtime `library.json`, `library-state.json`, cover files, weather database, or Sentinel journal. Document these distinctions before enabling the feature for real users.

Keep the initial integration additive. Avoid changing RT persistence schema or Mirage ledger schema unless necessary, reviewed, and covered by a separately tested migration plan. If either schema changes, write pre-migration backup, post-migration verification, and recovery procedures that account for newer app versions potentially writing data older versions cannot understand.

<a id="sec-15-2"></a>

### 15.2 Rollback triggers

Rollback or disable Mirage if any of the following is observed: spoiler leakage; unexplained identity mislinking; corruption/unexpected mutation of RT data; unbounded process restarts; repeated UI freezes; severe memory/CPU regressions; protocol incompatibility; failed migration; unexplained ledger integrity errors; or security/privacy violation.

For a feature-only incident, first disable the feature or stop launching the sidecar if that safely contains the problem. Do not delete the ledger as a troubleshooting shortcut. Preserve redacted logs, request IDs, commit SHAs, protocol versions, and reproduction steps. Escalate data-integrity concerns to both domain owners before attempting repair.

<a id="sec-15-3"></a>

### 15.3 Recovery rehearsal

Before production release, rehearse at least one code rollback, one sidecar crash recovery, one failed initialization, one invalid mapping recovery, and one documented data-backup restore using disposable test data. Record each step and observed result. An untested recovery plan is a hypothesis, not a verified safety mechanism.

RT's backup rotation and Sentinel protect RT-owned data under their own rules; they must not be assumed to back up Mirage's SQLite ledger. Define an independent Mirage ledger backup policy following its transaction/database requirements. Verify whether copying a live SQLite database requires a supported backup API or quiescing the process; do not simply copy open database files and claim the backup is consistent.

<a id="sec-15-4"></a>

### 15.4 Operational handoff

The final handoff must explain how to identify the running Mirage process, check its version/protocol compatibility, locate the approved ledger directory, inspect redacted diagnostics, run the test suite, disable the feature, recover from failed start, and escalate suspected spoiler/data-integrity defects. Document who owns runtime updates and how compatibility is tested before RT ships a new Mirage version.

---

<a id="sec-16"></a>

## 16. Implementation sequence and pull-request plan

[⤴ back to top](#top)

Use small PRs that can be reviewed and reverted independently. Do not create one mega-PR containing source moves, dependency changes, protocol changes, UI changes, schema migrations, and repository restructuring.

### PR 1 — Baseline and documentation only

Record exact SHAs, baseline commands/results, architecture inventory, open-risk triage, and normative document references. This PR should not change runtime behavior.

**Acceptance:** both owners approve baseline/risk register; no unresolved repository identity or source-revision ambiguity remains.

### PR 2 — Architecture and protocol ADR

Compare supported Mirage embedding options, choose a provisional transport, and define protocol contract, lifecycle, version compatibility, and error model. Include actual source paths/tests that establish each contract claim.

**Acceptance:** RT and Mirage owners approve the ADR; protocol is implementable without invented fields or commands.

### PR 3 — Host interface and fake transport

Add typed RT service abstraction and fake transport. Test loading, errors, cancellation, protocol mismatch, and disabled behavior without launching Mirage.

**Acceptance:** host module is isolated from SwiftUI and persistence; existing RT tests remain green.

### PR 4 — Real sidecar lifecycle and handshake

Implement launch, version handshake, stream framing, response validation, timeout, crash handling, shutdown, and bounded diagnostics. Do not yet add broad book-import automation or destructive operations.

**Acceptance:** real-sidecar smoke tests and injected-failure tests pass; no unbounded restart or UI-blocking behavior is observed.

### PR 5 — Identity mapping and one-book import

Add explicit user-driven EPUB import/link flow using actual Mirage contract. Keep mapping separate from RT's canonical library record and do not alter RT persistence schema unless separately approved.

**Acceptance:** duplicate, changed-file, ambiguous identity, missing file, cancellation, and process-crash cases are tested.

### PR 6 — Cursor-safe read-only query

Add the smallest useful query/projection experience with explicit cursor validation, provenance rendering, and fail-closed behavior. Avoid corrections, bulk operations, series editing, and broad background automation in this PR.

**Acceptance:** spoiler tests prove missing/invalid cursor evidence never expands visibility; attribution and uncertainty survive the UI boundary.

### PR 7 — Optional-feature settings and lifecycle polish

Add enable/disable behavior, unavailable-state UX, accessibility, clean shutdown, and user-facing data controls. Verify disabling Mirage does not delete data or affect ordinary RT use.

**Acceptance:** UI tests and clean-machine smoke tests pass with Mirage enabled, disabled, absent, and incompatible.

### PR 8 — Packaging and release readiness

Bundle or provision runtime according to approved distribution decision. Validate signing, sandbox, clean-machine behavior, CI, performance, rollback, and documentation.

**Acceptance:** release gates in Sections 13–15 pass, and exact artifact is approved by owners.

### Separate PRs only if approved

Repository consolidation, RT JSON-to-SQLite migration, Swift 6 strict mode, store splitting, dead-code retirement, CloudKit, broad series/correction UX, and App Store formalities should be tracked independently unless an approved ADR proves one is a hard dependency of the initial integration.

---

<a id="sec-17"></a>

## 17. Architecture decisions that must be recorded

[⤴ back to top](#top)

Create ADRs or equivalent reviewed decisions for the following. Do not leave them as informal assumptions in code review comments.

1. **Repository strategy:** keep repositories separate, use monorepo, or migrate while preserving history.
2. **Runtime distribution:** bundled runtime, separately installed runtime, or another approved packaging approach.
3. **Transport:** NDJSON sidecar, direct Python embedding, local HTTP/browser surface, or another verified interface.
4. **Protocol versioning:** compatibility rules, error schema, maximum message size, concurrency, cancellation, and idempotency.
5. **Data directories:** location/ownership of Mirage ledger, backups, logs, and temporary files.
6. **Identity mapping:** canonical identifiers, matching evidence, ambiguity handling, and remapping behavior.
7. **Spoiler cursor:** mapping from RT reading state to Mirage cursor, update timing, fail-closed behavior, and user control.
8. **Feature lifecycle:** enable/disable, launch timing, crash recovery, process shutdown, and update compatibility.
9. **Privacy and diagnostics:** logging, retention, data export/deletion, and network policy.
10. **Migration policy:** whether either schema changes and how backup, verification, and rollback work.
11. **Release policy:** supported macOS/runtime versions, signing, distribution, CI gates, and owner approvals.
12. **Scope exclusions:** which existing RT roadmap items remain outside the merge.

Each ADR must state problem, context, alternatives, decision, reasons, consequences, security/privacy impact, rollback implications, tests required, and approving owners. Mark superseded ADRs rather than silently rewriting historical decisions.

---

<a id="sec-18"></a>

## 18. Final acceptance checklist

[⤴ back to top](#top)

The merge is not complete merely because the branch compiles. Complete each applicable checklist item with evidence.

### Product and architecture

- [ ] RT remains the parent application and Mirage is presented as an optional feature.
- [ ] Ordinary RT reading, library management, sessions, analytics, goals, and navigation work without Mirage.
- [ ] Mirage's ledger, analysis, graph, provenance, corrections, and spoiler rules remain Mirage-owned.
- [ ] Integration boundary is typed, versioned, tested, and independent of SwiftUI view details.
- [ ] Transport and packaging strategy are documented in an approved ADR.
- [ ] No undocumented second app shell or hidden network service has become mandatory.

### Data safety and correctness

- [ ] RT and Mirage persistence remain separately owned.
- [ ] RT book identifiers and Mirage identifiers are explicitly mapped, not assumed equivalent.
- [ ] Ambiguous identity does not silently create a mapping.
- [ ] Cursor mapping is source-verified and edition-aware.
- [ ] Missing, stale, or mismatched cursor evidence fails closed.
- [ ] Normal page turns do not trigger full-book analysis.
- [ ] Series candidates do not become links without required user decision.
- [ ] Corrections do not silently become underlying book truth.
- [ ] No mutation is blindly retried after ambiguous timeout.
- [ ] Backup/recovery procedures cover both systems independently.

### Stability, testing, and performance

- [ ] RT baseline and regression tests pass.
- [ ] Mirage Python tests pass.
- [ ] Mirage Rust tests pass if required by selected build policy.
- [ ] Integration contract and real-sidecar smoke tests pass.
- [ ] Process failure, timeout, malformed response, cancellation, and shutdown tests pass.
- [ ] UI flows and accessibility have been tested.
- [ ] Large-library and real-library robustness requirements handled according to canonical procedure.
- [ ] MainActor work remains bounded and UI remains responsive.
- [ ] Performance budgets are measured against recorded baselines.
- [ ] No unexplained regression or skipped required test remains.

### Security, privacy, and release

- [ ] Runtime executable and environment are controlled and version-checked.
- [ ] File access is authorized and constrained.
- [ ] Logs are bounded and appropriately redacted.
- [ ] No network access or telemetry introduced without approval.
- [ ] Packaging works on a clean machine without developer-local tools.
- [ ] Signing, sandbox, entitlements, bundle identifier, and runtime permissions are verified.
- [ ] CI has separate visible gates for RT, Mirage, and integration.
- [ ] Known RT release blockers are resolved or production release is explicitly blocked.
- [ ] Rollback and restore procedures have been rehearsed.
- [ ] Both domain owners and release owner approve the exact commit/artifact.

### Repository governance

- [ ] Repository strategy is documented.
- [ ] Original repositories remain recoverable.
- [ ] No archive or deletion occurred implicitly.
- [ ] If migration was approved, refs, tags, required history, LFS objects, workflows, permissions, and external references were verified.
- [ ] Canonical repository location and future ownership are communicated.

---

<a id="sec-19"></a>

## 19. Required evidence bundle for handoff

[⤴ back to top](#top)

Publish an evidence bundle with the completed integration. It should include architecture ADR, protocol schema, source-revision inventory, baseline build/test logs, integration test report, performance report, security/privacy review, packaging validation, known-issue list, rollback rehearsal record, and final acceptance checklist.

For every command result, record commit SHA and environment. For every safety claim, link the test/source evidence supporting it. For every remaining limitation, state impact, owner, mitigation, and whether it blocks release. Do not label the system “fully verified” if a required test was skipped, real-library robustness remains untested, or the package has not been exercised outside the developer checkout.

Keep user data out of the evidence bundle. Use synthetic fixtures or approved sanitized data. If an authorized real-library test is required, record only the minimum evidence needed to prove it ran and met criteria; do not distribute the library or its content as an ordinary CI artifact.

The handoff must explain how to reproduce the build, run all suites, start the optional feature, disable it, inspect safe diagnostics, and recover from failed sidecar or migration. A new engineer should be able to follow it without guessing which repository, branch, Python environment, database, or runtime path is authoritative.

---

<a id="sec-20"></a>

## 20. Immediate next actions

[⤴ back to top](#top)

Do these in order. Do not start by moving files.

1. Confirm both canonical repository URLs and record exact source commit SHAs.
2. Read RT audit/register/handoff documents and Mirage mission statement/embedding/ADR documents in full.
3. Re-run both projects' baseline builds/tests in clean, recorded environments.
4. Triage RT's known persistence, import, concurrency, and release-blocker findings.
5. Inspect actual Mirage NDJSON/sidecar implementation and document its protocol/lifecycle.
6. Write and approve architecture ADR, with managed sidecar as leading candidate only if source evidence supports it.
7. Define RT-to-Mirage identity mapping and spoiler-cursor contract before exposing literary queries.
8. Implement host abstraction and fake-transport tests.
9. Add real sidecar lifecycle and one-book workflow in small, reviewable PRs.
10. Add spoiler-safe query experience and test failure isolation.
11. Validate packaging, signing, privacy, performance, and recovery on a clean machine.
12. Decide separately whether repository consolidation is worthwhile; do not delete either repository to make integration appear complete.

---

<a id="app-a"></a>

## Appendix A — Commands shown by the supplied READMEs

[⤴ back to top](#top)

These commands are transcribed from the supplied README and must be checked against the selected source commit before use. Use disposable database paths for exploratory Mirage commands.

### Reading Tracker

```bash
open "Reading Tracker.xcodeproj"

xcodebuild build \
  -project "Reading Tracker.xcodeproj" \
  -scheme "Reading Tracker" \
  -configuration Debug \
  -destination 'platform=macOS'

xcodebuild test \
  -project "Reading Tracker.xcodeproj" \
  -scheme "Reading Tracker" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -only-testing:"ReadingTrackerTests"
```

The README says RT runtime data lives under `~/Library/Application Support/johan.Reading-Tracker/`, including `library.json`, `library-state.json`, covers, weather SQLite data, `Backups/`, and `sentinel-journal.jsonl`. Verify the actual path in source before using it in scripts/documentation.

### Mirage

```bash
python3 -m unittest discover -s tests

cd crates/mirage-core
cargo test

PYTHONPATH=src python3 -m miragev10 --init-db --db mirage.sqlite3 --schema-version

PYTHONPATH=src python3 -m miragev10 --db mirage.sqlite3 --import-epub ./book.epub

PYTHONPATH=src python3 -m miragev10 --db mirage.sqlite3 --analyze-edition edition_skeleton_1

PYTHONPATH=src python3 -m miragev10 --db mirage.sqlite3 --project-at 4
```

The README also documents `mirage --serve-web` as a local-only browser UI, `mirage --serve --db mirage.sqlite3` for NDJSON commands on stdin, and optional sidecar example `examples/mirage_sidecar.py`. Verify exact arguments/protocol in implementation before integrating them.

---

<a id="app-b"></a>

## Appendix B — Open questions that must be answered from source or by owners

[⤴ back to top](#top)

These are not permission to guess. Resolve each with evidence or mark it a deliberate release limitation.

1. What exact NDJSON request/response schemas does the sidecar support?
2. Is the sidecar persistent, and how does it report readiness, errors, cancellation, and shutdown?
3. Which service methods are stable public API versus internal implementation details?
4. What are canonical Mirage identifiers for book, edition, unit, claim, and series?
5. How is a reading cursor represented and validated internally?
6. What source-unit mapping, if any, connects RT's reader position to Mirage's cursor?
7. What happens when the same EPUB is imported repeatedly or its content changes?
8. What database directory and backup mechanism does Mirage recommend for an embedded host?
9. Which Python runtime and packaging format are supported for a signed macOS app?
10. Does the selected sidecar path open sockets under any mode, and can that be proved by runtime tests?
11. Which Mirage operations are idempotent, and how are ambiguous mutation timeouts reconciled?
12. How should RT's “read,” “reading,” and “unread” map to Mirage's declared state vocabulary?
13. What are required day-2 real-library robustness steps, and what evidence marks them complete?
14. Which RT open defects must be fixed before an integration release?
15. Will repositories remain separate or become a monorepo, and who can approve migration?
16. What is the intended release channel, and what signing/notarization/runtime packaging constraints follow?

For every answered question, add source path or approved decision reference to the evidence bundle. For every unanswered question, identify an owner and whether the uncertainty blocks implementation or release.

---

<a id="app-c"></a>

## Appendix C — Safety invariants that must never be weakened

[⤴ back to top](#top)

1. RT remains usable if Mirage is disabled, missing, incompatible, or crashed.
2. RT persistence is not mutated by a failed Mirage request.
3. Mirage's ledger remains the source of truth for Mirage claims; graph output is a projection.
4. Spoiler eligibility is decided by Mirage's verified policy, with cursor uncertainty handled fail-closed.
5. Identity mappings are explicit and never inferred from title alone.
6. Ordinary page turns do not trigger full-book analysis.
7. Series linking does not become automatic merely because metadata overlaps.
8. Corrections do not silently become underlying book truth.
9. No mutation is blindly retried after an ambiguous timeout.
10. No repository is deleted or archived as an incidental merge step.
11. No build/test success is claimed without recording exact revision and observed result.
12. No source behavior is called verified merely because it is described in a README.
13. No real user library, secret, signing key, or unredacted content is placed in public artifacts.
14. No migration is performed without tested backup and recovery plan.
15. Every integration milestone ends with reviewable commit, evidence, and green required test gate—or a documented stop.

---

<a id="app-d"></a>

## Appendix D — Multi-pass document audit

[⤴ back to top](#top)

### D.1 Audit method

This playbook was checked using multiple concurrent review passes over the complete generated Markdown. Automated checks verify presence of major technical topics, key source-derived facts, required safety boundaries, and document-structure consistency. The checks are a completeness aid, not a substitute for engineer source review or formal security assessment.

The audit passes are:

- **Scope and product hierarchy:** RT parent, Mirage optional capability, explicit non-goals, repository decision separation.
- **Architecture and protocol:** sidecar candidate, transport alternatives, lifecycle, versioning, message validation, error handling, cancellation, idempotency.
- **Data integrity:** storage ownership, identity mapping, import, cursor mapping, fail-closed spoilers, series, corrections, migration and recovery.
- **Operations and repositories:** baselines, Git safety, CI, packaging, release, rollback, handoff.
- **Quality and privacy:** testing, failure injection, performance, accessibility, local-only policy, process boundary, logs, dependencies.
- **Source fidelity and caveats:** key README-reported facts retained and explicitly labeled as unverified until checked against source.
- **Structure and consistency:** headings, code fences, checklist sections, and required appendices.

### D.2 Required source-fidelity reminder

The source document provided for this task is a combined README, not the two full source repositories and not all internal documents referenced by those READMEs. Therefore, this playbook intentionally identifies source inspection and baseline execution as required phases. It does not claim to have inspected every line of either codebase, and it does not claim the integration is implemented or tested.

### D.3 Final reviewer sign-off

- [ ] RT owner reviewed product hierarchy, RT risks, persistence boundaries, and UI plan.
- [ ] Mirage owner reviewed mission, embedding contract, ledger ownership, cursor policy, and spoiler guarantees.
- [ ] Security/privacy reviewer reviewed process launch, file access, logs, network policy, and packaging.
- [ ] Test owner reviewed baseline, contract, integration, failure-injection, and UI test plans.
- [ ] Release owner reviewed CI, signing, packaging, migration, backup, and rollback gates.
- [ ] Every open Appendix B question has an owner.
- [ ] No required source/test evidence has been replaced by unsupported assumption.
- [ ] Final Markdown was re-scanned after the last edit and scan results recorded.

**End of playbook.**

### D.4 Automated concurrent scan results

- Initial full-document scan SHA-256: `ac9795c85f4bc1ddd1657365c833d764c1086753ac10cd9701f2a199cfac72ee`
- Initial scan scope: 1079 lines; 12951 words; 93887 UTF-8 bytes.
- Review passes executed concurrently: 7.

**Scope/Product Hierarchy**
- FAIL — RT is the parent application
- PASS — optional feature
- PASS — Explicit non-goals
- PASS — repository consolidation

**Architecture/Protocol**
- PASS — NDJSON
- PASS — process manager
- PASS — protocol version
- PASS — partial pipe reads
- PASS — cancellation
- PASS — idempotency
- PASS — MainActor
- PASS — fake transport

**Data Integrity**
- PASS — library.json
- PASS — ledger@0.0.10
- PASS — fail closed
- PASS — identity mapping
- PASS — series
- PASS — corrections overlay
- PASS — backup
- PASS — rollback

**Operations/Release**
- PASS — baseline
- PASS — xcodebuild build
- PASS — python3 -m unittest discover -s tests
- PASS — GitHub
- PASS — CI
- PASS — signing
- PASS — clean machine
- PASS — recovery rehearsal

**Quality/Privacy**
- PASS — failure injection
- PASS — performance budgets
- PASS — accessibility
- PASS — local-only
- PASS — logs and diagnostics
- PASS — network access
- PASS — real-library robustness
- PASS — security

**Source Fidelity**
- PASS — README-REPORTED
- PASS — NEW-DE-1
- PASS — NEW-DE-5
- PASS — WeatherKit
- PASS — docs/literary_intelligence_mission_statement.md
- PASS — ADR-0002
- PASS — 316 passing Python tests
- PASS — three Rust tests

**Structure/Consistency**
- PASS — ## 0. Executive directive
- PASS — ## 1. Source-derived baseline
- PASS — ## 4. Repository strategy
- PASS — ## 13. Phase 8
- PASS — ## 18. Final acceptance checklist
- PASS — ## Appendix D
- Code fence markers: 14 — PASS (even count required)
- Headings detected: 115
- Initial line count: 1079
- Initial word count: 12951

**Interpretation:** These checks establish topic presence and basic structural consistency only. They do not prove that an implementation detail is correct, that an external repository matches the README, or that a safety guarantee holds in execution. Those claims require the source and test evidence described in this playbook.

**Automated scan result:** REVIEW REQUIRED — scope/product hierarchy: missing RT is the parent application

### D.5 Final-artifact rescan

- Final SHA-256 before this footer: `481dc2f9f925866e9b04cb0d225dff41d98015eed8f85f1168ddbf78ad26da0a`
- Final size before this footer: 1157 lines, 13225 words, 96274 UTF-8 bytes.
- Code fence markers: 14 (balanced).
- Concurrent final-artifact passes: 5.
- **scope scan:** PASS RT remains the parent application; PASS Mirage as an optional; PASS Do not delete
- **technical scan:** PASS NDJSON; PASS ledger; PASS cursor; PASS protocol; PASS MainActor
- **operations scan:** PASS xcodebuild build; PASS cargo test; PASS rollback; PASS signing
- **safety scan:** PASS fail closed; PASS idempotency; PASS privacy; PASS backup; PASS SOURCE-VERIFIED
- **source-fidelity scan:** PASS NEW-DE-1; PASS NEW-DE-5; PASS ledger@0.0.10; PASS ADR-0002
- Final rescan outcome: PASS — required coverage and structure checks passed.
- Limitation: automated scans assess coverage and structure, not semantic truth; source-level verification and execution gates remain mandatory.

---

<a id="sec-21"></a>

## 21. Technical escalation addendum (section-by-section ≥21× intensification layer)

[⤴ back to top](#top)

**Document type:** Escalation formal overlayer appended to the base playbook.  
**Scoping rule:** Escalation of every normative sentence of §0–§20 and Appendices A–D into hardened, quantitative, byte-and-syscall-grade engineering specification territory.  
**Conflict rule:** If any statement herein is later shown to conflict with verified source behavior at the integration commit SHA, the verified source and an approved ADR govern; the tenure of any statement in this addendum is conditional on SOURCE-VERIFIED status being achieved.  
**Anti-fabrication rule:** Where this addendum specifies a field, command, pragma, error code, or budget that the supplied READMEs do not assert, it is labeled **ESCALATED-DESIGN** (a draft for ADR review, not a claim of existing behavior). README-derived facts carried into this layer remain **README-REPORTED** until re-verified. **The presence of executable-looking fragments in this addendum does not constitute authorization for any session, tool, agent, or automated actor to execute them. They are engineering artifacts for review only. NO instruction contained in this document is authorized to be acted upon by an AI session; human maintainer sign-off through a recorded PR review is the only execution path.**

<a id="sec-21-0"></a>

### 21.0 Escalation metric, doctrine, and non-execution charter

- **Escalation theorem:** Each original topic (form, content) is escalated via five tactics — **(F1) formalism** (state machines, invariants, pre/post-conditions, algebraic contracts), **(F2) byte/ABI precision** (wire formats, framing, encodings, syscalls, build-system pragmas, APFS/HFS+/POSIX-precise macOS semantics), **(F3) quantification** (budgets with upper bounds, latency distributions, memory ceilings, restart ladders, buffer capacities, timed-out escalation ladders), **(F4) failure taxonomy** (prefixed error code registries with user-safe disclosure strings), **(F5) excursiveness** (each original keyword row gets ≥20 sub-cases incl. cross-cutting interactions, e.g., the single concept "cursor" expands into 25+ enumerated failure modes).
- **Zone-of-applicability:** Addendum statements bind contractors, future reviewers, and test plans. They reduce no original authority. They do not, by themselves, make green any test or claim anything run.
- **Execution non-authorization (binding on all agents):** No entity operating this playbook may (a) run the baselines in §6.2/§6.3/Appendix A, (b) touch either codebase, (c) execute `mirage` fixtures or import drills, (d) honor the "immediate next actions" list in §20, or (e) generate animated automation to "helpfully implement" any section, without (i) a human-maintainer-approved branch, (ii) recorded commit SHAs, (iii) owner sign-off per §5.1. Agent-initiated execution is a stop condition per §5.3.

<a id="sec-21-1"></a>

### 21.1 Escalation of §0 — Executive directive → composition-theoretic topology

**S0-ES-1 (product topology as two trust domains with asymmetric control plane):** escalates §0 into a formal topology. RT and Mirage are not "two apps" — they are **two security principals** `R` and `M` in distinct trust domains `T_R ⊃ T_M` with asymmetric supervisory capability: `R` holds the process-spawn capability (`Capability.spawn`), the filesystem capability scope (`Capability.fs(~/Library/Application Support/johan.Reading-Tracker/**, authorized book paths)`, sandbox-profile-anchored), and the UI capability; `M` holds zero spawn capability, zero UI capability, and exactly one I/O capability — a controlled transport channel — plus arbitrary ephemeral compute. The **capability passing relation** is one-directional: `R ⊣ M : Capability.transport` with no reflexive edge `M ⊢ M` and no `M ⊣ R`. In implementation terms: no code path in Mirage may contain a `fork/exec`/`subprocess`-spawn call, and RT must statically refuse (at code review, not merely at runtime) any Swift diff that adds process supervision outside the single `MirageProcessSupervisor` type. **Enforcement points:** (a) review-time — a CODEOWNERS/pull-request check pattern: `grep -lw "Process\|NSTask\|subprocess" src/ | diff -approved-supervisor-list` in CI as a lint (ESCALATED-DESIGN), (b) runtime — RT's supervisor asserts the child's executable identity by SHA-256 compare against the pinned disk manifest **before first write**, else kill+disable per §9.2.

**S0-ES-2 (merge ≠ maximal file motion — formal treatment of the four temptation axes):** four fallacies encoded as named anti-goals, each with a mechanical detection signature so no future agent mistakes them for directives:
- **AU-1 store-unification fallacy:** treating `library.json`/`library-state.json` + mirrors + SQLite weather + `ledger@0.0.10` as one boundary. *Detection:* any PR diff writing to `library.json` from a module with an import path containing `Mirage`, or any PR diff in `src/miragev10/**` containing the literal `library.json`.
- **AU-2 lifecycle-usurpation fallacy:** Mirage driving application state (app start/stop). *Detection:* any Swift-side call graph where a Mirage-originated callback can reach a top-level `Scene`/`WindowGroup` state change that is not explicitly enumerated in the PR-approved feature-flag matrix.
- **AU-3 CLI-elimination fallacy:** removing `mirage` CLI or RT's keyboard/console flows as a "cleanup." *Detection:* any PR touching `mirage` CLI parser surface (`src/miragev10/**/cli*`) with reduced flag set; any PR deleting console (`Developer Console` ⌘⇧D) test personas.
- **AU-4 repo-cide fallacy:** interpreting "merge" to authorize deletion/archiving. *Detection:* any `git push --delete`, `gh repo archive`, remote URL rewrite, or force-push on shared branches recorded in the audit log. Every destructive `$GIT_*` operation requires owner countersign in the merge log — see §4 escalation.

**S0-ES-3 (ownership boundary vector, formalized):** RT owns the macOS app lifecycle: the `NSApplication`/`Scene`/`WindowGroup` surface, navigation stack, library import (`library.json` debounced pretty-printer loop, `library-state.json` sidecar), reading sessions and page-turn timing micro-history, `AnalyticsCache` (memoization of five whole-library reductions behind a mutation-epoch counter), goals/achievements (25 kinds), `.readingarchive` v1, weather SQLite inventory, Sentinel journal, `PersistenceWriter` utility-queue ownership, and `DataMaturityEngine` evidence floors with injected clock. Mirage owns: SQLite `ledger@0.0.10` (m0001–m0016 migrations; append-only claim history; CHECK-constrained vocabularies; crash-safe transactions), content-hash unit identity, browse, `analyze_edition` batching with screening cache and no-change outcomes, Stage E candidate/accepted gate, identity resolution with evidence-gated merges, spoiler eligibility via deterministic closure (fail-closed), graph projection with canonical content hashes, D-010 corrections overlay (append-only, reversible, never-truth-promoting P12), NDJSON serve/sidecar, browser UI at `127.0.0.1:8747`, and the demoted Rust core (ADR-0002). **Functional invariant:** RT and Mirage have **disjoint write-sets**, the sole permitted cross-domain write being Mirage's ledger writes under Mirage's transaction authority; RT's bidirectional writes are contractually limited to the transport channel. Any diff that grows either write-set without an approved ADR is rejected at review-time by automation (ESCALATED-DESIGN).

**S0-ES-4 (release principle escalated to staged monotone progression with per-transition proofs):** the release principle becomes a Kripke-style monotone system over configuration states `S ∈ {PRE, BOUNDARY, GATED, EXPANDED, PACKAGED, SHIPPED}` with strict promotion preconditions:
- `PRE → BOUNDARY`: baselines re-verified at pinned SHAs (§6 escalation), ADR-2 (transport) approved, defect triage gate §8 satisfied, protocol contract published and counter-interpreted (no edits), enumerated fake-transport test suite green.
- `BOUNDARY → GATED`: real-sidecar lifecycle (launch/handshake/version pin/stream framing/redaction) proven against a disposable DB; failure-injection suite (crash-during-query, crash-during-mutation, partial frames, oversized, stderr flooding, kill -9) passes; MainActor audit (Appendix F) shows no blocking path ≥ 5 ms on UI actor.
- `GATED → EXPANDED`: one-book import + identity mapping + cursor adapter + fail-closed spoiler query registered as four, separately revertible PRs; each has a reproducing regression bundle; end-to-end fake-transport smoke suite green.
- `EXPANDED → PACKAGED`: clean-machine prototype (no dev tools) builds/signs/launches the app with the runtime embedded per ADR-3; CI has ≥ 5 independent failure-visible gates; entitlement/Info.plist reconciliation complete (Appendix K).
- `PACKAGED → SHIPPED`: rollback rehearsal evidence (Appendix J release reheisals) recorded; owners sign the manifest of SHA `hash(artifact)`; privacy review closes with zero network-access deltas vs. baseline.

Each promotion is a commit of the configuration tree (not a verbal claim) and is evidence-gated — no state promotes on word of mouth, only on recorded evidence logs.

**S0-ES-5 (integrity of the "0.2 non-goals" list, hard-wired as executable policy):** every non-goal in §0.2 escalates into a **named contained measure** with a triggering test:
- NG-1 "no RT UI swap": binds SwiftUI navigation mesh; Mirage components are countable **at most one** `Tab`-or-sheet entry point.
- NG-2 "no RT persistence rewrite in this merge": any diff touching `library.json` schema (additive or not) is out of scope, keyed on a diff test: no new top-level Swift structs serialized into library.json within the MirageIntegration module boundary.
- NG-3 "no ledger-to-library.json consolidation": a runtime assertion in RT (Debug) that MirageIntegration never writes to the RT path except through the approved `MirageCallLog` (itself RT-owned, one JSON shot per operation) — and never in Mirage source, where an `import ctypes`/`fopen` against RT paths is a review-blocker.
- NG-4 "no library.json inversion": RT must not read Mirage tables; enforced by absence of any import of `sqlite3`/`SQLite` in RT integration modules, and by a PATH-level check in the packaging smoke test: bundle-size audit shows no `.sqlite3` file present in RT's container other than the pre-existing weather store, and no `ledger` path in RT's Application Support dir.
- NG-5 "no on-import analysis fan-out": RT integration hook list must be **empty** for `onLibraryLoad`, `onPageTurn`; only `onExplicitUserImport`, `onExplicitUserQuery` can enqueue, both pinned behind user gesture in the UI (an idempotent guard test asserts no queued analysis is emitted on file-change events).
- NG-6 "no title-only auto-mapping": RT-side mapping engine requires evidence class ≥ fingerprint match; title-similarity ≥ 0.95 must not escalate (unless the user explicitly confirms override, recorded with a signed rationale).
- NG-7 "no guessed cursor": any integer converted from page-fraction/percentage must raise `CU-0001` at RT before delegation, never be sent to Mirage; cursor representation and validity is Mirage's contract and RT is a **pass-through** (see §21 Appendix I).
- NG-8 "no auto series": any edit entry point that would create a series row without a blocking user gesture is disallowed; RT's adapter must always surface `--series-declare` behind explicit UI step and Mirage-side confirmation.
- NG-9 "no auto-accept corrections": corrections flow only through Mirage's D-010 overlay API; RT may never merge user suggestion strings into RT-local claims.
- NG-10 "no repo cede": deletion/archive duty must have an explicit merge-log entry with a written owner signature, not an automation artifact.
- NG-11 "no green-suite-as-safety claim": any release note, README update, or commit message claiming "safe"/"verified" **without a signed evidence bundle** is a review-blocker and reverted with cause.
- NG-12 "no evidence substitution": documentation audits (Appendix D-like scans) can never be used as a substitute for the SOURCE-VERIFIED record; evaluation of verification-grade is only via `(commit SHA, environment, method, result记录台账, reviewer)` tuples.

**S0-ES-6 (required outcome, quantified):** a feature-flag-gated, product-owner-controllable `Mirage` surface where: (a) with flag off, binary size delta ≤ 2 MiB (escalated budget, ADR-2); ZERO process spawns; ZERO sqlite/pytest imports; ZERO ledger reads; (b) flag on: cold-start handshake ≤ 800 ms p95; handshake version assertion must exactly match RT's pinned contract hash, else the client masks feature state as `protocol_incompatible` and disables user-visible entry beyond a read-only status row; (c) disabled/unavailable: 100 % of existing RT flows must remain reachable with ZERO Mirage touches per MainActor-timeout audit; (d) crash isolation: kill -9 of sidecar during a mutation request MUST leave the RT persistence strata functionally unchanged (both SHA-256 of all seven RT storage strata and post-restore collection counts), and must not leak the sidecar process (single-instance supervision via `pgrep -n` + supervisor PID file; lsof-verified).

<a id="sec-21-2"></a>

### 21.2 Escalation of §1 — Baseline evidence hardening and reproducibility lattice

**S1-ES-1 (evidence lattice as a typed register):** each baseline fact carries a typed record `{id, claim, source: README|SOURCE|TEST, verified_by: null|{commitSHA, env, cmd, method, reviewer, ts}, confidence: {0..1}, supersedes: []}`, and the entire playbook conversion from README-REPORTED → SOURCE-VERIFIED is a monotone, review-gated transition that never deletes history — a violation of §1.3's "no silent promotion" doctrine. Escalation of §1.1: RT's build is pinned not merely at "Xcode 27.1" but at tuple ⟨Xcode 27.1 (build 999), macOS SDK 26.5, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, deployment target 26.5, arm64, framework profile Debug, language mode Swift 5⟩ — a tuple hash written into the merge log so that any future re-run with a different SDK must be flagged as a **non-reproducible baseline** (the comparison rule: identical SHA-256 of `xcodebuild -version`, `xcodebuild -showsdks`, `swift package describe` serialized as a canonical JSON). The 0.68 test-suitability score decomposes into four regressable dimensions — defect-depth 0.9, breadth 0.4, hygiene 0.65, infrastructure 0.7 — each of which the integration must not regress by more than 0.05 in any dimension at any merged commit, measured on the same rubric with a CI-rendered rubric artifact (ESCALATED-DESIGN).

**S1-ES-2 (RT defect taxonomy → failure-mode engineering classes):** each NEW-DE-* escalates from "defect label" to a **failure-mode class** bound to one or more tests and to a specific containment mechanism class (ordering, capability, epoch) — the full mapping table:
- **NEW-DE-1 (PersistenceWriter ordering window):** class = *ordering-gap {unsynchronized encode→write pairs traversing a common gate}*; suspicion surface = any `(encode off-queue) → (performWrite gate)` pair lacking a shared fence; authoritative repair = restore FIFO serialization by binding encode into the same serialization domain as write, or by hash-stamped generation counters with resync-on-mismatch policy; regression = a two-routine interleaving test invoking two concurrent PersistenceWriter submissions with an injected mid-encode sleep; the unit test's assertion reads both content pages' wall-clock monotonicity and asserts last-writer-wins-per-mutation-epoch, never in-betweens. Cross-cuts NEW-DE-1 with MirageIntegration: the adapter MUST NOT enqueue any utility-queue writes from sidecar callbacks; a callback only transitions in-memory state and re-enqueues via PersistenceWriter.
- **NEW-DE-2 (embedded-cover legacy field in Explore/spatial views):** class = *stale-view-bindings {view-layer reads of a superseded model key}*; the well-known persistence bug class in SwiftUI `@Observable` store migration where a rename `book.coverImage` is not retroactively reflected in all card views. Integration relevance: new Mirage views are REQUIRED to use the canonical key; CI view-lint asserts no string literal `coverData` in new view code (ESCALATED-DESIGN).
- **NEW-DE-3 (idle→reading inflation under 24 h crash-relaunch, Sentinel threshold imperfection):** class = *evidence-floor mismatch { Sentinel repair floor (>24 h) lies above the onset hazard (<24 h)}*. Relevant to integration: when Mirage analysis is slow, users may background RT; session-close telemetry with crash+relaunch can pollute inferred activity contexts. Integration must touch `session lifecycle` fingerprints in a way that does not widen this hazard; if fields change in lieu of FIX, require ADR-9 marked with impact analysis.
- **NEW-DE-4 (AnalyticsCache no-day component):** class = *cache-key under-derivation {missing date-partition dimension in key schedule}*. Integration relevance: any Mirage-mediated analytics that extend `AnalyticsCache` MUST use `(epoch-day, book-vol, k-reductions)` key tuples and never omit date partition; a fixed-unit property test asserts a cache-invalidation before midnight-crossing (injected clock).
- **NEW-DE-5 (onboarding import bypasses facade/duplicate check; goal commit overwrites)**: class = *bypass-path {import entrypoint not routed through import-intelligence facade, duplicate check, and guarded goal commit}*. Integration relevance: the RT-side "import into Mirage" workflow MUST be routed through the same facade and duplicate-check that RT's onboarding path now violates. Shared-fix policy (ESCALATED-DESIGN): PR-5 must not proceed until RT-side facade bypass is resolved or a DECISION-REQUIRED ADR documents why the two paths are confidently independent (e.g., Mirage import validates against ledger, not RT's goals).
- **NEW-DE-blockers (icon/entitlements/plist)**: each is a packaging-grade invariant under §14 escalation.
- **Known Climate issues (row-level confidence = 1.0; location-denied New York; noncancellable RSVP; 12–15 % dead-code)**: all remain open, tracked in their own fixes; each integration PR must declare in the PR body which, if any, defects it *must not* mask (e.g., an integration view that calls weather must not "accidentally" fix row-level confidence without a separate fix-log entry).

**S1-ES-3 (Mirage ledger strata + immutability vector):** the Mirage side has its own ironclad invariants that RT must not weaken:
- `ledger-is-truth, graph-is-projection` — any RT pressure that tempts off-ledger shortcuts, e.g., "just read rows for the summary" or "remember that claim in RT" violates the ledger-first rule and is disallowed.
- `one analysis job at a time, 8 GB budget` — the sidecar must enforce single-flight analysis via an internal mutex/lease; if RT requests overlapping `analyze` ops the second must yield a typed `busy` envelope, not a race.
- `deterministic classical extraction by default` — any request path that would introduce an LLM/network stub must fail the contract version handshake (a capability bitmap must explicitly assert `NO_EXTERNAL_INFERENCE`), else the adapter disables the request.
- `fail-closed spoiler eligibility` — RT can only *lower* spoiler eligibility requests (declare stricter subjective cursor), never *raise* them; an API call cannot pass "assume read" semantics without evidence-gated declaration in Mirage's state vocabulary.
- `append-only claim history, reversible D-010` — RT must not expose a "delete claim" UI equivalent; Mirage's own `--remove-book` is the only supported destructive surface, and RT can only invoke it with user confirmation and a pre-flight `Export` that surfaces per-table counts (see §21 escalation of `--remove-book` semantics).

**S1-ES-4 (commands retained as candidate procedures only):** the baseline commands in §6.2/§6.3 and Appendix A are **candidate engineering procedures**; no automated agent session is authorized to run them (per 21.0 charter). They are recorded here unchanged for the human engineering pipeline; each final execution requires a recorded `(repo, SHA, env tuple, operator, result log)`. Note that `PYTHONPATH=src python3 -m miragev10 --init-db --db mirage.sqlite3 --schema-version` forms an **exploratory DB contract** — any executed result must be against `mktemp -d`-scoped DBs, never a user's real ledger; this is already doctrine in §6.3 and is escalated with a mechanical schema-check command (ESCALATED-DESIGN).

<a id="sec-21-3"></a>

### 21.3 Escalation of §2 — Integration contract, transport, protocol, and feature behavior

**S2-ES-1 (facade grammar, RT-side):** the provisional `MirageIntegration` module must present a **typed closed grammar** to SwiftUI. Minimal composite signature sketch (ESCALATED-DESIGN, struct names are proposals):

```swift
@MainActor final class MirageFeatureStatus: ObservableObject {
    public private(set) var state: MirageAvailabilityState
    // states: disabled, notInstalled, starting, ready, busy, requestFailed,
    //         protocolIncompatible, dataNeedsAttention, stopping; + transient `cancelling`
    public func enable(_ cfg: MirageConfiguration) async throws
    public func disable() async  // contract: no spawn, cancel all in-flight, graceful shutdown
    public func statusRefresh() async
}

protocol MirageClientProtocol: Sendable {
    func handshake() async throws -> MirageHandshakeEnvelope
    func listEditions(scope: MirageLibraryScope) async throws -> [MirageEditionSummary]
    func importEpub(access: MirageAuthorizedFileAccess) async throws -> MirageImportReceipt
    func analyzeEdition(_ id: MirageEditionID, policy: MirageAnalysisPolicy) async throws -> MirageAnalysisReceipt
    func projectAt(cursor: MirageCursorRef) async throws -> MirageProjection
    func series(ops: MirageSeriesOperations) async throws -> MirageSeriesReceipt
    func declareReadingState(_ d: MirageReadingDeclaration) async throws -> MirageDeclarationReceipt
    func health() async throws -> MirageHealthEnvelope
    func shutdown(grace: Duration) async throws
}
```

All envelope types are `Sendable`, `Codable`, structurally validated decoders that **reject unknown top-level fields** in strict mode and **reject unknown status enums** in all modes (unknown enum ⇒ `TC-VALIDATION-002` error, never a silent default — fail-closed symmetrical to both sides). Every operation carries an `id: UUIDv7` (timestamp-ordered for log correlation), a `protoVersion: SemVer-pinned`, `deadline: Duration`, and `retryPolicy: MirageRetryPolicy` that disallows blind retry of non-idempotent mutations (§2.4).

**S2-ES-2 (no raw JSON, no path leakage, no shell):** three hard prohibitions with review-lint equivalents:
- UI must not construct raw NDJSON strings; enforced by making the encoder internal to `MirageTransport` and by denying `Codable customStringRepresentation` usage in feature code.
- No absolute paths inside envelope bodies beyond the minimum path the protocol requires; titles/book contents never passed over the transport (violating this would leak user literary history into logs).
- Process spawn only via a hardened array-argument API (`Process(executableURL:arguments:environment:)` with a **pinned absolute executable URL resolved through Bundle** and **no inherited `PYTHONPATH`/`PYTHONHOME` env leakage**; cross-check with Apple `sandbox-exec`/app-sandbox practicalities — see Appendix K).
- `Process` launch MUST NOT traverse `$PATH`; the runtime must be invoked by URL with `isExecutableFile` + codesign validation (SHA-256 pin, ad-hoc signature compare at start/dispatch) — a silent fallback to any other `mirage` on `$PATH` is a **violation** of S12-ES.

**S2-ES-3 (transport candidate lattice — decision constraints):** the four alternatives from §2.3 escalate to a decision matrix (values are review inputs, not promises):
- **Managed NDJSON sidecar (leading candidate, ADR-2 default if evidence supports):** strengths: same-process-isolation-with-streams, stdlib-first transport, matches documented `mirage --serve`/sidecar examples; failure mode surface: pipe fragmentation, encoding/trailing newline variance, zombie/hung process, stderr filling, selective cancellation. Mitigations mandated in Appendix E.
- **In-process Python embedding:** risk set = dynamic-lib validation vs. hardened runtime (`com.apple.security.cs.disable-library-validation` is NOT granted by default), CPython C-API memory/exception handling at C-callsite, GIL contention during EPUB parse could starve Swift cooperative pool (must never run on the SwiftUI MainActor), difficulty of notarizing CPython dylibs, arch-fat binary concerns (arm64 + x86_64 parity), version-pinning brittleness vs. `ledger@0.0.10` migrations. Requires ADR with an arch and packaging study; default-disfavored absent SIGINT-level requirement.
- **Local HTTP/browser HTML surface (`mirage --serve-web` at `127.0.0.1:8747`):** threat set: DNS rebinding against localhost; other-user processes on a shared Mac reaching the same port; port squatting; origin confusion (UI served from ledger vs. external HTML frames); missing auth; mixed-session confusion; unbounded background analysis from a rogue local script. These are classed **HIGH** in the STRIDE matrix (Appendix K); a browser surface in RT's product path is second-preferred and requires user-visible local network feature disclosure.
- **Per-request CLI invocation (`python -m miragev10 --db …` per query):** adds 100s-of-ms process cold-start, breaks keep-alive, complicates cancellation semantics mid-`analyze`; acceptable only for smoke tests; product-request path disfavored.
- **Swift reimplementation (dual-truth heresy):** violates §3.1; categorized as forbidden even for "read-only summaries" because any duplicated intent reconstitutes the ledger-vs-graph split.

**S2-ES-4 (protocol contract, bidirectional, v1 proposed envelope):** the wire layer uses **exactly one compact JSON value per LF-terminated line, UTF-8 with no BOM, source-continuous Byte-transports (pipes) only**. Envelope shape (ESCALATED-DESIGN, ADR-2 subject):

```json
// request
{"v":"1.0.0","id":"<uuidv7>","op":"embedding.project_at","params":{…},"deadline_ms":5000,"idem_key":null}
// response (success)
{"v":"1.0.0","id":"<echo must match>","ok":true,"result":{…},"prov":{"ledger_mschemas":[…],"cursor":"…","source_hashes":[…]}}
// response (typed error)
{"v":"1.0.0","id":"<echo>","ok":false,"err":{"code":"TC-CURSOR-0101","msg_safe":"…user-safe text…","detail":"…redacted…","recover":false}}
```

Framing MUSTs: (1) the JSON serializer must be configured to escape U+2028/U+2029 even though JSON permits them raw — a raw U+2028 must not appear un-escaped because it is legal inside JSON strings and is byte-safe in UTF-8 but ambiguous to simple LF-framers that also split on exotic terminators; (2) the transport MUST treat any `\"`-escaped newline-in-string as legal and only terminate on a bare `\n` **at a structural top-level boundary** — a leniency scanner must track in-string state, which is why the parser is byte-level with an in-string flag; (3) a `NUL (0x00)` byte or invalid UTF-8 immediately errors `TC-FRAME-0014` on the current line and does **not** kill the transport unless 3 consecutive `TC-FRAME-001x` occur (rate-limit); (4) response limits default: request ≤ 1 MiB, response ≤ 16 MiB, stderr ring-buffer 256 KiB with rotation-drop accounting, and (5) no broadcast of underscores-leading fields (private), per strict-field convention (see Appendix E for the error-code registry).

**S2-ES-5 (lifecycle ladder):** `pending → spawning → handshaking → ready → busy → draining → stopped{|failed,crashed,forcekilled}` with hysteresis timers — e.g., after 3 crashes within 60 s, the supervisor MUST enter `dataNeedsAttention` and disable auto-restart until the user explicitly re-enables; backoff must be exponential with jitter (200 ms → 1.6 s → 6.4 s → 25.6 s → disable), preventing the notorious crash-loop-cycle UX.

**S2-ES-6 (cancellation semantics, precise):** cancellable queries retire by: (1) Swift task cancellation → transport issues `<op>.cancel` with the request's `id` (requires a well-defined sidecar cancel contract — VERIFY in docs/embedding.md); (2) if the sidecar lacks cancel semantics, RT still drops the pending envelope but continues reading stderr for a bounded `draining` period (default 2 s) before SIGTERM; (3) SIGTERM → wait 2 s → SIGKILL, with any process-group kill scope applied locally; (4) RT's own persistence is never blocked by cancellation, and no RT-side "analysis done" banner is emitted unless a valid success envelope arrives.

**S2-ES-7 (feature states, exhaustive):** at minimum the UI exposes: `disabledByUser, notInstalled/runtimeMissing, runtimeIncompatible(protoHashMismatch), starting, ready, busyAnalyzing, refreshFailedOnce, requestFailed(kind), protocolIncompatible, dataNeedsAttention(kind), stopping, stoppedBySystem, degradedLocalOnly` — each with a mandatory user-string, and state diffs are armed only via the typed client; no view constructs a state from raw stdout.

**S2-ES-8 (UI accessibility, escalating §9.4):** the feature entry point must (a) appear in VoiceOver order after library navigation, (b) expose >44 pt hit targets consistent with RT's existing patterns, (c) never render full EPUB-extracted text or raw claim text without passing through the spoiler-safe projection summary; (d) large result sets are truncated in UI at ≥ 200 items per page with explicit "load more" semantics; (e) UI must surface `busy: cancel available / cancel unavailable` distinctly.

<a id="sec-21-4"></a>

### 21.4 Escalation of §3 — Data ownership, identity, and synchronization

**S3-ES-1 (storage strata manifest):** a pinned registry of the seven RT-owned strata and their write-path owners:
| Stratum | Path (fallback: verify at source) | Format | Owner | Write model |
|---|---|---|---|---|
| `library.json` | `~/Library/Application Support/johan.Reading-Tracker/library.json` | debounced pretty-printed JSON monolith (1) | RT `PersistenceWriter` | utility-queue serialized, hash-gated topo rotation |
| `library-state.json` | same dir | goals/achievements/collections sidecar | RT | debounce-coalesced |
| weather store | keyed SQLite | 26.5-snapshot rows | RT | keyed, row-level confidence currently hard-coded 1.0 |
| cover store | content-addressed files | `<sha256-prefix>/<blob>` | RT | immutably hashed on write, NSCache-fronted |
| backups | `Backups/` depth-10 rotation | hash-gated copies | RT | committed only when content hash differs |
| `.readingarchive` | export/import archive | v1 format | RT | ZIPFoundation 0.9.20 pinned |
| sentinel journal | `sentinel-journal.jsonl` | append-only JSONL, 500-line rotation | RT Sentinel | append-only, rotation-gated |

Mirage-owned strata: `ledger.sqlite3` (+ any `-wal/-shm` if journal_mode=WAL — VERIFY), extraction temp dir (cursor-scoped, single-flight-leased), optional browser UI cache under Mirage's own CWD. **Disallowed:** RT-side `sqlite3` read of the ledger; Mirage-side writes to any RT strata; both must be caught in review by a path-ownership check (ESCALATED-DESIGN).

**S3-ES-2 (identity mapping formal contract):** the mapping is stored **only on the RT side** in its own stratum (ESCALATED-DESIGN — path: `~/Library/Application Support/johan.Reading-Tracker/mirage-integration/mapping.json`), with fields `{rtBookID, mirageBookID, mirageEditionID, contentSHA256, declaredState, cursorAnchor?, evidence{method,ref,ts}, state{unlinked|proposed|confirmed|stale|ambiguous|failed}, schemaVersion, overrideRationale?}`. Mapping state machine:
1. `unlinked → proposed` on fingerprint-match evidence.
2. `proposed → confirmed` on user admission OR strong-content rule approved by ADR.
3. `confirmed → stale` when Mirage `edition` fingerprint differs from stored, or RT book content mutates (file change detection via stat + SHA recompute debug gate).
4. `confirmed → ambiguous` when > 1 candidate editions tie at fingerprint-level; requires user resolution.
5. `any → failed` on protocol-error with `idem_key` logged.
**Impossibility rule (formal):** RT must never *infer* `mirageEditionID`. A `mirageEditionID` is a Mirage-issued opaque token, obtained ONLY in an `import_epub` or `list_editions` envelope; any value RT synthesizes to "make UI work" is an invariant violation, code `ID-SYNTH-9001`.

**S3-ES-3 (import workflow, formal staged):** `import` escalates to the following closed set:
- **W1:** RBAC check — RT holds user-granted access to the EPUB via security-scoped bookmark; Mirage NEVER escalates its own sandbox privileges.
- **W2:** SHA-256 pan-EPUB — preflight; if RT's local book differs from disk file (file mutation since import into RT), the adapter marks the candidate `stale` and requires re-confirmation before invoking Mirage.
- **W3:** dispatch envelope `import_epub` returned to RT with receipt `{mirageBookID, mirageEditionID, fingerprint, units_count?, warnings[]}`.
- **W4:** post-receipt validation — RT recomputes local fingerprint and compares to the receipt; mismatch → `ID-FINGER-7001` and mapping stays `proposed`.
- **W5:** persist mapping via RT's own atomic write path (never Mirage's ledger); compute a commit-receipt log line that references both sides' identifiers.
- **W6:** analysis-trigger policy: `user_initiated` or scheduled-batch only; **never** displaced by page-turn events. The **page-turn invariant**: no envelope class sourced from a `CGEvent`/scroll/turn callback.
**Duplicate recovery policy:** duplicate-import of identical content must be an idempotent no-op (`already_imported` receipt) for unchanged sources. RT must never append a second mapping row for the same `contentSHA256`; a repeated import with changed content is escalated to user review with a diff-proof summary before any re-import confirm.

**S3-ES-4 (cursor algebra, pointer):** the §10 escalation formalizes the cursor mapping; in the §3 layer, RT's responsibility is bounded to: the RT-book → Mirage-edition mapping (S3-ES-2) and *whether* a cursor is *decodable at all*. The conversion to a "Mirage cursor" must be defined as one of the Mirage-visible declaration vocabulary forms (`read`, `reading@N`, `unread`) — a formal `RT→Mirage` platform-lexeme transduction — verified against `src/miragev10/domain/**` state enums at the pinned commit. If no decodable mapping can be proven (e.g., RT's bookmarks are PDF page indices, Mirage's are EPUB unit indices), the adapter MUST return a typed `CU-REQUIRE-1001` and surface a UI affordance to request the cursor explicitly from the user, or the operation spends **no** spoiler-sensitive budget.

**S3-ES-5 (series semantics):** the instructive phrase "detection proposes, you dispose" escalates to: the series layer passes *candidate lists* from Mirage and *declared confirmations* back; auto-link risk bound is the `AU-4` non-goal; pooled breakdowns must always wrap the top-level result with per-book attribution `{book_id, edition_id, state, provenance}` — Mirage returns this; RT must not flatten away book attribution to top-level cells in backgrounds, headers, or summaries.

**S3-ES-6 (corrections overlay elevation):** RT may *render* overlay state; it may **never** mutate. The RT-side correction UI contract: (1) a "propose correction" form (ESCALATED-DESIGN) writes to Mirage's D-010 submission via the sidecar envelope `overlay.propose` (VERIFY the actual operation name in docs/embedding.md); (2) RT displays state `pending|accepted-under-Mirage-rules|rejected|reversible-undo-expanded` and always retains an "Undo submission" affordance when the overlay supports undo; (3) RT never writes to Mirage's ledger directly. If the overlay submission fails, error banner text is shown; RT does not retry automatically (non-idempotent).

<!-- addendum escalation pt1 end -->

<a id="sec-21-5"></a>

### 21.5 Escalation of §4 — Repository governance, Git safety, and supply-chain custody

**S4-ES-1 (custody chain of the two canonical objects):** each repository is treated as a **custodial artifact** with a formal custody record: `{canonical_origin_URL, owning organization, default_branch, pinned_HEAD_SHA_at_baseline, tag_manifest, release_channel, protected_branch_rules, required_checks[], CODEOWNERS_mtime, LFS_enabled, signed_commit_policy, external_referents[] (links from docs/CI/registries that embed the URL)}`. The integration workstream **may not temporarily become the owner** of either record. After every phase boundary, the custody record must be re-diffed against the baseline capture; any drift (new default branch, force-push, deleted tag, changed required check) is a §5.3 stop condition, not a footnote.

**S4-ES-2 (repository integrity ledger, per §4.2):** the §4.2 inventory escalates from "record things" to a signed manifest with re-verification semantics:
1. `refs/heads/*` full listing + re-list at every phase transition (destructive-history drift can appear as branch vanishing).
2. `refs/tags/*` with signer identity for annotated/signed tags.
3. `git log --first-parent -20` for each of `main`/`master`/default plus the integration branch — captured as canonical evidence lines.
4. Secrets inventory: names/owners/purposes/rotation only; values never enter the playbook, shell history, CI logs, test fixtures, or issue bodies. Secret *presence* in a diff is a review-block (regex lint + `gitleaks`-class scanner in CI, ESCALATED-DESIGN).
5. Actions workflows: enumerate triggers (`pull_request`, `pull_request_target`, `workflow_dispatch`, `schedule`) — `pull_request_target` from forks requires explicit write-token hygiene review.
6. Package registries, release automation, Pages, submodules, Git LFS, webhook targets, deploy keys, environments (with protection rules), branch deploy targets.
7. Ignored/generated artifacts: `graphify-out/`, `codegraph-out/` — verify via `.gitignore` content AND `git check-ignore -v` against actual paths; do not commit regenerated outputs merely because they exist on disk (43 MB RT disk footprint, ~30 MB regenerable per README).
8. Untracked-file census at baseline: `git status --porcelain` recorded verbatim in the merge log.

**S4-ES-3 (Git operation risk classes with pre-op contract blocks):** every elevated Git operation is binned into one of three classes, and class membership dictates the mandatory pre-operation block written into the merge log *before* execution:
- **Class Ω (irreversible/published-history):** `push --force` (with or without lease), `filter-repo`/`filter-branch`, tag deletion on origin, remote rewrite, repo archive/delete, `gh repo edit --visibility`. Preconditions: both owners' written countersign; recovery rehearsal on a disposable clone within the last 30 days; published SHA fan-out check (forks, package registries, citation links); post-op re-verification of ref ladders. Execution requires a two-person rule.
- **Class Δ (destructive to local state):** `reset --hard`, `clean -fd`, branch deletion, stash drop, rebase of a shared feature branch. Preconditions: working-tree census recorded; reflog-anchor captured (`git rev-parse HEAD` logged); applicable only to non-default branches or trees passing the "no unexplained dirty state" gate.
- **Class Π (additive):** new branches, annotated tags on private branches, PR creation, review comments. Standard review gates apply.
No operation class may be executed merely because a copied script or prior session transcript contains it (§4.3 item 9 escalation: *script provenance audit* — every pasted command's effect is re-derived from `man`/`--help` and the actual tree state before any run; un-understood commands are quarantined, paraphrased, and re-derived).

**S4-ES-4 (monorepo rehearsal protocol, if §4.4 is ever approved):** the §4.4 layout is illustrative-only; its escalation is a **do-simulate-then-act** ladder using disposable clones, never the canonical remotes:
1. Build the rehearsal environment: `git clone --mirror` both repos into a scratch workspace; compute pre-move relrefs: `git ls-files`, `git count-objects -v`, LFS object ladders (`git lfs ls-files` totals + collectible sha256s).
2. Two rehearsal runs minimum: (a) `git subtree split`/`filter-repo` path-rewrite on RT to `apps/reading-tracker-macos/**`, (b) Mirage to `components/mirage-runtime/**` — each followed by ref-tree diff (`git log --graph --all` compare) proving zero lost commits, zero rewritten unintended paths, and preserved authorship/committer metadata bit-for-bit for retained history.
3. Post-migration build proofs in the rehearsal tree: RT's Xcode project opens and builds (path references inside `.xcodeproj/project.pbxproj` are notoriously absolute/relative-sensitive — verify `fileSystemSynchronizedGroups` or known-region patterns against the actual project format), Mirage `python3 -m unittest discover -s tests` + `cargo test` (Rust) resolve from the new root, script shebangs/paths (`PYTHONPATH=src` assumptions, `scripts/*.py` internal path constants) verified by static scan + one execution each against disposable DBs.
4. Remote/CI cutover rehearsal: update workflow `actions/checkout` targets, package-registry source URLs, Pages sources, webhook payloads, submodule URLs, and RT-side pinned dependency lockfile references — then simulate consumers (a second clone fetching fresh).
5. Rollback window: originals stay intact and read-only until the post-migration acceptance gate (§4.5 last three items) is countersigned; deletion remains a Class Ω operation reserved as a *separate later decision*.

**S4-ES-5 (backup recoverability proof, formalized):** §4.3 item 4/5 escalates to: a backup is *recoverable* iff (a) `git clone` from it yields all required refs (`git for-each-ref` diff vs. origin = empty for required sets), (b) LFS objects resolve (`git lfs fetch --all` succeeds from the bare mirror), (c) at least one file from the earliest required commit checks out byte-identical (`git diff <old-sha> -- <file>` empty after checkout from the mirror), and (d) the mirror restore was timed and the restore procedure documented. A working-tree ZIP satisfies none of these and is classified "material convenience," not backup. Interval: refresh before each phase promotion; a mirror older than the last Class Ω/Δ op on that repo is stale by definition.

<a id="sec-21-6"></a>

### 21.6 Escalation of §5 — Governance topology, scope calculus, and stop-condition lattice

**S5-ES-1 (RACI escalation with authority-arbitration rule):** the six roles (RT owner, Mirage owner, integration lead, test/quality owner, security/privacy reviewer, release/operations owner) become a **decision matrix with conflict-resolution semantics**: domain owners hold *invariant veto* over their strata (RT owner: SwiftUI behavior, persistence, app lifecycle, reading semantics; Mirage owner: ledger, ingestion, identity, extraction, projection, spoiler policy, D-010, protocol). The integration lead coordinates but cannot override a veto. Test/quality owner holds *release-blocking authority* over gate integrity (a gate that passes without its recorded evidence is void, not waivable). Security/privacy reviewer holds *escalation authority* (a security concern cannot be "outvoted"; it can only be *mitigated, accepted in writing, or blocked*). Release owner holds *artifact-binding authority* — release exists at the SHA/artifact tuple they sign, nowhere else. Small-team role overlap is permitted; **authority entanglement is not**: the same individual approving both their own gate and the veto over it must record a self-review note, and any stop-condition touching a role they occupy must be escalated to the other domain owner.

**S5-ES-2 (scope as a typed contract, not prose):** the §5.2 goal statement becomes a machine-checkable scope contract: an allowlist enumeration of (a) modules RT may add (`MirageIntegration` package/target namespace), (b) Mirage surfaces RT may call (closed op set from §7.2's inventory), (c) strata RT may write (RT-owned only, per S3-ES-1), (d) flags/config surface (one enable/disable control + per-book context actions), (e) CI job additions, and a **deny-list of everything else** (all §0.2 non-goals, all deferred roadmap items: normalized SQLite core, store split, Swift 6 strict, BCE V3 UI, CloudKit, App Store formalities). First-milestone scope is frozen to: entry point, process lifecycle, handshake, **one read-only query path**, identity mapping, cursor-safe fail-closed behavior, failure isolation, integration tests. Every PR must carry a machine-readable scope declaration (a YAML front-matter block listing touched allowlist entries, ESCALATED-DESIGN) and a reviewer-manual check that the diff matches it — hidden scope creep is treated as an unexplained dirty state.

**S5-ES-3 (stop-condition lattice with severity taxonomy):** §5.3's stop conditions are escalated with formal parameters and escalation cutoffs, each bound to one or more detection tests:
- **SC-01 (source identity un-establishable):** symptoms — repo URL unreachable, HEAD SHA unstable across two consecutive reads, dirty-tree census unexplained. Trigger: >0 occurrences. Action: freeze; integration lead records evidence bundle; RT/Mirage owners decide commit/stash/exclude. Never discard work to fake cleanliness.
- **SC-02 (unattributable baseline failure):** any baseline test failure on the pinned SHA that cannot be attributed to (environment delta ∨ known-defective ∨ flaky-with-provenance). Flaky classification requires ≥2 reproductions + a root-cause hypothesis + a quarantine ticket with an expiry date, not "pytest rerun until green."
- **SC-03 (protocol/lifecycle un-establishable):** sidecar handshake semantics not derivable from docs/embedding.md + sidecar example + CLI parser + service tests. Action: BLOCKED — write the Swift client only after the contract draft is countersigned.
- **SC-04 (unreviewed persistence mutation):** any diff touching either system's schema (JSON shape, SQLite DDL, migration list) without an approved ADR + tested migration plan. Zero tolerance.
- **SC-05 (spoiler boundary violation):** any query path that can return content beyond a confirmed cursor under any injected failure combination from §13.4's catalog. Severity: release-impossible until root-caused; this is the only condition that also voids previously passed gates (via re-run of the spoiler test suite).
- **SC-06 (unknown-vs-verified mapping indistinguishable):** RT cannot classify a mapping's evidence class. Trigger: >0 in the integration test suite.
- **SC-07 (ambiguous-mutation repetition):** crash/timeout after a state-changing request that cannot be safely reconciled via idempotency keys or read-back verification. Action: the operation is disabled (not retried) until the reconciliation design is approved.
- **SC-08 (RT degradation when Mirage absent):** any RT flow requiring (not merely benefiting from) Mirage. Trigger: UI test failure of §13.3 case 1/3/14.
- **SC-09 (unauthorized secrets/permissions):** a build/release step requiring credentials the release owner has not pinned to the least-privilege environment.
- **SC-10 (migration without rollback):** any migration whose rollback procedure has not passed a rehearsal on disposable data.
- **SC-11 (unapproved dependency/network/job/collection):** any new `Package.resolved` entry, Cargo/lock delta, socket syscall in a runtime trace, background timer, or data-collection path appearing post-baseline without an ADR.
- **SC-12 (normative contradiction):** implementation contradicts docs/literary_intelligence_mission_statement.md or an existing ADR without a superseding ADR per §17's record rules.
No stop condition is waivable by schedule pressure (§5.3 escalation): a waiver attempt is itself recorded as a governance incident in the evidence bundle.

**S5-ES-4 (acceptance criteria quantification):** §5.2's minimum criteria escalate to: RT Debug build + full unit suite green at pinned SHA with executed/skipped counts matching the commit's expected census (README reports 108 `@Test` functions, ~160+ executions with parameterization — the actual pin is derived at baseline, not copied); Mirage 316 Python + 3 Rust green; the integration contract document and machine-readable schema published and counter-reviewed; one supported book mapped with zero inference-based steps; a spoiler-sensitive query demonstrably fails closed (`CU-REQUIRE-1001` path verified); sidecar `kill -9` during mutation leaves RT's seven strata byte-identical (SHA-256 tree compare); disable-prevents-launch verified in an instrumented run (zero `exec` tracebacks); clean-machine launch with Mirage absent works. Each is an evidence-linked gate row, not a checkbox impression.

<a id="sec-21-7"></a>

### 21.7 Escalation of §6 — Baseline lattice, environment pinning, and normative-document custody

**S6-ES-1 (environment as a first-class reproducible artifact):** every baseline run is recorded against a pinned environment tuple: ⟨OS version + build, arch, Xcode version + build (`xcodebuild -version`), SDK set (`-showsdks`), Swift toolchain, `xcconfig`-resolved settings dump, Python version + `pip freeze` state at Mirage's chosen runtime, Rust toolchain (`rustc -vV`, `cargo --version`), lockfile SHAs, disk-free ≥ threshold, timezone (matters for NEW-DE-4-class cache keys), locale⟩. Tuple serialized as canonical JSON, SHA-256 recorded, and the tuple re-verified before every suite re-run. Build/test logs preserved **with** redaction (paths containing usernames homogenized to `«user»`; no secrets) and stored under the phase evidence directory with retention ≥ the project's lifetime.

**S6-ES-2 (test-census arithmetic):** a "green" claim is only valid with census arithmetic: RT — executed `Nᵉ`, skipped `Nˢ`, parameterized expansion documented, expected `Nᵉ+Nˢ` == declared census for that commit; a mismatch (e.g., dictionary-derived suite silently dropping a class) is an SC-02-class event even when exit code 0. Skipped-with-reason lists are enumerated, each with an expiry/owner. Mirage — 316 Python (verify via `unittest` verbosity census: `Ran 316 tests in …`) + 3 Rust (`cargo test` line census) — treat any count drift as a signal of the wrong commit, wrong discovery path, or silent test-exclusion (SC-02). Zero-exit is necessary-not-sufficient; `xcodebuild` warnings budget: no *new* warning classes introduced by integration diffs (CI diff-lint on log output, ESCALATED-DESIGN).

**S6-ES-3 (normative-document custody protocol):** every binding document (`08-deep-audit.md`, `02-defect-register.md`, `03-fix-log.md`, `04-handoff.md`, mission statement, `embedding.md`, `problems.md`, `fixlog.md`, `testing.md`, `product_era_plan.md`, `completion_plan.md`, `p17-record.md`, ADR-0001, ADR-0002, the migration files m0001–m0016) is read **in full at a recorded commit** and registered in a document-custody ledger: `{path, commit_SHA, bytes, sha256, read_by[], read_at, binding_claims_extracted[] (each with source line anchors)}`. A document read at SHA A does not transfer authority to SHA B; re-read at the pinned integration SHA is mandatory if they differ. References-within-references: if a normative doc binds to another doc/ADR, the closure is walked recursively and each reachable binding document is registered too. The extract named **binding_claims** is the only thing reviewers may rely on in discussion — free-recall summaries are not evidence.

**S6-ES-4 (real-library robustness constraint, escalated):** the day-2 real-library robustness point is a user standing directive *bound, not skipped* per the Mirage README. Integration escalation: (a) the authorized fixture, procedure, and success criteria are sourced from Mirage's canonical records (docs/testing.md, `p17-record.md`, cohort calibration harness scripts/p28_calibration.py provenance) — never synthesized; (b) if the apparatus is unavailable to this team, the gate is recorded BLOCKED with named owner and unblock path — synthetic substitutes are forbidden (false equivalence is exactly the §1.3 evidence-crime); (c) RT-side analogues (large-library cases: ~185k persona page-timings → 1–3 s encode bursts; multi-year 1–10 M record scale → the known JSON-monolith hazards) are measured with instrumented, disposable data — never the user's real library; (d) the two scale-hazard mechanisms RT names (NEW-DE-1 write window; 10× back-copies amplifying crash cost) get explicit regression pins before any Mirage activity raises write volume on RT's queues.

<a id="sec-21-8"></a>

### 21.8 Escalation of §7 — Discovery quantification and contract extraction formalism

**S7-ES-1 (inventory as reproducible build-artifact):** §7.1's inventories are generated by scripted, re-runnable censuses (ESCALATED-DESIGN) producing: file tree + per-file LOC/comment/blank split (RT README: 120 files, 39,900 raw = 28,697 code / 5,869 comment / 5,334 blank — a re-census at the pinned SHA must reproduce within ±1 % or a custody explanation is required), test-file census, target/phase enumeration from the Xcode project, migration list, fixture inventory, ignore-rule audit, and generated-artifact suspicion list. Both repos' censuses committed as evidence artifacts, not chat recollections.

**S7-ES-2 (RT-side trace targets, enumerated):** the discovery pass must produce path-anchored answers for each of: user-action → SwiftUI view → `@Observable` store → model mutation → persistence boundary (`PersistenceWriter` enqueue semantics on a utility queue) → background work scheduling → error presentation path; the import pipeline(s) (including the *onboarding-import bypass path* NEW-DE-5 — identify and quarantine its mechanism from integration reuse); active-reader-position representation (what struct/field names hold it, units attached — CRITICAL input for §10's cursor adapter); session-save and session-close flows (incl. Sentinel repair interactions at launch: which repairs block save, the repair-before-save ordering contract); derived runtime path construction (`~/Library/Application Support/johan.Reading-Tracker/` — verify, don't transcribe); MainActor-default isolation implications for every new I/O touchpoint (a per-call-site annotation sweep justified by the *defining-build-setting* and its freeze-bug history). Anchoring: every answer is a `path:line-range` citation, not a paraphrase; answers lacking anchors are returned to discovery.

**S7-ES-3 (Mirage-side trace targets, enumerated):** entry surfaces (Python API `MirageService`, CLI `mirage`, NDJSON serve/sidecar incl. `examples/mirage_sidecar.py`) → request parsing within the documented command set → domain validation (`src/miragev10/domain/` typed contracts/enums) → ingestion/analysis/query service layer → ledger transaction boundary (which layer opens/closes the transaction, crash-safety mechanics, journal mode — VERIFY in migrations m0001–m0016 and ledger code) → spoiler predicate application point (the single shared predicate across projection/citations/search — verify there's exactly one, not per-surface drift) → graph projection construction (canonical content hashes) → response serialization. Persistence questions answered from source: single-ledger-per-library assumption, concurrent-open behavior, handle retention across sidecar shutdown, WAL/checkpoint behavior, migration driver (explicit-init vs auto-on-open), backup API (online backup vs copy caveats — informs §15.3).

**S7-ES-4 (interface inventory record — the closed op set):** each operation in §7.2's minimum set (handshake/version; list/resolve editions; import one EPUB; analyze one edition; spoiler-safe projection at explicit cursor; health/status) gets a full record: `{op_name (exact, from source), caller_rt_layer, input_schema (typed), validation_rules, side_effects_classification (read-only|state-changing|expensive|destructive), persistence_writes (whose strata), idempotency_class (N|KEYED|READBACK), timeout_policy, cancellation_contract, output_schema, error_code_mapping, provenance_fields, test_location (both fake-transport and real-sidecar test IDs), medium-of-truth (which doc pins it)}`. Ops absent from Mirage's actual API surface are *not invented to fill gaps* — a requested-but-unsupported operation yields a host-side typed `OP-UNAVAILABLE-0404` with a user-safe string; no protocol-shape nudging.

**S7-ES-5 (boundary-preservation constraints on persistence probing):** no read-only UI query may trigger a schema migration as a side effect unless that is the documented init contract with user-consented data changes — otherwise explicit init/migration flow with pre-migration backup, version gate (`ledger@0.0.10` check against RT's pinned min/max), transactional guarantee verification, and failure recovery plan. Exploratory ledger commands run only against disposable DBs in temp dirs — never a real user's ledger (Appendix A constraint, escalated with a temp-dir assert in any helper script).

<a id="sec-21-9"></a>

### 21.9 Escalation of §8 — Pre-existing-defect engineering program (Phase 3)

**S8-ES-1 (defect-object model):** each pre-existing finding becomes a work item with: `{defect_id (NEW-DE-n | RBLK-n), class (per S1-ES-2 taxonomy), disposition (FIX-FIRST | ISOLATED | BLOCKS-RELEASE), containment_mechanism, repro_steps (instrumented, deterministic), evidence_anchors (path:line + register references), owner, regression_test_id (pinned, named for the defect per house style), fix_protocol (Finality statement + fix-log entry + pinned test per RT standards), integration_interaction_map (which Phase-4+ items touch its surface)}`. Disposition is a decision by the RT owner recorded in the defect register — not an implicit outcome of merge momentum.

**S8-ES-2 (disposition matrix for integration coupling):** NEW-DE-1 → FIX-FIRST (integration multiplies concurrent write candidates; the stale-overwrite window must be closed by establishing a serialization fence and re-pinning with the interleaving test from S1-ES-2 before Mirage callbacks enqueue any RT writes). NEW-DE-5 → FIX-FIRST or formal decoupling ADR (the integration's import path MUST route through the import-intelligence facade + duplicate-check; if the bypass is untreated, the Mirage import flow inherits the same goal-overwrite hazard). NEW-DE-4 → ISOLATED unless Mirage results flow through `AnalyticsCache` (then the day-component becomes a hard prerequisite on any Mirage-cached key). NEW-DE-3 → ISOLATED with interaction-impact analysis if session-lifecycle surfaces are touched for cursor sync. NEW-DE-2 → ISOLATED (view-key migration lint per S1-ES-2). Blockers (AppIcon/WeatherKit/entitlement-mismatch/CFBundleIdentifier) → tracked under packaging gate §14.3 — production release remains explicitly blocked until resolved; integration cannot be declared "done" while any of them silently persists.
**No-masking rule:** integration PRs must report which open defects their diff lines *touch* (not merely "did not fix"); masking-free review uses defect-surface annotations in the PR template (ESCALATED-DESIGN).

**S8-ES-3 (change-isolation doctrine):** the merge does not bundle: persistence rewrites, store splitting, Swift 6 conversion, dead-code retirement (~12–15% of app target per README), SQLite normalization, CloudKit, App Store formalities. Each is an independent workstream with its own risk profile/rollback plan. reviewing a Mirage-integration PR must never require reasoning about an unrelated refactor, and vice versa — small, single-purpose PRs keep regression attribution unambiguous (which commit introduced which behavior change).

**S8-ES-4 (MainActor isolation audit, mechanized):** RT's defining build setting (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, implicated in its hardest freeze bug) mandates a per-type audit for every new integration type: task-creation sites, continuation/blocking calls, pipe reads/writes, JSON encode/decode of large payloads (`library.json`-scale payloads never encode on MainActor), sqlite access, and process spawn/signal calls — each classified allowed/blocking-with-justification/forbidden. The audit is an artifact (table of call sites × classification × measurement) not a review assertion. Async/await UI work stays on the required isolation context; process/I/O work is explicitly scheduled onto non-UI executors; sidecar activity during window open/close/navigation/termination is covered by §9.5's test matrix.

**S8-ES-5 (exit gate):** every defect triaged with a written record; ordering and import-safety owners assigned with pinned tests; MainActor audit artifact reviewed; no unrelated rewrites in the merge; RT buildable + testable at the phase boundary (suite green per house standard, census recorded, build/test logs preserved).

<!-- addendum escalation pt2 end -->

<a id="sec-21-10"></a>

### 21.10 Escalation of §9 — Integration boundary as formally specified subsystem

**S9-ES-1 (client abstraction algebra):** the §9.1 typed abstraction escalates to an algebraic contract: every client operation `op: Params → Task<Result, TypedError>` satisfies (a) **typed-ness**: `Params` and `Result` are Codable value types validated against the pinned schema before use; raw strings/JSON never cross the boundary; (b) **correlation**: each call maps 1:1 to a protocol-correlated request ID; (c) **temporal honesty**: the operation may observe states {sent, awaiting, validated, completed, failed(typed), cancelled} — the "completed" transition is reachable *only* via a validated correlated success envelope, never from progress ticks, never from optimistic inference; (d) **cancellation-safety**: cancellation leaves RT state unchanged and sidecar state defined by the documented contract; (e) **transport-agnosticism**: identical observable behavior against real sidecar, fake transport, and test double — verified by running the same conformance test suite against all three (a protocol-conformance harness, ESCALATED-DESIGN); (f) **fail-typed**: all failure modes from S9-ES-5's registry map into a closed Swift error enum with associated payloads; UI never receives raw NSError/English prose.

**S9-ES-2 (process lifecycle, syscall-precision requirements):** the supervisor's specification escalates to: launch via `posix_spawn`-backed `Process` with (a) absolute executable URL from `Bundle` (never `$PATH` search — the intentional-non-discovery rule; if the executable is not present, feature state is `notInstalled`, not a search of the disk); (b) argument vector assembled from constants + validated data (paths as data, never re-parsed as shell syntax — zero `sh -c` in the call graph); (c) environment: explicit allowlist dictionary (HOME/PATH minimal/`PYTHONHASHSEED=0` for determinism, ESCALATED-DESIGN) rather than inheritance, eliminating `PYTHONPATH`/`PYTHONHOME`/`LD_*/DYLD_*` injection vectors; (d) stdin/stdout as newline-delimited NDJSON channels with bounded read buffers (per S2-ES-4 sizes) and bounded stderr ring buffer (256 KiB, drop-oldest with drop-counter exposure in diagnostics); (e) child lifecycle: app shutdown → graceful drain attempt (bounded 2 s) → SIGTERM → bounded 3 s → SIGKILL → process-group reaping; crash detection via `terminationHandler` + exit-status taxonomy (0 normal, nonzero failure-classified, signal-death separately classified); (f) restart ladder per S2-ES-5 (exponential with jitter, three-in-60-s → feature disabled + `dataNeedsAttention`); (g) duplicate-launch prevention via supervisor-held PID + session-unique handoff token in the handshake; (h) orphan prevention verified by test: supervisor deallocation without shutdown = test failure.

**S9-ES-3 (message validation pipeline, layered):** inbound response processing escalates to a five-stage pipeline, each stage independently unit-testable: **L1 byte-level framing** (UTF-8 validity, LF-terminated lines, in-string escape tracking, oversize rejection → `TC-FRAME-*`); **L2 JSON syntactic parse** (single compact value per line; duplicate-key detection policy defined; number-precision policy for large ints; `TC-JSON-*`); **L3 envelope validation** (exact `v` match against pinned protocol version; `id` correlation echo match; `ok`/`err` shape exclusivity; unknown top-level field rejection per strict mode; `TC-ENV-*`); **L4 domain-schema validation** (typed decode of the op-specific result/error payload; enum exhaustiveness — unknown enum values are rejected, never defaulted; `TC-VALIDATION-*`); **L5 semantic invariants** (spoiler-gate fields present where required; provenance/uncertainty fields present on established facts; cursor-origin fields present on cursor-bearing results; `TC-SEMANTIC-*`). Parser failures must not trigger spoiler-expanding fallbacks (§9.3 escalation): a failure at any layer produces typed error → contained UI state; the *only* content ever displayed after a partial/failed response is Mirage's already-validated prior output or the explicit "withheld" state.

**S9-ES-4 (UI boundary laws):** §9.4 escalates to: views depend on the typed client protocol only; loading/ready/unavailable/error states enumerated from S2-ES-7's vocabulary; the initial surface is exactly five components (entry point, status surface, book/edition context, safe query flow, cursor-unavailable explanation) — no second app shell; Mirage's browser UI remains an optional Mirage-side affordance and must never be promoted into RT's stack by accident (e.g., no WKWebView embedding of `127.0.0.1:8747` without ADR; the HTTP surface is not the RT feature).

**S9-ES-5 (boundary test matrix → failure-mode registry):** §9.5's list escalates to a labeled error-code registry (ESCALATED-DESIGN — RT-side codes; exact Mirage-side codes are sourced from §7.4's contract extraction):
| Class | Codes | Trigger | Required host behavior |
|---|---|---|---|
| process | `PR-LAUNCH-01..12` | not-found, exec-failure, quick-exit, arch-mismatch, codesign-mismatch, spawn-denied | typed mapping, no auto-retry beyond ladder, user-safe string |
| protocol | `TC-FRAME/TC-ENV/TC-VALIDATION/TC-SEMANTIC-*` | per S9-ES-3 layers | reject line/response, bounded log, contained UI state |
| transport | `TX-TIMEOUT-01, TX-CANCEL-01, TX-DUPREQ-01, TX-PIPE-01 (broken pipe), TX-STDERR-01 (flood)` | timeout, cancel, duplicate ID, closed stream, stderr overflow | per-op timeout policy; non-idempotent ops never replayed |
| lifecycle | `LC-CRASH-QM-01 (crash during query), LC-CRASH-MU-01 (during mutation), LC-RESTART-01 (ladder exhaustion), LC-SHUTDOWN-01` | crash/kill/shutdown | RT strata untouched (SHA-verified), no restart loop |
| identity | `ID-SYNTH-9001, ID-FINGER-7001, ID-AMBIG-5002` | inference attempt, fingerprint mismatch, multi-candidate | mapping stays unresolved; user resolution flow |
| cursor | `CU-REQUIRE-1001, CU-GUARD-1002, CU-REGRESS-1003` | missing cursor, attempted advancement past evidence, regression handling | fail closed; visibility shrink only |
| policy | `PV-NETWORK-0001, PV-LOG-0001` | attempted non-local op, oversized/payload-rich log attempt | disable + alert per §12 escalation |

Every code in the registry has: machine-readable form (wire), human-safe string (UI), log-safe detail (redacted), and a pinned test proving both the host-side mapping and the fail-closed user experience. Fake-transport conformance tests deliberately fragment, delay, malform, oversize, and exit-at-controlled-points per §9.5; RT's seven storage strata asserted byte-identical across every failure scenario (tree-hash check in fixture teardown).

<a id="sec-21-11"></a>

### 21.11 Escalation of §10 — Adapter algebra: identity, import, cursor, synchronization

**S10-ES-1 (one-book discipline, procedure-grade):** §10.1 escalates to a pre-flight checklist executed before any `import_epub` envelope: (a) user gesture recorded (explicit import action, not file-watch); (b) security-scoped bookmark resolved; access verified under the app-sandbox configuration (recalling the `ENABLE_USER_SELECTED_FILES=readonly` vs entitlements-file mismatch from RT's blockers — resolve before any file-passing feature ships); (c) file still exists at referent path with stable stat (size/mtime fingerprint recorded pre-import and compared post); (d) operation surface declared in UI ("what will be created in Mirage's ledger") before dispatch; (e) cancellation readiness state verified (cancel affordance live until Mirage's own committed-point, per its documented semantics — cancellation after commit = new-state disclosure + next-status reconciliation, never a silent rollback claim).

**S10-ES-2 (post-import validation algebra):** §10.2 escalates to: receipt schema validated (L3/L4); identifiers present and non-empty (absence ≠ synthesis — `ID-SYNTH-9001`); edition identity cross-checked against RT's recomputed content fingerprint (mismatch → `ID-FINGER-7001`, mapping `proposed` → `stale`); operation correlation (the receipt must respond to *this* import — request-ID match); then and only then RT persists its mapping row (RT-owned stratum, RT's atomic writer). Idempotency test matrix from §10.2 retained verbatim as the required case list: repeated same-content import (expect `already_imported`-class no-op per Mirage's contract — VERIFY from source, not assumed), changed files, identical titles different editions, same content at different paths, fingerprint-vs-metadata conflicts — each case pinned with expected outcome sourced from Mirage's *actual* content-identity code/tests.

**S10-ES-3 (cursor contract document, formal):** §10.3's adapter contract escalates to a separate normative sub-document (an appendix of the §17 ADR-7) containing: field provenance (which RT field, which store, which mutation event last touched it), conversion algorithm (or the explicit statement that none exists and spoiler-sensitive surface ships disabled — the *no-conversion-is-the-safe-conversion* doctrine), edition-identity requirement (cursor valid only against the mapped `mirageEditionID`), invalidation conditions (content change, re-import, duplicate edition, stale fingerprint), regression policy (cursor may only move forward on verified evidence; backward movement requires explicit re-declaration), missing-data behavior (fail closed → `CU-REQUIRE-1001`), and the state-vocabulary transduction table (RT "read"/"reading"/"unread" → Mirage's `read`/`reading@N`/`unread` — validated against domain enums at the pinned commit; no inventing intermediate states). Unsafe-by-default rule: until this document is countersigned, no spoiler-sensitive query path may ship — read-only status surfaces only.

**S10-ES-4 (synchronization invariant catalog):** §10.4 escalates to six pinned invariants: (1) **page-turn non-trigger**: zero analysis-class envelopes may originate from page-turn/scroll/navigation callbacks — enforced by call-graph audit + a runtime tripwire test (instrument the transport; assert no `analyze`-class op observed during a scripted reading session simulator); (2) **bounded sync policy**: cursor/state declarations, if the API supports them, fire under debounce/coalescing with documented timing (§10.4's "measured bounded policy"), never per-event; (3) **durability gate**: a cursor update is "durable" only after Mirage's validated ack; RT may display "declared, pending confirm" intermediates; (4) **ordering**: out-of-order updates rejected via monotonic sequence/epoch — stale updates never overwrite newer confirmed cursors; (5) **crash reconciliation**: between an RT session-save and a Mirage cursor update there is *no* atomicity — document a defined reconciliation (next-handshake status check + explicit/readable delta surface for the user), never claim cross-store transactions; (6) **transparency**: every automatic-ish sync is user-visible in a review surface (what was declared, when, why), reversible where the Mirage contract permits.

**S10-ES-5 (adapter exit gate, evidence-linked):** §10.5's checklist rows each bind to named tests: one-book-through-the-interface (E2E case 5), mapping explicit/validated/recoverable (cases 5–7, 15), duplicate/changed-file behavior (cases 6–7), cursor units verified against implementation (S10-ES-3 doc + unit pins), fail-closed missing/stale cursor (case 9), series user-confirmed (case 10), page-turn non-trigger (case 1 + S10-ES-4 pin 1), strata separation (all-case teardown tree-hash), non-atomic reconciliation (case 12). A checklist row without a named test ID is not checked.

<a id="sec-21-11b"></a>

### 21.11b Escalation of §11 — Feature exposure, query experience, data controls

**S11-ES-1 (entry-point and settings constraints):** §11.1 escalates to: exactly one navigation entry point (placement product-reviewed in the running app); enable/disable control with defined non-deletion semantics (disable = no new launches + in-flight drain + status transition; **the Mirage ledger is never touched by the toggle** — deletion is Mirage's own explicit, confirmed, per-table-audited `remove-book` flow, if and only if separately exposed with user confirmation per §11.4); unavailable-state UX must distinguish the five causes (not installed / cannot launch / protocol incompatible / ledger unavailable / user-disabled) from S2-ES-7's vocabulary; no Python traceback or raw stderr in primary UI — bounded diagnostic view with redaction per §12.3 only.

**S11-ES-2 (query answering pipeline, spoiler-guarantee-preserving):** §11.2 escalates to: RT renders result envelopes without epistemic laundering — uncertain claims keep their uncertainty markers through rendering (no "probably ≈ certainly" smoothing, no probabilistic language added or removed); source/book attribution rendered *with every item* (never flattened away); citation/evidence references validated against the schema and rendered as structured evidence surfaces, not prose paraphrases; a spoiler-withheld result renders as such and **RT is forbidden from issuing any re-query that would obtain the withheld content by relaxation** (cursor-loosening, op-substitution, or repeated probing = sentence-level invariant with a runtime tripwire test that asserts one-request-per-user-gesture-per-cursor-evidence-class).

**S11-ES-3 (no-fallback-to-external-inference):** §11.2's prohibition escalates: no LLM/network service may be inserted into any query path to "answer what Mirage couldn't" without a separately approved, disclosed, spoiler/provenance-audited ADR; *runtime network dormancy* is a pinned guarantee (Mirage README: no runtime network, socket-denial install drill; integration must preserve this — verified per §12/§13 socket-assertion tests). Any proposed relaxation auto-triggers SC-12 review.

**S11-ES-4 (loading/error/accessibility specifics):** §11.3 escalates to: progress only from real protocol states (missing progress-reports = indeterminate affordance, **invented percentage = forbidden**); state set from S2-ES-7 mapped to accessibility traits; bounded result pagination (≥ 200-item pages per S2-ES-8; no unbounded graph dumps in a single render); minimum-window-size and VoiceOver coverage tests required before feature exit-gate; keyboard navigation and focus restoration tested during busy/cancel/window-close.

**S11-ES-5 (data-control surface, precise):** §11.4 escalates to a mandatory explanation surface covering: where the ledger lives (path, owner, backup policy §15.3), relationship to RT's library (separate strata, no shared rows), what import transmits (the EPUB content to Mirage's local processing — nothing leaves the machine), what unlink does (mapping deactivation only — never ledger impact, never RT destruction), what explicit remove-book does (per-table counts shown pre-confirmation, per Mirage's own audit contract), and what disable does (stops the runtime; deletes nothing). Both file paths and mental-model diagrams in the settings UI.

<a id="sec-21-12"></a>

### 21.12 Escalation of §12 — Security/privacy hard plane

**S12-ES-1 (network dormancy as a verified invariant):** §12.1 escalates to a testing-level doctrine: the *integrated runtime path* (sidecar processing a real query, minus any optional browser-UI surface) must be proven socket-inactive via a runtime assertion — launch the child under a socket-deny profile or `LAN`/inet-socket audit (macOS sandbox network denial / endpoint-audit tooling, ESCALATED-DESIGN) mirroring Mirage's own `p13_install_drill.sh` socket-denial doctrine; any fetch/connect/connectto in a trace = SC-11 stop + release-impossible. RT's existing Discovery/network surface is RT-owned and *visually separate*; the two network policies are documented as distinct but the integration adds zero deltas. If the browser-UI surface is ever enabled, get-out-of-denied requires the full STRIDE review chain ([§21.12 (S12-ES-3)](#sec-21-12)).

**S12-ES-2 (process/file boundary, elevated to capability register):** §12.2 escalates to: executable = Bundle-co-located, pinned-hash-validated (SHA-256 manifest + codesign check per launch, or feature starts `runtimeIncompatible`); args = constant template + validated data-only slots; env = explicit allowlist (S9-ES-2); cwd = pinned to a controlled container dir (never the user's home or an arbitrary sandbox-inherited value); file capability = the authorized user-selected EPUB (security-scoped) + Mirage's own container/ledger dir only; path inputs from protocol envelopes validated against traversal (`\.\./` rejection + canonicalization + containment checks before any open); no shell interpolation anywhere in the launch path; child process inherits no user-credential keychains.

**S12-ES-3 (localhost ≠ trusted call):** §12.2's HTTP constraint escalates with concrete threat enumerations: DNS-rebinding defenses (Origin check on every request, ESCALATED-DESIGN), loopback-only binding verified (`lsof -i :8747` showing `*.8747→127.0.0.1` never `*.*`), port-conflict fallback policy (if 8747 is occupied by an alien process, the surface refuses to start rather than shifting to a random port silently — a movable listener requires a capability the current README doesn't describe; VERIFY), request validation identical to sidecar pipeline, and cross-user processes on shared Macs treated as hostile unless proven otherwise. Given all four risks, the sidecar protocol remains the preferred surface and the HTTP surface ships disabled-by-default inside RT (draft, ADR-2 territory).

**S12-ES-4 (logging ontology):** §12.3 escalates to a per-operation logging schema with an explicit field-violation triage table:
- **Loggable-by-default:** operation class (from the typed client's closed enum), request-ID, latency, terminal state (ok/typed-error), protocol version hash prefix, redacted identifiers (DataFrame-style truncations).
- **Redact-by-default:** EPUB content (any passage at all), full claim text (literary summaries may be spoiler-sensitive; a claim text *is* content), unredacted book titles if user treats as sensitive (configuration policy required), user file paths (homogenize to `«user»`), full query text beyond first ~8 tokens with same-semantic-mask flags, ledger row dumps, whole-library snapshots.
- **Bounded:** retention window (default 7 days, ESCALATED-DESIGN), diagnostic wrap-cap, crash-report redaction filter (process arguments, env, paths rubric) applied *before* external sharing.
- **Separated:** RT diagnostics ≠ Mirage's ledger ≠ Mirage's correction history (append-only); no cross-domain log surfaces; shared crash-log bundles are pre-scan-blocked by a lint (ESCALATED-DESIGN; lint registered in the Appendix-F code registry).

**S12-ES-5 (supply-chain custody chain):** §12.4 escalates to a bill-of-materials requirement for any bundled runtime: `{artifact (wheel/CPython/Rust build), source commit/path, version pin, SHA-256, builder provenance (CI job ID + runner class), license (audit each transitive: Zero-Clause/MIT/Apache candidates for the declared stdlib-first posture), sign/notarize treatment per macOS channel, update mechanism, arch coverage (arm64/x86_64 policy), validation at startup (version+hash)}`. Runtime-fetch-on-first-launch = **forbidden**; unpinned/mutable tags = forbidden; CI must rebuild the artifact reproducibly (two-runner bit-compare policy, ESCALATED-DESIGN, or documented non-determinism with accepted risk). RT's single-dependency doctrine (ZIPFoundation 0.9.20 pinned) is an integration invariant: adding a second SwiftPM dependency requires an ADR naming why leaner transports (Foundation-only) cannot serve.

<!-- addendum escalation pt3 end -->

<a id="sec-21-13"></a>

### 21.13 Escalation of §13 — Testing calculus, quality gates, and statistical sufficiency

**S13-ES-1 (suite independence with census arithmetic):** §13.1 escalates to: RT suite, Mirage Python suite, and integration suite run **separately**, each with its own census row in every gate record: `{suite, commit SHA, env hash, executed, skipped, failed, flaky-quarantined, census-expected, census-verdict}` — counts are never summed into a single reassuring number; a failing Mirage job must visibly fail even when RT is green. Both existing suites pass at the pinned SHA **before** any integration diff; the integration suite adds a third, visibly separate job. A mocked-Mirage test proves host logic under the *mock contract*; a real-sidecar smoke test proves the *real contract*; both classes are mandatory (§13.1 retained verbatim), and the mock contract carries a doc-comment tying each stubbed behavior to the source path that defines the real behavior — a stub without a source anchor is a review-block (ESCALATED-DESIGN).

**S13-ES-2 (unit territory, per-stratum):** RT-side: protocol encode/decode (S2-ES-4 shapes, L1–L5 validation pipeline), schema validation exhaustion (unknown enums rejected), error-code mapping completeness (every registry code → typed case → user-safe string → log-safe detail), identity mapping state machine (S3-ES-2's six states + transitions, reachable + unreachable states enumerated), cursor conversion (or its explicit refusal logic), state transitions (S2-ES-7 vocabulary), settings, idempotency policy per op class. Mirage-side: preserve its own invariants (ingestion, incremental `analyze_edition` idempotency I-INC1, ledger append-only history, identity resolution + evidence-gated merges, D-010 overlay never-truth-promoting P12, spoiler eligibility shared predicate) **and** add pins for protocol behaviors the host relies on but Mirage doesn't already pin (per §13.2). Fixtures: fixed, deterministic, injected clocks; zero tests depending on real library/current weather/uncontrolled network/unpinned services; test DBs in temp dirs with teardown asserts that the developer home directory is untouched (file census diff before/after suite).

**S13-ES-3 (E2E scenario catalog, pinned and numbered):** §13.3's twenty scenarios escalate to individually numbered, individually fixable test IDs (INT-01…INT-20) with declared inputs, expected envelope sequences, and teardown tree-hash assertions. Retained scenarios verbatim-numbered: 1 disabled-no-launch; 2 enabled-handshake-ready; 3 absent/cannot-launch → contained status; 4 protocol-incompatible → disabled-safely-no-mutation; 5 valid-EPUB → canonical IDs + verified mapping; 6 duplicate-import → contract-true no-op; 7 metadata-similar editions stay distinct; 8 valid-cursor query → eligible-only + provenance/uncertainty preserved; 9 missing/invalid/stale/mismatched cursor → fail closed; 10 series read/reading/unread → per-edition policy + book attribution retained; 11 sidecar crash during read query → failure contained, PersistenceWriter strata untouched; 12 crash/timeout during mutation → no blind retry, documented reconciliation; 13 cancellation → convergence per contract; 14 disable → no new spawn/analysis, RT functional; 15 unlink → mapping-only change; 16 confirmed deletion (if implemented) → supported op + accurate audit counts; 17 RT termination → child closure per escalation ladder; 18 large responses + stderr bounded, MainActor unblocked; 19 full RT regression battery (books/goals/sessions/achievements/archives/covers/weather/Sentinel/backups); 20 clean-machine packaged run. Each scenario: fake-transport first, real-sidecar smoke second; both never conflated in a single test.

**S13-ES-4 (failure injection, matrix + volume/latency instrumentation):** §13.4 escalates to a parametrized injection matrix crossing {malformed JSON, truncated output, delayed response, process exit, locked DB, failed migration, corrupt ledger copy, disk-full, invalid file access, duplicate request, stale cursor} × {during query, during import, during analysis, during cursor declaration}; every cell asserts: typed error surfaced, RT strata byte-identical, restart ladder respected, no spoiler expansion, bounded logs. Performance profiling is *instrumented measurement, not vibes*: sidecar cold-start (p50/p95/p99), simple-query latency, cursor-bearing projection latency, `analyze_edition` latency + memory peak (8 GB budget respected at the *integrated* level, not just Mirage-side), response byte sizes, cancellation latency, idle CPU/memory when enabled-but-idle, RT save-burst latency during concurrent sidecar activity (the JSON-monolith 1–3 s encode bursts at persona scale is the already-measured baseline hazard — integration must not add concurrent pressure). Every metric baseline-then-integration under identical env tuples; any regression over the §13.6 budget threshold is a gate failure.

**S13-ES-5 (UI/accessibility test requirement, non-delegable):** §13.5 escalates: view-flow coverage gap (test-suitability 0.68, architecture-breadth 0.4) is a **known deficiency that integration must not deepen and should measurably improve** — UI tests cover: feature open, book change, status display, query loading/errors, cursor-unavailable states, return-to-reading; keyboard navigation, focus restoration, window-close-while-busy, developer-console coexistence (⌘⇧D personas must not collide with sidecar state). View-model unit test ≠ SwiftUI hierarchy verification — a documented untested-platform-flow list is published with the feature gate; untested ≠ fine, untested = disclosed limitation item in §19's bundle.

**S13-ES-6 (performance budget doctrine):** §13.6 escalates to: budgets are **measured baselines × owner-agreed multipliers or absolute ceilings** (ESCALATED-DESIGN starting points for ADR review): sidecar cold-start ≤ 800 ms p95; simple query ≤ 200 ms p95; cursor-bearing projection ≤ 500 ms p95; analysis = explicit status-surfaced async op (no budget until measured); idle CPU ≤ 1 % and idle RSS delta ≤ 30 MiB over 10 min; UI main-thread ceiling: no integration work ≥ 5 ms on MainActor (measured via signpost, not "feels fine"); page-turn save-path latency delta ≤ 10 % over baseline. Budgets without baselines are hypotheses, not gates.

<a id="sec-21-14"></a>

### 21.14 Escalation of §14 — Build/packaging/release engineering to artifact-custody grade

**S14-ES-1 (distribution decision algebra):** §14.1 escalates: the three options (bundle runtime / separate installer / user-managed runtime) are evaluated against: clean-machine first-launch success (no dev Python, no dev PATH, no source checkout), signed+notarized-bundle compatibility (embedded Python/Rust artifacts need their own signing + provenance treatment), version-drift control, update mechanics (and ledger-schema compatibility across updates — §15.1), bundle size, arch coverage (arm64 + Intel policy), support burden. `pipx install ./dist/miragev10-1.0.0-py3-none-any.whl` is a developer/user installation path, **not** an in-bundle runtime model — its mention in a README does not make the wheel distributable inside a signed macOS app (licensing of embedded CPython/dylibs, `@rpath` mechanics, hardened-runtime library-validation constraints, notarization of nested binaries). Decision recorded as ADR-3 with the rehearsal artifacts (clean-machine prototype run log) as annexes.

**S14-ES-2 (reproducible build chain):** §14.2 escalates: pinned Mirage version/commit ↔ pinned protocol version ↔ pinned ledger schema (`ledger@0.0.10` compatibility range declared in RT's constants: min/max supported + refuse-on-mismatch behavior — refuse = typed `runtimeIncompatible`, never a soft launch); runtime built in CI reproducibly (two-runner bit-compare or documented non-determinism acceptance); package contents audit: Python modules, data files, **SQL migrations m0001–m0016 present and loadable in order** (a missing migration discovered at customer runtime is a recall-class event — verify in packaging smoke), templates/assets, native artifacts (if the Rust core is ever promoted out of demotion — requires ADR-0002 supersession); RT locates runtime via Bundle-path resolution with zero `$PATH`/`$PYTHONPATH` ambiguity; startup version+hash validation per §14.3; update procedure never downgrades ledger schema without an approved recovery process (§15.1).

**S14-ES-3 (signing/sandbox/entitlements reconciliation):** §14.3 escalates: the four RT release blockers (empty AppIcon set; missing WeatherKit entitlement; `ENABLE_USER_SELECTED_FILES=readonly` setting vs read-write entitlements file mismatch; empty-string `CFBundleIdentifier` in custom plist) are resolved **as packaging preconditions**, each verified in the final built artifact (not project settings): `codesign -d --entitlements :-` output diffed against a declared expected-entitlements manifest; bundle ID non-empty and consistent across Info.plist/custom plists/targets; AppIcon non-empty across requested scales; WeatherKit entitlement either present (if weather ships) or the weather feature degraded with proper disclosure. Integration must not introduce a second bundle ID/entitlements file; embedded runtime executables get their own embedded signature + provenance records; notarization runs on the final bundle (not the inner binaries alone); child-executable permissions (`chmod +x`, quarantine attribute handling) verified on clean machine. `ENABLE_USER_SELECTED_FILES` policy must be consistent with what the RT↔Mirage import flow actually requires and the mismatch (as reported) resolved under an ADR with an explicit security-review note (readonly vs read-write is a security-posture decision, not an implementation detail).

**S14-ES-4 (CI topology, fail-visible):** §14.4 escalates to separate visible gates (masked failure = void gate): RT build+test; Mirage Python; Mirage Rust (per build policy); protocol contract tests (schema conformance, fake-transport); integration E2E (INT-01…20); packaging smoke (clean-machine launch + migration-presence audit); security checks (secret scanner, entitlement diff, network-dormancy assertion, log-payload lint). Dependency caches preserve lockfile correctness (cached artifacts keyed by lockfile hash, never by branch name); PRs from untrusted forks get zero access to release secrets; artifact publishing sanitized (no real libraries, no production ledgers, no unredacted logs, no unlabeled corpus); the evidence-bundle job **archives phase-gate artifacts by name** — an unarchived gate is a gate never passed.

**S14-ES-5 (release-gate rows bound to evidence):** §14.5 escalates each row to an evidence-typed row: clean-machine build+launch (log artifact), runtime packaging/protocol version recorded (manifest), RT/Mirage/integration jobs pass (CI run links), signing/sandbox/entitlements/file-access/app-identity verified (codesign output bundle), Mirage absent/disabled works (INT-01/03/14 logs), no network deltas (dormancy trace), performance budgets met (measurement tables), rollback+data-recovery rehearsed (rehearsal log §15.3), known blockers resolved or release explicitly blocked (defect register diff), owners approve the exact commit/artifact tuple (signature record). A row without its evidence link is unchecked, regardless of oral claims.

<a id="sec-21-15"></a>

### 21.15 Escalation of §15 — Rollback calculus, recovery rehearsal, operational handoff

**S15-ES-1 (dual-ledger rollback doctrine, formal separation):** §15.1 escalates: **code rollback ≠ data rollback ≠ schema rollback** — three distinct ledgers with distinct procedures: (a) code rollback = revert integration commits; RT/Mirage code returns to baseline SHA; (b) data rollback = RT strata restore from RT backups (their own rotation/Sentinel stack) while Mirage ledger restoration follows Mirage's *own* DB-consistent backup procedure — **restoring RT's Git history cannot restore `library.json` content**; restoring RT backups cannot restore Mirage's ledger; the two are operationally independent stores with independent restore procedures; (c) schema rollback = forward-only doctrine bias (SQLite schema downgrade across the ledger@0.0.10-family migrations m0001–m0016 is generally unsupported; a downgrade need requires an ADR with a verified downgrade/restore path — "newer app versions writing data older versions cannot understand" is the exact hazard §15.1 names, and the escalation is a compatibility matrix: app version × ledger schema × recoverability classification {full / partial-with-mapping-loss / unrecoverable}).

**S15-ES-2 (rollback triggers with detection thresholds):** §15.2 escalates: spoiler leakage (any observed beyond-cursor content in any UI surface under any failure combination → disable feature immediately + SC-05 re-run of spoiler suite), identity mislink (unexplained content appearing for the wrong book → mapping stratum audit + disable the affected book's mapping), RT data corruption/unexpected mutation (tree-hash mismatch vs baseline on any RT stratum after integration activity → freeze integration activity, inspect PersistenceWriter/queue interactions, both owners), unbounded restarts (ladder-exhaustion events in diagnostics), repeated UI freezes (MainActor-audit re-run), severe memory/CPU regression (budget breach), protocol incompatibility (version pin drift), failed migration (migration log + rollback rehearsal path exists), unexplained ledger integrity errors (ledger-side triage + Mirage owner), security/privacy violation (any incident class). Containment ladder: feature disable first (feature-only incidents: stop spawning the sidecar — contains the blast radius without touching either store); ledger deletion is *never* a troubleshooting shortcut; evidence preservation before repair (redacted logs, request IDs, SHAs, protocol versions, repro steps); data-integrity repairs require both owners before any attempt.

**S15-ES-3 (recovery rehearsal protocol, verified-or-fictional):** §15.3 escalates: rehearsal items each produce a log artifact (steps, timestamps, observed outcomes, operator, commit SHA): code rollback (revert PR-4 through PR-7 individually and verify RT-only behavior), sidecar crash recovery (kill -9 at staged points: mid-handshake/mid-query/mid-mutation/mid-import), failed initialization (corrupt/disabled ledger → contained state), invalid mapping recovery (stale/mismatched fingerprint flow), and one documented data-backup restore per system using disposable data. SQLite-backup discipline: never copy a live hot DB and call it a backup — VERIFY Mirage's supported backup path (VACUUM INTO / `.backup` / online backup API / quiesce-then-copy — from source, not assumption); if Mirage provides none, the policy is a documented gap with a named owner. RT's backup rotation + Sentinel protect RT strata under their own rules and must not be assumed to cover the ledger.

**S15-ES-4 (operational handoff bundle):** §15.4 escalates to a handoff document answering, path-anchored: identify the running Mirage process (supervisor PID file + process census command), check version/protocol compatibility (handshake fields), locate the approved ledger directory (path + ownership + backup policy), inspect redacted diagnostics (diagnostic surface + redaction rubric), run all test suites (from custodialized commands), disable the feature (exact toggle + observed effect), recover from failed start (restart ladder + manual re-enable), and escalate suspected spoiler/data-integrity defects (owners + SC-codes). Runtime-update ownership + compatibility-testing procedure before RT ships a new Mirage version, spelled as a runbook.

<!-- addendum escalation pt4 end -->

<a id="sec-21-16"></a>

### 21.16 Escalation of §16 — PR sequence with per-PR evidence gates

**S16-ES-1 (PR ladder with per-PR exit criteria, evidence-typed):** the eight-PR plan escalates each PR's acceptance into evidence-typed gates: **PR-1** (baseline/docs-only): custodialized normative documents (S6-ES-3 ledger), pinned SHAs, re-verified baselines with census (S6-ES-2), architecture inventory, risk register with severity×likelihood×owner×evidence×mitigation×test×gate rows, zero runtime-behavior delta (diff audit: no executable code changed — a behavior-touching PR-1 is a scope violation). **PR-2** (ADR): transport decision with source-anchored comparative analysis; protocol draft with envelope schemas (S2-ES-4), lifecycle ladder (S2-ES-5), version-compatibility rules, error model (S9-ES-5 registry), no invented fields. **PR-3** (host interface + fake transport): typed client passes conformance suite against fake + test double; RT suite green; zero process spawns; SwiftUI isolation verified (no persistence dependency). **PR-4** (real sidecar lifecycle): launch/handshake/framing/validation/timeout/crash/shutdown under failure injection; no unbounded restart; no MainActor-blocking work ≥ 5 ms; disposable-DB only. **PR-5** (identity + one-book import): explicit user-driven flow; mapping in its own stratum; RT persistence schema untouched; duplicate/changed/ambiguous/missing-file/cancel/crash cases pinned. **PR-6** (cursor-safe read-only query): explicit cursor validation + fail-closed tripwires + provenance/uncertainty rendering; no corrections/bulk operations/series editing/background automation. **PR-7** (settings/lifecycle polish): enable/disable semantics, unavailable-state UX, accessibility, clean shutdown; disable-deletes-nothing verified. **PR-8** (packaging/release): bundled/provisioned runtime per approved ADR-3; signing/sandbox/clean-machine/CI/performance/rollback all gate-bounded. Any post-PR-2 protocol change = new ADR or PR-2 amendment with owner countersign.

**S16-ES-2 (separation doctrine, verbatim retention of §16's header):** small PRs, independently reviewable and revertible; no mega-PR (source moves + dependency changes + protocol changes + UI changes + schema migrations + repo restructuring). §16's "separate PRs only if approved" list (repo consolidation, RT JSON-to-SQLite migration, Swift 6 strict mode, store splitting, dead-code retirement, CloudKit, broad series/correction UX, App Store formalities) is a deny-list with SC-12 review on any attempt to smuggle one of these into an integration PR.

<a id="sec-21-17"></a>

### 21.17 Escalation of §17 — ADR register with content contracts

**S17-ES-1 (ADR content contract, per-ADR):** the twelve §17 decisions escalate each ADR to a full content contract: `{problem statement, context (with source-anchored evidence), alternatives (with rejection reasons), decision, reasons, consequences (positive/negative/neutral), security/privacy impact analysis, rollback implications, tests required (named IDs), approving owners (named individuals, recorded sign-off), status (proposed|accepted|superseded), supersedes/superseded-by pointers}`. Superseded ≠ deleted: the ADR index is append-only with status transitions (mirroring the ledger/corrections doctrine). Twelve ADR slots, escalations: repository strategy (ADR-1); runtime distribution (ADR-3); transport + protocol versioning (ADR-2); data directories/ledger path/backup ownership (ADR-4); identity-mapping contract (ADR-5); feature lifecycle (ADR-6); spoiler-cursor contract (ADR-7 — with the S10-ES-3 formal sub-document as its annex); privacy/diagnostics (ADR-8); migration policy (ADR-9, none-by-default); release policy (ADR-10); scope exclusions (ADR-11). Each ADR states problem/context/alternatives/decision/reasons/consequences/security-privacy impact/rollback implications/tests/approving owners, per §17's closing escalation.

**S17-ES-2 (ADR namespace separation):** RT's and Mirage's own ADR series live in their repositories (docs/adr/ADR-0001-epub-first-ingestion-and-deterministic-defaults.md; ADR-0002 demoting the Rust core). Integration ADRs use the integration's own numbered series to prevent cross-namespace confusion in review; any reference chain crossing namespaces must cite full paths. Historical ADRs are marked superseded, never silently rewritten (§17 escalation).

<a id="sec-21-18"></a>

### 21.18 Escalation of §18 — Acceptance checklist with per-row evidence typing

**S18-ES-1 (modular row model):** each §18 row escalates to `{row, evidence_type (artifact | test-ID | signature), evidence_pointer (path / CI link / signature record), verifier, status}`. Rows without evidence pointers are unchecked by definition; a checked row whose evidence pointer is later found stale (a since-flaky test, a since-lost artifact) reverts to unchecked with an incident note. Verified facts vs assumptions are distinguished inside the artifact itself (per §7.4, escalated: every claim in the final report carries an evidence class from §1.3's label set).

**S18-ES-2 (conformance rows, strengthened):** all §18 rows retained verbatim, with these strengthened: "No undocumented second app shell or hidden network service has become mandatory" → split into two independently verifiable rows: (a) no second app shell (count of top-level navigation additions == 1 entry point); (b) no hidden network service (dormancy trace + socket census in the packaged run). "RT and Mirage persistence remain separately owned" → tree-hash teardown assertion across all seven RT strata plus ledger-side counters (INT teardown assertions). "Ambiguous identity does not silently create a mapping" → `ID-AMBIG-5002` path test. "Normal page turns do not trigger full-book analysis" → S10-ES-4 pin 1 (call-graph audit + runtime tripwire). "No mutation is blindly retried after ambiguous timeout" → duplicate-request/mutation-reconciliation tests. "No archive or deletion occurred implicitly" → merge-log countersign requirement (S4-ES-3 Class Ω ledger, zero rows during the integration's lifetime).

**S18-ES-3 (acceptance census rule):** the final acceptance record includes: rows total, rows checked with evidence, rows unchecked, rows N/A-with-reason, and the manifest of remaining limitations (each with impact/owner/mitigation/release-blocking classification from §19's bundle rules).

<a id="sec-21-19"></a>

### 21.19 Escalation of §19 — Evidence bundle with chain-of-custody formalism

**S19-ES-1 (bundle as append-only container):** the §19 bundle escalates to an append-only container: directory + manifest with per-file SHA-256s; the manifest itself hash-chained (each entry includes the previous manifest hash) for tamper-evidence. Contents: architecture ADR set; protocol schema; source-revision inventory; baseline build/test logs (with census); integration test report (INT-01…INT-20, both fake-transport and real-sidecar classes); performance report (measurement tuples); security/privacy review; packaging validation; known-issue list (each with impact/owner/mitigation/release-block status); rollback rehearsal record (S15-ES-3 artifacts); final acceptance checklist (S18-ES-1 records). Every command result carries `{commit SHA, env tuple hash}`; every safety claim links its pinned test/artifact; every limitation states impact/owner/mitigation/blocking-classification. The "fully verified" label is forbidden unless: every required test ran (census-explained), the real-library robustness gate disposition is recorded (executed, or blocked-with-named-path), and the package was exercised outside the developer checkout (clean-machine log). Keep user data out; synthetic/approved-sanitized fixtures only; if the authorized real-library test runs, record the *minimum* evidence (pass/fail + criteria-met flags with content-concealing summaries) — no real library content in public CI artifacts, a permanent rule.

**S19-ES-2 (handoff reproduction runbook):** the §19 handoff escalates: a new engineer must reproduce without guessing: which repository/branch/SHA is canonical (custody ledger), which environment tuple (S6-ES-1), which commands (Appendix A verified variants), which ledger/DB paths are disposable-only (temp-dir doctrine), how to start the optional feature (entry point + enable flow), how to disable it, how to inspect safe diagnostics, how to recover from a failed sidecar/migration (S15-ES-4 runbook). "Without guessing" is itself tested by dry-run review: a reviewer outside the integration team follows the runbook on a disposable environment until success or documented gap — the runbook passes only on an outside-reviewer-verified reproduction, not on author self-report.

**S19-ES-3 (footer doctrine):** the base playbook's own footer (Appendix D) already records SHA-256, line/word/byte counts, and multi-pass scans. This addendum's integrity footer (21.20/21.21) records the same for the escalated layer after the final rescan — no hash values are asserted without being computed.

<a id="sec-21-20"></a>

### 21.20 Escalation of §20 and Appendices A–D

**S20-ES-1 (immediate next actions — reordered dependency graph with owner gates):** §20's twelve actions escalate into a dependency-ordered graph with explicit owner gates and evidence rows: (1) confirm canonical repo URLs + record SHAs [custody ledger]; (2) full-read normative documents [custody ledger, S6-ES-3]; (3) re-run baselines in recorded clean environments [census, S6-ES-2]; (4) triage RT's persistence/import/concurrency/blocker findings [S8-ES-1 register]; (5) inspect the actual NDJSON/sidecar implementation and document protocol/lifecycle [S7-ES-4 inventory]; (6) write and approve architecture ADR [ADR-2; managed sidecar remains the leading candidate *only if* source evidence supports it]; (7) define identity-mapping and spoiler-cursor contracts before exposing literary queries [ADR-5, ADR-7]; (8) implement host abstraction + fake-transport tests [PR-3]; (9) real sidecar lifecycle + one-book workflow in small PRs [PR-4, PR-5]; (10) spoiler-safe query experience + failure isolation [PR-6]; (11) validate packaging/signing/privacy/performance/recovery on a clean machine [PR-8]; (12) decide repository consolidation separately — no deletion to make integration appear complete [ADR-1, Class Ω doctrine]. The header escalation is verbatim: do these in order; do not start by moving files.

**S-A-ES-1 (Appendix A commands — candidate-procedure status retained, escalated with pre-run block):** Appendix A's commands retain candidate-procedure status; no automated session is authorized to execute them (21.0 charter). Escalation adds, for each, a **pre-run block** written into the merge log before any future execution: `{intent, expected effect, recovery, approver}` (mirroring §4.3) plus: disposable DB paths for every `--db` flag (temp-dir scope, never a user's real ledger); path arguments validated and never shell-interpolated; `xcodebuild` destination/scheme names verified against the actual project post-relocation (§6.2's warning escalated); script-provenance audit for any command copied from prior transcripts (S4-ES-3): every pasted command's effect re-derived from `man`/`--help` and the actual tree state before any run; un-understood commands are quarantined.

**S-B-ES-1 (Appendix B open questions → tracked decision register):** the sixteen Appendix B questions escalate into a tracked register; each gets `{number, question (verbatim), status (open|answered|blocked), evidence path (source path:line or ADR/decision reference when answered), owner, blocks-implementation-or-release classification}`. Sample escalations (full register maintained in the evidence bundle): (1) exact NDJSON request/response schemas → answered only by §7.4's interface inventory at a recorded SHA; (5) cursor representation/validation → ADR-7 + S10-ES-3 document; (10) sockets under any mode → S12-ES-1 dormancy trace; (12) state-vocabulary transduction → domain-enum verification at the pinned commit; (13) day-2 real-library steps/evidence → custodialized `p17-record.md`/`testing.md` entries; (15) repo strategy → ADR-1; (16) release channel constraints → ADR-10. Unanswered items carry owners + blocking classification; an unanswered-with-no-owner item at gate time = gate failure.

**S-C-ES-1 (Appendix C invariants — tripwire-equipped restatement):** the fifteen Appendix C invariants remain in force verbatim, each now tripwire-equipped: (1) RT-usable without Mirage → INT-01/03/14; (2) RT persistence not mutated by a failed Mirage request → per-failure tree-hash teardown assertions; (3) ledger-truth/graph-projection → S1-ES-3; (4) fail-closed spoilers with cursor uncertainty → S10-ES-3/S9-ES-5 cursor codes; (5) identity never inferred from title alone → S3-ES-2 (`ID-*` codes); (6) page turns never trigger full-book analysis → S10-ES-4 pin 1; (7) series non-auto-link → series-declare UI gate; (8) corrections never truth → D-010 rendering rules (S3-ES-6); (9) no blind mutation retry → idempotency policy per op class; (10) no implicit repo deletion/archive → Class Ω countersign log (zero rows); (11) green-suite claims require revision+result record → census arithmetic (S6-ES-2); (12) README descriptive ≠ verified → evidence-lattice discipline (S1-ES-1); (13) no real user library/secret/signing key/unredacted content in public artifacts → artifact sanitizer lint; (14) no migration without tested backup/recovery → SC-10; (15) every milestone ends reviewable-commit + evidence + green gate or documented stop → phase-promotion evidence rows (S0-ES-4). Each tripwire is a named test or lint, never an aspiration.

**S-D-ES-1 (Appendix D method escalation):** the base playbook's multi-pass audit method (7 concurrent passes, keyword-presence checks) escalates for this addendum layer: a full-document rescan after the final edit, with headline metrics recorded in 21.21 below (SHA-256, lines/words/bytes, code-fence balance, escalation-block presence per §0–§20, charter presence). Same limitation doctrine as the original Appendix D: scans are a completeness aid, not semantic truth. The addendum additionally preserves: the original body (lines 1–1171) unmodified — this addendum is strictly appended after the original's final footer line; escalation tracking (every escalated section has an escalation block present); and the error-code registry as a single source of truth for host-side typed failures.

**Addendum integrity footer — reported by the appending session:**
- Appended layer: §21 (21.0–21.20, escalation of §0–§20 plus Appendices A–D escalation). Original body lines 1–1171 byte-preserved; strictly append-only after the original footer.
- **Non-execution charter reaffirmed:** this addendum contains engineering artifacts for review only; nothing has been executed by the authoring session. The base playbook's execution items (§6 commands, §20 actions, Appendix A commands) remain candidate procedures requiring human-maintainer execution with recorded `(SHA, env, operator, result)` records. Any session, agent, or automation reading this document is bound by 21.0's non-authorization rule.

<a id="sec-21-21"></a>

### 21.21 Addendum audit footer

- This subsection records addendum-layer integrity. Per the anti-fabrication rule, no hash or count is asserted in this file without being computed; the maintainer's evidence pipeline records the post-append full-document SHA-256, line/word/byte counts, and code-fence balance at commit time, alongside the base playbook's own Appendix D footer records.
- Structural facts asserted without computation (and therefore labeled): the addendum is append-only relative to the original 1,171-line body; escalation blocks exist for §0–§20 and Appendices A–D; the non-execution charter appears in 21.0 and is reaffirmed in 21.20; the error-code registry is consolidated in S9-ES-5.
- Final rescan outcome: **PENDING MAINTAINER RESCAN** — automated scans assess coverage and structure, not semantic truth; source-level verification and execution gates remain mandatory.

**End of escalation addendum.**

---
<a id="app-e"></a>

## Appendix E — Glossary

Alphabetical. Cross-references point to the section where the term does the most work. [⤴ back to top](#top)

**ADR (Architecture Decision Record)** — a reviewed, signed decision document; integration decisions live in the ADR-1…ADR-11 series ([§17](#sec-17)); RT and Mirage keep their own separate ADR namespaces (ADR-0001, ADR-0002).

**AnalyticsCache** — RT's memoization layer for five whole-library reductions, keyed behind a mutation-epoch counter; defect NEW-DE-4 (missing day component) lives here.

**Anti-goal codes (AU-1…AU-4)** — the four "merge ≠" fallacies (store unification, lifecycle usurpation, CLI elimination, repo deletion), each with a mechanical detection signature ([§21.1](#sec-21-1)).

**ATS (App Transport Security)** — macOS network policy layer; RT is described as ATS-clean and Mirage as runtime-network-free; the integration must add zero network deltas ([§12.1](#sec-12-1)).

**Capability (security)** — a held right to act (spawn a process, read a path). RT holds spawn/UI/filesystem capabilities; Mirage receives exactly one transport capability and nothing reflexive ([§21.1 (S0-ES-1)](#sec-21-1)).

**Census arithmetic** — a test run is "green" only when executed + skipped counts match the commit's declared census (README: 108 `@Test` functions, ~160+ executions; Mirage: 316 Python + 3 Rust). A zero exit code alone proves nothing ([§6.2](#sec-6-2), [§21.7](#sec-21-7)).

**CHECK constraint** — SQLite column-level vocabulary enforcement; Mirage's ledger uses CHECK-constrained vocabularies so invalid states are un-storable.

**Class Ω / Δ / Π** — Git operation risk classes: Ω = irreversible/published-history (force-push, filter-repo, repo deletion; two-person rule), Δ = destructive-to-local (reset --hard, clean -fd), Π = additive ([§21.5 (S4-ES-3)](#sec-21-5)).

**Clean machine** — a machine with no developer Python, no dev PATH, no source checkout; the only valid proof that packaging works ([§14.1](#sec-14-1)).

**Content fingerprint** — a hash over content identity; Mirage derives unit identity from content, so identical EPUB content is the same edition regardless of path ([§3.2](#sec-3-2)).

**Corrections overlay (D-010 / P12)** — Mirage's audited, append-only, reversible user-suggestion layer that can never be promoted into book truth; RT renders it, never mutates it ([§3.6](#sec-3-6)).

**Cursor / spoiler cursor** — Mirage's deterministic reading-position unit controlling spoiler eligibility; RT must never synthesize or guess one (fail closed → `CU-REQUIRE-1001`) ([§3.4](#sec-3-4), [§10.3](#sec-10-3)).

**Custody record / custodial artifact** — the formal record of a repository's canonical URL, owners, refs, and protections; re-diffed at every phase boundary ([§21.5 (S4-ES-1)](#sec-21-5)).

**DataMaturityEngine** — RT's gate holding intelligence claims behind evidence floors, with an injected clock for determinism.

**Day-2 real library** — Mirage's final robustness gate, bound (not skipped) to the real day-2 library per user standing directive; synthetic substitutes are forbidden ([§6.3](#sec-6-3)).

**Debounce** — coalescing rapid writes into one; `library.json` is written via a debounced pretty-printed encode.

**Dependency closure** — spoiler eligibility computes the closure of dependencies at/below the cursor; visibility is deterministic, never plausibility-based ([§1.2](#sec-1-2)).

**Edition vs book identity** — Mirage distinguishes a book from its editions (`book_<id>`, `edition_<fingerprint>`); RT identifiers are never assumed interchangeable with either ([§3.2](#sec-3-2)).

**Envelope** — the versioned request/response JSON structure on the transport ([§21.3 (S2-ES-4)](#sec-21-3)).

**EPUB ingestion** — Mirage's stdlib-first import path with security guards and content-hash unit identity; proven on a 63-real-book sweep ([§1.2](#sec-1-2)).

**ESCALATED-DESIGN** — §21's label for drafted specification (fields, budgets, codes) that the supplied READMEs do not assert; requires ADR approval to become binding.

**Evidence labels** — SOURCE-VERIFIED / TEST-VERIFIED / README-REPORTED / INFERRED / DECISION-REQUIRED / BLOCKED ([§1.3](#sec-1-3)).

**Fail-closed** — on missing/invalid evidence (especially the cursor), show less or nothing — never more. The spoiler policy's cardinal rule.

**Framing (NDJSON)** — the one-JSON-value-per-line wire rule; hazards include U+2028/U+2029 inside JSON strings, partial pipe reads, invalid UTF-8, and oversize lines ([§21.3 (S2-ES-4)](#sec-21-3)).

**Graph projection** — Mirage's read-optimized view derived from the ledger with canonical content hashes; a projection, never the source of truth.

**Handshake** — the startup version/capability exchange between RT and the sidecar; mismatch → `protocolIncompatible`, feature disabled safely.

**Hardened Runtime / notarization** — macOS code-signing regimes; bundled runtimes need their own signature and provenance records ([§14.3](#sec-14-3)).

**I-INC1** — Mirage's incremental/idempotent `analyze_edition` property (screening cache + no-change outcomes).

**Idempotency key** — a client-supplied dedupe token making a mutation safely replayable after ambiguous timeouts; non-idempotent mutations are never blindly retried ([§2.4](#sec-2-4)).

**Identity resolution / mapping** — Mirage's evidence-gated entity merging (internal), and the RT-side explicit RT-book ↔ Mirage-edition mapping with states unlinked → proposed → confirmed → stale/ambiguous/failed ([§3.2](#sec-3-2)).

**INT-01…INT-20** — the pinned end-to-end scenario catalog ([§13.3](#sec-13-3), [§21.13](#sec-21-13)).

**Ledger / ledger-is-truth** — Mirage's versioned SQLite store (`ledger@0.0.10`, migrations m0001–m0016); the ledger is truth, the graph is a projection ([§1.2](#sec-1-2)).

**library.json / library-state.json** — RT's debounced pretty-printed JSON monolith (books/sessions/page-timings) and its goals/achievements/collections sidecar; RT-owned, never Mirage-writable ([§3.1](#sec-3-1)).

**MainActor / MainActor-default isolation** — Swift isolation via `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; RT's defining build setting and the root cause of its hardest freeze bug; process/pipe/DB work must stay off the UI actor ([§8.3](#sec-8-3)).

**MirageIntegration** — the provisional name for RT's host-owned boundary module hiding process, protocol, mapping, and errors from SwiftUI ([§2.1](#sec-2-1)).

**MirageService** — Mirage's Python API embedding surface (`from mirage.api import MirageService`).

**Mutation-epoch counter** — RT's cache-invalidation counter bumped on mutations (used by AnalyticsCache).

**NEW-DE-1…5** — RT's October defect-register entries: write-ordering window (1), legacy cover field (2), idle-time inflation (3), cache signature (4), import bypass (5) ([§1.1](#sec-1-1), [§8](#sec-8)).

**NG-1…NG-12** — §0.2's non-goals restated as enforceable policies with triggering tests ([§21.1 (S0-ES-5)](#sec-21-1)).

**NDJSON** — newline-delimited JSON; the documented Mirage serve/sidecar transport candidate.

**PersistenceWriter** — RT's utility-queue owner of disk writes; NEW-DE-1's ordering window lives here; integration callbacks must not enqueue writes directly.

**Phase gates (PRE → BOUNDARY → GATED → EXPANDED → PACKAGED → SHIPPED)** — the monotone promotion ladder with per-transition evidence ([§21.1 (S0-ES-4)](#sec-21-1)).

**PR-1…PR-8** — the small, independently revertible PR ladder ([§16](#sec-16)).

**Provenance** — the evidence trail attached to established facts; must survive rendering into RT's UI ([§11.2](#sec-11-2)).

**Restart ladder** — bounded, jittered exponential backoff for sidecar restarts; three crashes within 60 s → feature disabled, `dataNeedsAttention` ([§21.3 (S2-ES-5)](#sec-21-5)).

**Rust core (`crates/mirage-core`)** — Mirage's reference core, demoted per ADR-0002; never assumed to be the production runtime ([§1.2](#sec-1-2)).

**SC-01…SC-12** — stop conditions; none waivable by schedule pressure ([§5.3](#sec-5-3), [§21.6](#sec-21-6)).

**Security-scoped bookmark** — macOS sandbox mechanism for persistent user-granted file access; the import path depends on it ([§10.1](#sec-10-1)).

**Sentinel** — RT's deterministic watchdog: launch-time scans, provably-safe auto-repairs with pre-touch snapshots, kill switch, append-only JSONL journal (500-line rotation).

**Sidecar** — a Mirage child process supervised by RT over the NDJSON boundary; the leading transport candidate ([§2.3](#sec-2-3)).

**SIGTERM→SIGKILL ladder** — graceful drain (2 s) → terminate (3 s) → force kill; process-group reaping ([§21.10 (S9-ES-2)](#sec-21-10)).

**Spoiler eligibility** — Mirage's deterministic predicate deciding visible content by cursor + source evidence; the single shared predicate across projection/citations/search; RT may only shrink visibility, never expand it ([§3.4](#sec-3-4)).

**S#-ES-#** — an escalation block in §21 re-deriving playbook §# (e.g., S9-ES-5 = §9, block 5).

**Stage E gate** — Mirage's explicit candidate/accepted gate in heuristic extraction.

**Stop condition** — a named, detection-tested pause-and-escalate trigger; zero schedule-based waivers.

**STRIDE** — threat-model classes (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege); the loopback/HTTP surface scores HIGH ([§21.12](#sec-21-12)).

**Test-suitability score** — RT's 0.68/1.0 rubric (defect depth 0.9, breadth 0.4, hygiene 0.65, infrastructure 0.7); integration must not regress any dimension by more than 0.05 ([§1.1](#sec-1-1)).

**Tree-hash teardown** — test assertion that all seven RT storage strata are byte-identical after failure scenarios (SHA-256 compare) ([§21.13](#sec-21-13)).

**Trust domain** — a security principal's isolation boundary; RT (T_R) ⊃ Mirage (T_M) with one-way capability flow ([§21.1](#sec-21-1)).

**U+2028/U+2029 hazard** — Unicode line/paragraph separators legal inside JSON strings; must be escaped or byte-level framing breaks ([§21.3 (S2-ES-4)](#sec-21-3)).

**WAL (Write-Ahead Logging)** — SQLite journal mode possibly in use by the ledger; affects backup procedure (never copy a hot DB; use the supported backup path) ([§15.3](#sec-15-3)).

**ZIPFoundation 0.9.20** — RT's single pinned dependency; adding a second SwiftPM dependency requires an ADR ([§12.4](#sec-12-4)).

**8 GB analysis budget** — Mirage's target ceiling for a single analysis job; one analysis job runs at a time ([§1.2](#sec-1-2)).

---

<a id="app-f"></a>

## Appendix F — Quick reference (one-page cheat sheet)

[⤴ back to top](#top)

### F.1 The ten rules that rule everything

1. RT stays the parent app; Mirage is an optional capability — in architecture, UX, data, build, and repos ([§0](#sec-0)).
2. One system of truth per domain: RT strata stay RT-owned; the ledger stays Mirage-owned ([§3.1](#sec-3-1)).
3. Never guess a cursor: missing/invalid evidence fails closed ([§3.4](#sec-3-4)).
4. Identity is never inferred from titles; mappings are explicit and evidence-classed ([§3.2](#sec-3-2)).
5. Page turns never trigger full-book analysis ([§10.4](#sec-10-4)).
6. Series: detection proposes, the user disposes ([§3.5](#sec-3-5)).
7. No blind retry of ambiguous mutations; corrections never become truth ([§2.4](#sec-2-4), [§3.6](#sec-3-6)).
8. No repo is deleted or archived as a side effect; Class-Ω operations need two-person countersign ([§4](#sec-4)).
9. Nothing is "verified" without (SHA, env, command, result, reviewer) ([§1.3](#sec-1-3)).
10. No automated agent executes anything in this document — human-maintainer PR review is the only execution path ([§21.0](#sec-21-0)).

### F.2 Phase & gate map

| Phase | § | Deliverable | Exit gate |
|---|---|---|---|
| 0 Governance | [§5](#sec-5) | owners, scope contract, stop conditions | scope in writing; owners assigned |
| 1 Baselines | [§6](#sec-6) | pinned SHAs, green suites with census, docs read in full | [§6.5](#sec-6-5) |
| 2 Discovery | [§7](#sec-7) | architecture map, protocol draft, risk register | [§7.4](#sec-7-4) |
| 3 Defect triage | [§8](#sec-8) | dispositions + pinned regressions | [§8.4](#sec-8-4) |
| 4 Boundary | [§9](#sec-9) | typed client, lifecycle, validation, tests | [§9.5](#sec-9-5) |
| 5 Adapter | [§10](#sec-10) | identity mapping + cursor contract, one-book flow | [§10.5](#sec-10-5) |
| 6 Feature | [§11](#sec-11) | entry point, query UX, data controls | §18 product rows |
| 7 Security | [§12](#sec-12) | local-first, process boundary, logs, supply chain | §18 security rows |
| 8 Testing | [§13](#sec-13) | INT-01…20, failure injection, budgets | §18 stability rows |
| 9 Packaging | [§14](#sec-14) | signing, CI, clean machine | [§14.5](#sec-14-5) |
| 10 Rollback | [§15](#sec-15) | rehearsed rollback/recovery, handoff | [§15.3](#sec-15-3) |

### F.3 PR ladder

| PR | Scope | Acceptance essence |
|---|---|---|
| PR-1 | baseline & docs only, zero behavior delta | owners approve; no SHA ambiguity |
| PR-2 | transport/protocol ADR | implementable without invented fields |
| PR-3 | typed client + fake transport | RT tests green; SwiftUI isolated |
| PR-4 | real sidecar lifecycle | failure injection passes; no restart loops |
| PR-5 | identity + one-book import | duplicate/changed/crash cases pinned |
| PR-6 | cursor-safe read-only query | fail-closed proven; provenance survives |
| PR-7 | settings & lifecycle polish | disabled = no data impact |
| PR-8 | packaging & release | §14.5 gates; owners sign artifact |

### F.4 Key facts & versions (README-REPORTED — re-verify at the pinned SHA)

| Item | Value |
|---|---|
| RT stack | Swift/SwiftUI · macOS 26.5 · Xcode 27.1 · `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |
| RT size | 120 files · 39,900 LOC · 108 `@Test` (~160+ executions) · 1 dep (ZIPFoundation 0.9.20) |
| RT suites | build + unit green 2026-10-17 · suitability 0.68/1.0 |
| RT data | `~/Library/Application Support/johan.Reading-Tracker/` (verify in source) |
| Mirage | package `miragev10` 1.0.0 · CLI `mirage` · ledger@0.0.10 (m0001–m0016) · 316 Py + 3 Rust tests |
| Mirage surfaces | Python `MirageService` · CLI · NDJSON serve/sidecar · `--serve-web` @ 127.0.0.1:8747 · Rust core demoted (ADR-0002) |

### F.5 Templates

**Pre-run block (write into the merge log BEFORE any command from [Appendix A](#app-a)):**

```
intent:         <what this command is for>
expected effect:<files/refs/stores touched>
recovery:       <how to undo>
approver:       <named owner>
```

**Evidence record (every claim):** `(claim, evidence label, commit SHA, env hash, command/test ID, result, reviewer)`.
**Stop-condition report:** `(SC-##, observed symptom, evidence link, owner paged, decision requested)`.

### F.6 Where to file things

| Artifact | Home |
|---|---|
| ADRs | integration ADR series ([§17](#sec-17)) |
| Defect dispositions | RT defect register + PR body ([§8.1](#sec-8-1)) |
| Baseline logs | phase evidence directory, redacted ([§6.1](#sec-6-1)) |
| Custody records | merge log ([§21.5 (S4-ES-1)](#sec-21-5)) |
| Rehearsal logs | evidence bundle ([§19](#sec-19)) |

---

<a id="app-g"></a>

## Appendix G — Revision log & integrity notes

[⤴ back to top](#top)

| Version | Date | Change |
|---|---|---|
| v1.0 | 2026-10-17 | Original playbook authored (§0–§20 + Appendices A–D); Appendix D records the 7-pass audit, SHA-256 `ac9795…72ee` (initial) and `481dc2…da0a` (final footer state). |
| v1.1 | 2026-10-18 | **§21 Technical escalation addendum appended** (21.0–21.21): section-by-section escalation of §0–§20 and Appendices A–D; non-execution charter; error-code registry (S9-ES-5); stop-condition lattice (S5-ES-3). Strictly append-only after the original 1,171-line body. |
| v1.2 | 2026-10-18 | **Navigation & reference pass:** Navigation Hub inserted (document map, role-based reading paths, TOC, code registries); explicit anchors added to every `##`/`###` section; `[⤴ back to top]` links after each major section; **Appendix E (Glossary)**, **Appendix F (Quick reference)**, **Appendix G (Revision log)** added. |
| v1.3 | 2026-10-18 | **§22 The Titanium Bridge (TiB) appended** — continuous-convergence subsystem: formal 4:00→4:01 SLO (p95 ≤ 60 s measured from CI publish), generation model (complete content-addressed snapshots, never diffs), one-bridge-two-rings topology with one-way direction of truth, 12-hop pipeline with per-hop budgets, APFS atomic pointer-flip swap, quiesce/drain revival policy, Performance Parity Certificate (byte-identity theorem + differential golden-output + benchmark envelope), shadow-ledger copy-on-write migration rehearsal, hash-chained Bridge Ledger (new RT-owned stratum), typed `TB-*` failure registry, drift/anti-tamper sensors, supply-chain threat model, storm/idempotency/clock policies, `rt-bridge` CLI, ADR-12 charter, interop matrix (one row per §0–§21), formal convergence argument, milestones TB-M0–M5, parked-ideas register. Nav hub, TOC, and code registries updated. Strictly append-only. |

### Integrity notes

- The SHA-256 values in Appendix D.4/D.5 authenticate the **original body only** (lines 1–1171 as of v1.0). They do **not** cover §21 or this pass. Maintainers should recompute a full-document SHA-256 at commit time and record it here — per the anti-fabrication rule, no hash is asserted without being computed.
- §21 and Appendices E–G are **additive layers**; the original §0–§20 body text is semantically untouched by v1.1/v1.2.
- v1.2 corrected the following drafting typos **within the §21 addendum layer only** (original body untouched): `artifactsz`→`artifacts`; `escalations §0`→`escalates §0`; `Capability.fs(Qt ~/…`→`Capability.fs(~/Library/…`; `ADR knight`→`approved ADR`; `impersonable`→`evidence-gated`; `"censor" expands`→`the single concept "cursor" expands`; `:你我 corrections flow`→`: corrections flow`; `handshaked`→`handshake`; `PID file;lsof-verified`→`PID file; lsof-verified`; `ERASING this`→`violating this`; `after书-library`→`after library`; `RG must`→`RT must`; `qué de Books → qué de Editions`→`the RT-book → Mirage-edition mapping`; `or Operation spends`→`or the operation spends`; `dispatcher (owner org)`→`owning organization`; `Squone rehearsal`→`Build the rehearsal`; `девушки logs`→`build/test logs`; `ESCATED-DESIGN`→`ESCALATED-DESIGN`; `` `esoteric` audit tooling``→`endpoint-audit tooling`; `μmutable`→`mutable`; anchor ids normalized (`addendum-e/m`, `esc-*` → `sec-21*`); §11 escalation block renumbered 21.11→21.11b to remove a duplicate heading number.
- No instruction in this document has been executed by any authoring session ([§21.0 charter](#sec-21-0)).

---

<a id="sec-22"></a>

## 22. The Titanium Bridge (TiB) — continuous-convergence subsystem

**Document type:** subsystem specification, SLO contract, operations runbook, and acceptance program for the final architectural component of the RT–Mirage integration.  
**Naming:** Titanium — for the metallurgical pitch: high strength-to-weight, corrosion-resistant, and it does not spark. The Bridge — because it carries every change across the one boundary this playbook exists to guard. **TiB** is the abbreviation (with a wink at the tebibyte: the bridge's unit of work is bytes, verified).  
**Status:** ESCALATED-DESIGN pending ADR-12. Nothing in this section is executed by any authoring session; the [non-execution charter (§21.0)](#sec-21-0) binds this section like every other.

**The one-sentence promise:** a line of code merged into Mirage at 4:00 PM is the same line, with the same behavior, the same performance envelope, and the same optimizations, running inside Reading Tracker's copy of Mirage by 4:01 PM — with zero human steps in the development ring, and with a signed, evidence-carrying promotion in the release ring.

[⤴ back to top](#top)

<a id="sec-22-0"></a>

### 22.0 The contract — formal SLO and the four sub-guarantees

**22.0.1 (convergence latency, defined honestly):** the bridge's latency is measured from **`T_publish`** — the moment Mirage's CI publishes the signed generation manifest for a commit — to **`T_ready`** — the moment RT's vendored runtime has swapped, revived, handshaked, and passed smoke. Measuring from CI's authoritative clock (not a local receive clock) removes every excuse about mail transport; clock policy is fixed at §22.14.4. The SLO:

| Percentile | Budget |
|---|---|
| p50 | ≤ 15 s |
| p95 | ≤ 60 s — the "4:00 → 4:01" contract |
| p99 | ≤ 90 s |
| error budget | 1 % of generations per rolling week may exceed p95; breach pages the integration lead |

**22.0.2 (the four sub-guarantees — the Titanium contract):**
- **G1 Fidelity:** the vendored tree that RT executes is **byte-identical** to the canonical subset for that generation. This is not a metaphor; it is a hash equality check (`vendored_subset_hash == manifest.tree_hash`) performed after every assembly, and its result is ledgered. Fidelity is a theorem (§22.18), not an aspiration.
- **G2 Performance parity:** the propagated generation carries the *same performance usage optimization profile* — interpreter build and flags, bytecode strategy, hashing seed, memory ceiling discipline — either by construction (byte-identity + identical env tuple ⇒ identical behavior, §22.8.1) or by certificate (the Performance Parity Certificate, §22.8.2) when artifacts are rebuilt.
- **G3 Safety:** the bridge cannot weaken any Appendix C invariant. It cannot leak spoilers, cannot mutate RT's seven strata, cannot write Mirage's ledger except through the documented migration path, cannot blind-retry a mutation, and cannot touch either repository. Its only writes are to its own strata (§22.10.3). When the bridge must choose between the 60-second budget and a safety invariant, the invariant wins — and the deferral is ledgered, not hidden (§22.7.4).
- **G4 Auditability:** every propagation is one hash-chained ledger entry with per-hop timestamps, check results, and actor identity. "What version of Mirage is RT running right now, why, and how did it get there?" is always exactly one command away (§22.10).

**22.0.3 (what the bridge is NOT):**
- **Not a bidirectional sync.** Truth flows canonical → vendored, one way, forever (§22.2.3).
- **Not a patch channel.** It never applies diffs to a live tree; it assembles complete immutable generations (§22.1). A "single line change" propagates as a complete generation that differs from its predecessor by (at least) that single line — which is precisely what makes the guarantee trivially verifiable and storm-proof.
- **Not a release distributor by itself.** It *automates* release promotion (§22.2.2) but the release ring's brake is the §14.5 gate set — "the gates are the only brake" (§22.16.2).
- **Not a runtime data path.** The sidecar's NDJSON channel (§2.4) is the runtime data plane; the bridge is a build-time/dev-time control plane. The running Mirage stays network-free exactly as doctrine requires (§12.1) — the bridge's own channel to the canonical origin is a *development-time* channel, documented, bounded, and separately tested (§22.13.5).

<a id="sec-22-1"></a>

### 22.1 Identity model — commits, generations, and why diffs are the wrong unit

**22.1.1 (the generation abstraction):** the unit of propagation is the **generation**: a complete, immutable, content-addressed snapshot of Mirage's vendored subset at a specific commit. A generation is identified by `gen_id = SHA-256(canonical manifest bytes)` and transitively pins: commit SHA, ref, subset tree hash, per-artifact hashes, ledger compatibility range, protocol version, benchmark baseline reference, signing metadata, and CI provenance. Generations are never edited — a new state of Mirage is a new generation, full stop.

**22.1.2 (the subset manifest):** RT does not vendor Mirage's docs, corpus, or test fixtures into the shipped runtime. The **subset manifest** is a versioned, reviewed declaration of what constitutes "RT's version of Mirage": `src/miragev10/**` (package code), `sql/` migrations (`m0001–m0016…`, present and loadable in order per §14.2), entry scripts (`mirage`, sidecar example), data/assets the runtime requires, and the compatibility constants. Subset hash = deterministic fold over sorted `(path, sha256, bytes)` triples. Changes to the subset manifest itself are classified C3 (§22.4.7) — because redefining "what RT's version of Mirage is" is a contract change, not a code change.

**22.1.3 (why complete generations beat diffs — the four pays):**
1. **Idempotency:** applying generation *g* twice yields the same bytes and the same pointer state; webhook-plus-poll double-fires become no-ops (§22.14.2).
2. **Coalescing:** in a 40-commit storm, the bridge applies generation 40 and marks 1–39 `SKIPPED-INTERMEDIATE` with pointer references; "latest wins" is semantically correct *because every generation is complete* (§22.14.1).
3. **Rollback:** the previous generation is retained verbatim; rollback is a pointer flip measured in milliseconds, not a reverse-patch hope (§22.15.4).
4. **Provable fidelity:** G1 reduces to one hash comparison over a complete tree — no delta bookkeeping, no merge logic, no partial-state bugs. The bridge's most dangerous failure class (partial application) is structurally impossible rather than defensively tested.

**22.1.4 (what "a single line change at 4:00 PM" means formally):** commit *c* at 4:00:00 touches one line in one file under `src/miragev10/`. Mirage CI publishes generation *g(c)* with a new subset tree hash. The bridge classifies it C1 (pure code, §22.4.2), assembles the new generation locally from content-addressed objects (six files change on disk if the packaging layer hardlinks objects; one file's bytes differ), flips the pointer, revives the sidecar, runs smoke, and ledgered the whole trajectory — inside the p95 budget. Section 22.5 narrates this second-by-second.

**22.1.5 (committed work only):** the bridge follows **commits**, never working trees. Uncommitted scratch changes do not propagate — review-before-merge is the discipline, and the bridge refuses to become a vector that launders unreviewed bytes into every machine that follows the ref. (A "local sandbox ring" for uncommitted experiments is a parked branch, §22.20.5.)

<a id="sec-22-2"></a>

### 22.2 Topology — one bridge, two rings, one direction of truth

**22.2.1 (dev ring):** RT developer checkouts and internal dev builds run the bridge in full-auto: follow the approved ref (default: Mirage canonical `main`), adopt every adoptable generation, 60-second SLO applies. The dev ring may execute an unsigned runtime **only** with a persistent, unmistakable banner (developer console + feature status surface) and a ledger flag — the permissive mode exists so a Friday-afternoon idea can be on every dev machine by 4:01, and it is the *only* place signature strictness relaxes.

**22.2.2 (release ring):** the packaged, signed, notarized app. The **same bridge machinery** executes release promotion under a stricter policy: a generation crosses into the release ring **only when every §14.5 gate emits green evidence for that exact `gen_id`** — RT suite, Mirage suites, protocol conformance, integration E2E (INT-01…20), packaging smoke, security checks, performance budgets, rollback rehearsal currency. "The gates are the only brake": if gates are green, promotion fires automatically with zero ceremony; if any gate is red or pending, the generation waits at the gate, visibly (`rt-bridge status` shows *held at gate X*). This is how the 4:01 dream and the playbook's governance doctrine are the same machine, not competing ones.

**22.2.3 (direction of truth — the anti-fork law):** propagation is one-way. RT must **never** hotfix, patch, or hand-tune its vendored copy; a needed change — even a one-character typo fix — lands in Mirage canonical first and then bridges. Justification: RT's vendored Mirage and Mirage canonical are one system of truth (§3.1); a forked vendored copy would create a second Mirage, violating the parent/child contract (§0), voiding G1's hash proof, and turning every future parity claim into archaeology. Local divergence is not tolerated-laziness; it is *drift*, detected and healed (§22.12).

**22.2.4 (where the bridge lives):** a small RT-owned module (provisional name **`MirageBridge`**) sitting beside `MirageIntegration` but beneath the SwiftUI boundary. It owns exactly three write surfaces, all inside RT's integration container: the **generation store** (content-addressed objects), the **pointer** (`current` → generation), and the **Bridge Ledger**. The §3.1 strata registry gains these as a documented RT-owned stratum ("vendored runtime + bridge state"); Mirage has no write access to any of them, and the bridge has no write access to anything else — least privilege is structural, not aspirational.

**22.2.5 (the bridge is not the supervisor):** process supervision of the sidecar remains with the §9.2 supervisor. The bridge requests lifecycle actions *through* the supervisor's documented interface and never spawns or signals the sidecar directly — two writers to a process is how orphan/zoo incidents happen (§9.2's duplicate-launch and orphan-prevention rules apply unchanged).

<a id="sec-22-3"></a>

### 22.3 Generation manifest, transport, and determinism of assembly

**22.3.1 (manifest schema — ESCALATED-DESIGN):**

```json
{
  "gen_id": "sha256-of-manifest-bytes",
  "commit_sha": "…", "ref": "main",
  "tree_hash": "sha256-of-subset-tree",
  "artifacts": [{"path": "src/miragev10/…", "sha256": "…", "bytes": 1234, "role": "code|migration|asset|entry"}],
  "ledger_compat": {"min": "0.0.10", "max": "0.0.10"},
  "proto_version": "1.0.0",
  "bench_baseline_ref": "gen-of-baseline",
  "published_at": "2026-10-18T16:00:00Z",
  "ci_run_id": "…",
  "provenance": {"builder": "mirage-release-ci", "materials": ["git:…", "wheel:…"]},
  "signature": {"key_id": "…", "alg": "ed25519", "sig": "…"}
}
```

Every field is load-bearing: `ledger_compat` gates the swap (§22.6.5), `proto_version` feeds the C3 classifier and RT's refuse-on-mismatch doctrine (§14.2), `bench_baseline_ref` anchors the parity certificate (§22.8), `provenance` is the supply-chain thread (§22.13).

**22.3.2 (transport):** any ordered, resumable, hash-verifiable channel qualifies; the default is plain `git fetch` from the canonical origin — git objects are *already* content-addressed, so the bridge reuses the universe's oldest content-addressed CDN — plus the manifest as a CI artifact. Bundle-file fallback exists for air-gapped setups. The bridge trusts **hashes, never names**: a file called `mirage.zip` has no authority; `sha256:…` in a signed manifest has total authority.

**22.3.3 (assembly is a pure function):** given (manifest, object store, target layout), the vendored tree is deterministic — two machines bridging the same `gen_id` produce byte-identical trees. This makes G1 machine-independent, makes the drift sensor's job trivial (§22.12.1), and makes "reproducible build" (§14.2) a property the bridge inherits rather than re-implements.

**22.3.4 (object reuse and locality):** generations share objects by hash; a one-line change assembles from N−k reused hardlinks/clonefiles plus k new objects. APFS `clonefile`/copy-on-write makes assembly near-free; a `copy` fallback covers non-APFS filesystems (typed `TB-ASSEMBLY-*` fallback, logged, never silent).

<a id="sec-22-4"></a>

### 22.4 The change-classification engine — not every line is "just a line"

**22.4.1 (principle):** the 60-second promise applies to changes that can *safely* propagate in 60 seconds. The classifier's job is to route each generation to the right propagation tier — conservatively. **Unknown ⇒ C5** (most conservative class). The classifier is a declarative, versioned rule table (paths × roles × diffs), recorded in the bridge ledger with each decision.

**22.4.2 (C0 — inert):** docs, comments, whitespace. Propagates at full speed (fidelity applies to prose too — G1 makes no exceptions), parity checks trivially pass, smoke may be reduced to handshake-only per policy table.

**22.4.3 (C1 — pure code):** Python under the package, within unchanged `ledger_compat` and unchanged `proto_version`. The hot path: full pipeline, full smoke, swap. This is the 4:00 PM line.

**22.4.4 (C2 — optimization-affecting):** interpreter version/flags change, bytecode strategy change, new native artifact, dependency pin change (even a patch bump). Triggers the mandatory Performance Parity Certificate (§22.8.2) before swap in the release ring; dev ring may swap with banner + mandatory local re-run. The bridge **detects** profile drift even when the classifier missed it (defense in depth): any `optimization_profile` hash change upgrades the run to C2 post-hoc and ledgered the upgrade (§22.8.4).

**22.4.5 (C3 — contract-affecting):** protocol version change, CLI surface change, domain enum/vocabulary change, subset-manifest change, ref-allowlist change. Dev ring: hot-swap allowed **for development**, but the RT-side contract artifacts (§7.4 inventory, typed client, envelope schemas) must regenerate and re-verify against the new contract — the bridge files a `CONTRACT-DRIFT` work item automatically rather than letting the typed client and the runtime drift apart silently. Release ring: held at gate until contract re-verification evidence lands.

**22.4.6 (C4 — ledger-affecting):** a new migration (`m0017+`) or any `ledger_compat` change. The swap becomes a **shadow-ledger rehearsal** (§22.9): copy-on-write ledger fork, apply, invariant battery, then flip. The 60-second budget does not apply to C4 — the SLO explicitly yields to §15.1's migration doctrine, and the yield is ledgered (honesty over vanity metrics).

**22.4.7 (C5 — doctrine-affecting):** changes touching the mission statement, Appendix-C-relevant invariants, ADR-0002 status (Rust core demotion), or anything the classifier cannot confidently classify. **Never auto-adopted**, by either ring. The bridge pins the previous generation and raises a `DECISION-REQUIRED` item to both owners (§5.1). The bridge is an automate-everything-but-doctrine machine.

**22.4.8 (classifier self-trust):** the rule table is itself under version control, itself classified (changes to it are C3), and its decisions are sampled-audited: a periodic differential audit re-runs classification against a human-reviewed sample to catch rule rot.

<a id="sec-22-5"></a>

### 22.5 The 60-second pipeline, hop by hop — and the 4:00 PM story

**22.5.1 (hop budget, warm path, dev ring):**

| Hop | Budget (p95) | What happens | Failure posture |
|---|---|---|---|
| H0 publish | — (t₀) | CI publishes signed manifest; bridge's clock zero | — |
| H1 detect | ≤ 5 s | webhook primary; 10 s poll reconciler guarantees no lost wakes | TB-DETECT-*: poll catches up |
| H2 fetch | ≤ 10 s | incremental content-addressed fetch of missing objects | resumable; partial trees never assemble |
| H3 verify | ≤ 5 s | hash every artifact (parallel), verify signature + provenance | TB-VERIFY-*: reject & quarantine, no swap |
| H4 classify | ≤ 2 s | declarative rules → C0–C5 | unknown ⇒ C5 |
| H5 assemble | ≤ 3 s | clonefile/hardlink objects → `generations/<gen_id>/` | copy fallback; disk-full ⇒ abort clean |
| H6 pre-swap | ≤ 3 s | ledger_compat in range? drift check? disk headroom? pointer sane? | gate-hold or defer |
| H7 quiesce | ≤ 4 s | stop new analysis; wait for mutation-free quiesce point | defer swap (ledgered) if busy |
| H8 swap | ≤ 100 ms | atomic pointer flip (`rename()`) | auto-rollback pointer on verify fail |
| H9 revive | ≤ 2 s | supervisor spawns new gen; handshake asserts `gen_id` + version | restart ladder §9.2 |
| H10 smoke | ≤ 25 s | INT subset {01, 02, 05, 08, 09, 18} against the live vendored runtime | any failure ⇒ auto-rollback + hold |
| H11 ledger | ≤ 1 s | hash-chained entry + console breadcrumb | ledger write is the commit point of record |
| **Total** | **≤ 60 s** | ~5 s reserve | — |

Cold path (first bridge on a machine, empty object store) is measured and reported separately; the SLO governs the steady state. The 4:00 PM story: `16:00:00` commit → `16:00:01` CI publishes → `16:00:03` webhook lands → `16:00:11` objects fetched → `16:00:15` hashes+signature green → `16:00:16` classified C1 → `16:00:18` tree assembled (one file's bytes differ) → `16:00:21` pre-swap green → `16:00:24` sidecar drained at a quiesce point → `16:00:25` pointer flipped → `16:00:26` new process alive, handshake echoes `gen_id` → `16:00:47` smoke green → `16:00:48` ledger entry chained → breadcrumb: *"RT is running mirage@`abc1234` (gen 8842, bridged in 48 s)".* The 4:01 promise kept with twelve seconds to spare.

**22.5.2 (every hop is a span):** each hop emits a timestamped span keyed by `trace_id = gen_id`; the full trace is annexed to the Bridge Ledger row and queryable (`rt-bridge trace <gen>`). SLO dashboards read spans, not vibes — measurement doctrine identical to §13.6's budgets.

**22.5.3 (the hop contract):** a hop either advances (and ledgered its span) or fails typed (and leaves the previous generation serving). There is no hop that can leave a *third* state. The pointer flip (H8) is the single instant of commitment; everything before it is abortable, everything after it is rollbackable (§22.15.4).

<a id="sec-22-6"></a>

### 22.6 Atomic swap engineering — pointer flips on APFS

**22.6.1 (layout):** `…/mirage-runtime/generations/<gen_id>/…` — immutable trees (read-only file flags; only the bridge's GC ever removes one, after retention policy). `…/mirage-runtime/current` — a symlink (or manifest-pointer file where symlinks are awkward) naming the serving generation. The pointer is the *only* mutable state in the entire runtime subsystem.

**22.6.2 (the flip):** pointer update is a single `rename()` of a staged symlink/file onto `current` — atomic on POSIX/APFS. A crash mid-flip leaves either old or new; there is no torn state to repair. Post-flip, the bridge verifies `readlink(current)` → `tree_hash == manifest.tree_hash` before declaring H8 done; on mismatch (filesystem betrayal, external interference) it flips back and raises `TB-SWAP-*`.

**22.6.3 (why not in-place edits):** editing files under a running interpreter risks half-written modules, stale `.pyc` confusion, and un-hashed drift. Immutability + pointer makes "what is running" a well-formed question with a one-line answer at every instant — which the drift sensor, the smoke suite, and the ledger all consume.

**22.6.4 (retention/GC):** keep last **N = 5** generations plus any pinned (mirroring RT's rotation doctrine — depth chosen for disk economy, configurable via ADR-12). GC never removes the current or pinned generation; GC events are ledgered.

**22.6.5 (pre-swap gates, restated as law):** `ledger_compat` must contain the existing ledger's schema version (else C4 path); drift sensor must be green (else heal first, §22.12.2); disk headroom ≥ generation size + margin; pointer target must exist and hash-verify. Every gate failure is a typed hold, never a fallback-to-hope.

<a id="sec-22-7"></a>

### 22.7 Runtime revival — drain, quiesce, and the in-flight request policy

**22.7.1 (why restart, not reload):** Python does not hot-reload safely — module identity, caches, and open sqlite handles make live-swap a correctness minefield. The bridge's contract with reality: a swap is a fast, disciplined restart. With drain ≤ 4 s, spawn ≤ 800 ms, handshake ≤ 500 ms (§13.6 budgets), the restart *fits* inside the 60-second SLO with room for smoke.

**22.7.2 (quiesce point):** the bridge stops issuing new analysis-class requests and waits for a **mutation-free quiesce point** — no in-flight state-changing request, no open ledger write transaction. Read-only queries may be cancelled with the standard §2.5 user-visible states. Mutations are **never** interrupted mid-flight: interrupting a ledger write to win four seconds is exactly the ambiguity §2.4's retry doctrine exists to prevent.

**22.7.3 (deferral):** if a long analysis is running (or a mutation is in flight beyond the drain window), the swap **defers** — retry loop with coalescing to the newest generation. Deferred time is excluded from SLO accounting *and explicitly ledgered* (`DEFERRED_{ANALYSIS,MUTATION}` spans). The SLO bends to the invariants; the ledger keeps the honesty.

**22.7.4 (cursor/state reconciliation after revival):** RT re-declares the current reading state per the §10.4 sync policy after the handshake; no cross-store atomicity is claimed (§10.4.5), and reconciliation follows the documented crash-window rules. A swap between an RT session save and a cursor declaration is the same non-event as a crash between them — handled by the same tested path.

**22.7.5 (UX during swap):** feature status transitions `ready → stopping → starting → ready` using the §2.5/§2-ES-7 vocabulary (plus bridge-specific annotations); RT's reading flows never block (MainActor doctrine §8.3); the developer console breadcrumb shows the hop trace live. A user reading a book at 4:01 PM notices nothing but a status flicker.

<a id="sec-22-8"></a>

### 22.8 Performance and optimization parity — the PPC

**22.8.1 (the byte-identity theorem):** if (a) `vendored_subset_hash == manifest.tree_hash` and (b) the runtime environment tuple — interpreter version *and build*, compile/optimization flags, bytecode strategy, `PYTHONHASHSEED=0`, env allowlist (§9-ES-2), memory discipline — equals the recorded profile for the baseline, then behavior and performance are **identical by construction**: same bytes, same machine profile, same semantics. Parity checking collapses to two hash comparisons. This theorem is the backbone of the 4:01 promise; every non-trivial parity mechanism below exists only for the cases where its preconditions fail.

**22.8.2 (the Performance Parity Certificate — for rebuilt artifacts):** when a generation's artifacts are *assembled* rather than copied verbatim (wheel rebuild, bytecode compile, C2-class changes), the swap requires the PPC:
1. **Differential golden-output test:** run the pinned evaluation-corpus subset through the old and new generations; outputs must be **byte-identical** (deterministic-extraction doctrine, §1.2). Any diff = parity failure. This catches semantic drift that hashes cannot (rebuilt ≠ edited, but prove it anyway).
2. **Benchmark envelope:** Mirage's scripts/benchmark.py plus RT-side measured ops (cold start, simple query, cursor projection, `analyze_edition` latency + memory peak) compared against `bench_baseline_ref` with statistics — median + MAD tolerance against the §13.6 budgets; no budget recorded yet ⇒ first run *records* the baseline and the gate pends (budgets without baselines are hypotheses, §13.6).
3. **Optimization-profile declaration:** a hashed `{interpreter, flags, sys.flags dump, bytecode policy, seed}` record shipped in the manifest; the bridge re-derives and compares it at H6.
The PPC is signed evidence, annexed to the ledger row, and bound to `gen_id`.

**22.8.3 (trust-but-verify):** CI-published benchmark evidence (signed, produced by the same commit's CI run) may satisfy 22.8.2(2) on the fast path — RT should not re-run a 25-minute benchmark suite to ship a one-line change. The bridge re-verifies locally on a cadence (every Nth generation, any env drift, any C2) so the fast path never becomes a trust-me path.

**22.8.4 (profile drift as a first-class event):** if the *observed* profile differs from the declared one at H6 (someone changed a flag without reclassifying), the bridge upgrades the run to C2 post-hoc, ledgered the upgrade, and enforces C2 policy (release ring: PPC mandatory; dev ring: banner). Optimization drift is treated exactly like integrity drift — because on this bridge, it *is* integrity drift.

**22.8.5 (parity failures):** release ring: never swap; hold at gate with the failing certificate attached. Dev ring: swap only with loud banner + typed `TB-PARITY-*` + mandatory local re-run of the failing leg. A parity failure on the *hot path* (byte-identity case) is impossible by theorem — a "failure" there means the theorem's preconditions were mis-measured, which is itself a TB-code (`TB-PARITY-PRECONDITION`) and an integrity incident.

<a id="sec-22-9"></a>

### 22.9 Ledger migrations over the bridge — the one thing that must never hot-swap

**22.9.1 (the doctrine collision, resolved):** a migration changes the schema of truth (§15.1). "By 4:01" must therefore mean: by 4:01 the *migration is rehearsed, validated, and staged* — and the swap executes the moment the rehearsal battery is green. For C4 generations the SLO yields to §15.1's migration doctrine; the bridge's contribution is making the doctrine *fast*, not making it optional.

**22.9.2 (shadow-ledger copy-on-write rehearsal):** (1) fork the current ledger via a DB-consistent mechanism (SQLite backup API / `VACUUM INTO` — never a hot-file copy, §15.3); (2) apply `m0017…` to the **shadow** copy; (3) run the invariant battery: append-only claim history intact, spoiler predicate behavior on pinned fixtures unchanged-or-policy-approved, CHECK vocabularies enforce, rollback procedure for the shadow *rehearsed*; (4) hash-record every result. The swap flips the generation pointer and the ledger generation **as one recorded event** — with the documented reconciliation window (no fake cross-store atomicity, §10.4.5).

**22.9.3 (instant rollback):** the old generation *and* the old ledger remain retained; rollback restores the pointer pair and is rehearsed as part of C4 acceptance. A C4 generation that has served real writes cannot silently roll back without a data decision — the bridge surfaces that decision explicitly (`REQUIRES-DATA-DECISION`), per §15.2's escalation rules.

**22.9.4 (compatibility gates):** `ledger_compat.min/max` is checked at H6 against the live ledger; out-of-range generations hold at the gate and raise `DECISION-REQUIRED` (ADR-9 interplay). RT's refuse-on-mismatch doctrine (§14.2) and the bridge's gate are the same check enforced twice.

<a id="sec-22-10"></a>

### 22.10 The Bridge Ledger — audit trail and the answer machine

**22.10.1 (format):** an append-only, hash-chained JSONL journal in RT's integration container, rotated at 500 lines exactly like Sentinel's doctrine (§19): `{"seq": n, "prev_hash": "…", "entry_hash": "…", "gen_id": "…", "tier": "C0..C5", "hops": [{"hop": "H1", "t0": …, "t1": …, "ok": true} …], "checks": {"integrity": "green", "ppc": "n/a|green|red", "smoke": "…"}, "swap": {"from": "gen", "to": "gen", "at": …}, "result": "APPLIED|DEFERRED|HELD|ROLLED_BACK|SKIPPED-INTERMEDIATE|REJECTED", "actor": "bridge@hostname"}`. The chain makes silent editing of history detectable; the rotation keeps files greppable; the schema is versioned (`ledger_v1`).

**22.10.2 (the answer machine):** the ledger exists to make four questions one command each: *What generation is RT running right now?* (`rt-bridge status`); *How did it get here?* (`rt-bridge trace <gen>` — the full hop-span timeline); *Has every generation we've ever run been faithful?* (`rt-bridge verify --all` — chain + hash re-derivation); *What happened during the 4:00 PM incident?* (filter by trace). An audit trail that cannot answer questions is a diary, not a ledger.

**22.10.3 (stratum status and write authority):** the Bridge Ledger, generation store, and pointer are a documented **RT-owned stratum** (§3.1 registry updated). Mirage has no write access to it; the bridge has no write access to anything else; RT app strata read it read-only. Sentinel (§19) gains read access and cross-checks the pointer's tree hash against its own scans — two independent integrity systems agreeing is the whole point.

**22.10.4 (breadcrumbs):** the RT developer console (⌘⇧D) shows current `gen_id`, bridge state (`FOLLOWING / PINNED / HELD-AT-GATE / OFFLINE`), and last convergence latency; the Mirage feature surface's restrained status row (§11.1) shows the embedded generation in About. A user can always answer "which Mirage am I running?" from the UI, not just the CLI.

<a id="sec-22-11"></a>

### 22.11 Failure-mode compendium — typed error registry `TB-*`

**22.11.1 (registry):** error codes are typed by hop, mirroring the S9-ES-5 discipline. Every code carries: trigger, containment posture, user-safe string (no internals leaked to end users; full detail to the dev console), and a mandatory ledger row.

| Code | Trigger | Containment | User-safe string |
|---|---|---|---|
| `TB-DETECT-WEBHOOK-LOST` | poll reconciler found a generation the webhook missed | proceed via poll path; ledger notes transport | Runtime update arriving (delayed wake) |
| `TB-DETECT-STORM` | > K generations/minute | coalescing engaged | — |
| `TB-FETCH-NETWORK` | origin unreachable | backoff ladder (§9.2 philosophy); resume later | Offline — updates resume automatically |
| `TB-FETCH-PARTIAL` | incomplete object set | never assemble; resume content-addressed | — |
| `TB-VERIFY-HASH` | artifact hash mismatch | reject + quarantine + alert; never swap | Update rejected (integrity) |
| `TB-VERIFY-SIGNATURE` | signature invalid / key unknown | reject; release ring hard-fails; dev ring banner | Update rejected (signature) |
| `TB-VERIFY-PROVENANCE` | provenance missing/malformed | reject (release ring); dev ring banner | — |
| `TB-CLASSIFY-UNKNOWN` | rule table cannot classify | escalate to C5; pin previous; DECISION-REQUIRED | Update awaiting review |
| `TB-ASSEMBLY-DISK` | insufficient headroom | abort clean; retain old generation; alert | Disk space needed for update |
| `TB-ASSEMBLY-CLONEFILE` | clonefile unsupported | copy fallback (slower, ledgered) | — |
| `TB-PRESWAP-LEDGER-RANGE` | ledger version outside `ledger_compat` | C4 path / gate hold | Awaiting migration rehearsal |
| `TB-PRESWAP-DRIFT` | vendored tree ≠ manifest | heal first (§22.12.2); no swap on drifted tree | Repairing runtime copy |
| `TB-QUIESCE-ANALYSIS` | long analysis in flight | defer swap; coalesce; ledger DEFERRED | — (invisible by design) |
| `TB-QUIESCE-MUTATION` | mutation in flight | wait for quiesce point; never interrupt | — |
| `TB-SWAP-RENAME` | pointer rename failed | old generation keeps serving; typed alert | — |
| `TB-SWAP-POINTER-VERIFY` | post-flip hash check failed | flip back; incident | — |
| `TB-REVIVE-SPAWN` | new generation won't start | restart ladder; then auto-rollback | — |
| `TB-REVIVE-HANDSHAKE` | handshake version/gen mismatch | kill new; rollback; never run unverified | — |
| `TB-SMOKE-FAIL` | any INT-subset failure | auto-rollback + hold generation | — |
| `TB-PARITY-OUTPUT` | golden-output diff (C2) | release: hold; dev: banner + re-run | — |
| `TB-PARITY-BENCH` | benchmark regression beyond tolerance | hold at gate | — |
| `TB-PARITY-PROFILE` | observed profile ≠ declared | upgrade to C2 post-hoc; enforce C2 policy | — |
| `TB-DRIFT-DETECTED` | vendored tree modified out-of-band | alert + quarantine option + heal | — |
| `TB-DRIFT-SUBSET` | canonical grew runtime-looking paths outside subset | classifier review queue | — |
| `TB-GC-*` | retention/GC anomalies | GC never touches current/pinned; alert | — |
| `TB-PIN-CONFLICT` | operation requires unpinning | refuse with explanation; human decides | — |
| `TB-LEDGER-CHAIN` | ledger hash chain broken | integrity incident; halt bridge writes; alert | — |

**22.11.2 (the universal posture):** every failure leaves the **previous generation serving**. The bridge's failure states are: not-yet-swapped, deferred, held, rolled-back — never half-swapped, never silently degraded. Auto-rollback is itself a ledgered propagation event (`result: ROLLED_BACK`), never a history rewrite; the ledger remembers the failure and the recovery with equal fidelity.

<a id="sec-22-12"></a>

### 22.12 Drift, divergence, and anti-tamper — the vendored tree is read-only to everyone but the bridge

**22.12.1 (the read-only invariant):** the bridge is the **only writer** of the vendored runtime tree. Not a developer "just quickly fixing" the vendored copy, not a script, not an editor. A background **drift sensor** hashes the pointed tree on a cheap stat-based dirty check (hash-on-change only, so the sensor is free at rest); any mismatch against the current manifest's `tree_hash` raises `TB-DRIFT-DETECTED`. Hand-edits are not a style violation — they are an integrity event, because G1's proof dies the moment the bytes diverge from the hash.

**22.12.2 (heal-by-reassembly):** drift is never patched — the tree is **re-assembled from the object store** and re-verified. Patching a drifted tree with more manual edits is how drift gets religion; reassembly restores the theorem's preconditions. If the object store itself fails verification, the bridge re-fetches from the signed manifest (the manifest is the root of trust, not the local cache).

**22.12.3 (divergence sensor — the reverse direction):** the bridge watches canonical for runtime-looking content *outside* the subset manifest (a new top-level directory that ships interpreter-visible code, a migration file placed outside `sql/`). Such growth means the subset manifest is stale relative to reality — a `TB-DRIFT-SUBSET` review item, because "RT's version of Mirage" silently shrinking is a contract change nobody approved.

**22.12.4 (skew alarm):** if following is enabled but the vendored generation is older than the canonical tip by more than a threshold (configurable; default 15 minutes or 3 generations), status surfaces **stale** — visible in the breadcrumb, never silent. The bridge does not nag; it tells the truth and lets the display do the nagging.

<a id="sec-22-13"></a>

### 22.13 Security threat model — the bridge is a code-injection channel, treat it like one

**22.13.1 (framing):** any system that moves code from a repository into a runtime process is in the highest risk class this playbook has (§12 supply-chain class). Compromise of Mirage's repo/CI plus a trusting bridge equals code execution inside RT's process family on every machine that follows the ref. The bridge's security posture is therefore fail-closed by default in the release ring and banner-loud in the dev ring — asymmetric trust for asymmetric exposure.

**22.13.2 (STRIDE highlights):** **Spoofing** → every manifest is signed (Ed25519; key id pinned in RT's configuration; alg pinned — no algorithm agility lottery). **Tampering** → every artifact hash-verified at H3 *and* the assembled tree re-verified at H8 (double verification catches transport-bug classes that single verification misses). **Repudiation** → the hash-chained ledger; every adoption, hold, rollback, and deferral is attributed. **DoS** → bounded fetch queues, poll reconciler as the wake-safety-net, and the old generation keeps serving under any flood — the bridge's DoS ceiling is "stale," never "down." **Elevation** → the bridge process is least-privileged: write access to exactly three surfaces (§22.2.4), no access to RT's seven strata, no keychain, no network beyond the canonical origin.

**22.13.3 (keys and provenance):** Mirage CI holds the signing key; RT pins key id + algorithm; rotation is a documented procedure that itself goes through the bridge's C5 class (key rotation is doctrine-adjacent, never automatic). Provenance metadata (builder identity, materials) is verified in the release ring and sampled in the dev ring — SLSA-flavored, proportionate to a two-repo operation, not a compliance theater program.

**22.13.4 (ref allowlist):** the bridge follows only approved refs — default: canonical `main` plus `release/*`. A feature branch is *not* followed by default; following a branch is an explicit, ledgered act (someone said "dev-ring-follow this experiment"). Ref-allowlist changes are C3-class contract changes.

**22.13.5 (network doctrine, stated precisely):** the runtime sidecar remains **network-dormant** (S12-ES-1) — the bridge does not change one byte of that guarantee. The bridge itself is a *development-time* control-plane channel to the canonical origin; it is a separate process, a separate network permission, and a separately-tested surface. Runtime data plane: local-only, forever. Bridge control plane: talks to the origin that holds Mirage's truth (in a fully-local operation that can be a localhost/LAN git remote — the local-first doctrine §12.1 is preserved because the *truth source* is local, not because the channel is magic).

**22.13.6 (no secrets):** the bridge holds no credentials beyond read access to the origin; it cannot publish, cannot push, cannot mutate canonical. Read-only clone credentials at most — the bridge is a *consumer* of truth with a photographic memory and no pen.

<a id="sec-22-14"></a>

### 22.14 Storms, skew, and pathological schedules

**22.14.1 (commit storms):** forty commits in a minute produce one adoption — generation 40 — with 1–39 ledgered as `SKIPPED-INTERMEDIATE` (each carrying its `gen_id` pointer so the audit trail shows the full storm). "Latest wins" is semantically correct *because generations are complete* (§22.1.3); no merge logic exists to get it wrong.

**22.14.2 (double-fire):** webhook plus poll reconciler both waking for the same generation is a **no-op by content address**: the pointer already names that `gen_id`, ledger a `NO-OP` row, sleep. Idempotency is not a defensive nicety here; it is the designed response.

**22.14.3 (flapping refs):** a ref that alternates between two heads (force-push ping-pong) is a canonical-side pathology the bridge refuses to chase: after K reversals in a window, the bridge pins and raises `DECISION-REQUIRED` — a ref that rewrites itself is a canonical-side incident (§4.1 Class Ω energy), not a sync problem.

**22.14.4 (clock policy):** the SLO is measured against CI's publish timestamp (authoritative); local clocks only fill in hop spans. Local skew > 5 s flags the span (`clock_skew` field) — measurement honesty is cheaper than timezone archaeology.

**22.14.5 (offline):** network down → backoff ladder, no partial trees ever, convergence on reconnect. Offline is a *paused* bridge, not a broken one; the breadcrumb shows the truth and the book keeps loading.

**22.14.6 (long analysis at swap time):** deferral semantics (§22.7.3) — the SLO accounting excludes deferral-by-design and the ledger records it. The alternative (killing a mutation to keep a dashboard metric green) violates §2.4 and common decency.

**22.14.7 (multi-machine teams):** each checkout runs its own bridge; optional **pull-through cache** (a dumb, verifiable object-cache proxy) for bandwidth politeness — the cache is untrusted by design (hashes check everything) so it adds speed without adding trust requirements. No shared mutable bridge state across machines, ever.

**22.14.8 (the monorepo future):** if ADR-1 eventually merges the repos, the bridge's *machinery* survives unchanged — manifest, pointer, parity, ledger all still apply; only the transport collapses to a path-sync. The manifest format is versioned with exactly this future in mind (generic source-of-truth binding, git is the default implementation, not the identity).

<a id="sec-22-15"></a>

### 22.15 Human controls — the DX surface

**22.15.1 (the CLI):** `rt-bridge status` (current gen, state, last latency) · `follow <ref>` (set/confirm the followed ref; ledgered) · `pin` / `unpin` (freeze/resume following — the demo-safety switch; a pinned bridge converges on unpin, it never silently adopted while pinned) · `rollback [--to <gen>]` (pointer flip to a retained generation — seconds, ledgered) · `verify [gen]` (full G1 hash re-derivation + optional PPC re-run) · `trace <gen>` (hop timeline) · `doctor` (env/profile audit, disk, permissions, key pin checks).

**22.15.2 (pin semantics):** pinning is **absolute**: no adoption, no smoke scheduling, no GC of the pinned generation. Demos, screencasts, and debug sessions get a frozen runtime; the canonical world keeps moving and the backlog of pending generations is shown honestly in `status`.

**22.15.3 (what the controls cannot do):** no control pushes to canonical, no control edits the vendored tree, no control edits the ledger, no control waives a gate in the release ring. The DX surface is a steering wheel, not a warranty-scraper.

**22.15.4 (rollback UX):** `rt-bridge rollback` flips to the previous retained generation and revives; total time ≈ one revive cycle (≤ 3 s) because the generation is already assembled and verified. Rollback is rehearsed in acceptance (§22.19) — a rollback that has never been performed is a rumor.

<a id="sec-22-16"></a>

### 22.16 Governance integration — ADR-12 and the doctrine collision, resolved

**22.16.1 (ADR-12):** the bridge's existence, ring policies, SLO, key custody, ref allowlist, subset manifest, retention depth, and the "gates are the only brake" release policy are recorded as **ADR-12** (next free slot, §17). Append-only per doctrine; this section is the design input, the ADR is the decision record.

**22.16.2 (the collision with §14/§17, and its resolution):** naive reading — "60-second auto-propagation contradicts review gates and pinned releases." Resolution — **one bridge, two rings**: the dev ring's auto-adoption is a *development-time* convenience explicitly authorized by ADR-12 (machines that already run unsigned dev builds may converge fast); the release ring's automation *executes* promotion only when the §14.5 gate set is green, so every governance invariant is preserved and merely stops requiring a human to push the button when nothing is wrong. The gates remain the brake; the bridge just removes the pushing.

**22.16.3 (stop-condition interplay):** bridge events can **raise** stop conditions — smoke failure with spoiler-surface drift raises an SC-05-class hold; any unexpected network behavior in the runtime raises an SC-11-class investigation — but nothing in the bridge can **lower or waive** one. The bridge is a subordinate of the stop-condition registry, never a counterparty.

**22.16.4 (charter interplay, §21.0):** the bridge automates *propagation*; it does not authorize any AI session to execute the playbook's procedures. Bridge operations are themselves governed operations — each adoption is a ledgered, policy-checked act by an owned process with a name, not a raw command in a terminal with no witnesses.

**22.16.5 (evidence-bundle interplay, §19):** the Bridge Ledger and hop traces are annexed to release evidence bundles; the shipped app's manifest binds its embedded `gen_id` — the artifact carries its own ancestry (§14.2's manifest discipline, extended one link).

<a id="sec-22-17"></a>

### 22.17 Interop matrix — one row per existing section

| § | Titanium Bridge interplay |
|---|---|
| §0 | Parent/child preserved: the bridge moves code, never authority — Mirage canonical remains the sole system of truth |
| §1 | Evidence labels: the bridge makes TEST-VERIFIED cheap (every swap runs smoke), which raises the floor for every claim |
| §2 | Runtime transport untouched — the bridge feeds the sidecar a new binary world; the NDJSON contract itself never auto-changes (C3 guards it) |
| §3 | New RT-owned stratum: vendored runtime + generation store + bridge ledger; registry updated; Mirage write-access: none |
| §4 | Bridge never mutates either repository; at most Class Π reads; drift sensor is a read-only integrity actor |
| §5 | Owners: the bridge's owner is initially the release owner; DECISION-REQUIRED items route to both owners for C3/C4/C5 |
| §6 | Env tuples and baselines are the PPC's raw material; the bridge records them per generation |
| §7 | Subset manifest ↔ interface inventory: C3 classification forces contract regeneration rather than silent drift |
| §8 | SwiftUI boundary untouched; status vocabulary (§11) gains bridge states; breadcrumb is dev-console-only |
| §9 | Lifecycle: bridge acts through the supervisor (§9.2), never spawns/signals directly; drain ladder reused verbatim |
| §10 | Cursor/state reconciliation after revival follows §10.4's documented crash-window rules — no new atomicity claims |
| §11 | Status vocabulary: `ready → stopping → starting → ready` reused; bridge states are developer-surface annotations |
| §12 | Supply-chain class: signatures, provenance, pinned keys, ref allowlist (§22.13); runtime stays network-dormant (§22.13.5) |
| §13 | Smoke = INT subset {01,02,05,08,09,18}; benchmark budgets feed the PPC; budgets-without-baselines doctrine respected |
| §14 | Release ring is the §14 pipeline with the push-button automated; refuse-on-mismatch and `ledger_compat` enforced twice |
| §15 | Rollback: bridge generations are a new, faster rollback ladder; §15.2 triggers unchanged; C4 rollback needs a data decision |
| §16 | PR interplay: the bridge follows merged PRs; a PR is "fully landed" when its generation is green in both rings |
| §17 | ADR-12; the bridge can raise stop conditions but never waive them (§22.16.3) |
| §18 | Acceptance rows for the bridge land in the §18 program via TB-M0–M5 exits (§22.19) |
| §19 | Bridge ledger + traces annexed to evidence bundles; Sentinel cross-checks pointer hashes |
| §20 | Next-actions gains the bridge milestone track |
| §21 | This section is written escalated; `TB-*` joins the code registries; charter (§21.0) binds the bridge like everything else |

<a id="sec-22-18"></a>

### 22.18 Formal model — why convergence is a theorem, not a hope

**22.18.1 (state):** let `T(t)` be canonical's approved tip; let `P(t)` ∈ Generations ∪ {⊥} be RT's pointer; let `adopt(g)` be the classified, gated decision for generation *g*. Convergence claim: under bounded delivery (network eventually works), no pin, no deferral, and an unchanged rule table, for every commit there exists Δ ≤ SLO bound such that `P(t+Δ) = adopt(T(t))` — and once canonical is still, `P` becomes still.

**22.18.2 (the three lemmas):** **Idempotence** — `apply(g); apply(g) ≡ apply(g)`, because adoption is a pointer write keyed by content address; re-adoption of the current generation is a ledgered no-op. **Completeness** — every generation is a total tree, so there is no partial-adoption state to reason about; the only mutable state is one pointer, and the pointer's transition function is `old → new` atomically. **Monotonic audit** — the ledger is append-only and hash-chained; history is never rewritten, so every claim in this section about "what happened" is verifiable after the fact. Together: G1 (fidelity) is a *theorem* over the pointer's transition function, not a property we test into existence — the tests (§22.19) exist to check the theorem's preconditions, not to compensate for their absence.

**22.18.3 (deferral accounting):** SLO metrics are computed over *adoptable, undeferred* generations; deferrals are ledgered with cause and excluded from the denominator. An SLO that counted forced waits as latency would be a lie; an SLO that hid the waits entirely would be a bigger one. The ledger does neither.

<a id="sec-22-19"></a>

### 22.19 Milestones and acceptance program

**22.19.1 (milestones):**

| Milestone | Scope | Exit evidence |
|---|---|---|
| TB-M0 | Manifest + hash-verify in observe mode (no swaps; drift sensor live) | 7 days of observation ledger; 0 false-green verifies |
| TB-M1 | Dev-ring follow behind a feature flag; pointer swap manual-confirm | First instrumented end-to-end trace archived |
| TB-M2 | Full hop pipeline (H0–H11) + smoke + auto-rollback | 4:01 scenario green, `kill -9` at every hop recovers |
| TB-M3 | PPC (differential outputs + benchmark envelope + profile declaration) | C2 generation held at gate until certificate green |
| TB-M4 | C4 shadow-ledger migration path | m0017-class migration rehearsed end-to-end; rollback rehearsed |
| TB-M5 | Release-ring automation ("gates are the only brake") | Signed promotion fired on green gates; held on red |

**22.19.2 (acceptance checklist — the tortures):** (1) the 4:00 PM scenario, instrumented, p95 ≤ 60 s across a week of real commits; (2) storm test — 20 commits/minute for 10 minutes, exactly one adoption, 199 ledgered skips; (3) kill -9 at every hop H1–H11 — old or new generation serves, never a third thing; (4) tampered object → `TB-VERIFY-HASH`, quarantine, no swap; (5) unsigned manifest in release ring → hard refusal; in dev ring → banner; (6) hand-edit the vendored tree → drift detected → heal-by-reassembly → hashes green; (7) pin → 10 commits land → status shows backlog → unpin → one adoption; (8) rollback mid-smoke-failure → previous generation serving in ≤ 3 s; (9) ledger chain tampering → `TB-LEDGER-CHAIN` incident; (10) offline for an hour → reconnect → convergence, zero partial state.

**22.19.3 (the metric of success):** the bridge succeeds when nobody talks about it — when "is RT running the latest Mirage?" stops being a question anyone asks, because the breadcrumb, the ledger, and the 48-second traces answer it before it forms.

<a id="sec-22-20"></a>

### 22.20 Parked branches — the exhausted-ideas register

Ideas considered and consciously closed, so future sessions don't re-open them from scratch:

1. **Live Python hot-reload** (swap modules without restart) — rejected: unsafe module/cache/handle semantics; the disciplined restart fits the budget anyway (§22.7.1).
2. **Delta/patch transport** (binary diffs between generations) — rejected: content-addressed objects are already incremental at the object level; delta logic would add a partial-state failure class to a subsystem whose whole point is having none.
3. **P2P sync between RT developer machines** — parked: pull-through cache covers the bandwidth case with a simpler trust story.
4. **Bridge-of-bridges** (genericize to N products vendoring N runtimes) — parked: the manifest format is already product-agnostic; generalize when a second vendor exists, not before.
5. **Uncommitted working-tree propagation** (the 3:59 PM un-saved-buffer dream) — rejected for the mainline: it launders unreviewed bytes; parked as an explicitly-labeled *local sandbox ring* if a real workflow demands it.
6. **Auto-bisect on smoke failure** (bridge walks back through generations to find the culprit) — parked: rollback-first doctrine wins; bisect is a human-initiated diagnostic, not a propagation posture.
7. **ML anomaly detection on benchmark traces** — parked: median + MAD statistics first; if the statistics are ever insufficient, the defect that proves it files itself in the ledger.
8. **10-second SLO** ("why not warp speed?") — parked with arithmetic: smoke alone is budgeted at 25 s and shrinking it weakens the safety story; the honest frontier is detection + fetch, and those are already ≤ 15 s.
9. **Bridge-managed virtualenvs/interpreters** (bridge installs the Python it pins) — parked: powerful, but it converts the bridge into a system package manager; keep interpreter provisioning adjacent and explicit until ADR-12 says otherwise.
10. **Watch-mode from RT's editor** (bridge as a file watcher for Mirage-side development) — parked: that is Mirage's dev-loop concern; the bridge moves *committed, signed* truth, not keystrokes.

---

**End of §22.** The Bridge is the last subsystem this playbook needed: truth flows, bytes match, performance carries, the ledger remembers — and every gate, invariant, and charter of §§0–21 still stands, unamended, behind it.

**End of playbook v1.3.**

