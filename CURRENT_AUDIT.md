# Reading Tracker — Current Audit

**Audit ID:** RA-CURRENT-001 · **Date of record:** session of record, post remediation-pass baseline
**Scope:** complete source tree of `Reading Tracker Main /` (app target, test targets, project configuration)
**Framework applied:** the architecture & defect review method + `TESTING_STRATEGY.md` (coverage/risk mapping)
**Status of this document:** this is the successor to the deleted `AUDIT_REPORT.md` / `TECH_DEBT.md`. Future sessions should treat **this file as the current defect & risk register** until superseded.

> **REVISION — RA-002 remediation session (all four roadmap phases executed):**
> Route-B verdict on the dead weather Fix-block (deleted; underlying engine defects re-registered
> below as **W-01/W-02/W-03 OPEN**); NA-2 goals/deadlines creation surface SHIPPED (Settings
> window ⌘, → goal editor → live dashboard propagation; F-08 weekGoalStreak now earnable);
> D6 async chained writes landed (saveImmediately contract preserved); O-8 batch closed (guarded
> lookups + duplicate-import surfacing); F-12 both bind sites fixed; NA-3 race guard; NA-4/NA-5
> submission artifacts added (apple-events entitlement + usage strings; PrivacyInfo.xcprivacy);
> F-09/F-11/F-13(a,b-c-logging)/NA-7(2 of 3)/NA-8 fixed; JanuaryFirstBannerView deleted;
> default.profraw removed. Suite TEST SUCCEEDED at every phase boundary. Full detail + plain-
> language verification pathways in fix-log.md §RA-002.
> **NEW OPEN ENTRIES:**
>
> ### W-01 · 🟠 High · Live aggregate confidence is decorative (reopened from dead "Fix 2")
> `WeatherAnalysisEngine.calculateAggregateConfidence` hardcodes recurrence/stability/consistency
> to 0.8 and dataCoverageScore to 1.0; called by BOTH live entry points (generateTrendReport,
> generateBehaviorReport). User-invisible today (panel renders neither report confidence field —
> verified by decision-gate read), hence High not Critical. Fix shape: accept coverageRatio +
> derive from correlation scores; pin with injected-ratio test.
>
> ### W-02 · 🟡 Medium · firstObserved/lastObserved derived from unsorted arrays
> buildCorrelation / buildBinaryConditionCorrelation pass `sessions.first/.last` unsorted;
> wrong temporal bounds flow into maturity gating evidence. Fix shape: sort by timestamp
> (authored temporalBounds(of:) was deleted with Route B; reimplement inline).
>
> ### W-03 · 🟡 Medium · avoidedGenres still selects rarest genres
> buildSeasonalProfiles uses suffix(3) of genre counts — labels least-read genres as "avoided".
> Fix shape: ≤5%-of-sessions threshold (dead authored logic deleted with Route B).

> **REVISION — Phase 2 (The Great Wiring) executed:** §8.2 refcount gate closed+pin;
> Environment Engine WIRED (D5 flagship); Library Explorer + Progressive Filtering model
> layer WIRED (collection CRUD w/ referential integrity); Import Intelligence verdict
> EXECUTED (surfaces at import); F-06 FIXED+pinned. BCE V3 activation intentionally
> deferred to its UI work (Phase 3). Suite green at close.
> **REVISION — Phase 1 (Foundation Strike) executed:** F-01, F-02, F-03, F-04 (Gates A+B),
> F-05, and F-07 are **FIXED** and pinned by regression tests (see fix-log.md Phase-1
> section; suite green at close). Remaining OPEN: F-06, F-08–F-13. Executive-summary counts
> below describe the register as originally written.

---

## 0. How to read this audit

Findings use the established severity/confidence scale:

| Mark | Severity | Meaning |
|---|---|---|
| 🔴 | Critical | Crash, data loss, or silent corruption reachable in normal use |
| 🟠 | High | Breaks under realistic conditions, or corrupts analytic/integrity guarantees |
| 🟡 | Medium | Breaks under uncommon-but-real conditions, or on currently-dormant paths that are wired for future activation |
| 🟢 | Low | Narrow impact; correctness/documentation inconsistencies |

