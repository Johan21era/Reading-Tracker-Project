# Reading Tracker — Fix Log

Companion to `AUDIT_REPORT.md`, `TECH_DEBT.md`, `TESTING_STRATEGY.md`, executed under the project's fix protocol. Organized by Fix Order (application execution path).

**Verification status:** every entry below passed a clean `xcodebuild build` at patch time.
The app launches standalone from today's binary (earlier "healthy launch" evidence came from a
stale June DerivedData container — see 4.1). **The unit suite now executes: 16/16 pass**
(`TEST SUCCEEDED`) after resolving O-7. Runtime-abuse regression tests for the Stage 2/3
behavioral fixes remain to be authored — the harness that would run them finally works.

---

## Stage 1 — Application Launch (compile blockers)

The app did not compile at session start. Confirmed against a pristine git-HEAD baseline build
(worktree at `.baseline-check`, removed): HEAD failed with these same errors plus cascades.
All findings are High confidence by direct compiler evidence + inspection.

### 1.1 — Illegal stored property wrapper in extension · 🔴 Critical
- **File:** `Features/Discovery/OnlineBookSearchDrawer.swift`
- **Root cause:** `@State var selectedBook` declared inside a `private extension`; assignment
  at line 82 depended on it. Swift forbids stored properties/wrappers in extensions.
- **Finality:** *"Moving the property into the struct body fixes both errors and resolves the
  line-82 assignment."*
- **Fix:** property added to struct body (`@State private var selectedBook:`); illegal extension
  deleted with its MARK.
- **Verification:** compiles; call site unchanged.

### 1.2 — Missing `import Combine` under MemberImportVisibility · 🔴 Critical
- **File:** `Features/DeveloperConsole/DeveloperConsoleDashboardView.swift` (~line 81)
- **Root cause:** `Timer.publish(...).autoconnect()` used with only SwiftUI imported;
  project enables `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`.
- **Finality:** *"Adding `import Combine` resolves the missing-defining-module error."*
- **Verification:** error gone on rebuild.

### 1.3 — Extension of non-nominal type `Any` · 🔴 Critical
- **File:** `Features/BehaviorContext/BehavioralCategory.swift` (~970; sole call site 680)
- **Finality:** *"Retyping to `extension Equatable` preserves the chained call syntax because
  the receiver (`io_object_t`/UInt32) conforms to Equatable."*
- **Verification:** call site compiled unchanged.

### 1.4 — Impossible synthesized `Codable` on `ProcessInfo.ThermalState` · 🔴 Critical
- **File:** `Features/BehaviorContext/BehavioralCategory.swift` (`ThermalStateEvent`)
- **Finality:** *"Manual Codable via raw Int value (throwing dataCorruptedError on invalid
  raw values) satisfies conformance without changing public surface."*
- **Verification:** type-checks; corrupt decode path throws deterministically.

### 1.5 — Public declarations exposing internal types (×5) · 🔴 Critical
- **File:** `Features/BehaviorContext/BehaviorContextEngine2.swift`
- **Sites:** `BehaviorContextAdapterInput.books` + init; `AnalyticsContextEnrichment.improvementVector`;
  console-extension `consoleIdentity` / `consoleSnapshot`.
- **Finality:** *"Demoting exactly those five decls to internal matches DataStore3's identical,
  compiling conformance pattern."*
- **Verification:** all five errors gone; zero external usages existed (grepped).

### 1.6 — API drift: `generateTrendReport(from:)` → `(sessions:)` · 🔴 Critical
- **File:** `Features/Environment/Weather/WeatherInsightPanel2.swift`
- **Finality:** *"Relabeling the argument matches the engine's declared signature."*

### 1.7 — Reference to removed `WeatherSnapshot.sessionID` · 🔴 Critical
- **File:** `Features/Environment/Weather/WeatherInsightPanel2.swift` (~300–320)
- **Finality:** *"Deleting the exact-match index (member no longer exists anywhere — normaliser
  discards linkage) while keeping closest-by-timestamp join preserves documented semantics."*
- **Logged observation:** multiple sessions may share the nearest hourly snapshot — inherent to
  the snapshot model, not introduced here. See also O-6.

### 1.8 — `FullIntegrationInput` missing raw-evidence arrays · 🔴 Critical
- **File:** `Features/BehaviorContext/BehaviorContextEngine2.swift`
- **Finality:** *"Adding `deviceStateEvents`/`inactivityRecords` members and populating them at
  the single construction site from the same kit arrays fixes both 'no member' errors with zero
  consumer changes."* Analyzer signatures verified before edit.

