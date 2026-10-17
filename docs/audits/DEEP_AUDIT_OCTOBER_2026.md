# Reading Tracker — Deep Audit · October 17, 2026

**Audit ID:** RA-DEEP-20261017 · **Performer:** Deep-audit session (live machine, this folder)
**Scope:** every file, byte-level inventory, live build + full unit suite execution, git history, all 15 docs, graphify artifacts.
**Supersedes nothing** — this complements `CURRENT_AUDIT.md` (defect register) and `fix-log.md` (protocol log). A future session should merge its NEW-DE defect IDs into the register.

> **Path note (post-reorg):** this audit was written when registers sat at the repo root. After the
> same-day documentation reorganization they now live as: `docs/registers/CURRENT_AUDIT.md`,
> `docs/registers/fix-log.md`, `docs/registers/handoff.md`, `docs/history/{FINAL_TRACES.md, profilerfix.md,
> LAST_DEFEAT_demo_profiles.txt, freeze.txt, diagnostics-2026-08-26.txt}`, `docs/tree.md`.
> Read any bare root-level doc reference below as its `docs/…` equivalent.

---

## 0. TL;DR — the 60-second version

The project is in the **best shape it has ever been**, and it is provably green *today*: it builds clean (exit 0) and the entire unit test suite passes (TEST SUCCEEDED), verified live during this audit — not inherited from a log. LOC claims are now validated by direct counting: **100 app files / 39900 raw LOC (~28.7k of real code), 18 test files / 2,763 LOC / 108 tests**, plus 2 UI-test stub files.

Outstanding reality: one **critical uncommitted fix** (the one-line `.environmentObject(dataStore)` that killed the Winter-Romantic freeze) is still only in your working tree since Sep 2 — commit it first. Beyond that, the app's remaining story is: (1) the giant-JSON monolith and main-thread re-analysis pattern still set hard limits on how big a library can get, (2) the Behavior Context Engine is **81% dead scaffolding** whose activation gates were finally diagnosed precisely (answer to your open BCE question is below), (3) release readiness has four concrete blockers (empty AppIcon, missing WeatherKit entitlement, a build-setting/entitlement conflict, and an empty `CFBundleIdentifier` key), (4) a handful of new defects found for the first time this audit (worst: a real bug where the Explore/spatial cards can never show real covers, and a weakened disk-write ordering guarantee).

Everything below is written twice: **plain-English** then **technical**, per the house style.

---

## 1. What this project is

**Layman:** A macOS reading-tracker app — you import PDF/EPUB books, read them inside the app, and it remembers everything: how fast you read each page, what time of day you read, what the weather was like, what app you were in before opening the book. It draws a night-sky background that tracks real time of day and weather, gives goals, streaks, 25 achievement badges, yearly review slides, and a speed-reading (RSVP) mode. It even has a slow-learning "context brain" that tries to reconstruct *where and why* you read. There's a hidden Developer Console (⌘⇧D) for stress-testing with 16 fake reader personalities, and a "Sentinel" — a safety watchdog that scans for data problems at launch, auto-repairs provably-safe ones, backs up everything before touching anything, and reports while you were away.