Confidence is stated per finding: **High** = direct code evidence traced end-to-end this audit; **Medium** = strong evidence, execution not reproduced here.

No code was modified during this audit. Every finding is logged OPEN for a future fix session following the project's fix protocol (Finality must be reached independently before any edit).

---

## 1. Method & coverage (stated honestly)

The audit combined three verification tiers. Every file in the app target falls into exactly one:

**Tier A — fully read this audit (line-by-line):**
App entry & root view (`ReadingTrackerApp 2.swift`, `NewContentView.swift`) · Core (`Book2`, `DataStore3`, `DataIntegrityValidator`, `SharedTextUtilities`) · Engines (`AnalyticsEngine`, `EstimationEngine`, `DataMaturityEngine`, `DataMaturityEngineAdapters`) · Sessions (`SessionCoordinator2`, `SessionEventRouter2`) · Achievements (`AchievementEngine2`) · Goals (`ReadingGoalManager2`) · Insights (`InsightEngine`) · Notifications (`IntelligentNotificationEngine`) · BehaviorContext (`BehavioralCategory`, `BehaviorContextEngine2`, `BehaviorEvidenceBuilder`) · Weather persistence/service (`WeatherKitService2`) · Reports (`AnnualReportData2`, `NewYearTransitionMonitor`) · Audio persistence/monitoring (`AudioTrackerMetadata2`) · Library import (`BookImporter`) · Developer Console core (`DeveloperConsoleRegistry`) · Tests (`ReliabilityTests.swift`) · project.pbxproj (target membership & build settings).

**Tier B — targeted inspection + tree-wide defect-class sweeps (every file covered by pattern, not every line read):**
All remaining view/controller files (dashboards, panels, discovery cluster, environment cluster, spatial library cluster, reader views, developer console views, audio snapshot/musical analysis, recommendation panel, session history). Sweeps executed against the *entire* tree regardless of tier:

- Force-unwrap census (`)!`) — 8 hits total; each individually adjudicated (§4 F-01, plus six safe/documented sites).
- `try!` census — **zero** hits.
- `fatalError` / precondition-style abort census — **zero** hits.
- Background-queue census (`DispatchQueue.global`) — **zero** hits; concurrency surface is @MainActor + one documented `Task.detached(.utility)` (import text analysis) + timer/Task hops.
- Timer lifecycle census — all `Timer` creation sites identified and adjudicated (see F-02, F-07).
- Custom-Decodable census — exactly one `init(from decoder:)` in the app target (`ThermalStateEvent`, the Stage-1 fix); all other model Codable conformance is compiler-synthesized (basis of F-04).
- Test-target membership verified in `project.pbxproj`: `Reading TrackerTests` is a `PBXFileSystemSynchronizedRootGroup` attached to the tests target — `ReliabilityTests.swift` and `WeatherTests.swift` compile into the executing target by folder membership. Build settings confirmed: Swift 5 language mode, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`, approachable concurrency enabled.

**Tier C — architecture-level assessment (unwired/dormant systems):**
Environment Engine cluster, Spatial Library cluster, Progressive Filtering types, Import Intelligence layer, BehaviorContextEngine Phase-2 append. These are unreachable from the running app today (verified by reference search); defects found inside them are logged at dormant severity because their activation is planned work (Part 12).

---

## 2. Executive summary

- **The remediation pass holds.** All ten Stage-1 compile fixes, all Stage-2 behavioral fixes, the Stage-3 observer/calendar/truth fixes, and all four Stage-4 discoveries were re-verified in live code this audit. Zero regressions of prior work were found.
- **7 new confirmed defects** are logged (F-01…F-07 below), of which one is High severity and was missed by the previous audit entirely (force-unwrapped Calendar math in the Annual Reports path).
- **Two documentation-status defects** were found: the most important being that the fix-log's O-3 entry ("New-Year feature unwired / latent") is **factually stale** — the feature is wired into the live window root, which promotes audit-old §8.1's orphaned-timer-chain defect from latent to live-code (F-02).
- **One systemic risk theme** emerges: schema evolution. The persistence models have grown v3/v4 fields whose decode requirements are stricter than the initializer defaults suggest, and the `SchemaVersion` machinery exists but runs nothing (F-04).
- Testing posture: the suite executes (28 passing per close-out record; not re-executed in this audit — see §7 caveat) and correctly pins last session's behavioral fixes; three prescribed regression areas remain unpinned (§7.2).

---

## 3. Verified-stable register (re-confirmed this audit)

Future sessions may rely on these without re-investigating:

| Prior ref | Fix | Verified state |
|---|---|---|
| §1.2 / D1 | Persistence health banner | `persistenceHealth` published; degraded set in every former silent-catch site incl. directory-creation failure; rendered by persistent bottom overlay in `ContentView`; healthy restored on any successful save |
| §2.1 | Multi-delete identity capture | `deleteItems` captures `Set<UUID>` before mutation |
| §2.2 | Toast FIFO queue | `pendingToasts` queue + incremental `markAchievementToastShown(id:)` consumption |
| §2.3 | Ghost-hover guard | `dataStore.book(id:) != nil` inside delayed work item |
| §3.1 | Debounce through tracking | `RunLoop.main.add(timer, forMode: .common)` |
| §3.3 | Unrepairable gate | `hasUnrepairableErrors` branches before auto-save; source file left untouched (also pinned by test) |
| §4.1 | Observer leak (screen-lock pair) | Token properties + idempotence guard + explicit teardown in `stopMonitoring()`; pinned by ten-cycle abuse test |
| §4.4 | Deinit resurrection | Empty documented `deinit`; ownership contract at type |
| O-7 | Registry dispatch_once self-wait | `registerAll(into:)` / `registerOne(_:into:)`; init passes `self`; no global access inside its own initialization |
| §4.2 | Weather store retry duplication | `BEGIN IMMEDIATE` → DELETE-by-session → INSERT → COMMIT, rollback-on-failure via defer |
| §5.1 (partial) | Calendar force-unwraps | All 13 previously enumerated sites guarded with documented degradation (`AnalyticsEngine`, `ReadingGoalManager2`) |
| §3.4-disproven | `timeOfDayAnalysis` max/min force-unwraps | Correctly untouched — dictionary seeded with all four `ReadingWindow` keys, never shrunk |
| §1.1 (comment) | False integration claim | Truthful STATUS CORRECTION comments in place |

---

## 4. New findings — OPEN

### F-01 · 🔴 Critical · High confidence — Missed §5.1-class crash: force-unwrapped failable Calendar construction in Annual Reports — ✅ **FIXED (Phase 1)**
- **File:** `Features/Reports/AnnualReportData2.swift`, function `analyticsPeriod(for:)` (~lines 35–37)
- **Mechanism:** `let start = Calendar.current.date(from: comps)!` and `let end = Calendar.current.date(from: comps)! - 1`. `Calendar.current` reflects the user's region calendar setting; `date(from:)` is documented-fallible. This is the exact defect class fixed at 13 other sites last session — these two sites were outside the enumeration scope of that sweep (it covered only `AnalyticsEngine` + `ReadingGoalManager2`) and were never audited.
- **Aggravating evidence:** the **same file** contains the correct pattern — `daysInCalendarYear(_:)` uses `guard let … else { return 365 }` twice. The hardening convention was known and applied in-file, just not here.
- **Trigger:** non-Gregorian user calendar (Japanese/Hebrew/Buddhist/Islamic are legitimate macOS settings) opening the Annual Reports archive or generating any year report. Callers: `sessions(in:year:)`, `booksCompleted(in:year:)`, `AnnualReportGenerator.generate` → takes down the reports sheet, and potentially more depending on where the throw-up propagates.
- **Fix shape:** guard both constructions with the file-local degradation convention (e.g., fall back to `DateInterval` computed from `startOfYear(for:)` arithmetic, mirroring `daysInCalendarYear`'s fallback style). Parameterized-Calendar unit test should cover `analyticsPeriod(for:)` when the §7.2 matrix test is authored.

### F-02 · 🟠 High · High confidence — New-Year celebration is WIRED; the orphaned-timer-chain defect (old §8.1) is therefore LIVE, contradicting the "latent/unwired" log — ✅ **FIXED (Phase 1)**
- **Files:** `ReadingTrackerApp 2.swift` (`.newYearTransitionAware()` on WindowGroup root) · `Features/Reports/NewYearTransitionMonitor.swift` (`NewYearCelebrationOverlay.startCelebration()`, `spawnParticles()`, `cleanup()`)
- **Status-defect component:** fix-log O-3 records the celebration chain as *"Latent (feature unwired). Fix before Part 12 wiring."* That premise is false today: the modifier is applied to the app's root content view, so the monitor runs whenever the app runs around midnight Dec 31→Jan 1. Per the protocol's own defect taxonomy, a doc/comment asserting the wrong wiring state is a defect in its own right.
- **Live defect component (unchanged from old §8.1, re-verified verbatim):**
  1. `startCelebration()` chains `Timer.scheduledTimer → Task { @MainActor } → assign next Timer → Task → …`. `cleanup()` (`.onDisappear`) invalidates only the references *at the instant it runs*; dismissal landing in the hop-window between a timer firing and the Task assigning its successor leaves the successor un-invalidatable — the phase sequence continues (including spawning the repeating 0.3 s `particleTimer` and calling `onComplete`) against a dismissed view.
  2. `spawnParticles()` assigns `particleTimer` without invalidating any pre-existing one (every other timer-starter in the codebase invalidates-first) — if the orphaned-chain path ever causes double-spawn, the first repeating timer becomes permanently unreachable.
- **Additional observations (same subsystem):** tapping during `.exiting` re-runs `beginExit()` (shared view branch for `.fullscreen/.exiting`), scheduling multiple `onComplete()` invocations; benign today (idempotent consumer) but worth hardening in the same pass.
- **Fix shape:** single cancellation token (or one structured-concurrency `Task` driving the phase timeline) such that one `cleanup()` stops the whole sequence in any phase; invalidate-before-reassign in `spawnParticles()`; guard `beginExit()` against re-entry. This is the prescribed prerequisite before any further Part-12 wiring, now urgent-adjacent because the feature is reachable.

### F-03 · 🟠 High · High confidence — Numeric HTML entities destroyed before decoding: corrupted extracted text and skewed word-count/difficulty metrics — ✅ **FIXED (Phase 1)**
- **File:** `Core/SharedTextUtilities.swift`, `decodeHTMLEntities(_:)`
- **Mechanism:** the function performs `result.replacingOccurrences(of: "&#(\\d+);", with: "$1", options: .regularExpression)` — i.e., regex-matches `&#160;` and replaces it with the captured group **as literal text**, converting the entity to bare digits (`&#160;` → `160`, `&#8217;` → `8217`). The subsequent `decodeNumericEntities(_:)` pass — which would have decoded them correctly — then finds no entity patterns left to match. Net effect: every numeric character reference in EPUB/PDF-extracted text renders as garbage digits instead of its character.
- **Impact surface:** `stripHTML` is used by `EPUBReaderScreen` (displayed text), `DifficultyAnalyzer` input (difficulty profile skew), `InsightEngine` corpus analysis, and `wordCount` (inflated counts — each entity contributes a bogus whitespace-delimited token). Numeric refs are extremely common in real-world EPUBs (curly quotes, dashes, non-breaking spaces).
- **Fix shape:** delete the pre-strip replacement entirely (the dedicated `decodeNumericEntities` pass already implements correct decimal+hex decoding); add unit fixtures `&#160;`→space, `&#8217;`→', `&#x2014;`→—.

