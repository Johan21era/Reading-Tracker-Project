# 11 · Completion & Health Report (2026-10-24)

> **Historical snapshot.** Several release-readiness findings below were fixed after this report, including the CI runner, shared scheme, package entitlements, and Mirage embedding. For current state see `README.md` §4 and `docs/registers/04-handoff.md`; the GitHub unit census is green on macOS 26 / Xcode 26.6.
>
> **Historical line numbers.** The `file:line` references below describe the
> 2026-10-24 tree. They are retained as the audit's evidence; use the owning
> file, not the line number, for current work. The two defect-register ranges
> and the testing-strategy pointer that no longer contained their subjects were
> replaced with plain file references on 2026-10-29.

**Scope:** the entire `Reading Tracker Main` folder — all 114 app Swift files, 34 test files, all docs, the graphify output, a live Debug build, a live full test run, the built `.app` bundle, and the real sandbox data store on this Mac.

**Bottom line:** this is a real, working app with an unusually strong core, test culture, and documentation estate. It is **not finished**, but it is much closer to “polish and ship” than “rewrite.” Our byte-weighted estimate is that **~67% of the app’s source bytes (comments included) are doing their intended job today**, **~19% of lines are dead or dormant**, and **~14% is partial work held back by release/feature blockers**. Three areas account for most of the remaining gap: **Behavior Context**, **Weather**, and **Mirage runtime packaging**. There is also one genuine live data bug — duplicate achievements — plus a persistence-ordering defect and several “looks wired but isn’t” features.

---

## 1. What was measured (not inherited from old notes)

| Check | Result |
|---|---|
| `xcodebuild build` (Debug, macOS) | **BUILD SUCCEEDED**, exit 0, no app-target warnings |
| `xcodebuild test` (full scheme) | **TEST SUCCEEDED** |
| Unit census from `.xcresult` | **191 passed / 0 failed / 4 skipped** (195 cases; 218 passes after parameter expansion) |
| UI tests | 4 executed cases, all pass — all are template tests with no real assertions (3 methods; one is run twice) |
| App source | **114 Swift files · 1,580,214 bytes · 42,569 lines** |
| Non-comment code | **1,164,367 bytes** (73.7% of source) |
| Comments | **373,278 bytes** (23.6%) |
| Blank lines | **5,556** |
| Tests | **34 files · 230,429 bytes · 5,272 lines · 193 `@Test` functions · 34 suites** |
| Docs | **36 Markdown files · 97,007 words · ~1.1 MB** |
| Graphify | 3,953 nodes · 10,769 edges · 178 communities · 674 isolated nodes · built at commit `b61af4d` (one commit behind HEAD) |
| Git | 66 commits · Jun 17–Oct 18 2026 · clean tree (only `.obsidian/` untracked) |
| Built app | 27 MB; **no `Assets.car`, no app icon, no `mirage-runtime`** |
| Real data store | `library.json` = **29,625,947 bytes**; 7 books; 292 sessions; **138,459 page timings** |
| Backups | **72 MB / 10 backups** |
| Covers | 38 files / 584 KB (for 7 books — orphaned files exist) |
| Achievements | **592 earned records** (should be ~25 unique kinds) |
| Weather store | **0 rows** (file exists at a different path than the docs claim) |
| Audio profiles | 3 profiles |
| Sentinel journal | 53 KB |

Commands used:

```bash
xcodebuild build -project "Reading Tracker.xcodeproj" -scheme "Reading Tracker" \
  -configuration Debug -destination 'platform=macOS'
xcodebuild test  -project "Reading Tracker.xcodeproj" -scheme "Reading Tracker" \
  -configuration Debug -destination 'platform=macOS'
xcrun xcresulttool get test-results summary --path <latest .xcresult>
```

The build and test claims in the README are **true today**. This report does not dispute them; it explains what those green numbers do and do not cover.

---

## 2. The scoreboard, in plain English

| Question | Answer | Basis |
|---|---|---|
| Does it compile? | **Yes** | live build, exit 0 |
| Do the tests pass? | **Yes — 191/0/4** | live `.xcresult` |
| Is every major feature present? | **~85%** | all major surfaces exist; ~19% of LOC is dead/dormant |
| Is every feature working in real use? | **~67%** | byte-weighted feature table in §3 |
| Is it App Store ready? | **~50%** | icon, entitlements, runtime packaging, CI, signing |
| How much code is dead/dormant? | **~8,100 LOC (19%)** | 6,400 future scaffold + 1,700 true debris |
| How much work is left? | **32–85 h to ship; 100–150 h to architecture-complete** | §8 |

The single most useful sentence:

> **The app is 67% “working product” by source-byte weight; it becomes ~86.5% working if Behavior Context, Weather, and Mirage packaging are finished — without touching most of the rest.**

That is not a guess about those three areas: they are 16.4%, 10.2%, and 7.6% of all app bytes respectively, and each is currently held back by a concrete, identified blocker.

