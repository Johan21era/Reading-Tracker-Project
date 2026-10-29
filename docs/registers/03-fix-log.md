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
| OT | Owner-test fixes: packaged entitlements, onboarding dismissal, folder-form EPUB import | `docs/owner-test-results/2026-10-24-session-1.md` |

**Live-data receipt after migration:** 7 books / 292 sessions / 138,459 page
timings. The app relaunched successfully from `Application Support/Asterisma/`.

**Release receipt:** `main` at `aba8aa4` (release commit `6da2d81`, tag
`asterisma-v1.0-mvp`). The owner accepted the reader workflow on the
`asterisma-v1.0-ux-audit-2` build. The ready tree carries app code `1c88ae5`
(tag `asterisma-v1.0-ready-2026-10-26`), package
`dist/AsterismaV1.0-1.0-arm64.zip`, SHA-256
`786832c8049e38ebe03d6220ae0a39b3a0005b010bdce4675e440cea65ef4643`.

**Still deferred:** Swift 6 strict mode, reader selection highlights/quotes,
behavior evidence in SQLite, collection rename UI, legacy artifact cleanup,
and Developer ID signing/notarization.


### Polish batch — reader appearance and library surface (2026-10-25)

| Area | What landed | Receipt |
|---|---|---|
| Reader appearance | Six theme presets, font family, bold, 80–200% size, line/character/word spacing, margins | `ReaderAppearance.swift`, `ReaderAppearanceTests` |
| Reader layout | Justify, hyphenation, Auto/One/Two columns, Slide/Fade/Instant page turns, optional page numbers | `EPUBReaderScreen.paginationScript` |
| Reader chrome | Theme-adaptive capsules; top-left controls still auto-hide | `EPUBReaderScreen.swift` |
| Page turning | Document-level left/right edge clicks without blocking trackpad scrolling or links | `EPUBReaderScreen.paginationScript` |
| Library | Selected-book book plate with large cover/progress/actions; quieter sidebar rows | `NewContentView.swift` |

**Verification:** Debug and Release builds green; package signed with sandbox
entitlements and bundle smoke green; `ReaderAppearanceTests` 5/5 with WCAG AA
contrast checks. At the time, the full UI-inclusive census rerun was blocked by
macOS `testmanagerd` automation bootstrap, not by an app assertion. The
2026-10-26 close-out later turned the deterministic unit gate green; the
UI-inclusive gate remains unclaimed.

**Candidate:** `a8ebf2ec1efd0b3513dd59a04a1efb8a830aefb2007b32632539906ba0517009`
(code `3bff002`, tag `asterisma-v1.0-polish-1`).

---

## Stage R — Repository reorganization and CI hardening (2026-10-26)

| Item | What changed | Verification |
|---|---|---|
| R-001 | App shell moved from the flat app root to `AsterismaV1.0/App/` | 2 `git mv` operations; before/after SHA-256 equal |
| R-002 | 48 flat test files grouped into `App`, `Behavior`, `Core`, `DeveloperConsole`, `Environment`, `Library`, `Mirage`, and `Reader` | 48 `git mv` operations; 100% renames, 0 content edits |
| R-003 | 280-file baseline reconciled; path-dependent, signing, user-data, release, and historical files left in place | 0 missing, 0 mismatched, 0 unapproved changes; report in `docs/reorganization/` |
| R-004 | GitHub `census` moved from `macos-14` / Xcode 15.4 to `macos-26` / Xcode 26.6 | Xcode 15.4 cannot open project format 77; Xcode 26.6 opens and builds it |
| R-005 | `OpenMeteoProvider` safe-array subscript marked `nonisolated` | Xcode 26.6 correctly enforced the project's `MainActor` default; behavior unchanged |
| R-006 | Bundled-runtime app-host assertion self-gates on `.mirage-runtime` | Clean CI builds without the ignored 47 MB runtime; synthetic runtime-contract tests still run |

**Final verification:** Debug build green; local unit census **220 passed /
0 failed / 9 skipped**; GitHub run `40266848038` green with **229 tests,
10 deliberate skips, 0 failures**; reorganized tree reconciles every baseline
file with no content change.