### F-04 · 🟠 High · High confidence (mechanism) — Schema evolution gap: synthesized `Decodable` makes defaulted fields mandatory; `library-state.json` corruption/legacy path resets goals & achievements with NO backup — ✅ **FIXED (Phase 1)**
- **Files:** `Core/Book2.swift` (`Book`, `LibraryState`) · `Core/DataStore3.swift` (`loadBooks()`, `loadLibraryState()`)
- **Mechanism, part 1:** the custom-decoder census shows exactly one hand-written `init(from:)` in the app (`ThermalStateEvent`). Everything else is compiler-synthesized, and synthesized Decodable does **not** consult initializer defaults. Therefore persisted JSON must contain every non-optional field ever added: `genre`, `notes`, `isFavorite`, `collectionIDs` (Book v3/v4 additions) and `collections` (LibraryState v4). A `library.json`/`library-state.json` written by any pre-v3/v4 build fails to decode outright.
- **Consequences differ sharply by file:**
  - Books path: decode failure → `backupCorruptFile` creates `.bak` + empty library + degraded banner. Lossy but recoverable and surfaced.
  - **State path:** `loadLibraryState()` catch resets to fresh `LibraryState()` with a degraded banner, but performs **no backup**, and the next `saveLibraryState()` atomically overwrites the file — permanently destroying the user's goals, deadlines, and earned-achievement history. Triggered not only by corruption but by *any* upgrade across the v3/v4 boundary.