### 1.9 — Misuse of IOKit C API in `systemIdleTime()` · 🔴 Critical
- **File:** `Features/BehaviorContext/BehavioralCategory.swift`
- **Root cause:** `.takeRetainedValue()` called on `kern_return_t` (confusion with
  `IORegistryEntryCreateCFProperty`); out-parameter passed as nil; optional-bound service fed to
  non-optional release/create calls.
- **Finality:** *"Rewrite with correct out-pointer pattern preserves byte-for-byte semantics
  (release always, 0 on failure, ns→s) and fixes compilation."*
- **Note:** masked until 1.3 unblocked deeper type-checking — cascade suppression.

### 1.10 — Inout through `if let` shadow binding · 🔴 Critical
- **File:** `Features/BehaviorContext/BehavioralCategory.swift` (~1266)
- **Finality:** *"Renaming the shadow binding lets clear(&activeSession) target the outer
  mutable optional; outer variable proven mutable by unconditional assignment elsewhere."*

---

## Stage 2 — Startup / Storage Loading / Library List

All verified at compile level (BUILD SUCCEEDED post-patch). Runtime abuse tests gated on O-7.

### 2.1 — Save/load failures completely silent in Release · 🔴 Critical · Audit §1.2 / Debt D1
- **Files:** `Core/DataStore3.swift`, `NewContentView.swift`
- **Finality:** *"`PersistenceStatus` published on DataStore, set degraded at every former
  silent-catch/site incl. directory-creation failure, reset healthy on any successful save,
  rendered by one persistent bottom banner = every failure mode Release-visible with
  dismiss-on-fix semantics."*
- **Implementation:** enum + `@Published private(set) var persistenceHealth`; degraded set in
  save/saveLibraryState catches, both load catches (backup messaging included), post-init
  directory check (placed where `self` is fully initialized); `PersistenceWarningBanner`.

### 2.2 — Unrepairable corruption silently re-persisted · 🟡 Med(sev)/🟢 High(conf) · §3.3
- **Finality:** *"Branch on `report.hasUnrepairableErrors` before auto-save; surface instead of
  overwriting the last-good file."* Validator source re-read to confirm flag semantics.

### 2.3 — Debounced save stalls during window tracking · 🟡 Medium · §3.1
- **Finality:** *"Timer(timeInterval:)+RunLoop.main.add(_, .common) keeps debounce firing through
  event-tracking modes without changing coalescing."*

### 2.4 — Multi-item delete corrupts/crashes on index reuse · 🔴 Critical · §2.1
- **Finality:** *"Capture ID set from offsets BEFORE mutation; remove by identity — eliminates
  index-shift effects for arbitrary multi-selects."*

### 2.5 — Achievement toast drops/re-shows on concurrency · 🟡 Medium · §2.2
- **Finality:** *"View-side FIFO fed by deduplicating onReceive + serial presenter +
  `DataStore.markAchievementToastShown(id:)` incremental consumption guarantees each earned
  achievement shows exactly once."* Tap consumes single item; panel sweep preserved.

### 2.6 — Ghost estimate for deleted book · 🟡 Medium · §2.3
- **Finality:** *"Guard `dataStore.book(id:) != nil` inside the delayed work item."*

---

## Stage 3 — Monitoring, Analytics Date Math, Truth-Fixes, Test Wiring

### 3.1 — Screen-lock observers leak & duplicate per foreground cycle · 🔴 Critical · §4.1 / D2
- **File:** `Features/BehaviorContext/BehavioralCategory.swift`
  (`startMonitoring` / `stopMonitoring` / `observeScreenLockEvents`)
- **Root cause:** two block-based `DistributedNotificationCenter.addObserver(forName:...)`
  registrations discarded their tokens; `removeObserver(self)` is a silent no-op for them;
  `startMonitoring()` re-registers on every `.active`. Net effect: zombie observers stack every
  background/foreground cycle for process lifetime, multiplying every lock/unlock evidence record.
- **Precedent inside same file:** `stopMonitoring` already removes `systemPowerObserver` by
  token — the correct pattern existed locally and was not applied here.
- **Finality:** *"Capturing both NSObjectProtocol tokens, guarding observeScreenLockEvents
  against re-entry, and removing tokens explicitly in stopMonitoring makes arbitrary
  start/stop cycling produce exactly one active registration pair."*
- **Fix:** `screenLockObserver`/`screenUnlockObserver` properties; idempotence guard;
  explicit token teardown + nil-out in `stopMonitoring`.