**Ready package:** rebuilt from app code `1c88ae5` —
`dist/AsterismaV1.0-1.0-arm64.zip`, SHA-256
`786832c8049e38ebe03d6220ae0a39b3a0005b010bdce4675e440cea65ef4643`.
The package signature, sandbox entitlements, embedded Mirage smoke, and
Gatekeeper-rejection expectation were re-verified by `scripts/package-release.sh`.

**Supersession:** this ready package supersedes the `a8ebf2ec…` polish
candidate for owner retesting. Reader behavior is unchanged; the only app-code
change is the `nonisolated` concurrency annotation.

## Stage S — SG8 surface coverage and repository hygiene (2026-10-28)

| Item | What changed | Verification |
|---|---|---|
| S-001 | `SQL-016` contract-checks every table in a source-generated manifest (existence, readability, primary key) | 11 surface pins; full census green |
| S-002 | `SELF-011` raises a required gap when a family loses its registered owner | Removal of `SQL-016` produces 15 required gaps in test |
| S-003 | `scripts/sentinel-surface.py` generates the surface catalog; CI freshness gate runs before the census | Simulated new table/preference made `--check` exit 1; restored check exit 0 |
| S-004 | Published history rewritten to remove AI co-author trailers from five commits | Trees byte-identical; GitHub contributors API now lists only the owner |
| S-005 | Build junk removed: `.DS_Store` files and the stale 84 MB `dist/` output | `git status --ignored` shows no build directory left |
| S-006 | Graphify refreshed from the new code | 7,510 nodes · 19,023 edges · 369 communities; HTML retired at the 5,000-node limit |
| S-007 | Sentinel catalog grew to 140 probes / 58 required; local census 432 tests / 671 runs / 9 skipped / 0 failed | `./scripts/census.sh --unit-only` passed; Debug and Release builds succeeded |

## Stage S follow-up — repository hygiene (2026-10-29)

| Item | What changed | Verification |
|---|---|---|
| S-008 | Removed regenerable graphify cache/backup, a byte-identical root playbook copy, and OS metadata | 102 MB → 77 MB; tracked tree clean; `graph.json`/`GRAPH_REPORT.md` and the Mirage runtime intact |
| S-009 | Refreshed the stale GitHub homepage contributor cache with a temporary same-SHA default branch | Sidebar lists 1 contributor (`Johan21era`); temp branch deleted; default branch restored to `main` |
| S-010 | Generated the missing `graph.html` from the existing graph; the 7,510-node graph auto-aggregated to 369 community nodes / 1,372 cross-community edges | 435 KB; browser preview renders one canvas; `graph.json`/`GRAPH_REPORT.md`/`manifest.json`/`.graphify_labels.json` hashes unchanged |
| S-011 | Added a deterministic offline 3D graph export: `scripts/build-graph-3d.py`, a vendored `3d-force-graph` 1.80.0 bundle with its MIT notice, and a tracked community page (`graph-3d.html`, since deleted) plus a gitignored full-node view | `--check` matches both outputs; Playwright rendered 369 nodes / 1,372 links and 7,510 / 19,023 with zero console errors after the favicon fix; full view sends only the document request; source/renderer hashes embedded instead of a timestamp |
| S-012 | 3D views made usable on a double-click in Safari: `[hidden]` now wins over the layout `display: grid` | WebKit `file://` load shows the canvas, `#fallback` computed `display: none`; the card had been covering a working WebGL canvas |
| S-013 | 3D render and navigation rework (quality, feel, full-sphere orbit) | See Stage T |

## Stage T — 3D graph render and navigation rework (2026-10-29)

Scope: the three owner follow-ups on the 3D graph views — sharper nodes, calmer
pointer feel with arrow keys, and an unrestricted orbit with far less per-frame
work. All changes are in `scripts/graph3d-template.html`; both outputs were
regenerated from `graphify-out/graph.json`.