- **Mechanism, part 2:** `SchemaVersion` exists (`.v1/.v2/.v3`, written into `LibraryState`), but no migration code runs anywhere — `loadLibraryState()` never inspects `schemaVersion`, and `.current` was never bumped when the v4-era fields shipped. The migration infrastructure is decorative.
- **Fix shape (two independent Finality gates):** (a) back up `library-state.json` before reset, mirroring `backupCorruptFile` semantics; (b) either adopt custom decoding with `decodeIfPresent` defaults for evolved models (recommended — makes all historical files readable forever), or implement actual `schemaVersion` migrations. Until then, treat cross-version upgrades as a known data-loss window.

### F-05 · 🟡 Medium · High confidence (mechanism; conditional trigger) — LocationProvider continuation overwrite leaks concurrent requests forever — ✅ **FIXED (Phase 1)**
- **File:** `Features/Environment/Weather/WeatherKitService2.swift`, `LocationProvider.fetchOneTimeLocation()` + delegate callbacks
- **Mechanism:** `fetchOneTimeLocation` stores its `CheckedContinuation` in a single property. A second overlapping request overwrites the stored continuation; the first caller's continuation is never resumed — the awaiting task hangs permanently (leaked task, no crash, no error). Delegate failure/success paths only resume whatever is currently stored.
- **Trigger:** two overlapping `currentLocation()` resolves (e.g., session-end weather capture racing a forecast fetch; router currently awaits sequentially, so today's live call-graph makes this rare — but the API contract permits it and Part-12 wiring expands callers).
- **Fix shape:** continuation queue/array keyed per request, or serialize access behind an async semaphore; resume-and-nil exactly once per stored continuation.

### F-06 · 🟡 Medium (dormant path) · High confidence — BehaviorContextEngine Phase-2 fatigue analyzer's primary signal is near-tautological — ✅ **FIXED (Phase 2)**
- **File:** `Features/BehaviorContext/BehaviorContextEngine2.swift`, `FatigueIndicatorAnalyzer.analyze(gaps:)` ("increasingGaps" branch)
- **Mechanism:** gaps are sorted **by duration ascending**, then the code counts consecutive `sorted[i] > sorted[i-1]` steps. In a duration-sorted array nearly every adjacent pair satisfies this, so ≥3 distinct-duration gaps almost guarantee the "increasing gaps" fatigue signal regardless of chronological reality. Additionally every emitted signal is stamped `date: Date()` rather than any gap-associated date.
- **Reachability today:** none — `analyzeWithIntelligence(input:)` (the only path into `RoutinePipeline` → `FatigueIndicatorAnalyzer`) has zero callers. Logged now because the Phase-2 append is explicitly staged for future activation and this analyzer's output would otherwise be trusted.
- **Fix shape:** sort chronologically (gap start/end) before run-counting; derive dates from gap boundaries; add fixtures with interleaved short/long gaps proving chronological discrimination.

### F-07 · 🟡 Medium · Medium confidence — Combine observer registrations lack the idempotence guard; two launch-time `startMonitoring()` call sites can double-register workspace/power observers for process lifetime — ✅ **FIXED (Phase 1)**
- **File:** `Features/BehaviorContext/BehavioralCategory.swift` (`observeApplicationLifecycle`, `observeWorkspaceActivity`, `observeSystemPowerEvents`, `startInactivityMonitoring`) + `ReadingTrackerApp 2.swift`
- **Mechanism:** last session's idempotence guard protects only the distributed-notification pair. The four Combine-based registration paths append sinks unconditionally, and `stopMonitoring()` clears them — so stop/start cycles are balanced. But the app has two independent startup invocations of `startMonitoring()` (the root `.task` pipeline binding **and** the initial `scenePhase → .active` change): if both fire before any stop, workspace/power sinks exist twice for process lifetime, duplicating every application activate/deactivate/launch/terminate/sleep/wake evidence record (two `ApplicationUsageSession`s per real foreground stint → skews `BehaviorEvidenceBuilder` aggregates feeding the context engine).
- **Why Medium confidence:** the double-fire at launch depends on SwiftUI delivering both the initial `.task` and the first `scenePhase` change on macOS, which is version-dependent; the *missing guard itself* is certain, the duplicate-registration consequence follows deterministically whenever double-invocation occurs.
- **Fix shape:** extend the existing re-entry pattern — either guard all five registration paths behind a `isMonitoring` flag, or make `startMonitoring()` itself idempotent (early-return when active). Cheap, matches the precedent inside the same file.

---

## 5. Lower-severity findings — OPEN

### F-08 · 🟢 Low · High confidence — `weekGoalStreak` achievement can never be earned
`AchievementKind.weekGoalStreak` ("Goal Week") is defined and registered in `AchievementDefinition.all`, but no code path awards it (`award(` census: zero matching sites; `detectGoalAchievements` covers only `annualGoalMet` + `firstDailyGoal`). Users can see an unearnable badge slot. Fix shape: implement detection (7 consecutive days meeting daily goal — note this needs daily-goal-meeting day history, which is derivable from `dailyActivity` + goalSet) or remove the definition.

### F-09 · 🟢 Low · High confidence — Divergent `stripHTML`/`wordCount` implementations; canonical-file header misstates its callers
`BookImporter` defines private `stripHTML`/`wordCount(fromHTML:)` (5 named entities, no numeric decoding, no paragraph preservation) instead of using `SharedTextUtilities` — whose header declares itself canonical, "do not copy-paste," and lists `BookImporter` as a caller. Result: import-time word counts/page estimates and difficulty sampling use different entity handling than reader-time extraction and InsightEngine corpus analysis (compounded by F-03 affecting only the shared implementation). Fix shape: point BookImporter at the shared functions after F-03 is fixed; correct the header.

### F-10 · 🟢 Low · High confidence — `AudioProfileStore.persist` failures are print()-only
`Features/Audio/AudioTrackerMetadata2.swift`: save failures log to console and return; no user-visible surface, unlike `DataStore`'s post-D1 treatment. Secondary data, hence Low — but it is the same silent-loss class D1 was invented for. Fix shape: reuse the `PersistenceStatus` pattern or accept-and-document the downgrade explicitly.

### F-11 · 🟢 Low · High confidence — Validator cosmetic/log defects
`DataIntegrityValidator.swift`: Rule S-3 declares unused `tmp` and logs "swapped" while actually clamping (`endPage = startPage`); Rule S-1 checks a condition that cannot exist (`!isActive && endTime == nil`, since `isActive ≡ endTime == nil`) — dead rule that can never fire. No functional harm; misleading repair reports cost future debugging time. Fix shape: correct message, remove dead variable, delete or repurpose S-1.

### F-12 · 🟢 Low · Medium confidence — Rebindable pipelines accumulate subscriptions on repeated root `.task`
`GoalProgressViewModel.bind(to:)` and `SessionEventRouter.bind(to:)` append sinks without cancelling prior ones. Closing/reopening the app window re-runs root `.task`, adding another sink each cycle. Router-side duplication of cascades is self-suppressing (diff-set consumed by first sink), so effect is redundant refresh work and slow growth, not duplicated notifications. Fix shape: cancel-on-rebind (`cancellables.removeAll()` at top of `bind`) — one line each, but requires its own Finality pass.

### F-13 · 🟢 Low · High confidence — Dead/misleading fragments noted for hygiene (bundle)
(a) `EstimationEngine.buildSpeedModel` computes `totalWeight` never used; instance-level `clamp(_:min:max:)` appears unused; `mapConfidence` appears uncalled (grep-verified within engine). (b) `DataMaturityEngine`'s expiry `ClaimRule` reads wall-clock `Date()` instead of the injected `referenceDate` — breaks deterministic testing of the expiry decision. (c) `WeatherSnapshotStore.openDatabase` ignores `sqlite3_open` failure — subsequent operations fail with generic `StoreError` (degradation works, diagnosis doesn't). (d) `InactivityGapRecord.precededSession/followedSession` names are inverted relative to their semantics (comments admit it) — rename candidate for a dormant-path pass.

