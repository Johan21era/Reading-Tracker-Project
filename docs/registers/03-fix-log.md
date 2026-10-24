# 03 · Fix Log

## What this document is

This is the project's repair diary. Every time someone fixes a bug in this codebase, they record it here in writing, following the project's fix protocol:

1. **Finality** — write down exactly what is being fixed and why it is the right fix
2. **Log entry** — add it here, organized by the order fixes were applied
3. **Pinned test** — add an automated test that proves the bug cannot come back

**Who should read this:** Anyone who wants to understand what has been fixed, verify that fixes are real, or follow the same protocol when fixing something new.

**How to read it:** The log is organized in stages. Each fix shows the file it touched, the root cause in plain English, the "Finality" statement (why this is the right fix), and how it was verified.

---

## Verification status

Every entry below passed a clean `xcodebuild build` at patch time. The app launches standalone from today's binary.

---

## Stage 1 — Application launch (compile blockers)

The app did not compile at the start of the remediation. All ten findings were High confidence (direct compiler evidence).

| # | Fix | File | Plain-English summary |
|---|-----|------|----------------------|
| 1.1 | Illegal stored property wrapper in extension | `Features/Discovery/OnlineBookSearchDrawer.swift` | A `@State` property was declared inside a `private extension`, which Swift forbids. Moved it into the struct body. |
| 1.2 | Missing `import Combine` | `Features/DeveloperConsole/DeveloperConsoleDashboardView.swift` | A timer publisher was used with only SwiftUI imported. Added the missing Combine import. |
| 1.3 | Extension of non-nominal type `Any` | `Features/BehaviorContext/BehavioralCategory.swift` | Retyped an extension to work with `Equatable` so chained call syntax compiled. |
| 1.4 | Impossible synthesized `Codable` on `ProcessInfo.ThermalState` | `Features/BehaviorContext/BehavioralCategory.swift` | Wrote manual Codable via raw Int value so invalid raw values throw cleanly. |
| 1.5 | Public declarations exposing internal types (×5) | `Features/BehaviorContext/BehaviorContextEngine2.swift` | Demoted five declarations to internal; zero external usages existed. |
| 1.6 | API drift: `generateTrendReport(from:)` → `(sessions:)` | `Features/Environment/Weather/WeatherInsightPanel2.swift` | Relabeled the argument to match the engine's declared signature. |
| 1.7 | Reference to removed `WeatherSnapshot.sessionID` | `Features/Environment/Weather/WeatherInsightPanel2.swift` | Deleted the exact-match index; kept closest-by-timestamp join. |
| 1.8 | `FullIntegrationInput` missing raw-evidence arrays | `Features/BehaviorContext/BehaviorContextEngine2.swift` | Added the missing members and populated them from the same kit arrays. |
| 1.9 | Misuse of IOKit C API in `systemIdleTime()` | `Features/BehaviorContext/BehavioralCategory.swift` | Rewrote with the correct out-pointer pattern; fixes compilation. |
| 1.10 | Inout through `if let` shadow binding | `Features/BehaviorContext/BehavioralCategory.swift` | Renamed the shadow binding so the outer mutable optional is targeted. |

---

## Stage 2 — Startup / storage loading / library list

| # | Fix | Severity | Plain-English summary |
|---|-----|----------|----------------------|
| 2.1 | Save/load failures completely silent in Release | 🔴 Critical | Added a published `persistenceHealth` status that degrades at every silent-catch site and renders as a persistent bottom banner — every failure is now visible in Release builds. |
| 2.2 | Unrepairable corruption silently re-persisted | 🟡 Medium | Branch on `hasUnrepairableErrors` before auto-save; surface instead of overwriting the last-good file. |
| 2.3 | Debounced save stalls during window tracking | 🟡 Medium | Timer added to `RunLoop.main` in `.common` mode so debounce keeps firing through event-tracking modes. |
| 2.4 | Multi-item delete corrupts/crashes on index reuse | 🔴 Critical | Capture the ID set from offsets *before* mutation; remove by identity to eliminate index-shift effects. |
| 2.5 | Achievement toast drops/re-shows on concurrency | 🟡 Medium | View-side FIFO fed by deduplicating `onReceive` + serial presenter + incremental consumption — each earned achievement shows exactly once. |
| 2.6 | Ghost estimate for deleted book | 🟡 Medium | Guard `dataStore.book(id:) != nil` inside the delayed work item. |

