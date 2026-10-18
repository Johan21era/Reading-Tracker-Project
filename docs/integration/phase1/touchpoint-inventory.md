# Evidence artifact — cross-codebase touchpoint inventory (Phase 1/2)

PART 1 = Reading Tracker; PART 2 = MirageV1.0. All claims anchored path:line. Verified zero "Mirage" references anywhere in RT (case-insensitive ripgrep over all file types → 0 hits) — the name is free.

## RT critical facts (root `/Users/johanrembeci/Desktop/Reading Tracker Main /`)

### Entry & surfaces
- `@main struct ReadingTrackerApp` — `Reading Tracker/ReadingTrackerApp 2.swift:26-27` (the `" 2"` suffix filename is itself a release-blocker-adjacent drift; audit §6.6). Owns `dataStore` + `coordinator` (one-instance policy :60-64).
- Launch `bind` hooks at :75-103 (`eventRouter.bind` :89-93, `behaviorKit.startMonitoring()` :98) — a Mirage sidecar manager binds here as `@StateObject`/`.task`, mirroring eventRouter.
- UI surfaces for an optional feature: Analytics Menu `NewContentView.swift:261-326` (+ one Button row), sheet harness :447-504 (9 existing `.sheet` presentations — canonical pattern), Windows (`ReadingTrackerApp 2.swift:151-181`). **No `.contextMenu` exists anywhere in RT** — book-context rows would be net-new surface.
- `#if DEBUG` Developer Console: `ReadingTrackerApp 2.swift:122-131` (⌘⇧D) + Window :176-181. Registration: conform to `DeveloperConsoleObservable` (`DeveloperConsoleObservable.swift:70-79`), self-register one line in init (`DeveloperConsoleRegistry.swift:51-55`). `consoleSnapshot` must be cheap + MainActor (:66-69).

### Persistence (single-writer discipline)
- `Core/PersistenceWriter.swift` (58 ln): `final class PersistenceWriter: @unchecked Sendable` :18-25, static `.shared`, serial `DispatchQueue(label:"readingtracker.persistence.writer", qos:.utility)` :23-24; `enqueue(encode:write:)` :30-36 → `Task.detached(.utility)`; `drainSync()` barrier :55-57.
- `Core/DataStore3.swift`: `@MainActor final class DataStore: ObservableObject` :34-35; paths :99-111 (`…/ReadTracker/library.json`, `library-state.json`); degraded fallback → temp dir `ReadTracker-degraded/` :124-139; debounce 0.5 s :62-64 (`scheduleSave` :536-548 bumps `analyticsEpoch` :537 → AnalyticsCache invalidation); `save()`/:586-594, `saveLibraryState()`/:596-604, `enqueueWrite → PersistenceWriter.shared.enqueue` :616-642; `saveImmediately()` = drainSync barrier + sync writes :556-579 (**MainActor-only**).
- `addBook` duplicate check = `books.contains { $0.fileURL == book.fileURL }` :199-207.
- Session/page API: `startSession` :359-376, `recordPageTurn` :378-397 (only PageTiming writer), `endSession` :399-404, `endAllActiveSessions` :407-417, `closeActiveSession` :437-451.
- `SentinelEngine` (`Core/SentinelEngine.swift`): `@MainActor` :90-92; journal `ReadTracker/sentinel-journal.jsonl` :136-141; doctrine S1 writes ONLY `sentinel-*` files + `SentinelQuarantine/`; repairs only through audited APIs (`dataStore.updateBook` :320/330); cycle every 15 min :152-164; kill switch `sentinel.enabled`.
- `LibraryArchiveManager` backups: `…/ReadTracker/Backups/library-<stamp>.json`, newest-10 retention (:149-200, invoked from DataStore init detached :161-166 and `NewContentView.swift:161-220` export/import).