### How the 67% is calculated

Every area gets a byte weight from the literal file sizes. The “working %” is an analyst judgment, stated openly in §3. The formula is:

```text
weighted working score = Σ (area bytes × area working %) / Σ area bytes
                       = 1,060,055 / 1,580,214
                       = 67.1%
```

The remaining gap is **520,159 byte-equivalents (32.9%)**. Its distribution is the priority map:

| Area | Share of remaining gap |
|---|---:|
| Behavior Context | **34.8%** |
| Weather / Environment | **13.9%** |
| Mirage | **10.3%** |
| Audio | **9.1%** |
| Library | 4.7% |
| Engines | 4.5% |
| Discovery | 3.6% |
| Recommendations | 3.3% |
| Everything else | ~15.8% |

Fixing the top four removes **68% of the remaining gap**. That is where the leverage is.

---

## 3. Completion by area (literal bytes, stated assumptions)

### Foundation and core reading loop

| Area | Bytes | Share | Working estimate | What works | What is missing / risky |
|---|---:|---:|---:|---|---|
| **Core** (persistence, models, validator, archive) | 132,456 | 8.4% | **95%** | Tolerant decoders, corrupt-file backup, validator, archive export/import, auto-backups, Sentinel bridge | JSON monolith; write-ordering defect; `saveImmediately` does not truly drain; shared encoder race; no pruning |
| **Engines** (analytics, estimation, maturity) | 154,428 | 9.8% | **85%** | Pure, deterministic, well-documented; EstimationEngine validated; DataMaturity design is strong | AnalyticsCache barely used; Insights bypasses it; DataMaturity has **zero direct tests** |
| **Root / app shell** | 49,400 | 3.1% | **90%** | Windows, Settings, Insights window, Developer Console, environment wiring | `ReadingTrackerApp 2.swift` filename; some stale comments |
| **Library** (import, explorer, spatial) | 69,649 | 4.4% | **65%** | PDF/EPUB import, covers, reader routing, explorer tiers, filters | Spatial cards never show real covers (one-line bug); entire `LibraryView.swift` dead; genre/series/favorite/collections/notes never populated for real users; collection CRUD APIs have no UI |
| **Reader** (PDF/EPUB) | 46,113 | 2.9% | **85%** | Both readers, bookmarks, session timing, metadata popover, Mirage entry | PDF RSVP extraction cannot be cancelled; EPUB import parsing still main-thread |
| **RSVP** | 10,611 | 0.7% | **90%** | Tokenizer, playback engine, UI, settings, tests | PDF extraction cancellation bug; only partial tokenizer-matrix coverage |
| **Goals** | 42,627 | 2.7% | **90%** | Daily/weekly/annual goals, deadlines, Settings editor, live refresh | Goal-achievement edge cases; `epoch` parameter is not actually used by status math |
| **Sessions** | 31,919 | 2.0% | **80%** | Coordinator, HUD, history, audio detail | Crash-window inflation; idle time counted; `restoreSession` zero callers |
| **Achievements** | 32,263 | 2.0% | **75%** | 25 badges, toast queue, panel, F-08 fixed | **Duplicate-award bug: 592 records for 25 kinds**; toast flood risk; current-vs-longest streak display inconsistency |
| **Reports** | 105,319 | 6.7% | **90%** | 9 report slides, race guard, non-Gregorian calendar pins, highlights, narrative | Slide 10 (audio) is computed but **never displayed**; header says 10 slides, view has 9 |
| **Insights** | 32,350 | 2.0% | **75%** | Nine insight families, dashboard, DataMaturity gating | Dashboard recomputes ~10 whole-library scans per body; **epoch = 0 everywhere**, so cache is bypassed |
| **Recommendations** | 49,257 | 3.1% | **65%** | V3 engine is live, deterministic, and correctly wired | V1/V2 and supporting models are dead (~75% of file); no tests for V3 |
| **Discovery** | 53,549 | 3.4% | **65%** | Open Library + Gutendex search, ranking, dedupe, offline state, detail view | **No way to import/download a found book**; no `limit`, no timeout; `worldCat` has no provider; Gutenberg descriptions always nil |
| **Notifications** | 37,822 | 2.4% | **60%** | Delivery wrapper, authorization, candidate engine, maturity gate | `sessionFit = 1.0` placeholder; TODO to thread real recommendation/estimation |
| **Onboarding** | 7,586 | 0.5% | **70%** | Three-step wizard, persists dismissal | Bypasses Import Intelligence and duplicate feedback; **overwrites the whole goal set** with only a daily target |

### Intelligence, optional features, and tools