---

## Stage 3 — Monitoring, analytics date math, truth fixes, test wiring

| # | Fix | Severity | Plain-English summary |
|---|-----|----------|----------------------|
| 3.1 | Screen-lock observers leak & duplicate per foreground cycle | 🔴 Critical | Two block-based observer registrations discarded their tokens; `removeObserver(self)` was a silent no-op for them. Captured both tokens, added an idempotence guard, and remove them explicitly in `stopMonitoring`. |
| 3.2 | Force-unwrapped failable Calendar arithmetic (13 sites) | 🟠 High | `Calendar.current` reflects the user's region setting; `date(from:)`/`date(byAdding:to:)` are fallible. Every site force-unwrapped. Guarded each with documented degradation. |
| 3.3 | False integration-status comment | 🟢 Low | `EnvironmentBackgroundView2.swift` header claimed integration that did not exist. Replaced with a truthful STATUS CORRECTION note. |
| 3.4 | Investigated and DISPROVEN | — | `buckets.max(by:)!.key` looked like a zero-data crash, but the dictionary is seeded with all four keys and keys are never removed — max/min can never see an empty collection. Untouched, documented. |
| 3.5 | Real test suites wired into executing target | 🟠 High | Converted three `XCTestCase` suites to `@Suite`/`#expect`, migrated test-only shims, stripped 13,903 chars of dead block from `WeatherKitService2.swift`. |

---

## Stage 4 — Test infrastructure forensics & first-run findings

| # | Fix | Severity | Plain-English summary |
|---|-----|----------|----------------------|
| 4.1 | O-7 RESOLVED: every Debug launch crashed in `DeveloperConsoleRegistry` init | 🔴 Critical | `registerAll()` → `registerOne<T>` → global access from inside `.shared`'s own `dispatch_once` callout. libdispatch detected self-wait and trapped. Pass the registry instance into `registerAll`/`registerOne` instead. |
| 4.2 | Weather store could strand stale rows forever on crash-retry | 🔴 Critical | Table PRIMARY KEY is each snapshot's UUID, so `INSERT OR REPLACE` never deduped retries under the same `session_id`. Added explicit DELETE-by-session followed by INSERT inside one transaction. |
| 4.3 | Fixture correction: clearCalm storm-index test | 🟢 Test-authoring | Production analytics untouched. Fixture now uses true calm (`windKPH: 0`) so zero inputs ⇒ zero index. |
| 4.4 | Deinit resurrection abort in BehaviorContextAccessKit | 🔴 Critical | `deinit { Task { @MainActor in stopMonitoring() } }` captured `self` from inside its own deallocation, retained the dying object, and called methods on freed memory. Removed the self-capturing Task; empty documented deinit with explicit ownership contract. |
| 4.5 | Regression battery authored | — | `ReliabilityTests.swift`: Validator ×5, DataStore persistence ×4, Library mutation ×2, Observer lifecycle ×1. Every failure names its defect class. |

---

## Open / unresolved (Finality not reached)

| Ref | Item | Status / next step |
|---|------|-------------------|
| O-3 | New Year overlay timer chain can outlive `cleanup()` | Latent — feature unwired. Fix before Part-12 wiring; needs cancellation-token redesign. |
| O-6 | Weather SQLite rows keyed by `sessionID` while normaliser discards it | Design decision required; logged, untouched. |
| O-8 | Sync main-thread writes; `urls(...).first!` ×2; `turnToPage` weak-store divergence; duplicate-import silent no-op | Left untouched per confidence rules; prescribed fixes recorded in the retired audit report. |

---

## Phase 1 — Foundation Strike

Executed under the fix protocol against the defect register findings.