| Item | What changed | Verification |
|---|---|---|
| T-001 | Node bodies, halos, and highlights are drawn by analytic impostor quads instead of per-node sphere/ring instances | Full view: 5,949,312 → 450,660 triangles, 4 draw calls; community view keeps 369 nodes / 1,372 links on the same impostor path |
| T-002 | A coarse depth shell occludes links behind node bodies, so links no longer bleed through the balls | Visual check at close range in Chromium and WebKit; body/halo radii scale with distance instead of growing into discs |
| T-003 | Orbit pitch is no longer clamped by the stock controller; the camera traverses the full sphere and flips its up vector at the poles | 260 pitch steps of π/48 (5.4π total): camera radius held at 1740.1, worst step dot product 0.9979, no lock-up; 240 yaw steps: 0.0000 up-vector drift |
| T-004 | Drag and zoom are normalized to viewport size and device pixel ratio, with damped rotate/zoom and arrow-key orbiting (Shift boosts) | Same drag distance turns the same visual angle at 1× and 2× DPR; arrow keys change yaw/pitch at every orientation |
| T-005 | The settled layout is cached in `localStorage` and restored on reopen | Full view cache 159,669 bytes; warm first interactive frame 256–340 ms vs 2,817 ms cold |
| T-006 | Frame pacing: idle **59.3–60 fps** (p95 18 ms), drag **59.6 fps** (p95 18 ms), versus 54.3 idle / 46.5 drag (p95 26–29 ms) before | Playwright in Chromium, 2560×1440 at DPR 2 with MSAA; community view also 60 fps |

**Verification commands:** `python3 scripts/build-graph-3d.py` then
`python3 scripts/build-graph-3d.py --check` — `ok` for both outputs (1.86 MiB
community, 7.71 MiB full). Hover, click-to-select, isolate, and reset were
exercised in the browser on both views with zero console errors and no external
requests. Arrow keys were measured on the shipped community file: yaw and pitch
both moved, camera radius stayed 964.2, no console errors.

**Output hashes:** `graph-3d.html`
`5eb179e77f55d0ff38d87dd8bd14b033c6a31c5fb3f2f2f4910642bde7a7495d`;
`graph-3d-full.html`
`ab9a19b6407b2a703d80c302701938f71d86a8c74f393f8927619f8265f67971`.

**Limitations:** the community view's cross-community links are still
`Line2` meshes, so it carries roughly 2.7k draw calls — fast on this machine
but more per-frame CPU than the full view's 4. Frame-rate figures are from
Chromium at DPR 2 on this Mac; Safari was verified for correctness (WebGL,
both views, `file://`), not benchmarked. The full view remains gitignored and
must be rebuilt locally.

### Repository policy (same session)

`AGENTS.md` gained a **CI gate** section: before calling a code task complete,
run `./scripts/verify-sentinel-surface.sh` and `./scripts/census.sh --unit-only`;
after an approved push, watch `census.yml` and keep fixing until the run is
green, never by skipping or weakening a check.

## Stage U — single 3D view (2026-10-29)

| Item | What changed | Verification |
|---|---|---|
| U-001 | Deleted the tracked community 3D page `graph-3d.html` (369 nodes, 1.86 MiB) at owner request; the full-node view is now the only 3D export | File removed from disk and git index; `graph.html` (2D) and `graph-3d-full.html` remain |
| U-002 | `scripts/build-graph-3d.py` no longer takes `--mode`; it builds, writes, and checks only `graph-3d-full.html` (−127 lines, the `community_view` builder and the multi-output loop) | `python3 -m py_compile` clean; `--check` → `ok` for the single output; no `community_view` / `--mode` references left |
| U-003 | `.gitignore` no longer un-ignores `graph-3d.html`; the full view keeps its ignore entry with the new single-view wording | `git status --ignored` shows no community 3D file; rebuild writes only the full view |

**Rebuild receipt:** `python3 scripts/build-graph-3d.py` wrote
`graphify-out/graph-3d-full.html` (7,510 nodes / 19,023 links, 7.71 MiB);
`--check` returned `ok`. Hash unchanged from Stage T:
`ab9a19b6407b2a703d80c302701938f71d86a8c74f393f8927619f8265f67971`.