---

## 6. Status-correction register (documentation vs reality)

| Claim living in the repo/logs | Reality (verified) | Disposition |
|---|---|---|
| fix-log O-3: NY celebration "feature unwired," latent | Wired at app root via `.newYearTransitionAware()`; §8.1 defect live (F-02) | Corrected by this audit; treat O-3 as OPEN-live |
| fix-log header: "16/16 pass" | Close-out stages record 27/27, handoff says 28 (16 weather + 12 reliability = 28) | Header drift; update when logs are next touched |
| `SharedTextUtilities` header lists BookImporter as caller of canonical stripHTML | BookImporter shadows with a local divergent copy (F-09) | Corrected by this audit |
| Old AUDIT_REPORT §8.1 severity "High (once wired)" | Now wired → effective severity High-live (F-02) | Promoted by this audit |

---

## 7. Testing posture (TESTING_STRATEGY.md applied)

### 7.1 What exists and is trusted
- Step-zero satisfied historically: tests target is a synchronized group containing real suites; `ReliabilityTests` maps 1:1 onto the strategy's risk table (validator ×5, persistence ×4, mutation ×2, observer lifecycle ×1) and every test names its defect class.
- `WeatherTests` carries the converted normaliser/store/engine-integration suites, including the idempotent-save pin for F-history §4.2.
- **Caveat recorded honestly:** this audit did not re-execute the suite (out of scope per session direction). "28 passing" is carried from the close-out record; the first action of any future fix session should remain the protocol's baseline build/test before touching code.