| Fix | File | Result |
|-----|------|--------|
| P1.1 — F-01 Calendar crash | `Features/Reports/AnnualReportData2.swift` | FIXED — guarded degradation + additive `calendar:` parameter; `NonGregorianCalendarTests` all pass |
| P1.2 — F-03 Numeric entity destruction | `Core/SharedTextUtilities.swift` | FIXED — removed pre-strip; existing correct decoder now receives intact entities; `TextExtractionTests` all pass |
| P1.3 — F-04 Gates A+B Schema evolution | `Core/DataStore3.swift`, `Core/Book2.swift` | FIXED — backup before reset + tolerant custom Decoders; `SchemaEvolutionTests` all pass |
| P1.4 — F-05 Location continuation leak | `Features/Environment/Weather/WeatherKitService2.swift` | FIXED — FIFO queue resumed exactly-once per continuation; inspection-verified |
| P1.5 — F-07 Observer double-registration | `Features/BehaviorContext/BehavioralCategory.swift`, `ReadingTrackerApp 2.swift` | FIXED — `isMonitoring` gate; `ObserverLifecycleTests` pass |
| P1.6 — F-02 New Year celebration chain | `Features/Reports/NewYearTransitionMonitor.swift` | FIXED — `CelebrationTimeline` extracted phase driver with one cancellable sequence task; `CelebrationTimelineTests` all pass |

Pins added this phase: `NonGregorianCalendarTests` (15 cases), `TextExtractionTests` (7), `SchemaEvolutionTests` (4), `CelebrationTimelineTests` (5), `ObserverLifecycleTests` double-start (+1).

Open after Phase 1: F-06, F-08–F-13, O-6, O-8 remainder.

---

## Phase 2 — The Great Wiring

| Fix | Result |
|-----|--------|
| P2.0 — Baseline re-verified green | ✅ |
| P2.1 — §8.2 gate: shared-engine refcount | FIXED+PINNED — consumer counting; `EnvironmentEngineTests` ×4 |
| P2.2 — D5 wiring: Environment Engine is LIVE | ✅ — `ContentView` owns the engine; `EnvironmentBackgroundView` composes as ZStack root |
| P2.3 — D5 wiring: Library Explorer live | ✅ — Explore toolbar presents `LibraryExplorerView`; collection CRUD with referential integrity; `LibraryCollectionTests` ×5 |
| P2.4 — Import Intelligence surfaces | ✅ — ~250 previously-unreachable lines now run on every real import |
| P2.5 — F-06 Chronological fatigue analysis | FIXED+PINNED — gap records carry real boundaries; `FatigueAnalyzerTests` ×7 |

Open after Phase 2: SpatialNavigator/FloatingCluster sub-surfaces ride inside Explorer already; remaining: F-08–F-13, O-6/O-8/D6, BCE V3 activation with UI, RSVP feature plan implementation.

---

## Live-test remediation (LT-001)

Source: Johan's manual stress-test report ("LIVE TESTING SESSIONS" — every action ×20 sessions). Root-caused from code; each fix built clean and the full suite stayed green throughout.

### Fixed

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| LT-1 | Discover Books bricked the app | 🔴 | Complete redesign as a proper modal (header + Close/Esc, prominent search, real results list, empty/loading/offline/error states, detail on selection) |
| LT-2 | Annual Reports bricked the app | 🔴 | Systemic `sheetDismissAffordance()` modifier (floating close + Escape) applied to ALL top-level sheets |
| LT-3 | Ghost books + phantom reading time | 🔴 | (a) Entitlements: app-scope bookmarks, user-selected RW, network.client — wired into both configurations via `CODE_SIGN_ENTITLEMENTS`. (b) Phantom time: EPUB starts timing only after package opens; PDF gains `onLoadSuccess` fired only when a document exists. |
| LT-4 | Insights pinned center / dragged main window | 🟠 | Insights now opens as its own real Window scene via `openWindow` |
| LT-5 | Report Prev/Next needed double/triple clicks | 🟡 | Hairline labels replaced with padded capsule targets + `contentShape` |
| LT-6 | Report clipped long sentences / ignored zoom | 🟡 | Slides render inside `GeometryReader`+`ScrollView`; narrative row uses `ViewThatFits`; truncation `lineLimit`s removed |
| LT-7 | Hover sluggish + wall-of-info | 🟡 | Delay 1.5s→0.55s; detail pane reveals in three animated waves |
| LT-8 | Demo profiles requested | ✅ DELIVERED | `DemoDataService` (DEBUG-only): 13-book deterministic catalog; `DemoProfileLabView` console pane with two-step armed install |