### Reader position (authoritative model)
- `Core/Book2.swift`: `struct Book` :34-81 — `fileURL` :38, `fileType` (epub/pdf) :241-248, `totalPages` :40, **`currentPage: Int`** :41 (persisted), `chapters: [Chapter]` :42, `sessions: [ReadingSession]` :43, `activeSessionID` :44, **security-scoped `bookmarkData: Data?`** :51; `resolveURL()` :121-145 (bookmark resolve w/ `.withSecurityScope`, fallback raw URL; callers must balance start/stopAccessingSecurityScopedResource :113-114 — EPUB file is NOT embedded; unzipped to fresh temp dir per session).
- `Chapter { id,title,index,startPage,endPage }` :338-356; `ReadingSession` :360-412; `PageTiming { pageNumber, startTime, endTime? }` :416-437 (per-page dwell).
- Authoritative position: `Features/Sessions/SessionCoordinator2.swift:23-27` — `currentPage` is "THE single authoritative current page value"; sole writers startReading/turnToPage/restoreSession; `turnToPage` :102-106 → `dataStore.recordPageTurn`.
- PDF: `PDFReaderView2.swift` — page-turn capture = **1 Hz Timer polling** :239-261 (:247 Timer, dedup `lastReportedPage`); scope held until dismantle :119-136; `PDFReaderScreen` wires `onPageChange → coordinator.turnToPage` :351-355, `startReading` on load-success :362-364; RSVP extraction detached :398-421.
- EPUB: `EPUBReaderScreen.swift` — `onAppear` open + startReading :60-83; chapter→startPage mapping :129-134, turnToPage on `goToChapter` :147-158. `EPUBPackage.swift` — `final nonisolated class` :73 (explicit opt-out from MainActor default, header comment :63-72 documents why); `open(book:)` :138-194 (scope→unzip→container.xml/OPF→spine); cancellation-safe cleanup `OpenCleanup` :205-224; ZIPFoundation `unzipItem` :228-234.

### Import & sessions fan-out
- `Features/Library/BookImporter.swift`: facade `importBook(from:)` :53-69 (scope before dispatch, defer release); `importPDF` :75-133 (bookmark, cover detached :114-116); `importEPUB` :188-248 (**page estimate = wordCount/250** :200-201; cover detached :228-231; ZIPFoundation + manual fallback :166-186); `ImportIntelligenceFacade.analyze` :748-772 (called `NewContentView.swift:604-609`).
- `SessionEventRouter2.swift`: `@MainActor` :20-31; binds to `$books.dropFirst().receive(on: RunLoop.main)` :75-81; detects session close by diffing active session IDs :86-98; `runPostSessionCascade` :100-168 = the fan-out hook (weather snapshot :118-122, notifications :127-141, BCE analyze :150-167 — **Mirage post-session trigger retrofits here**). Keep F-12 clear-first re-bind (:62-64).

### Concurrency idioms (under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, project.pbxproj:441-442/477-478)
| Idiom | Anchors |
|---|---|
| Serial utility queue (disk writes) | PersistenceWriter.swift:23-24 |
| `Task.detached(.utility)` | DataStore3.swift:161; BookImporter.swift:114,228,395,407; PersistenceWriter.swift:33 |
| `Task.detached(.userInitiated)` | PDFReaderView2.swift:401; AnnualReportArchiveView2.swift:161; DemoProfileLabView.swift:141 |
| Explicit `nonisolated` types/inits | EPUBPackage.swift:73,205; Book2.swift:149,349,393,431; LibraryArchiveManager :149 |
| nonisolated static encoder | DataStore3.swift:607-612 |
| Timer + `Task { @MainActor in }` handback | PDFReaderView2.swift:247; SessionCoordinator2.swift:190-195; SentinelEngine.swift:158-163; DataStore3.swift:539-543 |
| `await MainActor.run` handback | NewContentView.swift:596-628 (import flow); BookImporter.swift:114-116,228-231 |
| Private serial queues | CoverStore.swift:33; OnlineBookDiscoveryViewModel.swift:31 |
| **Engines/ = zero concurrency (pure statics on MainActor)** | AnalyticsCache.swift:28-30 `@MainActor`, memoized by epoch :32-48,61-66,142-151 |

### Build settings & sandbox (uniform Debug/Release; pbxproj lines Debug/Release)
- `ENABLE_APP_SANDBOX = YES` :424/460; **`ENABLE_USER_SELECTED_FILES = readonly`** :426/462 vs entitlements **read-write** `com.apple.security.files.user-selected.read-write` :12-13 + app-scope bookmarks :15-16 + `network.client` :17-18 + apple-events :25-26. **No `com.apple.security.inherit`** — spawned children do NOT inherit sandbox (children run unsandboxed) but CANNOT reuse security-scoped bookmarks; RT process must own all scoped reads/bytes.
- `PRODUCT_BUNDLE_IDENTIFIER = johan.Reading-Tracker` :437/473; `MACOSX_DEPLOYMENT_TARGET = 26.5` :345/404/435/471; Swift 5.0 mode :445/481; ZIPFoundation 0.9.20 exact-resolved (Package.resolved:10, rev 22787ffb).
- Info plist (custom `Reading-Tracker-Info.plist`): only NSAppleEventsUsageDescription + NSLocationWhenInUseUsageDescription :14-17; `GENERATE_INFOPLIST_FILE = YES` :427/463.