**Supersedes:** Stage T's T-001/T-006 rows, its output-hash list, and the
S-011/S-013 records still describe the deleted community view; that is the
historical record. From this stage on, one 3D page is generated and kept.

## Stage V — one-hop retrieval index and the cold-reader gate (2026-10-29)

Goal: make a context-free reader reach a niche fact in one hop, and prove it
with a gate that fails on drift. Two new artifacts and one CI step:

| Item | What changed | Verification |
|---|---|---|
| V-001 | `docs/INDEX.md`: one table per subsystem; every row links the owning file, and 22 rows link the exact `#L` line that settles the question. The index points at owners instead of restating values; the one deliberate exception is the destructive menu's own name ("Erase Library & Data"), because that label is the action. | `--validate-only` checked every path and anchor bound; the facts gate resolved all 30 questions through the index with 0 fallbacks |
| V-002 | `scripts/comprehension-bench.py` + `scripts/comprehension-questions.json`: 30 niche questions and 12 overview facts, each validated against the file that owns it; naive (grep-first) vs indexed (map-first) policies, 3 repetitions, calibrated gate | 24-question baseline with no index: naive **48.7 ms / 26,907 B / 88% accuracy** (3 misses). After the index: **0.1 ms / 4,681 B / 100% / 0 fallbacks**, speedup **351.8×**, byte ratio 0.17 |
| V-003 | Six harder questions added after the first pass (notification key, CI run id, erase-data action, snapshot counts, generator flag, data root) to stop the bank from matching only the rows it was written beside | Repeated 30-question runs: **344–352×**, byte ratio 0.20, **100%**, 0 fallbacks; three anchors were wrong on the way (CI line, retired-3D line, data-root line) and the gate caught each one |
| V-004 | Full-context scan test: 246 tracked files vs four entry documents (README, INDEX, handoff, MILESTONES) | naive **74.6 ms / 3,121,726 B / 246 files**; indexed **0.8 ms / 62,819 B / 4 files**; **97.2×**, coverage 100%, byte ratio 0.02 |
| V-005 | Cold-reader defect: README said 138 checks / 56 required, while the SG8 catalog receipt says 140 / 58. README lines 41 and 106 corrected to 140 / 58; the 138 figure remains only in the historical milestone/gate prose. | Found by the cold-reader brief, confirmed against `docs/registers/04-handoff.md:25` and `03-fix-log.md` S-007, then corrected |
| V-006 | CI: `census.yml` gains a “Comprehension index freshness” step running `python3 scripts/comprehension-bench.py --validate-only` between the surface gate and the unit census; `AGENTS.md` local mirror lists the same three steps | GitHub run `40811182851` on `c2c669d`: green in 3m26s, with the new step before a passing unit census |

**Gate definition (calibrated, not advisory):** one-hop accuracy 100%, zero
grep fallbacks, indexed median ≤ 25 ms and ≤ 2 linked files, ≥ 4× faster than
grep, ≤ 0.5× the bytes; overview coverage 100%, ≥ 5× faster, ≤ 0.2× the bytes.

**Final measured runs (30 questions + 12 overview facts, rep 3, full mode):**
repeated runs measured facts naive **51.2–51.3 ms / 27,264 B** versus indexed
**0.1 ms / 5,398 B** — **344.5–351.6×**, byte ratio 0.20, accuracy 100%, 0 grep
fallbacks. Overview naive **74.6–75.6 ms / 3,121,726 B / 246 files** versus
indexed **0.8 ms / 62.8–63.3 KB / 4 files** — **97.2–97.8×**, coverage 100%.
The gate passed on the command's own exit status each time; the earlier
24-question build measured 48.7 ms / 26,907 B / 88% before the index, which is
the baseline row above.

**Push receipt:** commit `c2c669d` (13 files, +2,529/−1,190) pushed to
`origin/main`; census run `40811182851` succeeded, so the index-freshness step
has now executed on a GitHub runner exactly as the workflow declares it.