### Open (queued — next work before ANY Phase 3)
- LT-9 Settings: symbol color customization
- LT-10 Achievements gallery (all badges + totals)
- LT-11 Star visual polish ("just dots")
- LT-12 Broader de-blocking design pass

### Verification
BUILD SUCCEEDED after every stage; full suite TEST SUCCEEDED at close. Entitlement change requires a fresh Run (clean build folder if Xcode caches signing).

---

## P5 — Five Production Features

Johan authorized all five "next-level" production moves. Every phase passed full `xcodebuild test` at its boundary and was pushed as its own commit.

| # | Feature | Commit | What it does |
|---|---------|--------|--------------|
| P5-A | Weather intelligence made evidentiary | `28e9919` | Aggregate confidence derives from correlation scores + real data-coverage ratio; correlation date bounds chronological; "avoided genres" means sub-5%-share within a season |
| P5-B1 | Cover art + live reading HUD | `575a2fe` | Imports capture covers automatically (PDF first-page thumbnail; EPUB OPF-declared cover); sidebar rows show real covers; ReadingHUD floats with cover, title, live elapsed clock, page position, End Session |
| P5-B2 | RSVP speed reading | `f5ec995` | Full feature per `06-rsvp-feature-plan.md`: tokenizer → playback engine → UI → wiring; hare button streams current EPUB chapter or entire PDF |
| P5-C | First-run onboarding + library search/sort | `8fb1bea` | 3-step wizard for brand-new users; sidebar search across title/author/series; Sort menu (7 modes) |
| P5-D | Data durability: portable archive + auto-backups | `c4968cb` | `.readingarchive` format exports everything; Import Library shows pre-flight summary then restores; automatic dated backups (newest 10 kept) |

### Attempted & honestly reverted

| # | Feature | Commit | Why reverted |
|---|---------|--------|--------------|
| P5-G | Storage Engine 2.0 (SQLite) | — | First test-host launch dies SIGTERM mid-suite — a connection-lifecycle race under `SQLITE_ENABLE_THREAD_ASSERTIONS`. Per Confidence Rules, Finality not reached ⇒ reverted to the proven engine. Zero user impact; no commit shipped it. Reopened for a dedicated session. |

---

## P5-HOTFIX — App-freeze report

Five confirmed main-thread stall sources — four introduced by the P5 feature pass, one pre-existing dormant cousin promoted to live by usage patterns. All fixed, suite green (exit=0).

1. **HUD tick × whole-library re-sort** — `visibleBooks` was a computed property; the ReadingHUD's once-per-second timer re-evaluated the ENTIRE library every second on main. Memoized on books/search/sort signature.
2. **Cover capture on main during import** — PDF rasterization froze imports. Now detached; `importPDF` became async.
3. **RSVP whole-PDF extraction on main** — froze the app solid before the sheet appeared. Now detached with progress-cancellation checks.
4. **Launch-time backup I/O on main** — auto-backup file copies ran in `DataStore.init`. Now a background utility task; rotation API converted to nonisolated static.
5. **Location continuation could hang forever** — if `CLLocationManager` never calls back, every awaiting task wedged permanently. 30 s watchdog now fails the queue.

---

## P6 — THE SENTINEL

Johan's long-wanted admin system: a deterministic rule-driven bug watchdog that finds problems, auto-fixes the provably-safe ones, and stalls the rest for human review.

**Architecture:** PROBES (8, pure reads) → CLASSIFIER (autoFixed vs stalled) → DISPATCHER (audited APIs only) → JOURNAL (append-only JSONL). Runs on launch + every N minutes.

**Security doctrine (S1–S7):**
- **S1** Write confinement — engine's only writable artifacts are `sentinel-*` files
- **S2** Reversibility — backup rotation runs BEFORE any mutation; if snapshotting is impossible, repairs are skipped entirely
- **S3** Append-only journal, atomic temp+rename rotation at 500 entries
- **S4** Static Release strings only; no paths/errors/user text in user-facing copy
- **S5** Kill switch — `defaults write johan.Reading-Tracker sentinel.enabled -bool false`; `runCycle` fully inert when off
- **S6** Conservative defaults — Debug repairs always; Release = monitor+report until the user flips Settings ▸ Sentinel ▸ Allow automatic fixes
- **S7** Determinism — no network, no randomness in probes