### 7.2 Remaining coverage gaps, priority order (per the strategy's own mapping, updated for current findings)
1. **Non-Gregorian Calendar parameterized matrix** — now doubly motivated: pins the 13 fixed sites AND F-01 (`analyticsPeriod(for:)`). Highest-value missing test in the repo.
2. **Achievement-toast FIFO concurrency pin** (§2.2 fix has no test; the fix is live and subtle).
3. **Numeric-entity decoding fixtures** (F-03) — trivial to write, prevents recurrence.
4. **Persistence-banner Release-surfacing** is pinned indirectly (health enum) but no UI-layer assertion exists; acceptable to defer until UI tests exist.
5. **NY-celebration chain under a controllable scheduler** — blocked behind F-02's redesign (test the cancellation token, not real timers).
6. Post-fix pins for F-04 (legacy-JSON decode acceptance) once decoding strategy is decided.

---

## 8. Unwired / dormant systems inventory (Part-12 planning input)

Verified-by-reference-search as unreachable from the running app today:

| System | Location | State |
|---|---|---|
| Environment Engine + stars/weather visuals | `Features/Environment/**` (engine, background view, star field, shooting stars) | Complete, self-consistent; truthful "NOT wired" headers; shared-engine start/stop refcount risk (old §8.2) still applies to future wiring design |
| Spatial Library (three-tier adaptive layout) | `Features/Library/Spatial/**` | Complete, unwired |
| Progressive Filtering types | `Book.series/isFavorite/collectionIDs`, `LibraryState.collections`, `LibraryFilter*` | Model layer shipped (and is the F-04 exposure); filter UI unwired |
| Import Intelligence layer | `BookImporter.swift` appended module (`ImportIntelligenceFacade` et al.) | ~250 lines, zero callers confirmed this audit — decide surface-or-delete at wiring time |
| BehaviorContextEngine Phase-2 | `analyzeWithIntelligence` + pipelines/adapters | Gated end-to-end but uncalled; contains F-06 and assorted rough edges (empty routines passed to quality scorer; synthetic evidence bridging in NarrativePipeline) — schedule a hardening pass BEFORE activation |
| BehavioralCategory support infrastructure | actors, replay controllers, pagination, indexes, debouncer, clocks, registries | Speculative scaffolding, mostly zero callers; harmless but inflates maintenance surface — inventory before Part 12 |