### Runtime dirs (source-verified)
- Library root = `Application Support/ReadTracker/` (DataStore3.swift:99-111; SentinelEngine.swift:138-140; CoverStore.swift:42 `covers/`; audio-profiles.json via DataStore3.swift:112).
- Weather store uses a DIFFERENT root: `Application Support/<bundle-id>/weather_snapshots.sqlite3` (WeatherKitService2.swift:363-377) — precedent that secondary stores may live in either root; Mirage ledger should follow `ReadTracker/` (beside, never inside, the library monolith; not in `Backups/`).

## Mirage critical facts (root `/Users/johanrembeci/Desktop/MirageV1.0`)
- Package `miragev10` v1.0.0; console script `mirage` (pyproject: `[project.scripts] mirage = "miragev10.cli:main"`); `python -m miragev10` works.
- `MirageService` (api/service.py): constructor `def __init__(self, ledger: Ledger)` :32-40 with `ResourceScheduler` (one heavy job, RSS budget 8192 MB — config.py:21); **canonical open `MirageService.open(db_path, migrate=True)` :42-58** runs `ledger.migrate()` + `recover_interrupted_jobs()` :48; `close()` :57-58; context-manager :51-55.
- Full method inventory: version :60, health :67, import_epub :84-174, analyze :176-225 (scheduler.run ticket :213), projection :247-272, search :280-290 (cursor mandatory), cited_claims :292, neighborhood :298, edge_detail :305, history :311, search_eligible :318, checkpoint/verify/reconstruct :326-338, verify_deltas :344, undo_mutation :350, export_graph :374, corrections set :388-443, translate :450, books_list :505-549, remove_edition/remove_book (confirm-gated) :551-566, series set :591-791 (`series_set_read_state(series_id, edition_id, state, cursor_unit?)` :647-657).
- CLI (`cli/__init__.py`): `--db` default `mirage.sqlite3` (CWD-relative — **RT must always pass an absolute path**); `--serve` → `serve(MirageService.open(args.db))` :253-257; `--serve-web` → 127.0.0.1-only ThreadingHTTPServer :259-271 (webserve.py:212).
- NDJSON.dispatcher `run_command(action, payload)` service.py:812-997 (28 actions; unknown → ValidationError 404).
- Domain enums (domain/enums.py): EntityType 8 cases :8-16; ClaimState 4 :19-23; EpistemicStatus 11 :26-37; DisclosureMode :40-43; ContributionRole :46-49; `Cursor` frozen dataclass :52-64.
- Ledger placed by caller: `Ledger.__init__(path)` ledger.py:47-48; sidecar argv[1] = DB path (mirage_sidecar.py:29-36); no env/config resolution.
- `readers/adapters.py` `AdapterPositionResolver` :11+ — reader-position ↔ unit_id mapping platform-versioned, manual fallback persisted in `position_mappings` (schema).

## INTEGRATION TOUCHPOINT TABLE (16 rows)