**Cold-reader trial:** three dispatch attempts with the same brief prompt,
timed from dispatch to report. Run 1 produced a 400-word, 12-citation brief in
~85 s and found the README 138/56 contradiction; run 2 returned a meta-summary
instead of reading files (~245 s, invalid sample); run 3, after the counts were
fixed and the index existed, produced a correct brief in ~48 s and found two
further inconsistencies (the Xcode version wording and the owner-gate order),
both since fixed. Wall-clock includes dispatch and model variance, so these are
not a clean before/after curve. Spawned workers inherit this session's
conversation — which is why run 2 failed — so the genuinely context-free,
repeatable measurement is the fresh-process harness, not the worker.

**Residual risks:** anchors are hand-maintained line numbers; CI's
`--validate-only` checks existence and bounds but cannot tell that a line moved
within the file. That drift is caught only by the local `--mode facts` gate, so
run it after any edit above an indexed line. Two anchors drifted during the
final doc edits (AGENTS retired-3D, README graph paragraph) and were re-pointed;
the full 30-question gate was then rerun and passed with zero fallbacks.

## Stage W — graph refresh and the Markdown truth audit (2026-10-29)

Goal: leave the navigation artifacts and the documentation byte-accurate for
the next engineering session, with every refreshed figure carrying a receipt.

| Item | What changed | Verification |
|---|---|---|
| W-001 | Graphify refreshed from the current tree. A root `.graphifyignore` now excludes `scripts/vendor/`, the minified 3D renderer, so its 3,371 AST nodes do not dominate the graph. | `graphify update . --force` exit 0: **7,599 nodes / 19,164 edges / 361 communities**, corpus 338 files / ~593,191 words; vendor nodes **0**; previous graph 7,510 / 19,023. |
| W-002 | 2D export regenerated as an aggregated community view; the 3D page rebuilt from the new graph. | `graphify export html` → 361 community nodes / 1,425 cross-community edges, 452,499 B; `python3 scripts/build-graph-3d.py` → 8,135,754 B (7.76 MiB); `--check` → `ok`. |
| W-003 | `AGENTS.md` graph verification corrected: it claimed both HTML pages were offline, but `graph.html` loads vis-network from unpkg by design. | The sentence now separates the self-contained 3D page from the networked 2D page. |
| W-004 | Markdown truth-audit rule, weighted rubric, append-only ledger, and evidence collector landed earlier this session; this stage records the close-out audit and refreshes the graph-cited counts. | `scripts/audit-markdown.py` OK on every edited file; `--validate-only` 30 facts / 12 overview facts; ledger rows appended. |

**Graph artifact hashes (2026-10-29):** `graph.json`
`fc4728f076bf080e175e2ad30d1a949c39c9ded4f4d0d55e380d9343c545f7bb`;
`graph.html` `05c85819dc15cace17c60213543a3a8cb6bd2cdc2ecf5130d358ff03ae86d3e7`;
`GRAPH_REPORT.md` `0db98f786082e0bb3a2954f02c58713f126dc5197ae1736a98d02ec179e314f4`;
`manifest.json` `813aa62cb845526feb64b4b956fe3152ea5d18df94ed9f3f0b096eea720bf806`.
The gitignored 3D page is
`360f961b681319b52a960fb01c08800a4d84eb31a10fd7c1fb39ba48756332ee`.

**Browser receipt:** the full 3D view loaded over loopback in Chromium with a
1280×720 canvas, WebGL true, **0 console errors**, and no external asset
references; the 2D page rendered through its documented unpkg renderer (one
local favicon 404).

**Local CI mirror:** surface OK (15 tables / 8 defaults keys / 5 notification
names); `--validate-only` OK; unit census **432 tests / 671 runs / 423 passed /
9 skipped / 0 failed**, exit 0.

**Limits:** the refresh used graphify's incremental AST update. A full semantic
re-extraction of docs was not run because no Gemini/Google backend is
configured; doc changes were re-extracted structurally by the update. The
tracked Markdown files outside this audit remain scheduled for the full sweep
recorded in `docs/registers/05-doc-audit.md`.