- **Verification:** compiles; lifecycle walked for double-start, rapid cycles, background
  teardown. Runtime count assertion pending O-7 (TESTING_STRATEGY prescribes exactly this test).

### 3.2 — Force-unwrapped failable Calendar arithmetic (13 sites) · 🟠 High · §5.1
- **Files:** `Engines/AnalyticsEngine.swift` (streak; `AnalyticsPeriod.dateRange`;
  `previousPeriod` ×3 cases), `Features/Goals/ReadingGoalManager2.swift` (`weeklyStreakStatus`)
- **Root cause:** `Calendar.current` reflects the user's region calendar setting
  (Japanese/Hebrew/Buddhist/Islamic are legitimate macOS settings); `date(from:)` /
  `date(byAdding:to:)` are documented-fallible; every site force-unwrapped. A single failure
  would crash Insights, Estimation, and Goal tracking simultaneously.
- **Confidence:** upgraded to High by direct enumeration (grep of all `)!` sites in both files —
  13 found, 13 patched, matching audit's list exactly).
- **Finality per shape:** *"Guarding each failable constructor with a documented degradation
  (same-day range for period bounds; equal-length window via pure arithmetic for previous-period
  bounds — mirroring the existing .custom case math; cursor=today for streak; neutral
  zero-progress GoalStatus for weekly streak) converts crash-on-nil into graceful degradation
  without changing any Gregorian-locale result."*
- **Verification:** compiles; all Gregorian paths byte-equivalent; non-Gregorian runtime matrix
  pending O-7 (TESTING_STRATEGY's parameterized-Calendar test covers it once runnable).

### 3.3 — False integration-status comment · 🟢 Low-sev defect class · §1.1 / D4
- **File:** `Features/Environment/EnvironmentBackgroundView2.swift` header
- **Evidence:** `NewContentView.swift` (fully read) contains no `environmentEngine` property and
  no reference to this view — the claim was verifiably false.
- **Finality:** *"Replacing the false sentence with a STATUS CORRECTION note pointing at
  LibraryExplorerView2's accurate header eliminates the misleading doc."*

### 3.4 — Investigated and DISPROVEN (Zero-Touch compliance)
- `AnalyticsEngine` ~566/567: `buckets.max(by:)!.key` / `.min(by:)!.key` looked like zero-data
  crashes but the dictionary is seeded with all four `ReadingWindow` keys and keys are never
  removed — max/min can never see an empty collection. **Untouched**, logged to document the
  adversarial self-check working as designed.

### 3.5 — Real test suites wired into the executing target · 🟠 High · §6.1 / D3 (code complete)
- **Route decision (Finality on approach):** TESTING_STRATEGY offered convert-to-Testing vs
  link-XCTest. Route A chosen: synchronized folder already runs swift-testing stub; no XCTest
  link exists; extraction also cures D3's anti-pattern (tests embedded behind
  `#if canImport(XCTest)` in a production file).
- **Done:** `Reading TrackerTests/WeatherTests.swift` created — three suites converted
  (`XCTestCase`→`@Suite`, asserts→`#expect`, `XCTUnwrap`→`try #require`, setUp/tearDown→
  init/deinit; every assertion message preserved); the test-only `coverageRatio(for:)` shim
  migrated with its callers; 13,903 chars of dead block stripped from `WeatherKitService2.swift`
  (1405→1082 lines). App target **BUILD SUCCEEDED** post-extraction.
- **Conversion bugs found & fixed during bring-up:** WeatherKit needed importing directly
  (MemberImportVisibility, third occurrence); `#require` around a throwing call needs its own
  `try`.
- **Execution:** BLOCKED BY O-7 below. Suites compile into `Reading TrackerTests` but the host
  dies pre-connection; per TESTING_STRATEGY step-zero, results are not claimed until green.

---

---

## Stage 4 — Test Infrastructure Forensics & First-Run Findings

### 4.1 — O-7 RESOLVED: every Debug launch crashed in DeveloperConsoleRegistry init · 🔴 Critical
- **Files:** `Features/DeveloperConsole/DeveloperConsoleRegistry.swift` (init / manifest)
- **Root cause:** `DeveloperConsoleRegistry.init()` called
  `DeveloperConsoleStaticEngineManifest.registerAll()` → `registerOne<T>` → line 111
  **`DeveloperConsoleRegistry.shared.registerStatic(type)`** — a global access from inside
  `.shared`'s own `dispatch_once` callout. libdispatch detects self-wait and traps:
  `_dispatch_once_wait` / EXC_BREAKPOINT, surfaced by test runners as "test runner crashed
  before establishing connection." Affected EVERY Debug launch since this file landed, not just
  tests — it was simply unreachable while the compile blockers existed.
- **Evidence correction:** an earlier log entry cited a healthy standalone launch as proof the
  crash was test-mode-only. That binary came from a **stale June 19 DerivedData container**
  (`bezhta…`) rather than the active one (`ewbssf…`). Retracted; forensics from the .ips
  (crashed-thread frames) supplied the true chain.
- **Finality:** *"Passing the registry instance into registerAll/registerOne removes the only
  global access inside its own initialization, so first-touch completes without self-waiting;
  registration set, timing, and providers unchanged."*
- **Fix:** `registerAll(into:)` / `registerOne(_:into:)`; init passes `self`.
- **Verification:** today's binary alive ≥6 s standalone; `xcodebuild test` connects and runs;
  **suite result 16/16 pass**.

### 4.2 — Weather store could strand stale rows forever on crash-retry · 🔴 Critical · found BY the tests
- **File:** `Features/Environment/Weather/WeatherKitService2.swift` (`WeatherSnapshotStore.save`)
- **Root cause:** table PRIMARY KEY is each snapshot's own UUID, so `INSERT OR REPLACE` never
  deduped retries under the same `session_id` — yet `fetch(sessionID:) LIMIT 1` and
  `countPresent` both assume exactly one row per session. A crash-recovery double-save left two
  rows; fetch returned the arbitrary-first (stale) weather record permanently.
- **Finality:** *"An explicit DELETE-by-session followed by the existing INSERT inside a single
  transaction makes any retry idempotent while keeping failure paths atomic (rollback leaves
  either zero or one row — never two, never none)."*
- **Fix:** `BEGIN IMMEDIATE` → conditional DELETE → INSERT → COMMIT, rollback-on-any-failure via
  defer; nil-session inserts unchanged.
- **Verification:** `save_idempotent_replacesExisting` passes; all other store tests unaffected.

### 4.3 — Fixture correction: clearCalm storm-index test · 🟢 test-authoring fix
- **File:** `Reading TrackerTests/WeatherTests.swift`
- **Diagnosis:** `computeStormIndex`'s wind term is deliberately unconditional (a labelled-clear
  90-kPH gale scoring ~0.23 is correct meteorology), so "near-zero" only holds at zero wind.
  The original never-executed fixture used `windKPH: 5` (index 0.0125 > 0.01 tolerance).