| # | Touchpoint | Anchor | Integration route | Risk (naive use) |
|---|---|---|---|---|
| 1 | Launch binding | RTApp 2.swift:75-103 | StateObject manager + `.task` like eventRouter.bind | Process IO must hop off main; manager stays MainActor |
| 2 | UI surface | NewContentView.swift:261-326, 447-504 | One menu Button + `.sheet` mirroring 9 existing | `@State` ownership block :108-117; memoized `visibleBooks` :142-155 is render-sensitive |
| 3 | Position→cursor | SessionCoordinator2.swift:23-27 ↔ Mirage Cursor enums.py:52-64 + readers/adapters.py | Map page→unit_index via adapter resolver; never page=unit | 1:1 page→unit corrupts spoiler boundary_key + dangles mappings |
| 4 | Page-turn recording | DataStore3.swift:378-397; PDF poll :247 | Only via `coordinator.turnToPage` on MainActor | Direct off-main calls bust MainActor isolation (whole tree MainActor-default, pbxproj:442) |
| 5 | Session close fan-out | SessionEventRouter2.swift:100-168 | Mirage trigger beside weather/notification blocks | Router is main + RunLoop.main receive (:77); keep F-12 clear-first (:62-64) |
| 6 | Library writes | DataStore3.swift:199-217, 536-548, 586-642 | All Book/LibraryState mutations through DataStore API | Never write library.json from sidecar (bypasses FIFO single-writer, PersistenceWriter.swift:23-24); never `saveImmediately()` off-main (:556-579); new Book fields = optional-only (tolerant decoder Book2.swift:212-236) |
| 7 | EPUB byte access for import | Book2.swift:121-145 resolveURL; EPUBPackage scope discipline :138-194, 205-224 → Mirage ingestion/epub.py:155-250 | RT resolves bookmark, reads bytes/exports copy, per-command; child cannot reuse scope (no inherit entitlement) | Sandboxed scope belongs to RT process; balance start/stop exactly once |
| 8 | Ledger placement & lifecycle | ledger.py:47-63; caller-specified | Absolute RT-owned path e.g. `…/ReadTracker/mirage/mirage.sqlite3` | One sidecar per ledger; migrate() refuses newer schemas → pin SCHEMA_VERSION ledger@0.0.10 |
| 9 | NDJSON transport | serve.py:44-63 (banner first), dispatch service.py:812-997 | Spawn `python3 mirage_sidecar.py <db>`; read banner; 1 req/line off main | Pipe reads on main stall debounce-timed UI; parse error envelope, never raw strings; NO protocol version field — pin via `version` action |
| 10 | Web UI route | webserve.py:69-214 | Keep OUT of RT (server bind from sandboxed app is a feature-negative; NDJSON sidecar only) | S12-ES-3 compliance |
| 11 | Heavy analysis | service.py:176-225 under ResourceScheduler | Only through `run_command("analyze",…)` | Direct `analyze_edition` bypasses single-job + RSS gates |
| 12 | Cache coupling | RT epoch DataStore3.swift:68-73 ↔ Mirage ledger-version cache | Keep independent | Mirage-triggered writes must NOT call scheduleSave() (bumps RT epoch → whole-layer recompute) unless library data actually changed |
| 13 | Dev console row | DevConsoleRegistry.swift:51-55; protocol .swift:70-79 | Conform manager; one `#if DEBUG` register line | Snapshot cheap + MainActor; Referenced Mirage state must exist in Release without DEBUG symbols |
| 14 | Sentinel co-existence | SentinelEngine.swift:136-141, :496-498, :556-571 | Mirage DB beside monolith; never in `Backups/` | StoreWritabilityProbe + DiskSpaceProbe (<200 MB warn) watch the same dir; unknown file types not attended by probes — keep Mirage artifacts isolated |
| 15 | Identity link | RT Book.id UUID (Book2.swift:35) ↔ Mirage fingerprint ids service.py:97-101 | Store explicit (Book.id → book_id/edition_id) pair at import time | Fingerprint ids change when file bytes change → NEW edition, dangled position mappings |
| 16 | Archive/restore | LibraryArchiveManager.swift:78-200; DataStore3.swift:181-192 | Decide whether ledger joins archive (ADR needed) | Restore strands `source_assets.local_path_ref`; keep ledger out of scope until decided |

## Naive-use failure flags (summary)
1. MainActor-default isolation on the whole RT tree — every "quiet" type is MainActor; use the three house idioms only (PersistenceWriter queue; Task.detached + MainActor.run handback; nonisolated value types).
2. PersistenceWriter is the ONLY write path for library JSON — sidecar/writes must never touch `library.json`/`library-state.json` directly, never enqueue non-DataStore data through `PersistenceWriter.shared`, never call `saveImmediately()` off-MainActor.
3. Sandbox: children don't inherit scopes (no `com.apple.security.inherit`); RT owns all scoped bytes; `ENABLE_USER_SELECTED_FILES=readonly` build setting conflicts with read-write entitlements (known release blocker — do not touch for Mirage).
4. EPUB page numbers are synthetic estimates; Mirage cursors are unit indexes — mapping is adapter's job.
5. Two Application-Support roots in play (`ReadTracker/` and `<bundle-id>/`); pick `ReadTracker/mirage/` and own it.