**Technical:** A Swift/SwiftUI AppKit-macOS app (Xcode project, 3 targets, one SPM dependency: ZIPFoundation 0.9.20), built to macOS deployment target **26.5**, in **Swift 5 mode** with **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** and `SWIFT_APPROACHABLE_CONCURRENCY = YES` (this default-isolation setting is the project's defining — and historically most destructive — build configuration; it caused the "background work secretly runs on main" freeze class). Persistence is hand-rolled: a debounced, pretty-printed **single JSON monolith** (`library.json` — every book, session, and individual page-turn timing), plus `library-state.json` (goals/achievements/collections), a keyed-arc **SQLite** weather snapshot store, a content-addressed **cover file store** with NSCache, a 10-deep hash-gated **backup rotation**, an exportable/importable `.readingarchive` format (v1), and an append-only **JSONL Sentinel journal** (500-line rotation). Analytics run as pure static-namespace engines; a memoization layer (`AnalyticsCache`) gates five whole-library reductions behind a mutation-epoch counter; `PersistenceWriter` owns disk writes on a serial utility queue.

**How it was built:** per the README — ~30 focused working sessions across 4 months (Jun 17 – Aug 26, 2026), governed by the project's fix protocol (every fix = Finality + fix-log entry + pinned regression test). That disciplined culture is the reason this codebase now has a defect register with a documented fix history few indies could match.

---

## 2. Method & verification performed THIS audit (nothing inherited)

| Check | Result |
|---|---|
| `xcodebuild build` (Debug, macOS, fresh DerivedData) | **BUILD SUCCEEDED, exit 0** (today, working tree incl. Sep-2 fix) |
| `xcodebuild test` (unit target, full run) | **TEST SUCCEEDED** — all suites green, fresh run today |
| Full recursive file scan | 120 `.swift` + 185 json + 15 md + config/asset files + 1 PDF |
| LOC validation | Direct `wc -l` on every file (numbers below, not copied from docs) |
| Deep reads | 4 parallel audit agents; Core+Engines (6,790 LOC) and BHE cluster (21 files, 13,183 LOC) read 100%; feature/UI layer ~13.3k LOC read + 8.5k skimmed; tests/console/config read 100% |
| Git forensics | 45 commits inspected; working-tree diff; artifact provenance (`freeze.txt` = 5-second `sample` capture of the freeze, Sep 2 2026) |
| Docs | All 15 `.md` + PDF read; cross-checked against code for truth-drift |

Verification commands used (reproducible):

```
xcodebuild build -project "Reading Tracker.xcodeproj" -scheme "Reading Tracker" -configuration Debug -destination 'platform=macOS'
xcodebuild test  ... -only-testing:"Reading TrackerTests"
```

---

## 3. Where we are project-wise (the honest scoreboard)

**Layman:** The app works, looks good, has been through repeated crash-bug exorcisms, and today proves it. About 90% of the original 4-phase remediation roadmap is done, plus all five "next-level" features, plus the Sentinel, plus a big performance-upgrade pass. What remains is: a long-tail of small-but-real defects (new list below), one architect-scale upgrade deliberately postponed (getting off the giant JSON file), the sleeping 81% of the context engine, and App Store formalities you've never attempted (icons, entitlements, privacy polish).

**Technical, by track:**

| Track | Status |
|---|---|
| RA-002 remediation (4 phases) | ✅ all 4 phases executed, suite green at every boundary (fix-log §RA-002) |
| P5 five production features | ✅ shipped (weather-evidentiary, covers+HUD, RSVP, onboarding+search/sort, archive durability); SQLite engine attempted → honestly reverted (§P5-G post-mortem is the blueprint) |
| P6 Sentinel | ✅ shipped with security doctrine S1–S7, 6 security/behavior pins |
| F-01…F-13 (legacy register) | ✅ all fixed & pinned except F-10-discipline items absorbed; F-13(d) rename still open (dormant path) |
| NA-1…NA-9 | ✅ resolved (W-01/W-02/W-03 reopened & closed; goals shipped via Settings ⌘,; privacy manifest + apple-events entitlement exist) — with the **W-01 caveat**: fixed at aggregate confidence level; per-correlation `dataCoverageScore` still hardcodes 1.0 (WeatherAnalysisEngine.swift:1412) |
| P6-HOTFIX series (demo freeze) | ⚠️ Two strong fixes committed (async install + nonisolated synthesis); the *actual final* root cause (missing `environmentObject` on the console window) is **fixed in the working tree but UNCOMMITTED since Sep 2** |
| P7 UI review | ✅ executed; `UI REVIEW.rtf` deleted in working tree (uncommitted deletion) |
| FINAL TRACES marathon | ✅ A (covers→files), B (AnalyticsCache), #4-safe-slice (PersistenceWriter) done; C/D/E blueprints written but not executed |
| Open from handoff | SQLite retry (session-sized), BCE V3 UI activation, CloudKit (deferred), LT-10/11/12 polish |
| **This audit's flags** | 13 new defect-class items (§7) incl. 1 live UI bug (spatial covers), 1 durability regression (write-ordering), 4 release blockers |

**Milestones timeline:** Jun 17 first commit → Jun weather/discovery → Jul debugging eras + house protocol written (Jul 21) → Aug 23–26 the big remediation/feature/sentinel marathon (24 of 45 commits on Aug 26 alone) → Aug 30 freeze sample captured (`freeze.txt`) → Sep 2 one-line fix found via that sample (`profilerfix.md`) → **Sep 2–Oct 17: dormant (no commits; fix never committed).**

---

## 4. The numbers (all directly validated today)

| Metric | Value | Validated how |
|---|---|---|
| Swift files | 120 total = 100 app + 18 tests + 2 UITests | `find` |
| App raw LOC | **39,900** (28,697 code / 5,869 comment / 5,334 blank) | `awk` count |
| Test LOC | **2,763** (unit) + 71 (UI stubs) | `wc -l` |
| Test functions | **108** `@Test` (~160+ executed, incl. 16× persona parameterization, 6×6×2 calendar matrix) | grep |
| Top-level types | 286 (classes/structs/enums/actors/protocols) | grep census |
| Largest files | BehaviorContextEngine2 5,252 · BehavioralCategory 3,187 · WeatherAnalysisEngine 1,499 · MusicalAnalysisEngine 1,404 · PredictiveRecommendationEngine 1,235 · AnnualReportView 1,196 · DataMaturityEngine 1,168 | `wc -l` |
| Commits | 45 (Jun 17 – Aug 26); repo 11 MB | git log |
| Folder size | 43 MB = 30 MB graphify-out (69%!) + 11 MB .git + ~1.8 MB sources + ~0.9 MB docs/arts | `du` |
| Docs corpus | ~30,192 words / 15 md files + 9-page PDF audit + 222 KB freeze trace | `wc -w` |
| Dependencies | exactly 1: ZIPFoundation 0.9.20 (pinned, Package.resolved committed) | SPM resolve |
| Toolchain | Xcode 27.1 (27A9275) · macOS 26.6.1 host · deployment target **macOS 26.5** | xcodebuild -version, pbxproj |
| Achievement kinds | 25 | AchievementEngine2 census |
| Developer personas | 16 deterministic (SplitMix64-seeded) | DemoProfileCatalog |

> Historical claim check: tree.md's Aug-26 numbers (92 app files / ~27,489 nb-LOC) were accurate then; the file has since grown by 8 files / ~1.2k LOC (Sentinel + traces work). README's old "36k LOC" caveat was true at Jul 15; you are now at ~40k raw / ~28.7k effective.

---

## 5. Strengths (verified, not flattery)

**Layman:** This app has a spine. It survived three crash hunts, a freeze apocalypse, and months of heavy churn and came out *more* organized than most human-built indie apps. The safety nets it has, it earned with tests.

**Technical:**
1. **Protocol-driven traceability.** Every historical fix is (a) implemented, (b) Finality-verified, (c) logged, and (d) pinned by a named regression test. The test suite reads like a defect history: `TextExtractionTests` ↔ F-03, `NonGregorianCalendarTests` ↔ F-01, `CelebrationTimelineTests` ↔ F-02, `FatigueAnalyzerTests` ↔ F-06, `SentinelPinsTests` ↔ S1/S5 security doctrine.
2. **Data-loss defenses stack.** corrupt-JSON → `.bak` + reset + degraded banner; unrepairable validator output blocks auto-save; corrupt state file gets backed up before reset (pinned); 10-deep content-hash-gated backups; export/import round-trip pinned; Sentinel pre-repair snapshot; kill switch pinned inert.
3. **Honest documentation culture.** The repo contains a documented *failed* attempt (SQLite revert), a "LAST DEFEAT" knowledge-transfer doc written in defeat, and status-correction registers — anti-machiavellian docs that any future session can trust. (Drift density is low: only 3 stale-doc items found this audit.)
4. **Correct use of the hard concurrency settings.** The nonisolated-stamp discipline on the demo-generation path (post-HOTFIX-v2) plus the compile-enforced lesson means the freeze class is now build-breaking, not behavior-breaking.
5. **Genuine architecture in places.** `EPUBPackage` (nonisolated, exactly-once cleanup across every cancel/failure path) is the best-engineered file in the repo. `DataMaturityEngine` is a real, domain-agnostic evidence-gating design with injected clocks (expiry rule now uses `referenceDate` — verified). EstimationEngine's weighted-blend + validate() clamping is clean.
6. **Deterministic test fixtures** everywhere that matters (seeded personas, injected calendars/clocks/dates, injected sleeper for timer races, temp-dir store isolation).
7. **Submission-adjacent basics already exist** that most indies forget: `PrivacyInfo.xcprivacy` (CA92.1 + C617.1 + declared coarse location), usage strings, apple-events entitlement, sandbox on, ATS-clean (https-only network).

---

## 6. Weaknesses (verified)

**Layman:** The two big structural weak spots are the same family: the app keeps *everything* — every page-flip record forever, in one text file — and the app re-does big math on the screen-drawing thread more often than it should (mostly it got better; a few paths still do it). Bigger-picture: a lot of the code you paid for is sleeping ornament (the context engine is 4/5 dead scaffolding; a whole legacy library screen is dead; half the import "intelligence" is computed then thrown away). And nothing Apple-Store-shaped (icon, WeatherKit permission, scheme hygiene) has ever been touched.

**Technical:**
1. **Monolith persistence grows with lifetime usage, unpruned.** `library.json` = every `Book` → every `ReadingSession` → every `PageTiming`, pretty-printed, re-encoded **whole** on each debounced mutation. Sessions/pageTimes have **zero pruning** in the entire repo. At your own persona scale (185k timings) encode is already 1–3 s. A multi-year real user (est. 1–10M timing records) → **~250 MB–5 GB single JSON**, launch decode + validate on main, per-page-turn full-array `updateBook` + eventual whole-file rewrites, `saveImmediately()` blocking main for entire writes, backups 10× the whole file. Every one of these numbers scales linearly with total pages turned, forever.
2. **Reaction-wave on main.** Post-session cascade runs `BehaviorContextEngine.analyze()` synchronously on the MainActor (O(sessions×evidence), rebuilt from scratch, never cached or persisted) on **every session close** — fine today, a stall at 10× volume. Weather panel joins are O(sessions×snapshots) inline on main. `currentBestEffort` does a synchronous SQLite read on main every 45 s (EnvironmentEngine loop).
3. **Dormant-code overhang.** BCE 1–945 lines live / ~4,270 lines (81%) dead scaffold; BehavioralCategory ~60% dead (24 zero-caller types incl. an orphaned `BehavioralClock` abstraction while production reads wall-clock `Date()`); `LibraryView.swift` (243 LOC) fully dead; `SessionCoordinator.restoreSession` zero callers; import-facade analysis/suggestions halves computed-then-discarded; `WeatherContextAdapter`/`EnvironmentalSessionAssembler`/historical+forecast fetches zero callers; `AnalyticsCache.perBookSpeed` zero callers **and buggy if ever called** (validates against an always-empty signature). Estimate: **~5.5–6.5k LOC (~15%) of the app target is unreachable.**
4. **Write-ordering weakened by the FINAL-TRACES #4 slice.** `PersistenceWriter.enqueue` resumes each job from the gate then runs encode+write on the *concurrent* cooperative pool — a slow encode can be overtaken by a fast later write ⇒ stale snapshot can land last. `saveImmediately` drains only jobs that already reached the gate. (See NEW-DE-1.)
5. **Test-belt scope.** Excellent pin density (40%-axis: ~0.9) but narrow architecture coverage: discovery network stack (the only Release-reachable network code), all view flows, session pipeline, readers, notifications = zero tests; UI target = 3 template stubs; one vacuous assertion (AnalyticsCache zero-epoch's stub returns nil); two tests side-effect into the real `CoverStore.shared`; archive round-trip assertions `#if DEBUG`-gated (vacuous in Release); no shared scheme / no test plan / no coverage → CI not reproducible.
6. **Release-formalities untouched.** Empty AppIcon set; no WeatherKit entitlement despite live WeatherKit use; `ENABLE_USER_SELECTED_FILES=readonly` build setting vs read-write entitlements file; empty-string `CFBundleIdentifier` key in the custom plist; macOS 26.5-only deployment target (cuts current macOS users out); " 2"-suffixed filenames (`ReadingTrackerApp 2.swift`) shipped in a synchronized folder that auto-includes strays.
7. **Git hygiene.** Last commit Aug 26; the Sep-2 freezer fix + README rewrite + artifact deletions sit uncommitted (44 days); `freeze.txt`/`profilerfix.md` untracked and unignored; diagnostic corpus (`diagnostics-2026-08-26.txt`, `LAST_DEFEAT…`) tracked in the repo; `.xcscheme` file absent.

---

## 7. NEW findings — this audit's defect register (not in any prior doc)

Severity: 🔴 crash/data-loss class · 🟠 corrupts guarantees · 🟡 observable defect · 🟢 hygiene.

### NEW-DE-1 · 🟠 High · PersistenceWriter does not actually serialize the heavy path
`PersistenceWriter.swift:33–47`: `enqueue` gates jobs through the serial queue *then* resumes each into unqueued decode/write work on the cooperative pool. Sequence: two debounced saves 0.5 s apart; save #1's 1–3 s encode is in flight when save #2's cheap write lands ⇒ **older snapshot can overwrite newer bytes on disk**. (`DataStore3.swift:75–76`'s "newest data always wins" and the header's "identical FIFO ordering contract" are no longer literally true.) Also `saveImmediately()` (DataStore3.swift:556–570) drains only already-gated jobs; a captured-but-ungated task can write after the flush; `pendingWrite` is set at enqueue time (631), not gate time.
**Fix shape:** have `enqueue` pre-encode the buffer synchronously on the caller (cheap value snapshot) and make the queue the *executor* (not the gate) of the actual `write(data:)`, or await the predecessor Task before writing. Re-pin with a rapid-mutation write-order test.

### NEW-DE-2 · 🟠 High · Explore/spatial cards can never show real covers (live UI bug)
`Spatial/BookCoverCardView.swift:46` reads `book.coverImageData` directly; import writes covers only to CoverStore (BookImporter:130/245) and the load-time migration nils the embedded field (DataStore3:464–472). The main sidebar uses the CoverStore-aware `book.coverImage` accessor (BookCoverSupport.swift:25–31); the spatial card does not ⇒ every migrated/explored card renders its placeholder gradient forever.
**Fix shape:** one-line — use `book.coverImage` (the encapsulating accessor the rest of the app uses). Pin with a store-migrated card test if cheap.

### NEW-DE-3 · 🟠 Medium · Crash-window time inflation (<24 h is Sentinel's blind spot)
A force-kill leaves a session persisted with `endTime == nil`; on next launch <24 h, `startSession`→`closeActiveSession` stamps `endTime = now` — the crash+idle gap silently becomes "reading time" (analogous LT-3b class on the *other* boundary). Only the >24 h Sentinel orphan rule repairs — and even then the repair records the full wall-clock duration (SentinelEngine.swift:293–297 doesn't clamp `duration`), inflating analytics by up to 24 h per orphan.
**Fix shape:** on load or on closeActiveSession, split duration at file-kill time (e.g., cap open-session duration at last PageTiming + a grace budget); Sentinel orphan repair should set end = last timing boundary, not "now".

### NEW-DE-4 · 🟡 Medium · AnalyticsCache goes stale across midnight
Signature (AnalyticsCache.swift:32–48) has no wall-clock component; `streak()`/trend buckets bake in "today" (AnalyticsEngine.swift:238–246, 550) → computed-at-23:59 values are served all next day until the next mutation.
**Fix shape:** fold `Calendar.current.startOfDay(for: .now)` into the signature (or a day-bucket prefix) — keeps hit-rate, kills the staleness.

### NEW-DE-5 · 🟡 Medium · Onboarding import bypasses Import Intelligence + goal clobber
`OnboardingView.importBook` (:207–211) calls neither the facade nor `addBook`'s duplicate return ⇒ first-run imports surface no warnings and silently swallow duplicates; `OnboardingView.commitGoal` (:220–226) **overwrites the entire `ReadingGoalSet`** with only the daily target — destroys any pre-set annual/weekly/deadline values (first-run only, but data-destroying).
**Fix shape:** route onboarding import through the same facade+`addBook` path as NewContentView (and merge, not replace, the goal set).

### NEW-DE-6 · 🟡 Medium · Uncancellable RSVP text extraction holds security scope + memory through dismissal
`PDFReaderScreen.loadRSVPText` (:401) — unassigned detached Task over the whole document; a huge PDF keeps extracting (and holding scope) after the sheet closes.
**Fix shape:** keep the Task, cancel on disappear, and pass a cancellation check inside the loop (pattern exists — extraction gained cancellation in P5-HOTFIX #3 for the reader path).

### NEW-DE-7 · 🟡 Medium · Weather silently posts to a wrong-location default
`LocationProvider.currentLocation` (WeatherKitService2:686–699) returns cached or a **NYC default** without surfacing denial; with location denied, weather columns silently describe a city you weren't in. Combine with: correlation↔snapshot join has no ±1 h window (WeatherInsightPanel2:334–337), so sparse coverage binds stale weather to old sessions.
**Fix shape:** surface "location unavailable — weather insights paused" state instead of defaulting; window the join (dead adapter's ±1 h logic at BCE:3407 is the reference).

### NEW-DE-8 · 🟡 Medium · W-01 residual: per-correlation coverage still a constant
`WeatherAnalysisEngine.calculateConfidence` (1412) still hardcodes `dataCoverageScore = 1.0` in every *correlation-row* confidence, though the aggregate report now derives real coverage. Rows display in the panel, so the numbers shown overstate evidence strength in session-sparse periods.
**Fix shape:** thread the already-computed `coverageRatio` (exists at :1426 context) into the row-level path; extend WeatherConfidencePinsTests currently at aggregate granularity.

### NEW-DE-9 · 🟢 Low · BCE scaffolding fabricates evidence timestamps when ever activated
`NarrativePipeline.run` (BehaviorContextEngine2:5018–5029) creates `BehaviorEvidence(timestamp: Date(), …)` at sampling time — under Confidence-V2 recency math (:4624–4628) that pins `evidenceRecency = 1.0`/`historicalDepth = 0`. Dormant today; becomes a maturity-signal pollutant the moment V3 is wired. Same file: orphaned `BehavioralClock` abstraction exists (BehavioralCategory:2539–2591) — adopt it when activating.

### NEW-DE-10 · 🟢 Low · Report-generation masked-conflicts and double-recording detail
(a) `SessionEventRouter`'s 2-min weather window can double-snapshot one session on rapid open/close cycles (:119 window). (b) `recordDeviceState` appends both a `DeviceStateEvent` and a duplicate `BehavioralEvent(.deviceStateTransition)` (BehavioralCategory:861–882) — every lock/sleep transition double-records. (c) `enabledVisibleBooks` memo signature is a folded hash-sum (NewContentView:143) — collidable under sets-vs-count coincidences (rare; cheap to switch to an id-array signature string).

### NEW-DE-11 · 🟢 Low · Discovery stack rough edges (only Release-reachable network code)
No OpenLibrary `limit=` param (unbounded response decode); no explicit timeout configuration (60 s default per-request); `BookSource.worldCat` rendered but no provider exists (OnlineBook.swift:12; rows :66, detail :89); Gutenberg `description` never populated ⇒ detail view always "No description available" and the +15 description score branch is dead (OnlineBookDiscoveryService.swift:143–149).

### NEW-DE-12 · 🟢 Low · Test hygiene set
CoverStorePinsTests 3–4 write through global `CoverStore.shared` into the real app-support covers dir (side effects in `xcodebuild test`); AnalyticsCache zero-epoch test asserts against a stub returning nil (vacuous); `Reading_TrackerTests.swift` is the template stub; DurabilityPins round-trip assertions sit inside `#if DEBUG` (silent no-op in Release runs).

### NEW-DE-13 · 🟢 Low · Misc truth-drift & hygiene
`AnalyticsEngine` header now contains the inverse of the old phantom-claim (says "no such cache type exists" while `AnalyticsCache` exists — stale doc-truth); `DemoProfileLabView:156` calls `try?` on the non-throwing `installCollections` (compiler warning, discarded summary); Sentinel quarantine dir declared (S1 header) but never used; 📄 `AchievementEngine2` uses `longestStreak` for detection but `currentStreak` in "Coming Up" progress display (:276 vs :452); `wordCountEstimate` documented "cached at import" but never set by the importer; ~12 `print()` debug statements in `PDFReaderView2` production paths.

---

## 8. The BCE "needs more data" mystery — CLOSED (your pinned follow-up)

Your INVESTIGATION NOTE from `profilerfix.md` (why does the engine stay silent with ~1,500 h of synthetic history — is it the engine or the profiles?) — answer, in code, with receipts:

1. **It's mostly the trigger, not the thresholds.** `analyze()` runs ONLY when a *live session closes* (SessionEventRouter2:75–98, `.dropFirst()` = never on launch/link). Loading 1,500 h of synthetic history triggers **zero** engine runs. The panel's "Learning Your Patterns…" after import is copy shown because `summary == nil` (ContextInsightPanel:26–34) — an engine that was never asked.
2. **Even when triggered, the synthetic evidence is thin.** The engine's *behavioral* evidence comes from `BehaviorContextAccessKit` — NSWorkspace foreground-app observations **in memory since app launch only** (:163 gate). A synthetic corpus creates zero app-usage evidence; the builder correctly refuses to invent it ("never derives context from absence").
3. **When it does run, day-span floors bind before hour-volumes do.** DataMaturityEngine floors: routine 4 samples/3 distinct days/7-day span; environment 6/4/10; weatherCorrelation 12/8/rep4/21-day span (DataMaturityEngineAdapters:140–180). `distinctDayCount`/`observedSpanDays` derive from **timestamps** (DataMaturityEngine:282–338) — synthetic corpora back-dated/collapsed into few simulated days fail span floors regardless of 1,500 h volume.
4. **The profiles are innocent.** Verified: all 16 personas generate validator-clean libraries (pinned), correct seasonality/hour signatures.

**What this means practically:** to make BCE live for a synthetic profile you need (a) an analyze-on-history-entry path (run `analyze()` over imported/synthetic data, not just live closes), (b) synthetic app-usage evidence generation inside `DemoDataService` (it fabricates reading; it doesn't fabricate NSWorkspace history), and (c) keep timestamps spread across their simulated days (they already are — good). The engine's V1 pipeline (lines 1–945) is the only part one can activate honestly; **V3/Phase-2 (81% of the file) needs a hardening pass first** — including fixing NEW-DE-9 and adopting the orphaned BehavioralClock — per its own checklist comments.

---

## 9. Risk register (ranked)

| # | Risk | Layman meaning | Likelihood / Impact | Notes |
|---|---|---|---|---|
| R1 | **Uncommitted 44-day fix** | The thing that made the app NOT freeze exists only on your desktop, on no other copy | Certain (it exists) / High if drive dies or a future session `git checkout .`s | Commit is 30 seconds; do it today |
| R2 | **Monolith persistence at scale** | Your real library will one day make the app slow the way the fake profiles made it fragile | Medium-term (linear growth) / High | Blueprint exists (§P5-G + FINAL_TRACES #1); est. below |
| R3 | **NAS/disk stale-overwrite window** (NEW-DE-1) | Fast successive saves can, in a narrow window, write an older version over a newer one | Low frequency / Medium (silent history loss; backups mitigate) | Fixed with modest writer surgery |
| R4 | **Main-actor stalls at 10× volume** | App UI hiccups as library/analytics grow | Grows over time / Medium | Known surfaces enumerated; memoize/move-off-main per HUD-lesson pattern |
| R5 | **Store-release hard failures** | App Store validation rejects: empty icon; WeatherKit entitlement 403s weather at runtime | Certain unless fixed / Medium | 4 concrete items, ~2–4 h + icon art |
| R6 | **Deployment target 26.5** | Only users on the newest macOS can install | Certain / Medium (audience) | Consider one step back (26.0) unless intentional |
| R7 | **Test-gaps in user-visible layers** | Discovery/network + view flows can regress silently | Medium / Medium | Add URLProtocol-mocked provider tests + a couple of view-model pins |
| R8 | **Achievement flood on bulk history import** | Installing a persona (or a real import of old data) erupts hundreds of toasts at once | Certain on that path / Low | Your own pinned note; treat as UX: "seen/settle" gate + one summary card |
| R9 | **Weather insight trust erosion** (NEW-DE-7/8) | Weather claims subtly overstate or mis-location | Medium / Low | Small fixes; big credibility win |
| R10 | **Synchronized-folder shipping strays** | Any scratch file dropped in `Reading Tracker/` silently compiles into Release | Low / Medium | Folder-synchronized membership is a two-edged pbxproj model |

---

## 10. Estimates (multiple bases, honest)

### 10.1 Effort estimates for open work (session units — an "Ox session" ≈ one concentrated working session under your protocol; hours assume a fresh, project-familiar context)

| Work item | Estimate (sessions) | Estimate (hours) | Notes |
|---|---|---|---|
| Commit pending fix + git hygiene (freeze.txt, ignore rules, artifact policy) | 0.05 | **0.5 h** | Do first; changes risk class of everything |
| Spatial cover fix (NEW-DE-2) | — | **0.25 h** | One line + visual check |
| Onboarding bypass + goal clobber (NEW-DE-5) | — | **0.5–1 h** | Route through facade; merge goal set |
| Crash-window duration split (NEW-DE-3) | — | **1–2 h** | Sentinel orphan-repair tightening included |
| PersistenceWriter ordering restore (NEW-DE-1) | — | **2–4 h** | Pre-encode or await-predecessor + order pin |
| AnalyticsCache day-boundary (NEW-DE-4) | — | **1–2 h** | Signature prefix |
| Weather honesty set (NEW-DE-7/8 + join window) | — | **2–3 h** | + extends existing pins |
| Release blockers (icon, WeatherKit entitlement, CFBundleID key, readonly conflict) | — | **2–4 h + icon art** | Icon art is the long pole |
| Dead-code retirement sweep (LibraryView 243, restoreSession, perBookSpeed, DemoLabError, worldCat, importer-facade halves, takeIf, BCE checklist comments) ⇒ −5.5–6.5k LOC | 1 | **3–5 h** | Product decision per item; zero behavior risk where zero-callers verified |
| Discovery hardening + tests (timeout/limit/worldcat/desc + URLProtocol mocks) | 0.5 | **3–4 h** | |
| Achievement-flood UX (settle-all + "recent" toggle; clear-all = dialog, stamps seen — per your spec) | 0.5–1 | **3–6 h** | |
| W-01 row-level coverage + pins | — | **1–2 h** | |
| BCE activation track: V1 history-entry analyze + synthetic NSWorkspace evidence + demo-profile wiring | 1.5–2 | **6–10 h** | Uses the NEW §8; skip Phase-2 |
| BCE V3/Phase-2 hardening + wiring (IF wanted at all) | 3–5 | **15–25 h** | or **1 session to DELETE** 4.2k LOC instead — recommend choosing now |
| Upgrade #3: split @Observable stores (Library/Goal/Health), per FINAL_TRACES plan | 1–2 (3 views/commit) | **8–14 h** | Touches ~20 views; protocol says fresh-context |
| Upgrade #1: SQLite normalized core (blueprint complete: FULLMUTEX + PersistenceWriter-owned queue + dual-read migration; RemediationPins as acceptance) | 2–3 | **12–20 h** | The structural future of the app |
| Swift 6 strict-concurrency completion (est. 20–40 Sendable annotations after #3) | 0.5–1 | **3–6 h** | Only after #3 |
| D6 pruning policy (sessions/pageTimes/TTLs/orphaned weather rows) | 0.5–1 | **3–5 h** | Design gate needed (what's the product story for pruning user history?) |
| Shared scheme + test plan + safe CI recipe | — | **1–2 h** | Unlocks machine-verifiable suites |

### 10.2 Scale-performance estimates (monolith kept as-is)

| Library shape | Encode/write per save | Launch validate | UI effect |
|---|---|---|---|
| Today's typical heavy user: 100 books / ~300 sessions / ~10k timings | ~0.3–0.8 s | ~50–150 ms | Fine behind debounce |
| 500 books / 3k sessions / ~200k timings (persona-scale) | 1–3 s (codebase's own data) | 0.5–1.5 s | Hover analytics occasionally drop frames (matches ROADMAP ~10× estimate) |
| Multi-year: 100k+ sessions / 1–10M timings | **~15 s–2 min** transactions; 250 MB–5 GB JSON | minutes on load | Debounce chains stack; `saveImmediately` visibly stalls UI; backups 10× file; risk profile near R2 |

The AnalyticsCache covers the 5 hottest whole-library reductions only when callers pass epoch (goal VM + InsightEngine do; ~8 other call sites pass `epoch: 0` = always uncached) — real but partial relief. The structural answer remains #1 (SQLite with per-session/aggregate tables), which changes every line above to O(1)–O(query).

### 10.3 Project-completion estimates (to "App Store ready", two scenarios)

- **Minimal-ship scenario** (fix NEW-DE-1…5 + release blockers + icon + commit hygiene + shared scheme): **1–2 sessions / ~6–10 h.** Realistic: within a weekend.
- **Proper-ship scenario** (minimal + dead-code retirement + discovery hardening + weather-honesty + achievement-settle UX + pruning policy + BCE V1 activation): **4–6 sessions / ~20–35 h.**
- **Architectural-future scenario** (proper + #3 split + #1 SQLite + Swift 6): **+3.5–6 sessions / ~23–40 h.** Recommend as its own multi-session arc, never appended to a short session (both blueprints say so).

### 10.4 Quality-fraction estimates (how much of the code is real vs ornament)

| Layer | Live (wired, reachable) | Dead/dormant |
|---|---|---|
| Core+Engines (6,790 LOC) | ~6,600 (97%) | ~190 (perBook-speed cache, sentinel quarantine plan, misc) |
| BHE cluster (13,183) | ~5,900 live | **~7,300 (55%)** — BCE 81% dead; BehavioralCategory ~60% dead |
| Feature/UI (~13.3k read-set) | ~92–94% | ~6–8% (LibraryView, restoreSession, facade halves) |
| Tests | all live | 3 stubs (UI target) |
| **App-target total (~40k)** | **~85–88% live** | **~12–15% dead (~5.5–6.5k LOC)** |

### 10.5 Test-suitability score (from the tests/config agent's weighted rubric)

**0.68 / 1.0** overall — 0.9 pinning depth (exceptional), 0.4 architecture breadth (narrow), 0.65 hygiene, 0.7 infrastructure. Verdict: a genuinely disciplined regression *net* for the persistence/engine/sentinel/demo layers; not yet a general quality gate.

---

## 11. Recommended order (next session(s))

1. **Today, 30 minutes:** commit the Sep-2 fix with a message naming `profilerfix.md` + `freeze.txt` (delete or mark them `docs/` after), decide artifact policy (`freeze.txt`, `diagnostics-2026-08-26.txt`→ ignored or archived), commit the `UI REVIEW.rtf` deletion and README rewrite. *Removes the single riskiest state in the repo.*
2. **Punch list (§10.1 first block, ~half day):** NEW-DE-2 → NEW-DE-5 → NEW-DE-4 → NEW-DE-3 → NEW-DE-1 (ordering last, it's the toughest); suite green after each.
3. **Punch list B (~half day):** release blockers + NEW-DE-7/8 + truth-drift set (NEW-DE-13) + test hygiene (NEW-DE-12).
4. **Decision gate (you, no code):** (a) BCE Phase-2 — wire-or-delete (report recommends delete first, restore from git if ever wanted); (b) pruning policy shape; (c) monolith schedule (#1 SQLite next arc?).
5. **Then** run the bigger tracks in the order the blueprints themselves prescribe: dead-code sweep → #3 store split → #1 SQLite → Swift 6 → (activation) BCE V1 → polish (LT-10/11/12, achievement gallery).

---

## Appendix A — Validation transcript (this audit)

- `xcodebuild build` → `** BUILD SUCCEEDED **` (fresh DerivedData; ZIPFoundation 0.9.20 resolved)
- `xcodebuild test -only-testing:"Reading TrackerTests"` → `** TEST SUCCEEDED **` (108 @Test funcs; parameterized expansions)
- Verified file-by-file: 100/18/2 swift split; 5,252/3,187/… largest-file claims; 286 types; 28,697 nb-code LOC
- Verified-in-code this audit: MaturityEngine expiry rule now uses injected `referenceDate` (F-13b closed); W-02/W-03 fixes real (`chronologicalBounds` order-independent; avoided-genre threshold); W-01 partial (row-level constant remains); spatial-cover bug real; PersistenceWriter gate-not-executor real
- Freeze artifact confirmed authentic: `freeze.txt` shows main thread 100% occluded by `EnvironmentObject.error()` ← `DemoProfileLabView.install(_:):151–152` (5 s, 4090/4090 samples) — matching `profilerfix.md`'s one-line fix, currently uncommitted

## Appendix B — Artifact inventory

| Artifact | Verdict |
|---|---|
| `freeze.txt` (222 KB) | Authentic forensic sample of the Last Defeat; keep (not in git) or add to `docs/` |
| `profilerfix.md` | The Sep-2 post-mortem; the missing commit is its proof — commit both |
| `LAST_DEFEAT_demo_profiles.txt` | Fine as repo artifact (tracked); part of history |
| `CURRENT_AUDIT.md` / `fix-log.md` / `handoff.md` / `tree.md` | Registers accurate as of Aug-26 stage; tree.md is 8 files stale (now 100 app files) |
| `TESTING_STRATEGY.md` / `REMEDIATION_ROADMAP.md` | Method docs: excellent, reusable |
| `graphify-out/` (30 MB) | Stale (built on commit c4968cb, Aug 26) but correctly gitignored; refresh after the next big code change, or prune old snapshots (29 MB of the 43 MB folder) |
| `diagnostics-2026-08-26.txt` (42 KB) | Old diagnostic corpus; tracked in git — consider untracking (history-only) |
| `.DS_Store` ×6 | Gitignored / untracked — fine |

## Appendix C — Folder name note

Per roadmap Phase-4 item 5 (still open): the folder is literally named `Reading Tracker Main ` **with a trailing space**, which has silently cost care in every shell command this audit (and can cost you in scripts). When feasible: rename outside any fix session (pure filesystem op; relative paths inside the project make it safe).

---

*End of report. This document is an audit, not a fix session: no code was modified. NEW-DE items should be merged into `CURRENT_AUDIT.md`'s register (keeping the ID scheme) by the next fix session, per the register's own supersession rule.*
