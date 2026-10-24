# 00 · AsterismaV1.0 — Project Report

> **TL;DR** — AsterismaV1.0 is a macOS reading-tracker app written entirely in Swift/SwiftUI. You import your PDF and EPUB books, read them inside the app, and it quietly records everything: per-page reading speed, time of day, live weather, and the app you were using just before opening the book. As of the October 2026 merge campaign, it also carries **Mirage** — a separately-owned companion engine for EPUB analysis, integrated behind a typed one-way boundary.

> **Bedrock update (2026-10-24):** the app now runs on a **GRDB/SQLite summary store** (JSON migrated to `.migrated`, load **5.06 ms** vs 493.7 ms), weather uses **Open-Meteo** with no WeatherKit entitlement, Mirage is **embedded and signed**, Behavior Context V3 is wired with an Advanced Context window, and real EPUB imports populate genre/series/word count. Standing census: **212 passed / 0 failed / 9 skipped**. The full gate record lives in `docs/plans/bedrock/`.

---

## Contents

| § | Section |
|---|---------|
| 1 | What the app does |
| 2 | The project at a glance |
| 3 | Technical overview |
| 4 | Verified health status |
| 5 | Open work, in priority order |
| 6 | Documentation map |
| 7 | Build & run |
| 8 | The fix protocol (for contributors) |

---

## §1 · What the app does

**AsterismaV1.0** imports PDF and EPUB books and lets you read them in-app — including an RSVP (Rapid Serial Visual Presentation) speed-reading mode that streams a chapter or a whole PDF one word at a time. While you read, the app records:

- **Per-page timing** — turn speed captured for every single page, feeding analytics and estimates
- **Temporal habits** — hour-of-day and day-of-week engagement patterns
- **Environmental context** — live WeatherKit snapshots correlated with sessions
- **Behavioral context** — foreground-app observation (via `NSWorkspace`) to reconstruct *where and why* you read
- **Goals, streaks, and 25 achievements** — daily/weekly/annual targets with a toast system
- **Annual Reports** — a yearly review rendered as slides
- **Night-sky ambience** — a starfield background that tracks real time of day, weather, and location
- **Mirage analysis (optional, opt-in per gesture)** — for an imported EPUB, an explicit "Analyze with Mirage" gesture sends that single book to a separately-owned analysis engine and wires the results to your reading state; the engine keeps its own ledger and never writes RT's store (see §3.5)

There is also a hidden **Developer Console** (⌘⇧D, Debug builds only) for stress-testing with **16 deterministic fake reader personas**, and a built-in **Sentinel** watchdog that scans for data problems at launch, auto-repairs the provably-safe ones, snapshots everything before touching anything, and reports what happened while you were away.

---

## §2 · The project at a glance

| | |
|---|---|
| **What it is** | A sandboxed macOS AppKit/SwiftUI app for tracking your reading — plus the integrated Mirage companion engine (optional feature) |
| **Language** | Swift 5 mode, SwiftUI + AppKit only |
| **Build config** | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, deployment target macOS 26.5, Xcode 27.1 |
| **Dependencies** | Exactly one Swift dependency: ZIPFoundation 0.9.20 (SPM, pinned via `Package.resolved` — used for unzipping EPUBs). Mirage ships as a self-contained bundled runtime (its own Python interpreter), not a Swift dependency |
| **App size** | 119 app files · 43,543 raw LOC (counted directly — not estimated) |
| **Tests** | 44 test files · 219 `@Test` functions · **standing default census: 212 passed / 0 failed / 9 skipped** (opt-in real-engine, benchmark, and SQLite/live-weather gates) |
| **How it is tested** | Swift Testing (`@Suite` / `@Test` / `#expect`) — not XCTest |
| **History** | ~30 working sessions (Jun–Oct 2026), 45+ commits, then the **RT–Mirage merge campaign** (Oct 2026): the 8-PR integration ladder PR-1…PR-8, closed with owner signatures |
| **Where your data lives** | Sandbox container: `~/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/Asterisma/` (see §3) — plus Mirage's own stratum (§3.5) |

---

## §3 · Technical overview

### 3.1 Architecture

The codebase is split into three layers, all pure Swift — no bridges, no C extensions:

| Layer | Path | What lives there |
|---|---|---|
| **Core** | `Core/` | `DataStore3` (persistence), `Book2` (models), `PersistenceWriter` (serial disk writes), `AnalyticsCache` (memoization), `CoverStore` (content-addressed cover files + NSCache), `DataIntegrityValidator`, `SentinelEngine`, `LibraryArchiveManager` (`.readingarchive` I/O) |
| **Engines** | `Engines/` | Pure static-namespace analytics: `AnalyticsEngine`, `EstimationEngine` (weighted-blend speed estimates), `DataMaturityEngine` (evidence gating with injected clocks) |
| **Features** | `Features/` | Everything user-facing: Library, Reader (PDF/EPUB), RSVP, Reports, Insights, Goals, Achievements, BehaviorContext, Environment (weather/stars), Discovery, Sessions, Audio, Notifications, Onboarding, DeveloperConsole, **and `Mirage/` — the integration surface (14 typed Swift files)** |

### 3.2 Concurrency model

The project's defining (and historically most destructive) build setting is `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: **every function is main-actor-isolated unless explicitly annotated `nonisolated`**. The freeze era is documented in `docs/history/10-profiler-fix.md`. The discipline now in place:

- Heavy paths (demo synthesis, library encode, cover capture, RSVP extraction, backup I/O, and **all Mirage transport/pruning work**) are explicitly stamped `nonisolated` so they truly leave the main thread
- The fix is **compiler-enforced** — a regression reintroducing a main-actor hop breaks the build loudly, rather than freezing at runtime

### 3.3 Data & persistence surface

All user data lives in one place (sandbox container):

```text
~/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/Asterisma/
├── library.json              Every book → session → individual page-turn timing (pretty-printed JSON monolith)
├── library-state.json        Goals, deadlines, earned achievements, collections
├── library.bak.json          Automatic same-name backup written before corruption resets
├── library.sqlite3 (+wal/shm) SQLite weather snapshot store (keyed by session ID)
├── covers/                   Content-addressed cover files (NSCache-fronted)
├── Backups/                  Automatic dated backups — newest 10 kept, hash-gated
├── mirage/                   Mirage's OWN stratum (created on first use): ledger db, identity map, supervisor guard file — Mirage-write territory, RT never writes it
└── sentinel-journal.jsonl    Append-only Sentinel audit log (rotates at 500 entries)
```

At the time of writing, the author's own working library weighs **~28 MB of `library.json`** with ~43 MB of backups — and these numbers scale linearly with pages turned forever (zero pruning exists). That scaling ceiling is the app's main architectural open item (§5).

Writes go through `PersistenceWriter` on a serial utility queue behind a debounce. All analytics reductions are static and pure; `AnalyticsCache` memoizes the five hottest whole-library reductions behind a mutation-epoch counter.

### 3.4 Sentinel (self-repair watchdog)

| Stage | Behavior |
|---|---|
| **Probes** | 8 deterministic, read-only probes run at launch + every N minutes |
| **Classifier** | Each finding is either provably-safe (`autoFixed`) or stalled for human review |
| **Dispatcher** | Repairs only through audited APIs; **all artifacts confined to `sentinel-*` files** |
| **Journal** | Append-only JSONL, atomic temp+rename rotation at 500 entries |

Security doctrine S1–S7 is pinned by tests (`SentinelPinsTests`), including write-confinement and the kill switch. Release builds default to **monitor + report only**; automatic fixes must be enabled in Settings ▸ Sentinel. To disable entirely:

```bash
defaults write johan.Reading-Tracker sentinel.enabled -bool false
```

### 3.5 The Mirage integration (October 2026)

Mirage is a **separately-owned companion engine** (Python) that integrates over a single spawn boundary: RT launches its sidecar on an explicit user gesture, speaks a typed NDJSON wire to it, and consumes typed outcomes. The enforcement rules, in plain English:

- **Ownership**: RT's store belongs to RT; Mirage's ledger belongs to Mirage. The only thing crossing the boundary is the analyzed-context handoff. Mirage entries in RT are born **only** from a validated import receipt — nothing is invented on either side.
- **Language**: the wire contract is immutable (`MirageWireTypes`) and version-gated; conformance test suites pin every shape.
- **Lifecycle**: one analyze gesture = one clean sidecar lifecycle (spawn → work → SIGTERM; no zombie processes, no persistence leavings).
- **Optional & safe**: a single Settings switch (`mirage.enabled`) turns the feature off entirely — which deletes nothing; disabled state spawns nothing. Spoiler-sensitive detail surfaces are disabled by design until a verified chapter→cursor mapping exists (fail-closed; typed refusal codes).
- **Packaged**: the engine ships inside the app as a digest-verifiable bundled runtime (staging script + manifest + SHA-256 checks + clean-machine gate).