| Area | Bytes | Share | Working estimate | What works | What is missing / risky |
|---|---:|---:|---:|---|---|
| **Behavior Context** | 258,764 | 16.4% | **30%** | V1 engine is wired and can produce routines/narratives when given evidence | Evidence is **in-memory only**; analyze runs only on live session close; no analyze-on-history; synthetic profiles create no NSWorkspace evidence; V3/Phase-2 (~4,200 LOC) is uncalled; live pipeline has no tests |
| **Environment / Weather** | 160,656 | 10.2% | **55%** | Palette, stars, shooting stars, 45 s engine, weather modifier, weather UI/engine | **WeatherKit entitlement is missing; the sandbox location entitlement is also absent; the real weather DB has 0 rows**; NYC fallback; row-level coverage hardcodes 1.0; nearest-snapshot join has no time window; several weather fields are 0.5 approximations |
| **Mirage** | 119,315 | 7.6% | **55%** | Typed wire, 28 actions, supervisor, identity map, import flow, cursor gate, status surface, ~85 tests, real-engine proofs | **No `mirage-runtime` in the built app**; only the dev env gate can find an engine; app-embed/signing/CI is a documented delta; spoiler detail surfaces intentionally disabled |
| **Audio** | 104,639 | 6.6% | **55%** | Music/Spotify monitoring, audio profiles, session detail, correlation engine, annual-report data builder | Annual-report audio slide is computed but never shown; save failures print-only; AppleScript runs on main every 60 s; profiles unpruned; 3 real profiles have 1-second durations |
| **Developer Console** | 81,491 | 5.2% | **90%** | Dashboard, registry, Sentinel pane, demo lab, system metrics | Debug-only by design; some console tiles are placeholders; 81 KB is a lot of debug surface |

**Weighted total: 67.1%.** If Behavior Context, Weather, and Mirage were finished to 100%, the same byte-weighted model yields **86.5%**.

---

## 4. What is genuinely good

1. **The core loop works.** Import PDF/EPUB, read, page-turn timings, session history, goals, streaks, achievements, reports, and RSVP all exist and are reachable.
2. **Build and test discipline is real.** We reproduced **191/0/4** and a clean build. The README’s central health claim is true.
3. **The data-safety stack is unusually mature for an indie app.** Corrupt-file backup before reset, tolerant decoders, schema evolution pins, validator, 10-deep backups, `.readingarchive` export/import, and a Sentinel watchdog with a written security doctrine.
4. **The Mirage boundary is genuinely well-engineered.** Typed NDJSON wire, one-lifecycle-per-gesture, fail-closed identity, write confinement, ~85 tests, and a real-engine handshake proof. The problem is packaging, not design.
5. **The engines are deterministic and testable.** EstimationEngine clamps and validates; DataMaturityEngine injects clocks and gates claims; calendars are injected for non-Gregorian tests.
6. **Feature breadth is impressive.** 25 achievements, 16 deterministic demo personas, nine annual-report slides, nine insight families, audio correlations, environment visuals, discovery, onboarding, and a debug console.
7. **Documentation culture is exceptional.** 97,000 words, ADRs, a fix log, a defect register, an audit with file:line evidence, and a merge campaign log. Very few solo projects have this.
8. **Security/privacy basics exist:** sandbox, privacy manifest, no telemetry, no network except WeatherKit/discovery, Apple Events entitlement, security-scoped bookmarks.
9. **UI craft is visible:** one design grid, shared corner radii, hidden title bar, ambient environment, reduced-motion/transparency handling.
10. **It survives real data.** The author’s library already has **138,459 page timings in a 29.6 MB JSON file** and the app still launches and passes tests. That is a useful stress proof, not a toy.
11. **The code explains itself.** Comments are **23.6% of source bytes** (373 KB); most explain rationale, history, and rejected alternatives rather than restating the code. That is why a new session can orient quickly despite the size.

---

## 5. What is actually bad (ranked, with receipts)

### P0 — correctness and data safety