Pins: `SentinelPinsTests` ×6 (orphan fix, phantom fix, stalled-stays-stalled, write-confinement SECURITY, kill-switch SECURITY, journal JSONL validity).

---

## P6-HOTFIX — Demo Profile installs froze the app

**Root cause:** `DemoProfileCatalog.install` ran synthesis + full-library encode on the MAIN ACTOR inside the button handler. Winter Romantic alone synthesizes ~621 sessions carrying ~185k page-timing chunks. Encode on main = multi-second lockup.

**Fixed:**
1. Install pipeline async: generation detached, swap-on-main trivial, staged progress UI
2. Re-entrancy guard + drain-before-swap in `debug_replaceLibrary`
3. Sentinel pauses during installs (bridge mutation flag)

---

## P6-HOTFIX v2 — THE ACTUAL ROOT CAUSE

**Root cause:** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (project.pbxproj). Every function without an explicit annotation is main-actor-isolated — including closures inside `Task.detached` and every model initializer they call. The v1 "background" pipeline performed ~1 MILLION serialized hops back to the main thread. The heavy work never left the main thread.

**Fixed:**
- **A:** `nonisolated` on Book/ReadingSession/PageTiming/Chapter inits + `generateBooks` + `demoChapters` + `SeededRNG` methods + `spec()`. Synthesis now truly leaves main.
- **B:** Library ENCODE moved off-main — enqueueWrite takes an encode thunk executed inside the detached task.
- **C:** `debug_replaceLibrary` simplified to `scheduleSave()`; rapid hops coalesce behind one job.

The isolation fix is compiler-enforced: any future regression reintroduces a MainActor hop on these paths and the build breaks loudly.

---

## P7 — UI REVIEW EXECUTION

Johan's UI REVIEW executed end-to-end. All three HIGH priorities plus both MEDIUMs and the LOW refinement landed.

1. Gray title bar is GONE; starfield reaches the window's top edge and traffic lights float over it
2. Night-time sky blue glow no longer draws a visible circle behind the UI; it fades past the corners
3. Reading HUD has no accent ring anymore and matches toast/banner corner radius exactly
4. All floating surfaces share ONE radius + inset vocabulary from `DesignGrid.swift` — change one constant, everything follows

---

## P6.5 — Sentinel transparency + render-safety fix

Fixed bright-red console spam ("Modifying state during view update" every second):
1. `SentinelEngine.init` loaded journal counters into `@Published` — init runs during SwiftUI's first evaluation. Counters now hydrate lazily inside `runCycle`.
2. `runCycle` wrote published state synchronously when invoked from `.onAppear`/`.task`. All published writes now deferred one runloop turn.

**New surface:** Dev Console ▸ Sentinel — two faces:
- **Technical:** raw findings with timestamp/severity/probe.rule/outcome badges + full `debugDetail`, rule filter, lifetime metrics, auto-repair mode indicator, Run Probe Now, journal folder reveal
- **Plain English:** static userSummary sentences, duplicates collapsed with counts, fix vs needs-you icons

---

## Stage M — The RT–Mirage integration era (Oct 2026)

A separate work program executed under its own playbook (`docs/integration/RT_Mirage_Codebase_Merge_Playbook.md`) — recorded here by reference per the no-duplication rule, not restated. Eight terraced PRs (`PR-1`…`PR-8`, all receipts in `docs/integration/merge-log.md` M-014…M-028), each closed on a green default census; censuses 191/0/4 standing at close; owner-signed acceptance round at campaign close.