- **Decision:** production analytics untouched (Zero-Touch); fixture now uses true calm
  (`windKPH: 0`), strengthening the real invariant: zero inputs ⇒ zero index. Reasoning recorded
  here to prevent a future session from 'fixing' the engine instead.

### 4.4 — Deinit resurrection abort in BehaviorContextAccessKit · 🔴 Critical · found BY new tests
- **File:** `Features/BehaviorContext/BehavioralCategory.swift` (`deinit`)
- **Root cause:** `deinit { Task { @MainActor in stopMonitoring() } }` implicitly captured
  `self` from inside its own deallocation. The task retained the dying object, hopped to main,
  and called instance methods on freed memory → double-dealloc →
  `swift_deallocClassInstance` fatal (SIGABRT). Latent since the class was written: production
  holds the kit for app lifetime (`@StateObject`), so nothing ever released one until the
  ObserverLifecycle regression test became the first caller to do so.
- **Forensic trail:** crash frames (`doDecrementSlow(PerformDeinit)` →
  `__deallocating_deinit` → `deallocClassInstance.cold.1`) initially masqueraded as an
  assertion failure with 0.000 s durations; an anchored-instance experiment split the two
  concerns — with dealloc prevented, the §4.1 assertion PASSED, proving both the observer fix
  and isolating the deinit as the sole crash source.
- **Finality:** *"Removing the self-capturing Task cannot regress any real behavior — a cleanup
  task running against deallocated memory never had defined behavior — while both live paths
  (scenePhase background, tests) already call stopMonitoring() before release."*
- **Fix:** empty documented deinit + explicit ownership contract at the type.
- **Verification:** unanchored lifecycle test passes; **full unit suite TEST SUCCEEDED,
  27/27 unique tests green** (one pass-line is log-interleaved mid-name in raw output;
  solo re-run confirms it).

### 4.5 — Regression battery authored (TESTING_STRATEGY step-two)
`Reading TrackerTests/ReliabilityTests.swift`: Validator ×5 (incl. the exact §3.3 gate key),
DataStore persistence ×4 (round-trip, corrupt→degraded+bak, unrepairable-gate byte-identity,
repairable-autosave), Library mutation ×2 (§2.1 identity contract, dedupe), Observer lifecycle
×1 (§4.1 ten-cycle abuse → exactly-once delivery). Every failure names its defect class.