| # | Issue | Evidence | Impact |
|---|---|---|---|
| 1 | **Duplicate achievements** | `AchievementEngine2.swift:224` captures `existingKinds` once; `award` at `:232` never inserts the newly awarded kind; `detectSpeedAchievements` loops every session at `:329`. Real store: **592 records = 292 Speed Reader + 292 Marathon + 8 real badges**. | Bloated state, duplicate badges, and a **584-toast flood** on any bulk import/demo install. This is the highest-value quick fix in the repo. |
| 2 | **Persistence writes can reorder** | `PersistenceWriter.swift:30–52` passes through a serial gate then encodes/writes on the concurrent cooperative pool; `DataStore3.swift:556–570` drains only the gate, not the work; `saveImmediately()` then writes directly. A slow older encode can land after a newer write. | Narrow-window silent loss of newest reading history; violates the “newest data wins” contract. |
| 3 | **Shared JSONEncoder across concurrent writes** | `DataStore3.swift:607–612` is one static `JSONEncoder` used by every detached write. `JSONEncoder` is not thread-safe. | Potential data race/corruption under overlapping saves. |
| 4 | **Crash-window time inflation** | `DataStore3.swift:437–451` sets `endTime = Date()` when closing a session left open by a force-kill; `SentinelEngine.swift:292–303` does the same for >24 h orphans. | A crash + idle gap becomes “reading time”; analytics/streaks/goals are inflated by up to 24 h per orphan. |
| 5 | **Onboarding bypasses import intelligence and clobbers goals** | `OnboardingView.swift:196–218` calls `BookImporter` then `dataStore.addBook` directly, ignoring duplicate rejection and Import Intelligence; `:220–225` writes `ReadingGoalSet.empty` plus one daily target. | First-run users get no import warnings, silently lose duplicates, and **lose any pre-set annual/weekly/deadline goals**. |
| 6 | **Spatial cards never show real covers** | `BookCoverCardView.swift:46` reads `book.coverImageData`; imports write covers only to `CoverStore` and `DataStore3.swift:464–472` nils the embedded field. | Every Explore/Spatial card shows a placeholder gradient forever. One-line fix: use `book.coverImage`. |
| 7 | **Analytics cache staleness and bypass** | `AnalyticsCache.swift:32–48` has no day component; `InsightEngine.swift:107–111` passes `epoch: 0`; `ReadingInsightsDashboard.swift:24–50` recomputes six whole-library properties in `body`. | Streaks/trends can be stale across midnight; opening Insights can trigger ~10 full-library scans on the main thread, repeated on every body evaluation. |
| 8 | **PDF RSVP extraction cannot be cancelled** | `PDFReaderView2.swift:398–420` starts an unassigned `Task.detached`; `Task.isCancelled` is never true because nothing holds/cancels the task. | A huge PDF keeps extracting and holding the security scope/memory after the sheet closes. |

### P1 — features that look finished but are not

| # | Issue | Evidence | Impact |
|---|---|---|---|
| 9 | **Weather cannot work in the built app** | `Reading Tracker.entitlements` has no `com.apple.developer.weatherkit` and no `com.apple.security.personal-information.location`; `WeatherKitService2.swift:43` uses `WeatherService.shared`; the real `weather_snapshots.sqlite3` has **0 rows**. | The headline “live weather” feature silently never records; weather insights stay empty; users get no explanation. |
| 10 | **Weather fallback/coverage honesty** | `WeatherKitService2.swift:107` uses `cachedLocation ?? defaultLocation`; `:673` defaults to NYC; `:681–699` returns NYC for `.notDetermined`; `WeatherAnalysisEngine.swift:1412` hardcodes `dataCoverageScore: 1.0`; `WeatherInsightPanel2.swift:334–337` joins the nearest snapshot with no maximum time window. | Weather claims can describe the wrong city and overstate evidence; sparse snapshots bind to unrelated sessions. |
| 11 | **Mirage is not packaged into the app** | `MirageRuntimeLocator.swift:75–96` requires `Resources/mirage-runtime/`; the built app contains no such folder; `final-acceptance-2026-10-18.md` lists app-embed as an honest delta; `README.md:46/117` claims it ships inside the app. | In a normal build, Mirage always reports “engine isn’t set up”; only a developer with `MIRAGE_REAL_ENGINE_DIR` can use it. |
| 12 | **Behavior Context is starved** | `BehaviorContextAccessKit` keeps evidence in memory only (`BehavioralCategory.swift:438–457`); `SessionEventRouter2.swift:95–168` analyzes only on live session close and **requires non-empty evidence**; `analyzeWithIntelligence()` at `BehaviorContextEngine2.swift:5085` has no app call site. | With a large imported history, the panel still says “Learning your patterns” because the engine was never asked, and synthetic demo data creates no NSWorkspace evidence. |
| 13 | **Library metadata/filter dead-ends** | `BookImporter.swift:120–133, 233–244` never sets `genre`, `series`, or `wordCountEstimate`; `isFavorite` is only set by demo data; `addCollection`/`setBook` are only called by `DemoDataService.swift:514–521`; no UI exists for genre/series/favorite/collections/notes. | The filter sidebar is real, but for a real user most of its dimensions are always empty. Genre analytics, recommendations, and the annual-report genre slide degrade to `Unknown`. |
| 14 | **Audio annual report is computed then discarded** | `AnnualReportData2.swift:164–165, 287–302` builds `audioReport`; `AnnualReportView.swift:46` sets `totalSlides = 9` and the router `:184–196` has no audio slide. | The most expensive audio analysis output is never shown. |
| 15 | **Audio monitoring risks** | `AudioTrackerMetadata2.swift:472` runs `NSAppleScript` synchronously on main every 60 s; `:113–121` prints save failures only; profiles are never pruned. | UI hiccups, silent secondary-data loss, unbounded `audio-profiles.json` growth. |
| 16 | **Discovery cannot acquire a book** | `OnlineBookDetailView.swift` and `BookDiscoveryView.swift` have no Import/Download action; `OpenLibraryProvider.swift:24` has no `limit`; both providers use default URLSession timeouts; `GutenbergProvider.swift:44` always sets `description = nil`; `OnlineBook.swift:12` defines `.worldCat` with no provider. | “Discover Books” is a browse-only catalog; a “Free” Gutenberg result cannot be opened or added. Network calls can hang for 60 s; descriptions are permanently empty. |
| 17 | **Notifications are placeholder-scored** | `IntelligentNotificationEngine.swift:207` sets `sessionFit = 1.0`; `:216` has a TODO to thread real recommendation/estimation signals. | Notification targeting is partially decorative. |
| 18 | **Release readiness** | AppIcon set has no images and the built app has **no `Assets.car`**; `.github/workflows/census.yml:13` uses `macos-14` while the target is macOS 26.5; there is **no shared `.xcscheme` or `.xctestplan`**; `ENABLE_USER_SELECTED_FILES=readonly` coexists with a read-write entitlement; signing is “Sign to Run Locally”; deployment target is 26.5. | Cannot ship as-is; CI on a fresh clone is not reproducible; the icon/entitlement/signing work is external to the code. |
| 19 | **Test gaps and test isolation** | Only **45.2% of app bytes** are referenced by any test type; UI tests are four template methods; no tests for DataMaturity, Insights, Reports, Importer, Readers, Audio, Discovery, Notifications, or live BCE. `SentinelPinsTests.swift:51/73/90` writes to the **real** Sentinel journal (we saw it during our run); `CoverStorePinsTests.swift:84/93` writes through `CoverStore.shared` into the real covers dir; `AnalyticsCachePinsTests.swift:96–103` is vacuous; `LibraryCollectionTests.swift:80` is `#expect(true)`. | The green census is a strong regression net for the layers it covers, but it is not a general quality gate; tests also mutate real app-support state. |
| 20 | **Documentation drift** | `docs/registers/02-defect-register.md` still lists F-01…F-13 as “Open defects” although `03-fix-log.md:95–104` says they are fixed; `README.md:46/117` says Mirage ships inside the app; `AnalyticsEngine.swift:20–28` says “no such cache exists” while `AnalyticsCache.swift` exists; `LibraryExplorerView2.swift:29–31` says “not yet wired” although `NewContentView.swift:479–494` wires it; `AnnualReportData2.swift` header says 10 slides, the view has 9; README says 192 tests, actual 193. | A future session can waste hours trusting the wrong document. The docs are excellent but need a truth pass. |

