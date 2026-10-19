# Graph Report - .  (2026-10-18)

## Corpus Check
- 197 files · ~292,984 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3953 nodes · 10769 edges · 178 communities (157 shown, 21 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 528 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Behaviorcontext
- Engines
- Behaviorcontext
- Recommendations
- Library
- Behaviorcontext
- Core
- Developerconsole
- Behaviorcontext
- Behaviorcontext
- Core
- Engines
- Reports
- Notifications
- Reports
- Weather
- Insights
- Reports
- Behaviorcontext
- Behaviorcontext
- Behaviorcontext
- Mirage
- Reading Trackertests
- Discovery
- Core
- Root Docs
- Reading Tracker
- Weather
- Reading Trackertests
- Audio
- Audio
- Mirage
- Engines
- Audio
- Weather
- Engine
- Reading Trackertests
- Audio
- Core
- Mirage
- Rsvp
- Weather
- Mirage
- Phase1
- Weather
- Root Docs
- Core
- Mirage
- Mirage
- Reading Trackertests
- Achievements
- Mirage
- Registers
- Reading Trackertests
- Developerconsole
- Reading Trackertests
- Mirage
- Reading Trackertests
- Integration
- Root Docs
- Core
- Core
- Engine
- Reading Trackertests
- Developerconsole
- Root Docs
- Goals
- Sessions
- Mirage
- Root Docs
- Achievements
- Mirage
- Mirage
- Integration
- Weather
- Library
- Reader
- Reader
- Behaviorcontext
- Behaviorcontext
- Integration
- Reading Trackertests
- Mirage
- Reading Trackertests
- Spatial
- Adr
- Adr
- Adr
- Adr
- Core
- Audio
- Core
- Achievements
- Reading Trackertests
- Behaviorcontext
- Providers
- Weather
- Audits
- History
- Root Docs
- Weather
- Goals
- Root Docs
- Reading Trackertests
- Reading Trackertests
- Adr
- Reader
- Goals
- Audio
- Developerconsole
- Discovery
- Discovery
- Discovery
- Providers
- Reader
- Root Docs
- Reading Trackertests
- Reading Trackeruitests
- Integration
- Engines
- Weather
- Library
- Onboarding
- Developerconsole
- Reading Trackertests
- Core
- History
- Behaviorcontext
- Behaviorcontext
- Weather
- Root Docs
- Reading Trackertests
- Reading Trackertests
- Reading Trackertests
- Reading Trackertests
- Root Docs
- Integration
- Engines
- Behaviorcontext
- Developerconsole
- Sessions
- Reading Trackertests
- Rsvp
- Tib
- Behaviorcontext
- Spatial
- Reading Trackertests
- Discovery
- Goals
- Reader
- Sessions
- Reading Tracker
- Engines
- Mirage
- History
- Reading Trackertests
- Integration
- Scripts
- Integration
- Scripts
- Scripts
- Audits
- Audits
- Audits
- History
- History
- History
- History
- History
- History
- History
- Integration
- Integration
- Integration
- Tib
- Tib
- Roadmap
- Root Docs

## God Nodes (most connected - your core abstractions)
1. `DataStore` - 113 edges
2. `Foundation` - 104 edges
3. `BehavioralEnvironmentType` - 62 edges
4. `ReadingGenre` - 60 edges
5. `ReadingSession` - 58 edges
6. `ContextConfidence` - 53 edges
7. `ReadingContextRecord` - 50 edges
8. `RT ⇄ Mirage Integration Merge Log (append-only session log)` - 49 edges
9. `BehavioralEvent` - 47 edges
10. `WeatherAnalysisEngine` - 46 edges

## Surprising Connections (you probably didn't know these)
- `mirage/ stratum (Mirage-write territory, RT never writes)` --semantically_similar_to--> `Ledger stratum: ReadTracker/mirage/mirage.sqlite3 (exclusive Mirage-write territory)`  [INFERRED] [semantically similar]
  README.md → docs/integration/adr/ADR-4-ledger-placement-and-backup-ownership.md
- `MirageWireTypes (immutable version-gated wire contract)` --conceptually_related_to--> `Managed stdio NDJSON sidecar transport decision`  [INFERRED]
  README.md → docs/integration/adr/ADR-2-transport-and-protocol.md
- `Winter Romantic persona (≈620 sessions / 185,000 page-timings)` --shares_data_with--> `library.json JSON monolith (books/sessions/page-timings)`  [EXTRACTED]
  docs/history/LAST_DEFEAT_demo_profiles.txt → README.md
- `Reading Tracker (macOS reading-tracker app)` --conceptually_related_to--> `MirageV1.0 (local-first, spoiler-safe literary knowledge graph)`  [INFERRED]
  README.md → docs/integration/Twin-READMES-2026-10-18.md
- `Mirage integration (typed one-way boundary)` --conceptually_related_to--> `Fail-Closed Identity (no title inference; degrade instead of guess)`  [INFERRED]
  README.md → docs/integration/adr/ADR-5-identity-mapping.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Fail-closed doctrine family (no synthesis / no inference under uncertainty)** — docs_integration_adr_adr_5_identity_mapping_fail_closed_identity, docs_integration_adr_adr_7_spoiler_cursor_contract_fail_closed_cursor, docs_integration_twin_readmes_2026_10_18_spoiler_visibility, docs_integration_adr_adr_2_transport_and_protocol_protocol_incompatible_mask, docs_integration_pr5_execution_plan_2026_10_18_id_synth_rule [INFERRED 0.85]
- **Mirage strata ownership (ledger / identity / RT territory, disjoint write-sets)** — docs_integration_adr_adr_4_ledger_placement_and_backup_ownership_ledger_stratum, docs_integration_adr_adr_5_identity_mapping_identity_map_json, readme_mirage_stratum, docs_integration_adr_adr_4_ledger_placement_and_backup_ownership_disjoint_write_sets [INFERRED 0.85]
- **Sidecar transport stack (managed stdio NDJSON + raw read(2) fix)** — docs_integration_adr_adr_2_transport_and_protocol_managed_sidecar, docs_integration_pr4_defect_analysis_2026_10_18_mirageprocesstransport, docs_integration_pr4_defect_analysis_2026_10_18_miragechildprocess, docs_integration_pr4_defect_analysis_2026_10_18_miragesidecarsupervisor, readme_mirage_wire_types [INFERRED 0.85]
- **Eight-PR Integration Ladder (PR-1…PR-8 under the Playbook)** — docs_integration_merge_log_pr_1, docs_integration_merge_log_pr_2, docs_integration_merge_log_pr_3, docs_integration_merge_log_pr_4, docs_integration_merge_log_pr_5, docs_integration_merge_log_pr_6, docs_integration_merge_log_pr_7, docs_integration_merge_log_pr_8, docs_integration_merge_log_merge_playbook [EXTRACTED 1.00]
- **TB-M0 Observe-Mode Instrument Chain (manifest → verify → ledger)** — docs_integration_merge_log_adr_12, docs_integration_tib_tb_m0_gate_plan_tb_m0, docs_integration_tib_tb_m0_gate_plan_tb_m0_gate_plan, docs_integration_tib_tb_m0_gate_plan_subset_manifest, docs_integration_tib_tb_m0_gate_plan_verify_instrument, docs_integration_tib_tb_m0_gate_plan_tamper_drill, docs_integration_tib_observe_ledger_observe_ledger [EXTRACTED 1.00]
- **Closing Owner Round 2026-10-18 (four signatures: ratify/accept/countersign)** — docs_integration_merge_log_adr_6, docs_integration_merge_log_adr_3, docs_integration_adr_adr_8_repository_strategy_adr_8, docs_integration_merge_log_adr_12 [EXTRACTED 1.00]

## Communities (178 total, 21 thin omitted)

### Community 0 - "Behaviorcontext"
Cohesion: 0.03
Nodes (78): AsyncStream, IOKit, IOKit.pwr_mgt, ActivityResumptionEvent, ApplicationBehaviorProfile, ApplicationDescriptor, ApplicationSessionReconstructor, BehavioralAdvancedQuery (+70 more)

### Community 1 - "Engines"
Cohesion: 0.06
Nodes (53): ClaimRequirement, CustomStringConvertible, ClaimDecision, ClaimDisposition, blocked, displayableFull, displayableSoftened, ClaimRegistry (+45 more)

### Community 2 - "Behaviorcontext"
Cohesion: 0.08
Nodes (71): Codable, Element, Hashable, Identifiable, BehavioralEvidenceSource, AdvancedRoutineAnalysis, AdvancedSignificanceAssessment, BehavioralCorrelation (+63 more)

### Community 3 - "Recommendations"
Cohesion: 0.07
Nodes (43): ReadingGenre, biography, business, children, education, fantasy, fiction, historical (+35 more)

### Community 4 - "Library"
Cohesion: 0.05
Nodes (54): Character, Compression, NSSize, PDFDocument, PDFOutline, decodeHTMLEntities(), decodeNumericEntities(), extractPlainSentences() (+46 more)

### Community 5 - "Behaviorcontext"
Cohesion: 0.05
Nodes (31): Notification, NSObjectProtocol, ApplicationUsageSession, BehavioralArchive, BehavioralEventStore, BehavioralEvidenceBuffer, BehavioralQuery, BehaviorContextAccessKit (+23 more)

### Community 6 - "Core"
Cohesion: 0.06
Nodes (36): SentinelDataBridge, AchievementDriftProbe, DeadlineOverdueProbe, DiskSpaceProbe, IntegrityProbe, OrphanedActiveSessionProbe, Outcome, autoFixed (+28 more)

### Community 7 - "Developerconsole"
Cohesion: 0.04
Nodes (42): AnyObject, ObservableObject, BehavioralObserverDiagnostics, DeveloperConsoleObservable, DeveloperConsoleStaticObservable, DeveloperConsoleRegistry, DeveloperConsoleStaticEngineManifest, Int (+34 more)

### Community 8 - "Behaviorcontext"
Cohesion: 0.06
Nodes (30): AdvancedRoutineDetector, AdvancedSignificanceEngine, AnalyticsContextEnrichment, bceAppendShannonEntropy(), BehavioralEnvironmentType, administrative, browsing, creative (+22 more)

### Community 9 - "Behaviorcontext"
Cohesion: 0.06
Nodes (30): BehavioralDiversityAnalyzer, BehavioralDiversityProfileBuilder, BehavioralSequenceAnalyzer, ContextAnalysisPipeline, ContextCorrelationAnalyzer, ContextDistributionAnalyzer, ContextEvidenceChainBuilder, ContextTrendAnalyzer (+22 more)

### Community 10 - "Core"
Cohesion: 0.09
Nodes (19): IndexSet, LibraryState, DataStore, PersistenceStatus, degraded, healthy, Book, Bool (+11 more)

### Community 11 - "Engines"
Cohesion: 0.11
Nodes (22): AnalyticsConstants, AnalyticsEngine, BookForecastAnalytics, ChapterPredictionAnalytics, ConfidenceAnalytics, GenreAnalyticsSummary, GenreProfile, ImprovementAnalytics (+14 more)

### Community 12 - "Reports"
Cohesion: 0.12
Nodes (25): ReadingSession, AnnualReportArchiveView, Bool, Int, analyticsPeriod(), AnnualReportData, AnnualReportGenerator, availableReportYears() (+17 more)

### Community 13 - "Notifications"
Cohesion: 0.14
Nodes (25): clamp(), IntelligentNotificationEngine, IntelligentNotificationResult, NotificationAnalytics, NotificationBehaviorProfile, NotificationCandidate, NotificationCategory, achievementMilestone (+17 more)

### Community 14 - "Reports"
Cohesion: 0.07
Nodes (29): CelebrationPhase, exiting, expanding, fullscreen, toast, CelebrationTimeline, DebugCelebrationBus, NewYearCelebrationOverlay (+21 more)

### Community 15 - "Weather"
Cohesion: 0.10
Nodes (18): CurrentWeather, Forecast, HourWeather, Date, EnvironmentalSessionAssembler, ReadingSessionMetrics, Bool, Date (+10 more)

### Community 16 - "Insights"
Cohesion: 0.09
Nodes (30): Int, ReaderProfileAnalytics, Array, InsightEngine, InsightKind, bestReadingTime, consistencyReward, difficultyMatch (+22 more)

### Community 17 - "Reports"
Cohesion: 0.10
Nodes (22): ContextInsightPanel, RoutineRow, Int, String, AchievementsSlide, AnnualReportView, GoalsSlide, HighlightCard (+14 more)

### Community 18 - "Behaviorcontext"
Cohesion: 0.07
Nodes (37): CaseIterable, AudioBehaviorEvolution, InsightCategory, behaviorShift, distractionPattern, genrePreference, optimalEnvironment, preferredSoundtrack (+29 more)

### Community 19 - "Behaviorcontext"
Cohesion: 0.12
Nodes (14): DateInterval, BehavioralContextSummary, BehavioralRoutine, BehaviorContextEngine, BehaviorEvidence, ContextProfile, ContextTransition, ContextWindow (+6 more)

### Community 20 - "Behaviorcontext"
Cohesion: 0.06
Nodes (36): BehavioralSignificanceClassification, dominantBehavior, incidentalNoise, moderateSignal, strongSignal, weakSignal, BehaviorCategory, administrative (+28 more)

### Community 21 - "Mirage"
Cohesion: 0.10
Nodes (27): work, MirageBannerFault, notJSON, statusNotReady, MirageChildChannels, MirageJSONValue, MirageOnceCloser, MirageProcessTransport (+19 more)

### Community 22 - "Reading Trackertests"
Cohesion: 0.12
Nodes (9): CryptoKit, Foundation, Reading_Tracker, AnalyticsCache, Int, MirageCursor, MirageRealEngineSmokeTests, Reading_TrackerTests (+1 more)

### Community 23 - "Discovery"
Cohesion: 0.13
Nodes (21): LocalizedError, DemoProfileLabView, Book, DemoBookSpec, DemoInstallSummary, DemoLabError, unknownProfile, DemoPersona (+13 more)

### Community 24 - "Core"
Cohesion: 0.14
Nodes (30): Book, BookCollection, BookFileType, epub, pdf, BookNote, Chapter, DailyActivity (+22 more)

### Community 25 - "Root Docs"
Cohesion: 0.05
Nodes (29): NavigationSplitViewVisibility, SentinelReportCardView, Int, String, Void, OnlineBook, OnlineBookDetailView, OnlineBook (+21 more)

### Community 26 - "Reading Tracker"
Cohesion: 0.09
Nodes (25): DispatchWorkItem, EarnedAchievement, AchievementToastView, BookEstimationView, ContentBookRowView, ContentView, LibrarySortMode, author (+17 more)

### Community 27 - "Weather"
Cohesion: 0.17
Nodes (24): Array, coefficientOfVariation(), ConditionBucket, ConfidenceReport, CorrelationAccumulator, EnvironmentalBehaviorReport, EnvironmentalBehaviorSnapshot, EnvironmentalEvolutionFinding (+16 more)

### Community 28 - "Reading Trackertests"
Cohesion: 0.11
Nodes (17): Fault, correlationFailure, envelopeShapeInvalid, responseUnparsable, MirageClient, Outcome, engineError, success (+9 more)

### Community 29 - "Audio"
Cohesion: 0.21
Nodes (5): AudioSessionRecord, AudioCorrelation, MusicalAnalysisEngine, Book, Double

### Community 30 - "Audio"
Cohesion: 0.14
Nodes (14): CoreAudio, NSAppleEventDescriptor, AudioMonitorService, AudioTrackMetadata, DetectionResult, Bool, Double, Int (+6 more)

### Community 31 - "Mirage"
Cohesion: 0.06
Nodes (32): Encodable, object, MirageWireAction, analyze, bookRemove, booksList, checkpoint, citedClaims (+24 more)

### Community 32 - "Engines"
Cohesion: 0.20
Nodes (15): BookEstimationResult, ChapterEstimation, ConfidenceModel, EstimationEngine, ReadingContext, SpeedComponents, SpeedModel, Book (+7 more)

### Community 33 - "Audio"
Cohesion: 0.13
Nodes (22): AudioCategory, ambientSoundscape, audioBook, music, podcast, silence, spokenWord, unknown (+14 more)

### Community 34 - "Weather"
Cohesion: 0.20
Nodes (4): EnvironmentalCorrelation, EnvironmentalSessionRecord, Bool, WeatherAnalysisEngine

### Community 35 - "Engine"
Cohesion: 0.10
Nodes (20): Duration, AnchorClock, EnvironmentAnchorPeriod, afternoon, midday, morning, night, Calendar (+12 more)

### Community 36 - "Reading Trackertests"
Cohesion: 0.19
Nodes (16): MirageSidecarSupervisor, MirageHandshakePinTests, CountingLauncher, LaunchCounter, makeMirageTestTempDir(), makeStubSupervisorConfig(), makeStubTransportConfig(), mirageTestHex() (+8 more)

### Community 37 - "Audio"
Cohesion: 0.15
Nodes (21): AudioCharacteristics, AudioContextProfile, AudioSnapshot, InferredMood, calm, energetic, focused, melancholic (+13 more)

### Community 38 - "Core"
Cohesion: 0.11
Nodes (17): LibraryArchive, LibraryArchiveError, corruptArchive, emptyLibrary, LibraryArchiveManager, Book, Bool, Data (+9 more)

### Community 39 - "Mirage"
Cohesion: 0.12
Nodes (19): MirageCursor, MirageCursor, absent, estimated, page, unit, MirageCursorGate, MirageCursorGateError (+11 more)

### Community 40 - "Rsvp"
Cohesion: 0.13
Nodes (14): NaturalLanguage, RSVPPlaybackEngine, Double, Int, Never, String, Task, Void (+6 more)

### Community 41 - "Weather"
Cohesion: 0.08
Nodes (24): OpaquePointer, DayPeriod, afternoon, dawn, evening, morning, night, WeatherConditionCategory (+16 more)

### Community 42 - "Mirage"
Cohesion: 0.11
Nodes (22): MirageIdentityMapEntry, MirageIdentityMapFile, MirageIdentityMapLoad, loaded, unreadable, MirageIdentityMapSchema, MirageIdentityMapStore, MirageIdentityMapTime (+14 more)

### Community 43 - "Phase1"
Cohesion: 0.11
Nodes (29): .github/workflows/census.yml (CI census receipt), OPE-004 — Real-Engine Smoke (env-gated, disposable DB), Operation Risk Classes (Class Ω / Δ / Π ownersign gates), PR4-defect-analysis-2026-10-18 (BUG-stripe campaign of record), RT ⇄ Mirage Integration Merge Log (append-only session log), Titanium Bridge (TiB) Era — §22 charter execution, Mirage ADR-0001 (deterministic classical-only, no network providers), Mirage ADR-0002 (Rust core demoted; Python API only sanctioned surface) (+21 more)

### Community 44 - "Weather"
Cohesion: 0.11
Nodes (20): CheckedContinuation, CLLocation, CLLocationManager, CLLocationManagerDelegate, CoreLocation, Error, LocationError, permissionDenied (+12 more)

### Community 45 - "Root Docs"
Cohesion: 0.09
Nodes (19): CoreGraphics, DesignGrid, CGFloat, Double, Star, CGFloat, CGPoint, Double (+11 more)

### Community 46 - "Core"
Cohesion: 0.07
Nodes (28): CodingKeys, activeSessionID, author, bookmarkData, chapters, collectionIDs, collections, coverImageData (+20 more)

### Community 47 - "Mirage"
Cohesion: 0.10
Nodes (12): MirageAnalysisSheet, MirageStatusSection, Book, MirageAppImportMount, MirageSupportPaths, Book, URL, MirageStatusController (+4 more)

### Community 48 - "Mirage"
Cohesion: 0.09
Nodes (21): Decodable, Equatable, Self, Status, done, idle, running, MirageJSONValue (+13 more)

### Community 49 - "Reading Trackertests"
Cohesion: 0.14
Nodes (10): repaired, DataStorePersistenceTests, LibraryMutationTests, Book, Data, Int, String, URL (+2 more)

### Community 50 - "Achievements"
Cohesion: 0.08
Nodes (26): AchievementKind, annualGoalMet, books10, books25, books5, books52, deepReader, firstBook (+18 more)

### Community 51 - "Mirage"
Cohesion: 0.17
Nodes (13): Bool, MirageFileStat, MirageImportEnvironment, MirageImportFlow, MirageImportSource, MirageSourceFingerprint, Bool, Date (+5 more)

### Community 52 - "Registers"
Cohesion: 0.13
Nodes (25): Merge Log Milestones (M-001…M-034), RT_Mirage_Codebase_Merge_Playbook v1.3 (governing document), PR5-execution-plan-2026-10-18, Feature-Module Isolation Doctrine (self-contained module, zero feature deps), Fix-Finality Triad (Finality statement + fix-log entry + pinned test), 07 · Testing Strategy (bands, census discipline, house conventions), F-01 — Calendar Crash in Annual Reports (Critical, fixed Phase 1, NonGregorianCalendarTests pin), F-02 — New Year Celebration Timer Chain (High, redesigned P1.6) (+17 more)

### Community 53 - "Reading Trackertests"
Cohesion: 0.12
Nodes (9): AnalyticsCachePinsTests, Book, String, URL, CoverStorePinsTests, Book, Bool, Data (+1 more)

### Community 54 - "Developerconsole"
Cohesion: 0.12
Nodes (16): DeveloperConsoleDashboardView, DeveloperConsoleKnownSubsystem, DeveloperConsoleKnownSubsystems, FlaggedItem, Bool, String, ConsolePalette, OnlineBookRow (+8 more)

### Community 55 - "Reading Trackertests"
Cohesion: 0.15
Nodes (12): SeasonalPeriod, autumn, spring, summer, winter, Double, URL, UUID (+4 more)

### Community 56 - "Mirage"
Cohesion: 0.09
Nodes (22): String, MirageOutcomeCopy, String, MirageIdentityState, linked, mapUnreadable, notImported, orphaned (+14 more)

### Community 57 - "Reading Trackertests"
Cohesion: 0.25
Nodes (10): Data, Fixture, mirageBooksListFixture(), MirageIdentityDriftTests, mirageReceiptFixture(), Bool, Data, Sendable (+2 more)

### Community 58 - "Integration"
Cohesion: 0.16
Nodes (24): ADR-8 — Repository Strategy (Two Canonical Repositories, One Verified Vendor), Verified Vendor Pattern (byte-verbatim, digest re-verifiable, refusal pins), OPE-001 — Class Δ Stub-Cover Deletion (38 files, archived list), §19 Evidence Bundle — Assembly Manifest (2026-10-18), §18 Final Acceptance Checklist (2026-10-18, ladder complete), ADR-5 — Identity Mapping (fail-closed receipt-born entries), ADR-6 — Feature Lifecycle (mirage.enabled one switch), ADR-6a — NEW-DE-5 Import-Independence Discharge (+16 more)

### Community 59 - "Root Docs"
Cohesion: 0.12
Nodes (14): Animation, RandomNumberGenerator, SeededGenerator, UInt64, EnvironmentBackgroundView, CGSize, ShootingStarManager, CGSize (+6 more)

### Community 60 - "Core"
Cohesion: 0.20
Nodes (9): AnalyticsCache, Signature, Book, Bool, Double, Int, UInt64, UUID (+1 more)

### Community 61 - "Core"
Cohesion: 0.17
Nodes (15): DataIntegrityValidator, SchemaVersion, v1, v2, v3, Severity, error, warning (+7 more)

### Community 62 - "Engine"
Cohesion: 0.16
Nodes (14): EnvironmentColor, EnvironmentGradientStop, Double, String, EnvironmentPalette, EnvironmentPaletteSnapshot, Double, TimedKeyframe (+6 more)

### Community 63 - "Reading Trackertests"
Cohesion: 0.16
Nodes (9): MirageStatusInventory, MirageJSONValue, EngineFixture, MirageStatusSurfaceTests, RecordingBooksListTransport, Data, MirageIdentityMapEntry, String (+1 more)

### Community 64 - "Developerconsole"
Cohesion: 0.10
Nodes (19): DeveloperConsoleRootView, DeveloperConsoleSection, architectureExplorer, dashboard, deadCode, demoLab, dependencyGraph, errorCenter (+11 more)

### Community 65 - "Root Docs"
Cohesion: 0.14
Nodes (14): EnvironmentMath, ClosedRange, Double, ShootingStar, CGPoint, CGSize, Date, Double (+6 more)

### Community 66 - "Goals"
Cohesion: 0.27
Nodes (10): GoalStatusCard, String, BookDeadlineStatus, GoalStatus, ReadingGoalManager, Book, Double, Int (+2 more)

### Community 67 - "Sessions"
Cohesion: 0.17
Nodes (10): App, SessionCoordinator, Bool, Date, Int, TimeInterval, Timer, UUID (+2 more)

### Community 68 - "Mirage"
Cohesion: 0.12
Nodes (18): Darwin, Blocker, engineUnavailable, permanentDown, protocolIncompatible, describe(), MirageSidecarAttemptFailure, restartable (+10 more)

### Community 69 - "Root Docs"
Cohesion: 0.14
Nodes (15): NSObject, os, Coordinator, EPUBChapterWebView, Context, Coordinator, Error, URL (+7 more)

### Community 70 - "Achievements"
Cohesion: 0.15
Nodes (13): AchievementDefinition, AchievementTier, bronze, gold, platinum, silver, AchievementBadge, AchievementDetailPopover (+5 more)

### Community 71 - "Mirage"
Cohesion: 0.14
Nodes (15): Channel, engineVerified, localMap, LinkState, linked, mapUnreadable, notImported, orphaned (+7 more)

### Community 72 - "Mirage"
Cohesion: 0.20
Nodes (11): Bundle, MirageDevChannel, MirageRuntime, MirageRuntimeChannel, bundled, dev, MirageRuntimeLocator, MirageRuntimeManifest (+3 more)

### Community 73 - "Integration"
Cohesion: 0.11
Nodes (20): ADR-2: integration transport & protocol (managed stdio NDJSON sidecar), id-echo request correlation, Pipe I/O on nonisolated worker (no MainActor-blocked work ≥5 ms), Managed stdio NDJSON sidecar transport decision, S12-ES-3: localhost is not a trusted call (HTTP disabled inside RT), S2-ES-4 wire discipline (one compact JSON per LF line, no invented fields), Single-instance supervision + bounded restart (≤3 attempts, 2/4/8 s backoff), BUG-001: batch-context silent stdout wedge (+12 more)

### Community 74 - "Weather"
Cohesion: 0.10
Nodes (20): ReadingBehaviorMetric, abandonmentLikelihood, bookLength, booksCompleted, chaptersCompleted, completionLikelihood, complexity, difficulty (+12 more)

### Community 75 - "Library"
Cohesion: 0.15
Nodes (17): BookRowView, LibraryFilter, all, epub, pdf, LibraryFilterBarView, LibraryHeaderView, LibrarySearchBarView (+9 more)

### Community 76 - "Reader"
Cohesion: 0.24
Nodes (8): EPUBPackage, EPUBSpineItem, OpenCleanup, ParsedOPF, Book, Int, String, URL

### Community 77 - "Reader"
Cohesion: 0.17
Nodes (9): PDFView, PDFViewDelegate, Coordinator, CGFloat, CGSize, Context, Coordinator, Timer (+1 more)

### Community 78 - "Behaviorcontext"
Cohesion: 0.12
Nodes (15): BehavioralEventType, applicationActivated, applicationDeactivated, applicationLaunched, applicationTerminated, deviceSleep, deviceStateTransition, deviceWake (+7 more)

### Community 79 - "Behaviorcontext"
Cohesion: 0.12
Nodes (15): Configuration, ContextWindowPreset, custom, extended, fullDay, narrow, standard, DynamicContextWindowSelector (+7 more)

### Community 80 - "Integration"
Cohesion: 0.15
Nodes (18): §15.4 Operational Handoff Bundle (2026-10-18), Honest Deltas (five ledgered, not acceptance-blocking), ADR-2 — Transport & Protocol (managed stdio NDJSON sidecar), ADR-4 — Ledger Placement & Backup Ownership (mirage/ write territory), BUG-001 — Batch-context stdout wedge (H2 machinery-local, C2 raw read(2)), MirageSidecarSupervisor (state machine, pid-file guard, [2,4,8] backoff), MirageWireTypes / MirageClient / MirageTransport (typed 28-action boundary), PR-3 — Mirage Host Interface + Typed Wire (56bf5d8) (+10 more)

### Community 81 - "Reading Trackertests"
Cohesion: 0.14
Nodes (7): GoalEditorPane, GoalPersistenceTests, RebindIdempotenceTests, Book, Bool, String, URL

### Community 82 - "Mirage"
Cohesion: 0.20
Nodes (6): MirageAnalyzeSession, MirageProcessLauncher, MiragePythonLocator, String, URL, MirageZBootDiagnosticTests

### Community 83 - "Reading Trackertests"
Cohesion: 0.21
Nodes (6): MirageBundledRuntimeTests, Bool, Data, MirageJSONValue, String, URL

### Community 84 - "Spatial"
Cohesion: 0.13
Nodes (13): BookVisualState, RotationStyle, flat, threeDimensional, Bool, CGSize, Double, View (+5 more)

### Community 85 - "Adr"
Cohesion: 0.14
Nodes (16): Census receipt upload (merge-presence receipt artifact), Census CI workflow (census.yml), 01 · Project Tree (repository file map), ADR-3: packaged runtime distribution (engine + interpreter bundled), Clean-machine gate (fresh-clone build + bundle spawn + census subset), MirageBundledRuntimeTests, Pinned python-build-standalone CPython (relocatable, redistributable), RUNTIME-MANIFEST.json (pinned checksums, honest provenance) (+8 more)

### Community 86 - "Adr"
Cohesion: 0.15
Nodes (16): NEW-DE-5: onboarding import bypass + goal-set clobber, Runtime locator ladder (bundled → dev gate → unavailable copy), MIRAGE_REAL_ENGINE_DIR dev-opt-in gate, Content-derived EPUB identity (edition_<digest>), identityDrift rule (RT recomputes byte-hash vs sourceFingerprint), reused:true idempotent import receipt, ADR-6a: Mirage import-path independence (NEW-DE-5 discharge), Independence-by-construction argument (no addBook, no goal machinery) (+8 more)

### Community 87 - "Adr"
Cohesion: 0.16
Nodes (16): ADR-12: Titanium Bridge (TiB) charter, Generation model inviolable (whole-directory atomic swap only), TB-M0...TB-M5 owner-gated milestones (gates are the only brake), Owner custody of promotion signing keys (fail-closed on unsigned material), Titanium Bridge (continuous convergence: same bytes inside RT by +1 min), Two rings, one bridge (dev ring flag / release ring gates), Bundled runtime decision (RT.app/Contents/Resources/mirage-runtime), ADR-6: Mirage feature lifecycle (canonical §17 seat) (+8 more)

### Community 88 - "Adr"
Cohesion: 0.17
Nodes (16): mirageProtocolIncompatible mask (feature masked to status row), ADR-5: identity-mapping contract (RT Book ↔ Mirage book/edition), degraded_import receipt rejected as mapping input, Fail-Closed Identity (no title inference; degrade instead of guess), MirageIdentityDriftTests, MirageIdentityMapContractTests, ADR-7: spoiler-cursor contract (+ S10-ES-3 annex), Fail-closed cursor refusals (CURSOR-MISSING / SPOILER-CURSOR-UNVERIFIED / SPOILER-PROBE-REJECTED) (+8 more)

### Community 89 - "Core"
Cohesion: 0.27
Nodes (8): CoverStore, Bool, CGFloat, Data, NSImage, String, URL, UUID

### Community 90 - "Audio"
Cohesion: 0.12
Nodes (16): AudioFactor, albumIdentity, artistIdentity, audioCategory, audioSource, dayOfWeek, genreCategory, genreEnergy (+8 more)

### Community 91 - "Core"
Cohesion: 0.14
Nodes (8): AppKit, Combine, Network, Book, BookCoverThumbnail, Bool, CGFloat, NSImage

### Community 92 - "Achievements"
Cohesion: 0.25
Nodes (8): AchievementEngine, Book, Bool, Date, Int, Set, UUID, Void

### Community 93 - "Reading Trackertests"
Cohesion: 0.27
Nodes (6): BehavioralSessionGapAnalyzer, FatigueIndicatorAnalyzer, FatigueAnalyzerTests, Double, Int, UUID

### Community 94 - "Behaviorcontext"
Cohesion: 0.13
Nodes (15): RoutineCategory, activityAssociated, afternoonReading, emergingRoutine, entertainmentTransition, eveningReading, lateNightReading, learningTransition (+7 more)

### Community 95 - "Providers"
Cohesion: 0.19
Nodes (12): CodingKeys, authorName, coverI, isbn, key, title, OpenLibraryDocument, OpenLibraryProvider (+4 more)

### Community 96 - "Weather"
Cohesion: 0.13
Nodes (15): EnvironmentalFactor, cloudCover, dayPeriod, feelsLikeTemperature, humidity, month, pressure, rain (+7 more)

### Community 97 - "Audits"
Cohesion: 0.15
Nodes (14): BCE Phase-2 dead scaffold (81% dormant), Deep Audit RA-DEEP-20261017, NEW-DE-1: PersistenceWriter stale-overwrite window, NEW-DE-2: Explore/spatial cards never show real covers, NEW-DE-3: crash-window time inflation, NEW-DE-4: AnalyticsCache stale across midnight, 09 · Final Traces performance marathon, Upgrade #4 safe slice: PersistenceWriter owned serial queue (+6 more)

### Community 98 - "History"
Cohesion: 0.14
Nodes (14): EnvironmentObject.error() fatal assertion on main thread, freeze.txt — 5-second sample capture of frozen app (pid 68556, Aug 30 2026), AchievementEngine (badge thresholds walker), DemoDataService (fabricates deterministic fake history), THE LAST DEFEAT — demo profile freeze saga, DemoProfileLabView (console screen with Install button), GoalProgressViewModel (progress calculator on main), LibraryBatchUpdate bracket (suspend listeners during bulk swap) (+6 more)

### Community 99 - "Root Docs"
Cohesion: 0.19
Nodes (9): Comparable, ClosedRange, Self, MirageProtocolConstants, SemVer, Bool, Data, Int (+1 more)

### Community 100 - "Weather"
Cohesion: 0.30
Nodes (5): CorrelationRow, Bool, String, WeatherInsightPanel, WeatherStatCard

### Community 101 - "Goals"
Cohesion: 0.18
Nodes (9): DeadlineEditorPane, MirageSettingsPane, RSVPSettingsPane, SentinelSettingsPane, SettingsRootView, Date, Double, String (+1 more)

### Community 102 - "Root Docs"
Cohesion: 0.20
Nodes (11): SpatialNavigatorCard, Book, Bool, CGFloat, Void, SpatialNavigatorView, Book, Bool (+3 more)

### Community 103 - "Reading Trackertests"
Cohesion: 0.38
Nodes (6): MirageAnalysisStatus, CountingRunner, MiragePageTurnNonTriggerTests, Book, Bool, Int

### Community 104 - "Reading Trackertests"
Cohesion: 0.31
Nodes (6): MirageIdentityMapContractTests, MirageIdentityMapEntry, MirageIdentityMapEntry, String, URL, UUID

### Community 105 - "Adr"
Cohesion: 0.15
Nodes (13): Operational handshake (health banner → version → api_version pin), ADR-4: ledger placement & backup ownership, Ledger backup ownership = Mirage's own doctrine (RT never fabricates ledger backups), S0-ES-3 disjoint write-sets doctrine, Ledger.backup is in-process only (not a NDJSON action), Ledger stratum: ReadTracker/mirage/mirage.sqlite3 (exclusive Mirage-write territory), MirageLedgerPathPinsTests, MirageRestoreInvarianceTests (+5 more)

### Community 106 - "Reader"
Cohesion: 0.26
Nodes (8): NSViewRepresentable, PDFKit, PDFReaderScreen, PDFReaderView, Book, Int, String, Void

### Community 107 - "Goals"
Cohesion: 0.28
Nodes (8): Decoder, BookDeadline, GoalProgressViewModel, ReadingGoalSet, Bool, Date, TimeInterval, UUID

### Community 108 - "Audio"
Cohesion: 0.15
Nodes (13): AudioSource, appleMusicApp, audiobooksApp, chromeBrowser, firefoxBrowser, iinaPlayer, podcastsApp, quickTimePlayer (+5 more)

### Community 109 - "Developerconsole"
Cohesion: 0.19
Nodes (5): SentinelPaneView, Story, Bool, Date, Int

### Community 110 - "Discovery"
Cohesion: 0.23
Nodes (11): AvailabilityState, free, referenceOnly, unknown, BookSource, gutenberg, openLibrary, worldCat (+3 more)

### Community 111 - "Discovery"
Cohesion: 0.36
Nodes (5): BookDiscoveryService, Bool, Int, OnlineBook, String

### Community 112 - "Discovery"
Cohesion: 0.24
Nodes (7): BookDiscoveryViewModel, Bool, Never, OnlineBook, String, Task, Void

### Community 113 - "Providers"
Cohesion: 0.27
Nodes (9): BookProvider, GutenbergProvider, GutendexAuthor, GutendexBook, GutendexFormats, GutendexResponse, Int, OnlineBook (+1 more)

### Community 114 - "Reader"
Cohesion: 0.24
Nodes (7): EPUBReaderScreen, Book, Bool, Int, Never, String, Task

### Community 115 - "Root Docs"
Cohesion: 0.21
Nodes (11): BreakdownGrid, RecommendationCard, RecommendationPanel, ScoreGauge, Book, Bool, Double, Int (+3 more)

### Community 116 - "Reading Trackertests"
Cohesion: 0.24
Nodes (6): CountingRunnerForLifecycle, MirageFeatureLifecycleTests, Book, Bool, Int, MirageIdentityMapEntry

### Community 117 - "Reading Trackeruitests"
Cohesion: 0.17
Nodes (5): Reading_TrackerUITests, Reading_TrackerUITestsLaunchTests, Bool, XCTest, XCTestCase

### Community 118 - "Integration"
Cohesion: 0.17
Nodes (12): docs/integration/ merge-campaign chapter, Page-turn non-trigger pin (no Mirage calls from reader events), ADR register (§17, ADR-1...ADR-11 slots), Explicit non-goals (no store unification, no repo deletion, no auto-analysis), RT Mirage Codebase Merge Playbook (governing playbook), MirageIntegration module (typed integration boundary), Parent-child hierarchy (RT parent app, Mirage optional capability), D-010 corrections overlay (audited, append-only, never book truth) (+4 more)

### Community 119 - "Engines"
Cohesion: 0.24
Nodes (8): ReadingWindow, afternoon, evening, morning, night, ReadingInsightsDashboard, Date, String

### Community 120 - "Weather"
Cohesion: 0.17
Nodes (12): EnvironmentalInsightCategory, abandonment, completion, consistency, engagement, environmentalSensitivity, genreAvoidance, genrePreference (+4 more)

### Community 121 - "Library"
Cohesion: 0.18
Nodes (9): LibraryFilterState, ReadingStatusFilter, all, completed, inProgress, notStarted, Book, Bool (+1 more)

### Community 122 - "Onboarding"
Cohesion: 0.21
Nodes (5): OnboardingView, Book, Bool, String, UniformTypeIdentifiers

### Community 123 - "Developerconsole"
Cohesion: 0.29
Nodes (6): PersonaDetail, PersonaRow, Bool, Content, String, Void

### Community 124 - "Reading Trackertests"
Cohesion: 0.38
Nodes (4): Date, Double, String, WeatherConfidencePinsTests

### Community 125 - "Core"
Cohesion: 0.29
Nodes (5): DispatchQueue, PersistenceWriter, Never, String, Task

### Community 126 - "History"
Cohesion: 0.27
Nodes (10): Monolith persistence at scale (unpruned lifetime growth), NEW-DE-12: test hygiene (CoverStore.shared side effects), FULLMUTEX + owned serial queue lesson (SQLITE_ENABLE_THREAD_ASSERTIONS), Upgrade #1: normalized SQLite core blueprint, Upgrade #2: CoverStore content-addressed cover files + NSCache, Diagnostics: xcodebuild test run 2026-08-26, DurabilityPinsTests.exportImportRoundTrip failure (Aug 26), OPE-001: stub-cover debris corpus (hash-family cleanup, Class Δ gate) (+2 more)

### Community 127 - "Behaviorcontext"
Cohesion: 0.27
Nodes (6): ProcessInfo, BehavioralExportEncoder, Data, Decoder, Encoder, ThermalStateEvent

### Community 128 - "Behaviorcontext"
Cohesion: 0.33
Nodes (5): BehavioralEvidenceCursor, BehavioralEvidencePage, BehavioralPaginationEngine, Bool, T

### Community 129 - "Weather"
Cohesion: 0.20
Nodes (10): CorrelationLifecycle, declining, emerging, persistent, recurring, seasonal, stable, strengthening (+2 more)

### Community 130 - "Root Docs"
Cohesion: 0.24
Nodes (7): ShallowPerspectiveView, Book, Bool, CGFloat, Double, Int, Void

### Community 131 - "Reading Trackertests"
Cohesion: 0.33
Nodes (3): CelebrationTimelineTests, DismissalFlag, Bool

### Community 132 - "Reading Trackertests"
Cohesion: 0.36
Nodes (3): LibraryCollectionTests, Book, String

### Community 133 - "Reading Trackertests"
Cohesion: 0.38
Nodes (3): MirageSidecarLifecycleTests, Data, String

### Community 134 - "Reading Trackertests"
Cohesion: 0.56
Nodes (3): GoalStreakTests, Int, UUID

### Community 135 - "Root Docs"
Cohesion: 0.31
Nodes (7): async, MirageChildLauncher, Configuration, Bool, TimeInterval, URL, Void

### Community 136 - "Integration"
Cohesion: 0.36
Nodes (9): ADR-12 — Titanium Bridge Charter (§22), ADR-3 — Packaged Runtime Distribution (bundle with the app), MirageRuntimeLocator (bundled → dev gate → nothing), PR-8 — Packaged Runtime (staging, locator, CI, 0aa4ed8), RUNTIME-MANIFEST.json (staged-runtime digest bindings), scripts/stage-mirage-runtime.sh (pinned fetch + refusal pins + manifest), scripts/verify-clean-machine.sh (3-stage refusal gate), §15.3 Recovery Rehearsal Log (S15-ES-3 artifacts, 2026-10-18) (+1 more)

### Community 137 - "Engines"
Cohesion: 0.22
Nodes (9): AnalyticsPeriod, custom, thisMonth, thisWeek, thisYear, today, ClosedRange, Date (+1 more)

### Community 138 - "Behaviorcontext"
Cohesion: 0.33
Nodes (4): BehaviorEvidenceBuilder, Date, Double, Int

### Community 139 - "Developerconsole"
Cohesion: 0.31
Nodes (4): DeveloperConsoleSystemMetrics, Double, String, UInt64

### Community 140 - "Sessions"
Cohesion: 0.28
Nodes (7): AudioDetailView, AudioPill, SessionHistoryRow, SessionHistoryView, Book, Int, String

### Community 141 - "Reading Trackertests"
Cohesion: 0.33
Nodes (7): MirageIdentityRealEngineImportTests, MirageImportFault, mirageZipFixtureDirectory(), Bool, String, URL, writeMinimalRealEpubFixture()

### Community 142 - "Rsvp"
Cohesion: 0.29
Nodes (6): RSVPPivotWordView, RSVPReaderView, Double, Int, String, Void

### Community 143 - "Tib"
Cohesion: 0.50
Nodes (7): append_row(), check(), compute(), load_manifest(), main(), sha256(), tree_digest()

### Community 144 - "Behaviorcontext"
Cohesion: 0.29
Nodes (7): CodingKey, CodingKeys, id, thermalState, timestamp, CodingKeys, imageJPEG

### Community 145 - "Spatial"
Cohesion: 0.29
Nodes (5): AdaptiveLayoutTier, floatingCluster, fullSpatialNavigator, shallowPerspective, Int

### Community 146 - "Reading Trackertests"
Cohesion: 0.29
Nodes (3): SchemaEvolutionTests, JSONDecoder, JSONEncoder

### Community 147 - "Discovery"
Cohesion: 0.40
Nodes (3): BookDiscoveryView, OnlineBook, String

### Community 148 - "Goals"
Cohesion: 0.33
Nodes (6): GoalKind, annualBooks, bookDeadline, dailyPages, dailyTime, weeklyStreak

### Community 149 - "Reader"
Cohesion: 0.33
Nodes (6): EPUBPackageError, cannotReadContainerXML, cannotReadOPF, opfPathNotFound, securityScopeUnavailable, zipFoundationUnavailable

### Community 150 - "Sessions"
Cohesion: 0.33
Nodes (4): ReadingHUD, Book, String, TimeInterval

### Community 151 - "Reading Tracker"
Cohesion: 0.33
Nodes (5): HoverIntent, ignore, inspecting, interested, Double

### Community 152 - "Engines"
Cohesion: 0.40
Nodes (4): ConfidenceLevel, high, low, medium

### Community 153 - "Mirage"
Cohesion: 0.40
Nodes (3): MirageSettings, MirageSettingsCopy, Bool

### Community 154 - "History"
Cohesion: 0.67
Nodes (4): Developer Console freeze (persona install, Sep 2026), EnvironmentObject.error() fatal root cause, One-line fix: .environmentObject(dataStore) on the console window, Winter Romantic persona (620 sessions, 185k timings)

### Community 155 - "Reading Trackertests"
Cohesion: 0.50
Nodes (3): ProbeTripwireTransport, Data, Int

### Community 156 - "Integration"
Cohesion: 0.67
Nodes (3): BUG-003: CodeSign xattr detritus from iCloud File Provider, BUG-005: stale probe artifact (wrong pipe index, never compiled), Test-campaign protocol (xattr clean, no timeout, delete probes)

## Knowledge Gaps
- **674 isolated node(s):** `id`, `title`, `author`, `fileURL`, `fileType` (+669 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **21 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Foundation` connect `Reading Trackertests` to `Behaviorcontext`, `Engines`, `Behaviorcontext`, `Recommendations`, `Library`, `Reading Trackertests`, `Core`, `Developerconsole`, `Core`, `Engines`, `Behaviorcontext`, `Developerconsole`, `Notifications`, `Reports`, `Insights`, `Spatial`, `Reading Trackertests`, `Mirage`, `Discovery`, `Core`, `Mirage`, `Weather`, `Reading Trackertests`, `Audio`, `Engines`, `Audio`, `Engine`, `Reading Trackertests`, `Audio`, `Core`, `Mirage`, `Rsvp`, `Mirage`, `Weather`, `Root Docs`, `Mirage`, `Mirage`, `Mirage`, `Reading Trackertests`, `Root Docs`, `Core`, `Core`, `Engine`, `Mirage`, `Achievements`, `Mirage`, `Mirage`, `Reader`, `Core`, `Providers`, `Goals`, `Discovery`, `Discovery`, `Providers`, `Library`, `Core`?**
  _High betweenness centrality (0.161) - this node is a cross-community bridge._
- **Why does `DataStore` connect `Core` to `Reading Trackertests`, `Core`, `Developerconsole`, `Reports`, `Sessions`, `Reading Trackertests`, `Sessions`, `Discovery`, `Reading Tracker`, `Weather`, `Audio`, `Core`, `Reading Trackertests`, `Reading Trackertests`, `Developerconsole`, `Sessions`, `Achievements`, `Library`, `Reading Trackertests`, `Weather`, `Goals`, `Goals`, `Developerconsole`, `Root Docs`, `Engines`, `Onboarding`?**
  _High betweenness centrality (0.071) - this node is a cross-community bridge._
- **Why does `ReadingGenre` connect `Recommendations` to `Library`, `Behaviorcontext`, `Engines`, `Reports`, `Behaviorcontext`, `Discovery`, `Core`, `Root Docs`, `Core`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **What connects `id`, `title`, `author` to the rest of the system?**
  _674 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Behaviorcontext` be split into smaller, more focused modules?**
  _Cohesion score 0.031857031857031856 - nodes in this community are weakly interconnected._
- **Should `Engines` be split into smaller, more focused modules?**
  _Cohesion score 0.061455525606469004 - nodes in this community are weakly interconnected._
- **Should `Behaviorcontext` be split into smaller, more focused modules?**
  _Cohesion score 0.08107502799552072 - nodes in this community are weakly interconnected._