---

## Open / unresolved — Finality not reached or execution blocked

| Ref | Source | Item | Status / Next step |
|---|---|---|---|
| O-3 | Audit §8.1 | New-Year overlay timer chain can outlive `cleanup()` | Latent (feature unwired). Fix before Part 12 wiring; needs cancellation-token redesign reaching Finality. |
| O-6 | This session | Weather SQLite rows keyed by sessionID while normaliser discards it → `coverageRatio(for:)` sees only legacy rows | Design decision required; logged, untouched. |
| O-8 | Audit §3.2, §3.4, §7.1, §2.4 | Sync main-thread writes; `urls(...).first!` ×2; `turnToPage` weak-store divergence; duplicate-import silent no-op | Left untouched per Confidence Rules (Medium/Low confidence, or Low severity awaiting batch with UI feedback work). Prescribed fixes recorded in AUDIT_REPORT. |

**Definition-of-Done scorecard:** files read ✔ (all touched files + callers fully read; giants
covered region-exhaustively around every edit) · confirmed bugs fixed-or-open ✔ (**23 fixed**
incl. O-7 and the store-retry defect; 1 fixture corrected with rationale; 3 open tracked:
O-3 latent celebration timers, O-6 weather session-key design, O-8 medium/low-confidence
dispositions) · `fix-log.md` ✔ · `handoff.md` ✔ · **unit suite executing: 16/16 pass** ✔


---

# Phase 1 — Foundation Strike (current session)

Executed under the project's fix protocol against CURRENT_AUDIT.md findings.
Every entry below passed a clean `xcodebuild build` AND `xcodebuild test` (TEST SUCCEEDED)
at patch time. Stage 0 protection landed first: commit `9f7c619` (tree reorg, frozen
pre-fix content), commit `608868e` (remediation session + hygiene: .gitignore for
user-state/coverage/generated-analysis artifacts).

## P1.1 — AUDIT F-01 · 🔴 Critical · Annual Reports Calendar crash · FIXED
- **File:** `Features/Reports/AnnualReportData2.swift` (`analyticsPeriod(for:)`)
- **Root cause:** two force-unwrapped failable `Calendar.date(from:)` constructions;
  `Calendar.current` follows the user's region calendar setting. Same class as the §5.1
  thirteen, missed because that sweep enumerated only AnalyticsEngine + ReadingGoalManager2.