### P2 — housekeeping and data hygiene

| Item | Evidence | Why it matters |
|---|---|---|
| **Orphaned covers** | 38 cover files for 7 books (584 KB) | Demo-profile switching and tests leave files behind; `removeBook` cleans, but bulk replacement does not |
| **Abandoned SQLite artifact** | `library.sqlite3` (4 KB) + `library.sqlite3-wal` (825 KB) from the failed P5-G experiment | Dead bytes and a confusing second “database” next to the real JSON store |
| **Split data directories** | Library data lives in `.../Application Support/ReadTracker/`; weather DB lives in `.../Application Support/johan.Reading-Tracker/` | Backups and documentation assume one root; weather sits outside it |
| **Stale migration artifacts** | `library.bak.json`, `library.migrated`, `library-state.migrated` | Harmless but noisy; a future session may mistake them for live files |
| **Graphify weight** | 28 MB / 68% of the folder; 10.8 MB tracked `graph.json` + `graph.html` | Slows clones and buries the 1.6 MB of app source; prune or regenerate on demand |
| **Filename/folder quirks** | Folder name has a trailing space; `ReadingTrackerApp 2.swift` is the real `@main` | Every shell command needs quoting; the “ 2” name looks like a duplicate and is a synchronized-folder hazard |

---

## 6. Dead / dormant / unwired inventory (literal)

This is stricter than “this file looks old.” We built a reachability graph from `ReadingTrackerApp`/`ContentView`, then separately checked uncalled extension entry points and real call sites.

