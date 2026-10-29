<a id="top"></a>

# 📚 Twin READMES

> **What this file is:** two complete project READMEs collected into a single handoff document.
> 📱 **Part 1 — “Reading Tracker”** · a macOS reading-analytics app (Swift/SwiftUI)
> 🖥️ **Part 2 — MirageV1.0** · a local-first, spoiler-safe literary knowledge graph (Python + a Rust core)
>
> *The original wording is preserved word-for-word — this pass only repaired copy-paste mangling (shattered tables, mid-word line breaks, stray formatting characters) and added the cover, cheat sheet, and table of contents for easy navigation.*
>
> **Path rule.** Part 2 is the MirageV1.0 README. Its paths belong to that separate repository and are plain text here; only paths under this repository are backticked.

---

<a id="cheat"></a>

## ⚡ At a glance

| | 📱 Reading Tracker | 🖥️ MirageV1.0 |
|---|---|---|
| **One-liner** | macOS reading-analytics app that quietly remembers everything about how you read | “Literary Intelligence Engine” — a local-first, spoiler-safe literary knowledge graph |
| **Stack** | Swift/SwiftUI only · macOS deployment target 26.5 · exactly 1 dependency (ZIPFoundation, pinned) | Python stdlib-first core + SQLite ledger (`ledger@0.0.10`) · reference Rust core (demoted per ADR-0002) |
| **Size & proof** | 120 Swift files · 39,900 raw LOC · 108 `@Test` functions (~160+ executed with parameterization) | 316 Python tests + 3 Rust tests, all green |
| **Status (Oct 2026)** | Building & fully tested · October audit: 13 new defects + 4 release blockers open (§5) | v1.0.0 product era opened (2026-10-17) · readiness 99/100 · last robustness point bound to the day-2 real library |
| **Look here first** | [§5 Open findings](#rt-5) · [`docs/audits/08-deep-audit.md`](#rt-8) | [Current status](#mv-status) · [docs/literary_intelligence_mission_statement.md](#mv-docs) |

---

## 📇 How to navigate

**Part 1 · Reading Tracker** →
[1 · What it is](#rt-1) · [2 · The numbers](#rt-2) · [3 · Current health](#rt-3) · [4 · Where we are](#rt-4) · [5 · Open findings](#rt-5) · [6 · Estimates](#rt-6) · [7 · Strengths & weaknesses](#rt-7) · [8 · Documentation map](#rt-8) · [9 · Build / run / verify](#rt-9)

**Part 2 · MirageV1.0** →
[Current status](#mv-status) · [Quickstart](#mv-quickstart) · [Core principles](#mv-principles) · [Repository layout](#mv-layout) · [Dev dependencies](#mv-deps) · [CLI usage](#mv-cli) · [Embeddable usage](#mv-embed) · [Tests](#mv-tests) · [Documentation index](#mv-docs) · [Graph & audit outputs](#mv-graph) · [Version](#mv-version)

---
---

<a id="part-1"></a>

# 😴 Part 1 — “Reading Tracker”

### A macOS reading-analytics app

> — and one of the most honestly documented indie codebases you'll ever read. Built over ~30 focused working sessions, Jun 17 – Aug 26 2026, then hard-audited and reorganized (Oct 2026). Swift/SwiftUI only. One dependency.

**This README is the project report.** The full audit with file:line evidence for every claim lives in `docs/audits/08-deep-audit.md`. Live registers: `docs/registers/02-defect-register.md` (defects) · `docs/registers/03-fix-log.md` (protocol log) · `docs/registers/04-handoff.md` (where we left off).

---

<a id="rt-1"></a>

## 1 · What it is

**Plain English.** You import your PDFs and EPUBs, read them inside the app, and it quietly remembers everything: how fast you turned each page, what hour you read, what the weather was, what you were doing on your Mac beforehand. It draws a living night-sky background that follows real time and weather, tracks goals/streaks/25 achievement badges, renders a year-in-review slideshow, and has an optional speed-reading mode. A slow-learning "context brain" tries to reconstruct where and why you read. Hidden Developer Console (⌘⇧D) stress-tests the app with 16 fake reader personas; a "Sentinel" watchdog scans for data problems at launch, auto-repairs the provably-safe ones, snapshots everything before touching anything, and reports overnight.

**Technical.** Swift/SwiftUI macOS app, 3 targets, `MACOSX_DEPLOYMENT_TARGET = 26.5`, Swift 5 language mode with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` + approachable concurrency (the project's defining build setting — and the root cause of its hardest freeze bug). Persistence is hand-rolled and layered: a debounced pretty-printed JSON monolith (`library.json` — every book → session → page-turn timing), sidecar `library-state.json` (goals/achievements/collections), keyed-access SQLite for weather snapshots, a content-addressed cover file store (NSCache'd), 10-deep hash-gated backup rotation, `.readingarchive` v1 export/import, and an append-only JSONL Sentinel journal (500-line rotation). Analytics are pure static-namespace engines; `AnalyticsCache` memoizes five whole-library reductions behind a mutation-epoch counter; `PersistenceWriter` owns disk writes on a utility queue; `DataMaturityEngine` gates every intelligence claim behind evidence floors with an injected clock.

---

<a id="rt-2"></a>

## 2 · The numbers (validated by direct count, Oct 17 2026)

| Stat | Value |
|---|---|
| Swift files | 120 — 100 app · 18 unit tests · 2 UI-test stubs |
| Application | 39,900 raw LOC (28,697 code / 5,869 comment / 5,334 blank) |
| Test suite | 2,763 LOC · 108 `@Test` functions (~160+ executed with parameterization); 25 achievement kinds; 16 deterministic personas; 286 top-level types |
| Dependencies | exactly 1 — ZIPFoundation 0.9.20 (pinned) |
| History | 45 commits (Jun 17 – Aug 26 2026) + Oct 2026 audit/reorg commits |
| Toolchain | Xcode 27.1 · deployment target macOS 26.5 |
| Docs | ~30k words of registers, method docs, and session history under `docs/` |
| Repo | 43 MB on disk (30 MB is regenerable `graphify-out/` analysis artifacts — gitignored) |

---

<a id="rt-3"></a>

## 3 · Current health (verified live, not inherited)

- ✅ **`xcodebuild build` → `BUILD SUCCEEDED (exit 0)`** — fresh Debug build of the exact current tree.
- ✅ **`xcodebuild test` (unit target) → `TEST SUCCEEDED`** — full suite green on a fresh run Oct 17, 2026.
- ✅ The once-critical Sep-2 one-line freeze fix (`.environmentObject(dataStore)` on the console window) is now committed (`355d68e`) instead of living only in an uncommitted working tree.
- ⚠️ See [§5](#rt-5) for what's still open.

**Test-suitability score: 0.68 / 1.0** — exceptional defect-pin depth (0.9; nearly every test is named for a numbered historical defect), narrow architecture breadth (0.4; views/network/readers untested), good hygiene (0.65), sound infrastructure (0.7).

---

<a id="rt-4"></a>

## 4 · Where we are project-wise

Every planned remediation arc and feature package has been executed, with the suite green at every phase boundary:

| Track | Status |
|---|---|
| Bug-hunt remediation (Stages 1–4, 10 compile + behavioral + observer/calendar fixes) | ✅ shipped, pinned |
| Four-phase remediation of the full RA-002 re-audit | ✅ shipped |
| Five production features (weather evidentiary · covers + reading HUD · RSVP speed-reading · onboarding + search/sort · archive durability) | ✅ shipped (SQLite engine attempted → honestly reverted; post-mortem preserved) |
| THE SENTINEL (deterministic watchdog + safe auto-repair + kill switch) | ✅ shipped with security doctrine S1–S7 pinned |
| Demo-profile freeze saga (3 failed rounds → probe-the-frozen-process → 1-line root cause) | ✅ closed; evidence pair kept in `docs/history/` |
| Performance marathon FINAL TRACES (covers files → AnalyticsCache · PersistenceWriter slice) | ✅ shipped; store-split & SQLite blueprints written |
| UI Review execution (chrome recedes, one atmosphere) | ✅ shipped |

**Not yet done (deliberate, blueprinted):**

- the normalized SQLite core (retiring the JSON monolith — the roadmap's one XL item)
- split `@Observable` stores
- Swift 6 strict mode
- BCE V3 UI activation (audit recommends delete-first)
- CloudKit (deferred by design)
- App Store submission

---

<a id="rt-5"></a>

## 5 · Open findings snapshot (October register)

13 new defect-class items + 4 release blockers were logged by the October audit and merged into `docs/registers/02-defect-register.md` Appendix D.

**The ones that matter most, in fix order:**

1. **NEW-DE-2** 🟠 — Explore/spatial card views read the legacy embedded-cover field, so real covers never show there post-migration — one-line fix (`book.coverImage`).
2. **NEW-DE-5** 🟡 — Onboarding import bypasses the import-intelligence facade and duplicate check; its goal commit can overwrite an existing full goal set.
3. **NEW-DE-4** 🟡 — AnalyticsCache signature has no day component → streak/trend values can go stale across midnight.
4. **NEW-DE-3** 🟠 — A crash + relaunch under 24 h silently converts idle time into reading time (Sentinel only repairs >24 h, and even then books the full wall-clock duration).
5. **NEW-DE-1** 🟠 — PersistenceWriter gates but does not serialize the encode/write work — a narrow stale-overwrite window exists; restore the ordering contract and re-pin.
6. **Release blockers** — empty AppIcon set; missing WeatherKit entitlement (weather will 403 at runtime); `ENABLE_USER_SELECTED_FILES=readonly` build setting vs read-write entitlements file; empty-string `CFBundleIdentifier` key in the custom plist.

**Also worth knowing:**

- Per-correlation weather confidence still hardcodes coverage = 1.0 (aggregate fixed, row-level not).
- Location-denied weather silently describes New York.
- RSVP text extraction tasks aren't cancellable.
- ~5.5–6.5 k LOC (~12–15% of the app target) is dead/dormant scaffolding, headlined by the Behavior Context Engine's 81%-dead Phase-2 append and the never-instantiated `LibraryView.swift`.

> **Closed mysteries:** the Behavior Context Engine's silence on 1,500 h of synthetic history was diagnosed from code — `analyze()` only fires when a live session closes (`.dropFirst()` suppresses launch/import), and synthetic personas generate zero NSWorkspace evidence; day-span floors bind before hour-volumes do. The profiles are proven innocent (16/16 validator-clean, pinned).

---

<a id="rt-6"></a>

## 6 · Estimates (multi-basis)

| Scenario | Sessions | Hours |
|---|---|---|
| Quick fixes + release blockers + commit hygiene (minimal-ship shape) | 1–2 | ~6–10 h |
| \+ dead-code retirement, discovery hardening, weather honesty, achievement-flood UX, pruning policy, BCE V1 activation | 4–6 | ~20–35 h |
| \+ store split (#3) + normalized SQLite core (#1) + Swift 6 completion | +3.5–6 | +23–40 h |

**Scale reality check (monolith kept):** 100 books/300 sessions → fine. Persona-scale (~185k page-timings) → 1–3 s encodes (the codebase's own measurement). A multi-year real library (~1–10 M timing records) → a 250 MB–5 GB single JSON re-encoded per save burst with launch validation on main — which is exactly why the SQLite blueprint exists and is the recommended next architectural arc. Monolith-breaking risks are real even now: the write-ordering window (NEW-DE-1) and 10× back copies of the full library are the two mechanisms by which a crash could cost real history; both are small, bounded fixes.

---

<a id="rt-7"></a>

## 7 · Strengths & weaknesses (verified)

**Strengths.**

- Protocol-driven traceability — every historical fix is implemented, Finality-verified, logged, and pinned by a test named for its defect (the suite reads like a defect history).
- A layered data-loss defense stack (corrupt → `.bak` → banner → repair-blocks-save → rotation → archive → Sentinel).
- Honest session logs including documented failures.
- Correct handling of the brutal MainActor-default isolation.
- Genuinely well-engineered files (EPUBPackage, DataMaturityEngine, EstimationEngine, the Sentinel security doctrine).
- Submission-adjacent basics already exist (privacy manifest, usage strings, sandbox, ATS-clean network).

**Weaknesses.**

- Unpruned lifetime-growth persistence.
- Several main-actor re-analysis paths that stall at 10× volume.
- ~12–15% dead code.
- A test belt that pins the persistence/engine layers superbly but leaves the only Release-reachable network feature (Discovery) and all view flows untested.
- Zero App Store formalities attempted (icon, entitlements-gap, scheme/test-plan hygiene).
- Historical `" 2"`-suffixed filenames in an auto-including synchronized folder.

---

<a id="rt-8"></a>

## 8 · Documentation map

```text
docs/
├── registers/              living truth: CURRENT_AUDIT (defects) · fix-log (protocol log) · handoff (session state)
├── roadmap/                REMEDIATION_ROADMAP (phases, mostly executed) · rsvp feature plan
├── method/                 testing strategy
├── history/                FINAL_TRACES marathon log · profilerfix post-mortem · LAST_DEFEAT knowledge transfer
│                           freeze.txt (the 5-second sample of the frozen app) · diagnostics-2026-08-26.txt
├── audits/                 08-deep-audit.md (the full audit behind this README)
└── 01-project-tree.md      regenerated project tree
```

**Engineering standards** (carried by `docs/registers/03-fix-log.md`): every fix needs a Finality statement, a fix-log entry, and a pinned regression test; suites must be green at every phase boundary; probe a frozen process (sample) before reasoning about performance.

---

<a id="rt-9"></a>

## 9 · How to build / run / verify

```bash
open "Reading Tracker.xcodeproj"      # Xcode 26.5+ tooling (built here with Xcode 27.1)

# Run: ⌘R        Develop console: ⌘⇧D (Debug only)        Settings (goal editor): ⌘,

# Verify:
xcodebuild build -project "Reading Tracker.xcodeproj" -scheme "Reading Tracker" -configuration Debug -destination 'platform=macOS'
xcodebuild test  -project "Reading Tracker.xcodeproj" -scheme "Reading Tracker" -configuration Debug -destination 'platform=macOS' -only-testing:"ReadingTrackerTests"
```

Runtime data lives under `~/Library/Application Support/johan.Reading-Tracker/` (`library.json`, `library-state.json`, covers, weather SQLite, `Backups/`, `sentinel-journal.jsonl`).

> **Status:** healthy, building, fully tested, and finally telling the truth about itself. The next session should start at §5 item 1 — and commit at every boundary, exactly like this one.

[⤴ back to top](#top) · [⏭ next: MirageV1.0](#part-2)

---
---

<a id="part-2"></a>

# 🖥️ Part 2 — MirageV1.0

> MirageV1.0 is the Literary Intelligence Engine (MIE): a local-first, spoiler-safe literary knowledge graph that should answer complex reader questions without reducing a book to a plot summary.

**The normative source of truth is** docs/literary_intelligence_mission_statement.md.

---

<a id="mv-status"></a>

## Current status

**V1.0 — product era opened (2026-10-17, tag v1.0.0):** the project is declared out of its MVP-freeze phase. Distribution/branding is now miragev10 (package `miragev10`, wheel `miragev10-1.0.0-py3-none-any.whl`, product name MirageV1.0); the CLI command stays `mirage`. The engineering state is unchanged from the MVP freeze and its §21 evidence stands (docs/p17-record.md): suite reverified green at the rename — 316 Python + 3 Rust; the final robustness point is still bound to the day-2 real library (user standing directive), bound, not skipped. The product/usage phase plan is docs/product_era_plan.md.

**MVP freeze v0.1.0-mvp (2026-10-17, tagged):** all eight §21 MVP-success requirements proven on the freeze commit (docs/p17-record.md), release notes supersede rc1 honestly. The engine is cohort-calibrated: 14 adversarial books hand-graded end-to-end (E-043: 1,427 entity + 1,414 claim rows), then the P-028 upgrade batch closed behind a published calibration harness (E-044) — graded tp retention 234/234 entities, 475/479 claims (1.0 modulo a four-row cited below-surface register), false-positive suppression 0.589/0.401, gate rc 0. Post-freeze housekeeping (per the user's standing compaction directive): superseded-generation ledgers are zipped in place; answer keys stay loose. Readiness 99/100 in the plan rubric — the last robustness point is bound to the day-2 real library (user standing directive), bound, not skipped.

**The project has:**

- typed domain contracts and enums (`src/miragev10/domain/`)
- a versioned SQLite ledger of truth (`ledger@0.0.10`, migrations m0001–m0016) with append-only claim history, CHECK-constrained vocabularies, and crash-safe transactions
- stdlib EPUB ingestion with security guards and content-hash unit identity (proven on a 63-real-book sweep, docs/artifacts/p7/)
- incremental, idempotent analysis: cursor-scoped `analyze_edition` with screening cache and no-change outcomes (I-INC1)
- heuristic extraction with entity typing, speaker attribution, per-claim epistemic status, and an explicit Stage E candidate/accepted gate
- exact identity resolution wired into the pipeline; evidence-gated identity merges
- cursor-safe spoiler eligibility (dependency closure, fail-closed) with a shared predicate across projection, citations, and search
- spoiler-safe graph projection with canonical content hashes
- the D-010 corrections overlay: audited, append-only, reversible user suggestions that can never become book truth (P12)
- embeddable surfaces: Python API (`MirageService`), CLI (`mirage`), unified NDJSON serve/sidecar protocol, and the local-only browser UI (`mirage --serve-web`)
- a reference Rust core (`crates/mirage-core`; demoted per ADR-0002)
- 316 Python tests + 3 Rust tests; extraction quality harness (scripts/evaluate.py), benchmark harness (scripts/benchmark.py), torture-MD converter/runner (scripts/round4_torture.py), cohort calibration harness (scripts/p28_calibration.py)
- · roadmap: docs/completion_plan.md · performance records: docs/eng-perf-001-record.md · docs/eng-perf-002-record.md · tree: docs/tree.md

---

<a id="mv-quickstart"></a>

## Quickstart (daily driver, P13/P14)

```bash
# one-time install (offline doctrine: pipx keeps your python clean; pip works too)
pipx install ./dist/miragev10-1.0.0-py3-none-any.whl

# build a library: import as many books as you like (identity is content-derived)
mirage --db mirage.sqlite3 --import-epub /path/to/book.epub
mirage --db mirage.sqlite3 --import-epub /path/to/other.epub
mirage --db mirage.sqlite3 --analyze-edition edition_<fingerprint>

# the library inventory at the CLI
mirage --db mirage.sqlite3 --list-books

# MirageV1.0 — open in your browser (localhost only); the book switcher picks
# any book in the library — boot data comes from the ledger, not config
mirage --db mirage.sqlite3 --serve-web
# → MirageV1.0 UI: http://127.0.0.1:8747

# removal is explicit and confirmed, with per-table counts in the audit
mirage --db mirage.sqlite3 --remove-book book_<id> --confirm

# series (P15.5): detection proposes, you dispose. Imports capture EPUB series
# metadata as hints; shared-name overlaps become candidates — nothing auto-links
mirage --db mirage.sqlite3 --list-series

# register a series (id or unique title works for every later reference),
# then declare your per-book reading state — that declaration is the spoiler gate
mirage --db mirage.sqlite3 --series-create "Trilogia Verba" --series-editions E1,E2,E3
mirage --db mirage.sqlite3 --series-declare "Trilogia Verba" E1 read
mirage --db mirage.sqlite3 --series-declare "Trilogia Verba" E2 reading@2
mirage --db mirage.sqlite3 --series-declare "Trilogia Verba" E3 unread

# the pooled recap: read books give everything, the reading book up to your
# declared cursor, unread books nothing — every item labeled with its book
mirage --db mirage.sqlite3 --series-breakdown "Trilogia Verba"

# or script it: NDJSON commands on stdin
mirage --serve --db mirage.sqlite3
```

No network is used at runtime: the install drill runs the whole flow under socket denial (scripts/p13_install_drill.sh), and the engine paths open no sockets at all.

---

<a id="mv-principles"></a>

## Core principles

- **Ledger is truth; graph is projection.**
- Spoiler visibility is deterministic by cursor and source evidence, not plausibility.
- One analysis job at a time under the 8 GB target budget.
- Deterministic classical extraction by default — heuristic NLP, regex, and lexicons; no heavyweight external components.
- Established facts must carry provenance and uncertainty.
- Incremental processing: normal page turns must not trigger full-book analysis.

---

<a id="mv-layout"></a>

## Repository layout

| Directory | Contains |
|---|---|
| `crates/mirage-core` | Rust reference core (demoted per ADR-0002) |
| `corpus/books` | Labeled evaluation corpus with gold annotations (§44) |
| `docs` | Normative doctrine, ADRs, registers, plans, testing, timeline |
| `examples` | Sidecar embedder example |
| `experiments` | Emergency scratch only; durable records live in docs/testing.md |
| `scripts` | `evaluate.py` (quality harness), `benchmark.py` (perf harness), `round4_torture.py` (torture-MD converter/runner) |
| `sql` | Future migration helper scripts |
| `src/miragev10` | Python domain, storage, ingestion, extraction, pipeline, query, API, CLI |
| `tests` | Python invariants and integration checks |
| `ui` | Reserved staged Tauri/React layer |

---

<a id="mv-deps"></a>

## Install local development dependencies

Only the standard library is required for the Python skeleton. For Rust tests:

```bash
cd crates/mirage-core && cargo test
```

---

<a id="mv-cli"></a>

## CLI usage

Initialize and inspect schema version:

```bash
PYTHONPATH=src python3 -m miragev10 --init-db --db mirage.sqlite3 --schema-version
```

Import EPUB:

```bash
PYTHONPATH=src python3 -m miragev10 --db mirage.sqlite3 --import-epub ./book.epub
```

Run heuristic extraction:

```bash
PYTHONPATH=src python3 -m miragev10 --db mirage.sqlite3 --analyze-edition edition_skeleton_1
```

Build a cursor-specific projection:

```bash
PYTHONPATH=src python3 -m miragev10 --db mirage.sqlite3 --project-at 4
```

---

<a id="mv-embed"></a>

## Embeddable usage

MirageV1.0 is intentionally packaged as a program and library. Reader or e-reader hosts can use it in three stable ways:

- **Python API:** `from mirage.api import MirageService`
- **CLI:** `python -m miragev10 ...`
- **Optional sidecar:** `examples/mirage_sidecar.py mirage.sqlite3`

See docs/embedding.md for lifecycle, command names, and the embedder command boundary.

---

<a id="mv-tests"></a>

## Tests

```bash
python3 -m unittest discover -s tests
```

Current verified counts:

- Python: 316 tests passing
- Rust: 3 tests passing

---

<a id="mv-docs"></a>

## Documentation index

See docs/README.md.

**Key files:**

- Doctrine: docs/literary_intelligence_mission_statement.md
- Defects/risks: docs/problems.md
- Fix-only log: docs/fixlog.md
- Timeline: docs/timeline.md
- Test report: docs/testing.md
- Research: docs/ideas_conceptual.md
- Plan: docs/execution_plan_heuristic_only.md
- ADR-0001: docs/adr/ADR-0001-epub-first-ingestion-and-deterministic-defaults.md

---

<a id="mv-graph"></a>

## Graph and audit outputs

A structural code-graph audit (AST extraction plus a documentation-corpus scan, no external API calls) summarized 595 nodes, 1,345 edges, and 31 communities. The execution roadmap toward MVP is docs/completion_plan.md. `codegraph-out/` is treated as a transient artifact and is ignored; durable findings belong in docs/testing.md.

---

<a id="mv-version"></a>

## Version

- Current package: **miragev10 1.0.0**
- Current ledger schema version: **ledger@0.0.10**

[⤴ back to top](#top)