The full campaign of record — playbook, ADR register (ADR-2…ADR-8, ADR-12), merge log M-014…M-034, evidence bundle, §22/TiB charter — lives in `docs/integration/` (see §6).

---

## §4 · Verified health status

Checked directly against the working tree during the October 2026 sessions — not inherited from an old note:

- ✅ `xcodebuild build` (Debug, default DerivedData) → **BUILD SUCCEEDED, exit 0**
- ✅ `xcodebuild test` (full unit target) → **TEST SUCCEEDED** — standing default census **191 passed / 0 failed / 4 skipped** (the 4 skips are three opt-in real-engine suites whose gates are deliberately unset in ordinary runs)
- ✅ The Mirage merge ladder closed green at every PR boundary (each PR's census receipt lives in `docs/integration/merge-log.md` M-014…M-028)
- ✅ Real-engine receipts: the sidecar identity proof and the packaged-runtime spawn smoke (banner → version → inventory → clean teardown) both executed live, single-lifecycle
- ✅ Working tree: the merge-era commits are all pushed to GitHub; the only working-tree edits at print time are this documentation refresh itself

---

## §5 · Open work, in priority order

IDs reference the defect register (`docs/registers/02-defect-register.md`) and the audit (`docs/audits/08-deep-audit.md` §7). Effort estimates assume a project-familiar working session.

| # | Item | Why it matters | Estimate |
|---|------|----------------|----------|
| 1 | **Punch list: NEW-DE-1 … NEW-DE-5** (audit-era items, all still open — the merge campaign did not touch the legacy defect list) | Write-ordering so an older snapshot can never overwrite a newer one (NEW-DE-1); spatial Explore cards never show real covers (NEW-DE-2); crash-window time inflation (NEW-DE-3); midnight-stale analytics cache (NEW-DE-4); onboarding import bypass + goal-set clobber (NEW-DE-5) | ~2–4 h |
| 2 | **App Store readiness** | Empty AppIcon set, missing WeatherKit entitlement, empty `CFBundleIdentifier` key, `ENABLE_USER_SELECTED_FILES=readonly` conflicting with the read-write entitlement | ~2–4 h + icon artwork |
| 3 | **Weather honesty set** | Denied location silently defaults to NYC; per-correlation coverage still hardcodes 1.0 (NEW-DE-7/8) | ~2–3 h |
| 4 | **Dead-code retirement** | Dead scaffolding — zero-caller code with zero behavior risk, verified call-site by call-site | ~3–5 h |
| 5 | **Architectural tracks** (in blueprint order) | Split the `@Observable` store monolith (#3) → SQLite normalized core with dual-read migration (#1, blueprint + full post-mortem exist) → Swift 6 strict concurrency | Multi-session arc |
| 6 | **Product decision needed** | Behavior Context Engine Phase-2: 81% of its file is dead scaffold — wire it (15–25 h, needs hardening) or delete it (1 session, 4.2k LOC). The audit recommends delete | Decision, then 1+ session |
| 7 | **Mirage era — standing items** | TB-M0 observation cadence (7 consecutive ledger days → owner's exit gate → TB-M1; day-one receipt already green); Mirage app-embed exercise at the first CI run or an operator stage-into-app; a Mirage perf-budget report as deltas; the backup-surface wire gap named to the engine owner («docs/integration/final-acceptance-2026-10-18.md» ledgered deltas) | Process, not code |

---

## §6 · Documentation map

Every deeper document has its own numbered ID and plain-English introduction. Start at any of them without guessing what a file is for:

```text
README.md                                    ← you are here
docs/
├── 01-project-tree.md                       Where every file lives
├── registers/                               Living truth
│   ├── 02-defect-register.md                Everything known to be broken or risky
│   ├── 03-fix-log.md                        Everything fixed, with verification proof
│   └── 04-handoff.md                        What to do next, in order
├── roadmap/
│   ├── 05-remediation-roadmap.md            The long-term plan, phase by phase
│   └── 06-rsvp-feature-plan.md              Historical design record — RSVP SHIPPED (P5-B2)
├── method/
│   └── 07-testing-strategy.md               How tests are written and why
├── audits/
│   └── 08-deep-audit.md                     Full independent audit (Oct 2026) — file:line evidence for every claim
├── integration/                             THE RT–MIRAGE MERGE CAMPAIGN (Oct 2026)
│   ├── RT_Mirage_Codebase_Merge_Playbook.md The governing playbook — still executes the §22/TiB era
│   ├── merge-log.md                         The campaign log of record (M-014… M-034+)
│   ├── final-acceptance-2026-10-18.md       §18 acceptance checklist with receipts
│   ├── evidence/                            §19 evidence bundle manifest + handoff bundle + receipt artifacts
│   ├── adr/                                 The ADR register (transport, packaging, stratum, identity, lifecycle, spoiler contract, repo strategy, TiB charter)
│   ├── phase1/                              Pre-ladder extraction: wire protocol, touchpoints, normative docs
│   ├── rehearsals/                          §15 rehearsal log (rollbacks, backup restore, runtime swap)
│   └── tib/                                 §22 Titanium Bridge — TB-M0 gate plan + observation ledger
└── history/
    ├── 09-final-traces.md                   Performance upgrade diary
    ├── 10-profiler-fix.md                   The freeze post-mortem
    ├── freeze.txt                           Raw 5-second `sample` capture taken during the actual freeze
    ├── diagnostics-2026-08-26.txt           Raw build output from Aug 26
    └── LAST_DEFEAT_demo_profiles.txt        The freeze hunt, told to be read by anyone
```

Campaign bookkeeping note: the root copies `merge-log.md` and `RT_Mirage_Codebase_Merge_Playbook.md` are the owner's personal kept snapshots — canonical, versioned copies live in `docs/integration/` and move forward there; the root copies are frozen at the campaign's close.

**If you are new to the project,** read `docs/registers/04-handoff.md` next — it answers what was done, why, and what comes next in order.

---

## §7 · Build & run

Requires a Mac with Xcode installed.

1. **Open the project:** double-click `AsterismaV1.0.xcodeproj`
2. **Run:** ⌘R (or the Play button)
3. **Developer Console:** ⌘⇧D (Debug builds only)
4. **Settings:** ⌘, — includes the **Mirage pane** (feature switch, engine availability)

To verify from the command line:

```bash
xcodebuild build -project "AsterismaV1.0.xcodeproj" \
  -scheme "AsterismaV1.0" \
  -configuration Debug \
  -destination 'platform=macOS'

xcodebuild test -project "AsterismaV1.0.xcodeproj" \
  -scheme "AsterismaV1.0" \
  -configuration Debug \
  -destination 'platform=macOS'
```

Both should end with `BUILD SUCCEEDED` / `TEST SUCCEEDED`. Run these **before and after every change** — the suite must be green at every boundary. Canonical census numbers come from `xcrun xcresulttool get test-results summary --path <latest .xcresult>`.

Mirage real-engine development (opt-in only, never part of the default suite):

```bash
TEST_RUNNER_MIRAGE_REAL_ENGINE_DIR=/path/to/MirageV1.0 \
  xcodebuild test -project "AsterismaV1.0.xcodeproj" \
  -scheme "AsterismaV1.0" -configuration Debug \
  -destination 'platform=macOS' \
  -only-testing:"AsterismaV1.0Tests/MirageIdentityRealEngineImportTests"
```

Builds under Desktop/iCloud paths must use the **default DerivedData** — a custom `-derivedDataPath` there breaks code signing (BUG-003's iCloud stamp root cause; see the defect register).

---

## §8 · The fix protocol (for contributors)

Every fix in this repo's history followed the same three-step protocol, and new fixes must too:

1. **Finality** — write down exactly what you are fixing and *why this fix is the right one*, before touching code
2. **Log it** — record the entry in `docs/registers/03-fix-log.md`, with the root cause and proof of verification
3. **Pin it** — add a named regression test that proves the bug cannot return (the test name should cite the defect ID)

House rules:

- **Start at the handoff** (`docs/registers/04-handoff.md`) and pick one small item from the register — each is marked with severity, confidence, and effort
- **Baseline green first:** run the §7 commands and confirm the suite passes before editing anything
- **Commit at every boundary** — never leave a fix uncommitted for more than a day
- **During a freeze, profile first:** run `sample <pid>` before reasoning about performance (`docs/history/10-profiler-fix.md` is the proof this works)
- **Honest reverts are successes:** a fix that never reaches Finality gets reverted and documented, never shipped half-broken
- **Mirage-specific rules (from the merge playbook, standing):** never unify Mirage's store with RT's; never spawn a second sidecar lifecycle while one lives; work on `main`, one commit at a green census boundary

---

## Status

**Healthy, building, fully tested, integrated, and honest about what remains.** The merge campaign is closed and signed. The next session starts at `docs/registers/04-handoff.md` — either the TB-M0 observation cadence (Mirage era) or §5 item 1 (the NEW-DE punch list), baseline green first, commit at every boundary — exactly as every session before it did.