| Cluster | Approx. LOC | Approx. bytes | Status | Recommendation |
|---|---:|---:|---|---|
| **BehaviorContextEngine V3 pipeline** (`BehaviorContextEngine2.swift:991–5251`) | **4,261** | ~122 KB | **Dormant**: `analyzeWithIntelligence()` has no app call site; advanced detectors, routines, narratives, significance, diversity, evolution, and `FullContextIntelligenceReport` are only reachable from that uncalled entry point | Wire V1 history-entry analysis first; decide whether V3 is worth 15–25 h of hardening, or delete 4.2k LOC |
| **BehavioralCategory scaffold** (`BehavioralCategory.swift:1030–3187`) | **2,158** | ~44 KB | **Dormant**: event stores, replay controllers, pagination, validators, export encoders, etc. | Delete or wire as part of the BCE decision |
| **Old recommendation engines** (`PredictiveRecommendationEngine.swift:1–887`) | **887** | ~37 KB | **Dead**: V3 at `:932+` replaced V1/V2; `RecommendationPanel` uses V3 | Delete V1/V2 and their models; keep V3 |
| **Legacy `LibraryView.swift`** | **243** | ~6.8 KB | **Dead**: zero references; `ContentView` uses the sidebar + Explorer | Delete whole file |
| **Weather adapters** (`WeatherKitService2.swift:774–950`, dead engine types) | ~300 | ~9.5 KB | **Dead**: `EnvironmentalSessionAssembler`, `ReadingSessionMetrics`, forecast/evolution types have no live callers | Delete or wire as part of weather honesty work |
| **Importer plugins/debug** (`BookImporter.swift:684–760`) | ~90 | ~3 KB | **Dead**: `PageEstimationModel`, `ImportDebugSnapshot`, `ImportPluginManager`, `ImportPlugin` | Delete |
| **Misc debris** | ~200 | ~6 KB | **Dead**: `HoverIntent`, `DemoLabError`, `SessionCoordinator.restoreSession`, `AnalyticsCache.perBookSpeed`, `ReadingComplexityHints`, `sanityTestRecommendationEngine` | Delete; keep `MirageCursorGate` (intentionally gated, not dead) |
| **Intentionally gated** (`MirageCursor.swift`) | ~100 | ~2.4 KB | **Keep**: ADR-7 spoiler gate; refusing is the feature | Do not “fix” without a countersigned amendment |

**Totals:** ~**8,100 LOC / 19%** dead or dormant. Of that:
- **~6,400 LOC** is future-facing scaffold (BCE V3 + BehavioralCategory) — a product decision, not garbage.
- **~1,700 LOC** is true debris that can be deleted with near-zero behavior risk.
- **~100 LOC** is intentionally gated Mirage code that must stay.

Also unwired but not “dead code”:
- Genre, series, favorite, collections, and notes have **no user-facing editing/population path**.
- `ImportIntelligenceFacade` computes suggestions/chapter issues that `NewContentView` discards.
- `wordCountEstimate` is computed during EPUB import but never stored on the `Book`.
- `AnnualReportData.audioReport` is computed but has no slide.
- `DataStore.removeCollection` / `renameCollection` have no UI callers.
- `AnalyticsCache` exists, but only the Goals view model passes a real epoch; Insights passes 0.

---

## 7. Risk register (ranked)

| # | Risk | Likelihood / impact | Why |
|---|---|---|---|
| R1 | **Weather never works** | Certain today / High for the feature | Missing WeatherKit + location entitlements; 0 real rows; errors swallowed |
| R2 | **Achievement duplication/toast flood** | Certain / Medium-high | 592 records already; bulk import can queue 500+ toasts |
| R3 | **Silent newest-data loss from write reordering** | Low frequency / High | Writer gate is not the executor; `saveImmediately` does not drain work |
| R4 | **JSON monolith hits a wall** | Certain over time / High | 29.6 MB for 7 books; 214 bytes per page timing; no pruning; backups 10× |
| R5 | **Mirage cannot ship without packaging/signing work** | Certain until done / High for that feature | No runtime in app; embedded Python signing is the riskiest unproven step |
| R6 | **App Store rejection/blockers** | Certain until fixed / High | No icon, no WeatherKit entitlement, local signing, entitlement conflict |
| R7 | **Behavior Context never delivers value** | Certain with current wiring / Medium | In-memory evidence, analyze only on live close, V3 uncalled |
| R8 | **Docs mislead the next session** | Certain / Medium | Register and README contradict the code in multiple places |
| R9 | **Tests mutate real user data** | Certain / Low-medium | Sentinel journal and CoverStore tests use real app-support paths |
| R10 | **Main-thread stalls at 10× volume** | Likely / Medium | Insights body recompute, weather SQLite every 45 s, AppleScript every 60 s, EPUB parse on main |

---

## 8. What we can fix, in order

### Session 1 — “Stop the bleeding” (2–3 h)

1. **Fix duplicate achievements** — `AchievementEngine2.swift:224–235`: make the awarded-kind set mutable and insert after every award. Add a dedupe migration for existing state (keep earliest per kind). Pin with a multi-session fixture that expects exactly one Speed Reader/Marathon.
2. **Fix spatial covers** — `BookCoverCardView.swift:46`: use `book.coverImage`.
3. **Fix onboarding** — route import through the same facade + `addBook` path as `NewContentView`; merge goals instead of replacing `ReadingGoalSet`.
4. **Pin all three** with focused tests.

### Session 2 — “Trust the disk” (4–6 h)

5. **Restore write ordering** — make `PersistenceWriter` the executor of encode+write, or await the predecessor task; make `saveImmediately` drain actual work; use a per-write encoder or a serialized encoder.
6. **Fix crash-window duration** — cap open-session end at last page timing + grace; make Sentinel orphan repair use the last timing boundary, not `Date()`.
7. **Pin** with a save-storm/order test and a crash-window fixture.