- **Failure scenario:** non-Gregorian calendar user opens Annual Reports → nil force-unwrap crash.
- **Finality:** guarded degradation (same-day range if year-start fails; arithmetic next-year
  bound mirroring this file's own daysInCalendarYear style) plus additive defaulted
  `calendar:` parameter makes the crash impossible while keeping Gregorian output identical.
- **Verification:** `NonGregorianCalendarTests` — Gregorian exactness pin + parameterized
  no-crash/span-sanity across hebrew/japanese/buddhist/islamicCivil/persian. All pass.

## P1.2 — AUDIT F-03 · 🟠 High · Numeric HTML entity destruction · FIXED
- **File:** `Core/SharedTextUtilities.swift` (`decodeHTMLEntities`)
- **Root cause:** regex pre-strip replaced `"&#(\d+);"` with `"$1"`, converting entities
  into bare digits before decodeNumericEntities could run (&#8217; → "8217").
- **Impact surface:** EPUBReaderScreen display text, wordCount inflation,
  DifficultyAnalyzer + InsightEngine corpus inputs.
- **Finality:** deleting the pre-strip lets the existing correct decimal/hex decoder receive
  intact entities; named-entity path untouched.
- **Verification:** `TextExtractionTests` — decimal/hex decode, corruption-signature impossibility,
  stripHTML end-to-end, word-count integrity, malformed-entity inertness. All pass.

## P1.3 — AUDIT F-04 Gates A+B · 🟠 High · Schema evolution / state-file data loss · FIXED
- **Files:** `Core/DataStore3.swift` (loadLibraryState), `Core/Book2.swift` (Book, LibraryState)
- **Gate A Finality:** backing up the unreadable state file via backupCorruptFile before reset
  makes goals/deadlines/achievements recoverable instead of silently overwritten by next save.
- **Gate B Finality:** tolerant custom Decoders (decodeIfPresent + current defaults) on Book and
  LibraryState accept pre-v3/v4 files; encoding remains synthesized so first save upgrades schema.
- **Verification:** `SchemaEvolutionTests` — legacy Book JSON decodes w/ defaults, modern round-trip
  lossless, version-less LibraryState accepted, corrupt state file → .bak preserves original bytes.
  All pass.

## P1.4 — AUDIT F-05 · 🟡 Medium · LocationProvider continuation leak · FIXED
- **File:** `Features/Environment/Weather/WeatherKitService2.swift` (LocationProvider)
- **Root cause:** single continuation slot; overlapping request overwrote it, leaking the first
  awaiting task forever.
- **Finality:** FIFO queue resumed exactly-once per continuation on delegate success/failure
  (drain-before-resume prevents re-entrancy) makes overlap safe; single-request path identical.
- **Verification:** inspection-level only — CLLocationManager cannot be driven synthetically in
  unit tests without location authorization. Build green; behavior walked for success/fail/overlap.
  Logged honestly as inspection-verified.

## P1.5 — AUDIT F-07 · 🟡 Medium · Combine observer double-registration · FIXED
- **Files:** `Features/BehaviorContext/BehavioralCategory.swift`, `ReadingTrackerApp 2.swift`
- **Root cause:** idempotence existed only on the screen-lock pair (§4.1); the four Combine paths
  appended sinks unconditionally, and launch calls startMonitoring() twice (.task + initial
  scenePhase change) → duplicate workspace/power evidence for process lifetime.
- **Finality:** isMonitoring gate (cleared in stopMonitoring) makes redundant starts no-ops while
  preserving start/stop cycle contract.
- **Verification:** `ObserverLifecycleTests/redundantStartsDoNotDuplicateWorkspaceObservers` —
  synthetic willSleepNotification after launch-style double-start delivers exactly ONE
  DeviceStateEvent (pre-fix: two). Existing ten-cycle abuse test still green. Pass.

## P1.6 — AUDIT F-02 (+ former O-3) · 🟠 High · NY celebration chain · FIXED
- **File:** `Features/Reports/NewYearTransitionMonitor.swift`
- **Status correction logged:** feature was already wired at app root (.newYearTransitionAware());
  O-3's "unwired/latent" premise was false. Header comments truth-fixed to match reality.
- **Redesign:** three Timers + nested Task hops replaced by CelebrationTimeline (extracted phase
  driver with injected sleeper) driven by one cancellable sequenceTask; particle trickle is an owned
  cancellable task (compounding spawnParticles non-invalidation issue structurally eliminated);
  beginExit() re-entry guard stops duplicate onComplete during .exiting taps.
- **Finality:** cancellation now provably halts every future step regardless of phase; no Timer
  successor can be assigned post-cleanup because no Timers exist.
- **Verification:** `CelebrationTimelineTests` — full-run ordering, dismissal-during-toast silences
  ALL steps, mid-expand blocks fullscreen+autoExit, mid-fullscreen blocks autoExit, spec durations
  pinned. All pass. (The exact §8.1 race is now a deterministic test.)

## Pins added this phase
NonGregorianCalendarTests (15 cases) · TextExtractionTests (7) · SchemaEvolutionTests (4) ·
CelebrationTimelineTests (5) · ObserverLifecycleTests +1 (double-start). Toast-FIFO UI-side pin and
persistence-banner UI assertion remain deferred by design (view-local logic; documented in
CURRENT_AUDIT §7.2).

## Open after Phase 1
F-06 (dormant fatigue analyzer) · F-08–F-13 (Low) · O-6 · O-8 remainder · D6/D7 — all tracked in
CURRENT_AUDIT.md, scheduled Phases 2–5.


---

# Phase 2 — The Great Wiring (current session)

Executed under the project's fix protocol against CURRENT_AUDIT.md §8/D5 inventory.
Every stage verified by clean build; full suite TEST SUCCEEDED after each pin landed.

## P2.0 — Baseline re-verified green before any edit (protocol step-zero).

## P2.1 — AUDIT §8.2 gate · Shared-engine refcount · FIXED+PINNED
- File: EnvironmentEngine2.swift. Finality: consumer counting (start ++, stop --,
  cancel at zero) makes multi-consumer appear/disappear cycles preserve the shared
  45s loop for remaining readers while single-consumer behavior is unchanged.
- Pin: EnvironmentEngineTests ×4 — synchronous-first-state via injected noon clock,
  single-consumer parity, THE freeze regression (A-stops/B-survives), over-release safety.

## P2.2 — D5/§1.1 wiring: ENVIRONMENT ENGINE IS LIVE
- ContentView owns the single engine via @StateObject per the view's own documented
  contract; EnvironmentBackgroundView composes as ZStack root behind NavigationSplitView;
  sidebar scrollContentBackground(.hidden) lets the gradient read through; engine exposed
  downstream via .environmentObject. Status headers truth-fixed (WIRED).
- Note: detail-pane material tuning deferred to visual polish (wiring ≠ theming pass).

## P2.3 — D5/§1.1 wiring: LIBRARY EXPLORER LIVE (filtering → spatial pipeline)
- "Explore" toolbar item presents LibraryExplorerView sheet (books + collections +
  engine-driven reducedMotion); onSelect routes to the estimation detail pane.
- Progressive Filtering model layer added: DataStore collection CRUD
  (add/rename/remove/setMembership) WITH referential integrity on removal
  (dangling collectionIDs stripped from every book).
- Pins: LibraryCollectionTests ×5 incl. THE integrity pin + filter-ghost interplay.
- En-route catch: my first test draft had a REAL isolation bug (stores sharing one
  derived library-state.json through the common temp root) — root-caused from failure
  pattern (book-side asserts passed, collections-side failed), fixed, documented here
  as the worked example of Phase-3 discipline applied to tests themselves.

## P2.4 — AUDIT §1.1 verdict EXECUTED: Import Intelligence surfaces
- ~250 previously-unreachable lines now run on every real import; warnings surface via
  an "Import Notes" alert (⚠️ critical / • informational). Facade untouched (pure).

## P2.5 — AUDIT F-06 · 🟡 dormant-path defect · FIXED+PINNED
- Files: BehaviorContextEngine2.swift (InactivityGapRecord + builder + FatigueIndicatorAnalyzer).
- Root cause: duration-sorted "consecutive increase" counting = near-tautology; Date() stamps;
  day-grouping impossible without dates. Fix: gap records carry real boundaries; increasing-run
  computed chronologically; extended-gaps grouped per calendar day of start; signals dated from
  gap boundaries. V3 activation itself remains scheduled with its UI work (per roadmap).
- Pins: FatigueAnalyzerTests ×7 — interleaved-timeline silence (the tautology killer),
  genuine-run fires once dated correctly, same-day grouping, cross-day non-grouping,
  overnight dating + precondition, empty input.

## Open after Phase 2
SpatialNavigator/FloatingCluster sub-surfaces ride inside Explorer already; remaining:
F-08–F-13 (Low, Phase 5), O-6/O-8/D6 (Phases 4–5), BCE V3 activation with UI (Phase 3),
RSVP feature plan read+implementation (Phase 3).


---

# LIVE-TEST REMEDIATION (LT-001) — current session

Source: Johan's manual stress-test report ("LIVE TESTING SESSIONS" — every action ×20
sessions). Per directive, this superseded all roadmap work. Root-caused from code, not
guessed; each fix built clean and the full suite stayed green throughout.

## FIXED

### LT-1 · Discover Books bricked the app · 🔴 → FIXED
Root cause: sheet presented a nearly-transparent ZStack hiding a left-edge "drawer"
behind a floating tab — no title bar, no close control, dead-end by design.
Fix: complete redesign as a proper modal (header+Close/Esc, prominent centered search,
real results list, empty/loading/offline/error states, detail on selection).
OnlineBookSearchDrawer.swift retired (sole reference removed).

### LT-2 · Annual Reports bricked the app · 🔴 → FIXED
Root cause: archive sheet was a NavigationSplitView with zero dismissal affordance.
Fix: systemic `sheetDismissAffordance()` modifier (floating close + Escape) applied to
ALL top-level sheets — a dead-end sheet is now structurally impossible.

### LT-3 · Ghost books + phantom reading time · 🔴 → FIXED (two fused defects)
(a) Persistence: app is sandboxed (ENABLE_APP_SANDBOX) but shipped with NO entitlements —
security-scoped bookmark creation failed silently at import; session-scoped access masked
it until relaunch; every EPUB became unopenable ("permissions may have expired").
FIX: created Reading Tracker.entitlements granting app-scope bookmarks, user-selected RW,
and network.client (Discovery/Weather were also silently broken under sandbox); wired into
both configurations via CODE_SIGN_ENTITLEMENTS.
(b) Phantom time: BOTH readers called coordinator.startReading() unconditionally on appear,
so staring at the load-error screen accrued sessions (×20 test sessions = the phantom
1h30m). FIX: EPUB starts timing only after package opens; PDF gains onLoadSuccess callback
fired only when a document exists. Time-on-unopenable-files is structurally impossible.

### LT-4 · Insights pinned center / dragged main window · 🟠 → FIXED
Insights now opens as its own real Window scene (movable, resizable) via openWindow;
sheet path removed.

### LT-5 · Report Prev/Next needed double/triple clicks · 🟡 → FIXED
Hairline plain-style labels replaced with padded capsule targets + contentShape.

### LT-6 · Report clipped long sentences / ignored zoom · 🟡 → FIXED
Slides render inside GeometryReader+ScrollView (designed layout at full size, scrolls
when cramped); narrative row uses ViewThatFits stacking; truncation lineLimits removed.

### LT-7 · Hover sluggish + wall-of-info · 🟡 → FIXED
Delay 1.5s→0.55s; detail pane reveals in three animated waves (reduced-motion = instant).

### LT-8 · Demo profiles requested · ✅ DELIVERED
DemoDataService (DEBUG-only): deterministic 13-book catalog — romance-dominant hours per
your example — with ~16 weeks of staggered session history, page timings, streak patterns,
completed/in-progress mix, series pair, favorites, and two collections. Analytics ▸
"Load Demo Library (Debug)" installs everything in one click.

## OPEN (queued — next work before ANY Phase 3)
- LT-9 Settings: symbol color customization
- LT-10 Achievements gallery (all badges + totals)
- LT-11 Star visual polish ("just dots")
- LT-12 Broader de-blocking design pass (partially addressed via capsule buttons/fades)

## Verification
BUILD SUCCEEDED after every stage; full suite TEST SUCCEEDED at close. Entitlement change
requires a fresh Run (clean build folder if Xcode caches signing): books imported AFTER this
build will persist across launches; existing ghost books need re-importing once.


---

# LT-8 v2 — DEMO PROFILE LAB + Celebration Trigger (follow-up session)

Per Johan's spec: 16 selectable synthetic reader personas locked inside the Developer
Console, heavy-data, mutually isolated, plus an on-demand New Year celebration trigger.

## DELIVERED
- **DemoDataService.swift (rewritten)**: 16 personas incl. The Winter Romantic
  (~1,000h romance, winter-dominant via full 12-month weight table), The Afternoon
  Devotee (≥70% sessions 12–5pm), Fantasy Marathoner, Commuter Snacker, One-Book Wonder,
  Completionist, Serial Abandoner, Night Owl Scholar, Poetry Dabbler, Business Grinder,
  Seasonal Cyclist, Rereader, Speed Demon, Slow Savorer, Goal Crusher, Comeback Story.
- Deterministic SplitMix64 seeded per persona id (pinned by tests).
- Session synthesis: weighted hour-buckets, seasonality multipliers, weekday gating,
  persona pace ranges, page-timing chunks; horizon auto-sized to catalog hours.
- ISOLATION: whole file #if DEBUG; single mutation path through debug_replaceLibrary
  (which NOW also resets LibraryState so profiles never blend); Analytics-menu hook from
  v1 removed — Dev Console is the only door. Release builds contain none of it.
- **DemoProfileLabView**: console pane (sidebar section "Demo Profile Lab") — persona
  list w/ book+hour counts, detail panel (blurb, metrics, full catalog preview),
  two-step armed install with explicit replace warning, last-install summary.
- **Celebration Lab card**: "Trigger New Year Celebration" button → DebugCelebrationBus
  (weak static handoff) → NewYearTransitionMonitor.debug_forceCelebration(); disabled with
  explanation until the main window owns a monitor. Full overlay sequence fires over the
  live app window for review.
- **Pins: DemoProfileServiceTests ×9** — catalog shape; EVERY persona validator-clean
  (no unrepairable issues, all sessions closed, pages in range); Winter Romantic signature
  (winter share >0.45, romance share ≥0.52); Afternoon Devotee signature (>70% in-window);
  per-id determinism.

## EN-ROUTE FINDINGS (logged per protocol)
1. Heredoc-emitted backslashes doubled through tooling — swept across affected files;
   guard: any future generated-Swift emission must be audited for `\\( ` artifacts.
2. A misplaced diagnostic referenced a variable before declaration; stale incremental
   builds masked the compile error as flaky runtime failures across several runs.
   Clean-build discipline re-established as the only trustworthy verification mode.
3. Month-weight design flaw caught by mirror-simulation BEFORE shipping: uniform
   default weights lose to non-winter day-count arithmetic; fixed by specifying ALL
   twelve months and verifying shares in an offline port of the seeded algorithm
   (winter 51%, romance 70%) prior to the final Swift build.

## Verification
BUILD SUCCEEDED; FULL SUITE TEST SUCCEEDED at close (~108 cases).