| Unit | What it landed | Pointer |
|---|---|---|
| PR-1…PR-3 | Campaign scaffolding → the typed wire (28 actions, `MirageWireTypes`) → transport conformance | `docs/integration/merge-log.md` |
| PR-4 | Sidecar lifecycle machinery: supervisor ladder (spawn→banner→exchange→teardown), EOF/timeout/reaping, BUG-stripe with full externalized repro receipts | PR4 closeout snapshot: `docs/integration/PR4-defect-analysis-2026-10-18.md` |
| PR-5 | Identity map (fail-closed, receipt-born entries, crash-atomic) + one-book import + real-engine identity proof | `docs/integration/PR5-execution-plan-2026-10-18.md` |
| PR-6 | Spoiler-status surface + the gated `MirageCursor` (ADR-7: detail surfaces disabled until verified calibration; typed refusal codes) | merge log M-025/M-026 |
| PR-7 | Feature lifecycle governance (`mirage.enabled`, disable-deletes-nothing byte-proof) + OPE-001 (owner-countersigned stub-cover deletion, ‑38 files, list archived) + the 4-rung boundary root-cause ladder (M-024→M-027) | merge log M-027 |
| PR-8 | The packaged runtime per ADR-3: staging script (pinned interpreter checksum, refusal pins), verified manifest, locator ladder, clean-machine gate, CI workflow (`census.yml`) + self-hosted spawn smoke | merge log M-028 |
| Closing round | Owner signatures: ADR-6 ratified, ADR-3 accepted, ADR-8+ADR-12 countersigned, single-branch adoption, first TB-M0 ledger receipts (verify GREEN + tamper-refused) | merge log M-032/M-033/M-034 |

**Documented, deliberately unfixed (owning decisions attached):** the wire exposes no ledger-backup surface (engine-side duty; named owner); Mirage app-embed exercise awaits the first CI run; R1's remaining three rollback rehearsals (procedure recorded, scheduled).

**Retirement receipted here (for traceability):** the BUG-001 repro `.xcresult` (104 MB, externalized during Stage 4-era bookkeeping) was retired by the owner on 2026-10-18 when the campaign folder was deleted; no unique information was lost (the receipt's metadata lives at `docs/integration/evidence/BUG-001-LogStoreManifest-2026-10-18.plist`).

---

## Stage B — Bedrock / Asterisma (2026-10-24)

The Bedrock program closed the audit-era correctness punch list, moved the live
store to SQLite, and finished with the Asterisma rebrand. Gate receipts live in
`docs/plans/bedrock/`.

| Gate | What landed | Receipt |
|---|---|---|
| G0 | Baseline, worktree, data snapshot, test isolation, benchmark | `BASELINE.md` |
| G1 | NEW-DE-1…NEW-DE-5 fixed and pinned: writer ordering, crash-window clamp, cache day bucket, onboarding import/goal merge, spatial covers, RSVP cancellation | `gates/GATE-G1.md` |
| G2 | App icon, entitlements, shared scheme, ad-hoc signed package | `gates/GATE-G2.md` |
| G2B | Mirage runtime embedded, signed, manifest-verified, bundle-smoke green | `gates/GATE-G2B.md` |
| G3A/B/C | GRDB schema, lazy summary store, real-library cutover, JSON retired to `.migrated` | `gates/GATE-G3A.md`, `GATE-G3B.md`, `GATE-G3C.md` |
| G4 | Open-Meteo provider + live session→snapshot→SQLite pipeline; no WeatherKit entitlement | `gates/GATE-G4.md` |
| G5 | EPUB genre/series/word count, Book Details, notes, tags, collections | `gates/GATE-G5.md` |
| G6 | Behavior Context V3 report + Advanced Context window + JSON evidence archive | `gates/GATE-G6.md` |
| G7 | −1,157 lines of dead code; Swift 6 deferred (148 actor-isolation errors) | `gates/GATE-G7.md` |
| G8 | Release candidate accepted: census 213/0/9, package + launch smoke | `gates/GATE-G8.md` |
| R1 | AsterismaV1.0 rebrand + `ReadTracker` → `Asterisma` data-root migration | `docs/REBRAND-ASTERISMA.md` |

**Live-data receipt after migration:** 7 books / 292 sessions / 138,459 page
timings. The app relaunched successfully from `Application Support/Asterisma/`.

**Release receipt:** `main` at `aba8aa4` (release commit `6da2d81`, tag
`asterisma-v1.0-mvp`), package `dist/AsterismaV1.0-1.0-arm64.zip`, SHA-256
`31dc0abf35ea7cba4eeb9ab8580b6a60eeee6e10086bc7d3759f174dd33447cc`.

**Still deferred:** Swift 6 strict mode, reader selection highlights/quotes,
behavior evidence in SQLite, collection rename UI, legacy artifact cleanup,
CI-runner alignment, and Developer ID signing/notarization.