### Session 3 — “Honest analytics” (3–5 h)

8. **AnalyticsCache** — add `startOfDay` to the signature; remove or fix `perBookSpeed`; pass the store epoch from `InsightEngine` and the Insights dashboard; memoize the dashboard’s derived values outside `body`.
9. **Weather honesty** — add missing entitlements (WeatherKit + location) once the Apple account is ready; stop defaulting to NYC; surface “location unavailable”; thread real coverage into row-level confidence; add a max join window (e.g. ±1 h); replace 0.5 approximations with real signals or label them.
10. **RSVP cancellation** — hold the extraction task, cancel on dismiss, check `Task.isCancelled`.

### Session 4 — “Make the features real” (6–10 h)

11. **Packaging** — add a build phase/script that stages `mirage-runtime` into `Resources`, signs the embedded interpreter/dylibs, and runs `bundle_smoke.py` in CI; remove the README overclaim until it is true.
12. **Import metadata** — parse OPF `dc:subject` into `genre`, populate `series`, store `wordCountEstimate`; add a small book-details editor for genre/series/favorite/collections, or explicitly scope those out and hide the filters.
13. **Audio** — add the audio report slide or delete `audioReport`; route save failures through `persistenceHealth`; move AppleScript off main or reduce cadence; prune profiles.
14. **Discovery** — add `limit`, explicit timeouts, import/download for Gutenberg, remove or implement WorldCat, populate descriptions.

### Session 5 — “Ship shape” (4–8 h)

15. App icon artwork + asset catalog.
16. Shared scheme + test plan + coverage; fix `macos-14` CI to an image with Xcode 27/macOS 26 SDK.
17. Remove the readonly/read-write entitlement conflict; clean the empty `CFBundleIdentifier` key; decide deployment target (26.5 vs lower).
18. Docs truth pass: merge NEW-DE items into the register, mark F-01…F-13 resolved, fix README Mirage claim, fix the AnalyticsEngine header, update test counts and slide counts.

### Later — “Architecture” (40–60 h)

19. Pruning policy for sessions/page timings/weather/audio/backups.
20. SQLite normalized core + dual-read migration; split the `@Observable` store monolith; complete Swift 6 strict concurrency.
21. BCE decision: wire V1 history-entry analysis (+6–10 h) or delete V3/Phase-2 (+1 session).
22. Fill test gaps: DataMaturity, importer/readers, reports, audio, discovery, a real UI smoke suite.

---

## 9. Timeline estimates

Assumptions: one project-familiar developer; tests green at every boundary; no scope creep; “full-time” = 30–35 focused hours/week; “part-time” = 10 focused hours/week.

| Scenario | Work included | Hours | Full-time | At 10 h/week |
|---|---|---:|---:|---:|
| **Minimum credible v1** | P0 fixes + release blockers + weather entitlements + docs truth; leave Mirage honestly unavailable | **24–40 h** | 1–1.5 weeks | 2.5–4 weeks |
| **Shippable v1 with Mirage** | Above + Mirage runtime embed/signing + CI | **32–52 h** | 1–1.5 weeks | 3–5 weeks |
| **Proper v1** | Above + import metadata, audio slide, discovery hardening, notifications, dead-code sweep, test gaps | **60–90 h** | 2–3 weeks | 6–9 weeks |
| **Architecture-complete** | Above + pruning, SQLite core, store split, Swift 6, BCE activation/decision | **105–155 h** | 3.5–5 weeks | 10–15 weeks |

The project’s own audit estimated 6–10 h for a minimal ship and 20–35 h for a proper ship. We are raising that because the audit missed or underweighted four concrete blockers: **WeatherKit/location entitlements**, **Mirage runtime packaging**, **duplicate achievements**, and **the metadata/filter dead-ends**. Those are not polish; they determine whether features work.

At 10 focused hours/week, a realistic “I can hand this to a stranger” milestone is **3–5 weeks**; a “proper, defensible v1” is **6–9 weeks**; the architecture future is another **4–6 weeks**.

---

## 10. Documentation and graphify assessment

### Docs

The docs are a genuine asset — 97,007 words, numbered, cross-referenced, with ADRs and receipts. But they are now **partly stale in ways that can actively mislead**:

| Document | Claim | Reality |
|---|---|---|
| `docs/registers/02-defect-register.md` | F-01…F-13 are “Open defects — what is broken right now” | `03-fix-log.md:95–104` says F-01…F-05/F-07 are fixed; the audit says all but F-13(d) are fixed |
| `README.md:46,117` | Mirage ships inside the app as a bundled runtime | Built app has no `mirage-runtime`; acceptance lists app-embed as a delta |
| `Engines/AnalyticsEngine.swift:20–28` | “No such cache type or mechanism exists” | `Core/AnalyticsCache.swift` exists and is used |
| `Features/Library/LibraryExplorerView2.swift:29–31` | Explorer is “not yet wired into NewContentView” | `NewContentView.swift:479–494` presents it |
| `Features/Reports/AnnualReportData2.swift` header | 10 slides including audio | `AnnualReportView.swift:46` has `totalSlides = 9`; no audio slide |
| `README.md` / `docs/method/07-testing-strategy.md` | 192 `@Test` functions (at the 2026-10-24 audit) | 193 |
| `docs/registers/02-defect-register.md` | Environment/Spatial/Import Intelligence unwired | All three are wired in `NewContentView` / `ContentView` |

**Recommendation:** do a 2–4 h “truth pass” before the next feature session. The docs are too valuable to let drift; a future session will trust them.

### Graphify

Graphify is a semantic/AST reference graph, not a call graph. It correctly identifies the god nodes:

- `DataStore` — 113 edges
- `Foundation` — 104
- `BehavioralEnvironmentType` — 62
- `ReadingGenre` — 60
- `ReadingSession` — 58
- `WeatherAnalysisEngine` — 46

It reports **no import cycles**, 178 communities, and 674 isolated nodes. It confirms the architectural center of gravity: `DataStore` is the hub, and `BehaviorContext`/`Weather` are large, weakly coupled clusters. It does **not** detect uncalled private methods or the BCE V3 dead block; that required the reachability/call-site work in §6.

Housekeeping: `graphify-out/` is 28 MB (68% of the folder, ~75% of tracked bytes); `graph.json` + `graph.html` are 10.8 MB of the 14.4 MB tracked tree. It was built at `b61af4d`, one commit behind HEAD. Recommend regenerating after the next structural change and pruning old artifacts; the graph is useful as a map, not as a source of truth for dead code.

---

## 11. Recommended next five sessions

| Session | Goal | Acceptance |
|---|---|---|
| **1** | Duplicate achievements, spatial covers, onboarding | 592 → ~25 records; Explore shows real covers; onboarding preserves goals and reports duplicates; new pins green |
| **2** | Persistence ordering, crash-window duration | Save-storm test proves newest bytes win; crash fixture does not inflate time; `saveImmediately` truly drains |
| **3** | Cache/Insights, weather honesty, RSVP cancel | Midnight cache test; Insights opens without repeated full scans; weather errors are visible and coverage is real; RSVP stops on dismiss |
| **4** | Mirage packaging + import metadata | Built app contains a verified `mirage-runtime`; smoke test spawns it; real imports get genre/series/word count; filters have data |
| **5** | Ship shape | Icon, shared scheme, CI image, entitlements, deployment target, docs truth pass; full census green |

After session 5, decide the two big product questions:

1. **Behavior Context:** wire V1 history-entry analysis (+6–10 h) or delete V3/Phase-2 (~4.2k LOC)?
2. **Persistence:** keep the JSON monolith with pruning, or commit to the SQLite normalized core (+12–20 h) and the store split (+8–14 h)?

Those are the two decisions that determine whether the app is “a good indie app” or “a durable multi-year product.”

---

## 12. Appendix — methodology and caveats

### Byte accounting

- Raw source bytes are exact `stat` sizes of every `.swift` file under `Reading Tracker/`.
- “Code bytes” strips `//` and nested `/* */` comments while preserving string literals and newlines.
- “Working %” per area is an analyst judgment, not a compiler measurement. The byte weights are literal; the status percentages are explicitly stated so they can be challenged.
- Dead/dormant LOC is a combination of (a) a reachability graph from `ReadingTrackerApp`/`ContentView`, (b) manual verification of uncalled extension entry points such as `analyzeWithIntelligence()`, and (c) region counts for the BCE V3/BehavioralCategory scaffold. It is approximate to ±10%.

### Test accounting

- Census from `xcrun xcresulttool get test-results summary`: 191 passed, 0 failed, 4 skipped, 195 total cases.
- 193 `@Test` declarations; parameterization expands to 218 passes.
- “Test-touched bytes” = any app file whose declared type name appears in the test target after comment stripping. This is an **upper bound**; a mention is not a behavioral test. It yields 45.2%.
- UI tests are template methods (`testExample`, `testLaunchPerformance`, `testLaunch`, with one duplicate execution); they launch the app but assert almost nothing.

### Real-data caveats

The real store is the author’s current sandbox data, not a synthetic fixture. It shows what the app actually does at 138k page timings. It is also why some findings are concrete (592 achievements, 0 weather rows, 38 covers for 7 books). It should not be committed or shared.

### What this report is not

- It is not an App Store review; Apple’s current validation rules and the WeatherKit account requirements may add work.
- It is not a security audit; it focuses on completion, correctness, and maintainability.
- It does not modify code. Every finding is a candidate fix, not a shipped change.

---

*End of report. The next session should start with the P0 fixes in §8, baseline green first, and re-run the census at every boundary.*