---

## 9. Carried-forward open items (revalidated)

| Ref | Item | Current disposition |
|---|---|---|
| O-3 | NY timer-chain redesign | **Promoted**: feature is wired (F-02). Do before/with any further wiring work. |
| O-6 | Weather rows keyed by sessionID while normaliser discards linkage | Still a genuine design question; unchanged. Note `coverageRatio(for:)` sees only session-keyed rows. |
| O-8 batch | sync main-thread writes (JSON + now SQLite-on-main noted); `urls(...).first!` ×2 (now ×3 counting `WeatherSnapshotStore`); `turnToPage` weak-store divergence; duplicate-import silent no-op | All reconfirmed present and correctly left per confidence rules; batch when UI-feedback work happens |
| D6 | No archival/pruning for session & pageTimes history | Unchanged; interacts with main-thread writes; plan before multi-year-scale data |
| D7 | Hand-rolled SQLite surface | Now has running tests (post-§4.2) — materially improved from original D7 framing |

---

## 10. Recommended order for the next fix session

1. Baseline `xcodebuild build` + `xcodebuild test` (protocol step-zero; confirms 28-green before touching anything).
2. Commit protection for the working tree (reorg commit + fixes commit) — prerequisite hygiene recorded in the prior session analysis.
3. F-01 (Critical calendar crash — smallest blast radius, immediate user-facing class).
4. F-03 (entity destruction — small, high-leverage correctness fix + fixtures per §7.2.3).
5. F-02 (NY chain redesign + status correction; unlocks §7.2.5 test).
6. F-04 (state-file backup gate first — one Finality; decoding strategy decision second — larger, design-gated).
7. F-07 (idempotence extension — cheap, closes the evidence-duplication class).
8. F-05/F-06/F-08…F-13 in severity order as capacity allows.

---

## Appendix A — Severity/confidence totals

Confirmed new findings: **13** (1 Critical, 3 High incl. one promoted-from-latent, 3 Medium, 6 Low) + 4 documentation-status corrections + 1 systemic theme (schema evolution) folded into F-04.
Prior-work regressions found: **0**.

## Appendix B — Files fully read this audit (Tier A index)

`ReadingTrackerApp 2` · `NewContentView` · `Book2` · `DataStore3` · `DataIntegrityValidator` · `SharedTextUtilities` · `AnalyticsEngine` · `EstimationEngine` · `DataMaturityEngine` · `DataMaturityEngineAdapters` · `SessionCoordinator2` · `SessionEventRouter2` · `AchievementEngine2` · `ReadingGoalManager2` · `InsightEngine` · `IntelligentNotificationEngine` · `BehavioralCategory` · `BehaviorContextEngine2` · `BehaviorEvidenceBuilder` · `WeatherKitService2` · `AnnualReportData2` · `NewYearTransitionMonitor` · `AudioTrackerMetadata2` · `BookImporter` · `DeveloperConsoleRegistry` · `ReliabilityTests` · `project.pbxproj` (membership/settings sections)

*End of audit. This file supersedes AUDIT_REPORT.md / TECH_DEBT.md as the working defect register.*
