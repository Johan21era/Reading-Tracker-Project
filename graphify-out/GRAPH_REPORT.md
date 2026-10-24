# Graph Report - AsterismaV1.0  (2026-10-24)

## Corpus Check
- 252 files · ~337,967 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 4674 nodes · 11424 edges · 416 communities (226 shown, 190 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 666 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `aba8aa4c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- SessionCoordinator
- SwiftUI
- AnalyticsCache
- Foundation
- .dataRootURL
- ReadingSession
- Identifiable
- Sendable
- CodingKeys
- CodingKeys
- BookDeadline
- CaseIterable
- ReadingGenre
- .mapped
- NoteTag
- DailyActivity
- DataStore
- AppKit
- View
- CoverStore
- .validate
- ReadingInsight
- MaturityEvidenceDigest
- Combine
- BehavioralCategory
- .addBook
- LibraryDatabase
- .updateGoalSet
- AnnualReportArchiveView
- LibraryArchive
- .generateBooks
- .enqueue
- DemoRapidSwitchTests
- .runCycle
- SentinelEngine.swift
- SentinelFinding
- String
- SentinelEngine
- RSVPPlaybackEngine
- .versionIsSupported
- AnalyticsEngine.swift
- AnalyticsEngine
- .gate
- .estimate
- AchievementDefinition
- AchievementKind
- AchievementEngine
- AudioContextProfile
- AudioCategory
- AudioSource
- MusicalAnalysisEngine
- AudioMonitorService
- AudioProfileStore
- AudioFactor
- BehaviorContextEngine2.swift
- InactivityGapRecord
- Double
- UUID
- Date
- BehaviorCategory
- MirageProcessTransport
- RoutineCategory
- ContextContinuityType
- ContextTrend
- BehavioralEvent
- .gap
- .evidence
- BehavioralCategory.swift
- DeviceStateType
- Date
- BehaviorContextAccessKit
- Int
- BehavioralObservationWindow
- ThermalStateEvent
- Equatable
- BehavioralObserverStatus
- Color
- PersonaDetail
- DeveloperConsoleDashboardView
- ConsoleSubsystemSnapshot
- DeveloperConsoleSection
- DeveloperConsoleSystemMetrics
- State
- SentinelPaneView
- BookDiscoveryView
- AvailabilityState
- BookDiscoveryService
- BookDiscoveryViewModel
- GutendexBook
- CodingKeys
- EnvironmentAnchorPeriod
- EnvironmentColor
- EnvironmentEngine
- SeededGenerator
- .clampUnit
- EnvironmentState
- ShootingStarManager
- Star
- OpenMeteoProvider.swift
- OpenMeteoLiveSmokeTests.swift
- WeatherSnapshot
- LocationProvider
- OpenMeteoProvider
- .archiveSnapshot
- WeatherAnalysisEngine.swift
- WeatherConditionCategory
- SeasonalPeriod
- Double
- EnvironmentalFactor
- ReadingBehaviorMetric
- CorrelationLifecycle
- WeatherInsightPanel
- .assembleAtSessionEnd
- .normalise
- Coordinator
- GoalStatus
- GoalKind
- SettingsRootView.swift
- InsightKind
- ReadingInsightsDashboard.swift
- BookDetailsView
- BookImporter.swift
- PDFReaderView
- .importEPUB
- .importPDF
- ImportWarningLevel
- ImportPlugin
- LibraryFilterSidebarView
- LibraryFilterState
- AdaptiveLayoutTier
- BookVisualState
- SpatialNavigatorCard
- MirageImportOutcome
- MirageClient
- MirageSidecarSupervisor
- .perform
- MirageCursorGateError
- MirageDetailRequest
- .makeFixture
- MirageBundledRuntimeTests
- MirageSettings.swift
- MirageAnalysisStatus
- MirageStatusSurfaceTests
- MirageJSONValue
- MirageWireAction
- NotificationCandidate
- OnboardingView
- EPUBReaderScreen
- .recommend
- RecommendationCard
- .generate
- analyticsPeriod
- NewYearTransitionMonitor.swift
- NewYearCelebrationOverlay
- SnowParticle
- CelebrationPhase
- Step
- SheetDismissAffordance
- SessionHistoryView
- ContentView
- LibrarySortMode
- AnalyticsCachePinsTests.swift
- BedrockBaselineTests.swift
- DismissalFlag
- G1CorrectnessPinsTests.swift
- .disabledFeatureNeverRunsTheStatusRunner
- MirageIdentityRealEngineImportTests.swift
- ProbeTripwireTransport
- GoalStreakTests
- SQLiteFoundationTests.swift
- SchemaEvolutionTests
- .record
- WeatherLivePipelineTests.swift
- WeatherSnapshotStoreTests
- AsterismaV1_0UITests
- benchmark.sh
- bundle_smoke.py
- census.sh
- generate-app-icon.py
- package-release.sh
- stage-mirage-runtime.sh
- observe.py
- verify-clean-machine.sh
- verify-test-isolation.sh
- 08 · Deep Audit (Oct 2026)
- 09 · Final Traces performance marathon
- 10 · Profiler fix (freeze post-mortem)
- PR-4 Current-State Defect Analysis — Real Sidecar Lifecycle
- PR-5 Execution Plan — Identity Map + One-Book Import (drafted 2026-10-18 evening)
- 🧭 Navigation Hub — read this first
- 1. Source-derived baseline and confidence rules
- 2. Product and architecture contract
- 3. Data ownership, identity, and synchronization
- 4. Repository strategy and GitHub safety
- 5. Phase 0 — Governance, scope, and stop conditions
- 6. Phase 1 — Establish and verify both baselines
- 7. Phase 2 — Source-code discovery and contract extraction
- 8. Phase 3 — Fix or isolate pre-existing RT risks
- 9. Phase 4 — Build the integration boundary first
- 10. Phase 5 — Implement the book/edition and cursor adapter
- 11. Phase 6 — Expose Mirage as an optional RT feature
- 12. Phase 7 — Security, privacy, and local-first guarantees
- 13. Phase 8 — Testing strategy and quality gates
- 14. Phase 9 — Build, packaging, and release engineering
- 15. Phase 10 — Rollback, recovery, and operational support
- 16. Implementation sequence and pull-request plan
- 18. Final acceptance checklist
- Appendix D — Multi-pass document audit
- 21. Technical escalation addendum (section-by-section ≥21× intensification layer)
- Appendix F — Quick reference (one-page cheat sheet)
- 22. The Titanium Bridge (TiB) — continuous-convergence subsystem
- 🖥️ Part 2 — MirageV1.0
- ADR-12 — Titanium Bridge (TiB) charter: continuous convergence across the guarded boundary
- ADR-2: integration transport & protocol (managed stdio NDJSON sidecar)
- ADR-3 — Packaged runtime distribution (engine + interpreter bundled with RT)
- ADR-4 — Data directories, Mirage ledger placement & backup ownership
- ADR-5: identity-mapping contract (RT Book ↔ Mirage book/edition)
- ADR-6 — Mirage as an optional RT feature: lifecycle governance (canonical §17 seat)
- ADR-6a — Mirage import-path independence from RT's onboarding-import bypass (NEW-DE-5)
- ADR-7 — Spoiler-cursor contract (with S10-ES-3 formal sub-document as annex)
- ADR-8 — Repository strategy: two canonical repositories, one verified vendored copy (canonical §17 seat)
- README.md
- §15.4 Operational handoff bundle — RT ⇄ Mirage integration (2026-10-18)
- §18 Final Acceptance Checklist (2026-10-18, ladder complete)
- Evidence artifact — MirageV1.0 normative docs + wire protocol extraction (Phase 1/2)
- Binding claims (path:line-anchored)
- RT critical facts (root `/Users/johanrembeci/Desktop/Reading Tracker Main /`)
- §15.3 recovery rehearsal log — S15-ES-3 artifacts (2026-10-18 session)
- TB-M0 gate plan — manifest + hash-verify in observe mode (OPEN — ADR-12 countersigned 2026-10-18)
- observe-ledger.md
- 06 · RSVP Feature Plan
- Reaction wave (badge/goal recompute on main after bulk swap)
- Slim Timings (downsample synthetic page-timings)
- nonisolated stamps (~15 functions on generation path)
- STEP 1 playbook: sample the frozen process
- debug_replaceLibrary (persona library swap)
- SessionEventRouter2 (library-changed listener)
- AnalyticsEngine (page-timing accountant)
- Deep Audit RA-DEEP-20261017
- NEW-DE-1: PersistenceWriter stale-overwrite window
- NEW-DE-2: Explore/spatial cards never show real covers
- NEW-DE-3: crash-window time inflation
- NEW-DE-4: AnalyticsCache stale across midnight
- NEW-DE-5: onboarding import bypass + goal-set clobber
- Diagnostics: xcodebuild test run 2026-08-26
- Monolith persistence at scale (unpruned lifetime growth)
- BCE Phase-2 dead scaffold (81% dormant)
- Four release blockers (AppIcon, WeatherKit entitlement, CFBundleID, readonly conflict)
- DataMaturityEngine (evidence gating with injected clocks)
- EPUBPackage (exactly-once cleanup design)
- Upgrade #1: normalized SQLite core blueprint
- Upgrade #3: split @Observable stores blueprint (Library/Goal/Health)
- Upgrade #4 safe slice: PersistenceWriter owned serial queue
- Upgrade #5: AnalyticsCache (signature ⊕ epoch memoization)
- FULLMUTEX + owned serial queue lesson (SQLITE_ENABLE_THREAD_ASSERTIONS)
- Developer Console freeze (persona install, Sep 2026)
- EnvironmentObject.error() fatal root cause
- One-line fix: .environmentObject(dataStore) on the console window
- Profile-first discipline (sample the frozen process before reasoning)
- Achievement flood on bulk history import
- Winter Romantic persona (620 sessions, 185k timings)
- PR-4 current-state defect analysis (PR4-DEF-ANALYSIS-2026-10-18)
- BUG-001: batch-context silent stdout wedge
- H1: ghost consumer on the pipe read end (falsified)
- H3: bytes never entered the pipe (falsified)
- H2 confirmed: FileHandle.read machinery-local wedge
- E1 kernel-level forensic probe (raw read(2) discriminator)
- C2 fix: raw read(2) transport path + MirageOnceCloser epoch disposal
- MirageProcessTransport
- MirageChildProcess / MirageProcessLauncher / MiragePythonLocator
- MirageSidecarSupervisor (backoff ladder, permanent-down)
- BUG-003: CodeSign xattr detritus from iCloud File Provider
- BUG-005: stale probe artifact (wrong pipe index, never compiled)
- OPE-003: PR-4 census (138 executed / 0 failed / 1 skipped)
- swift-subprocess adoption track (future countersigned PR)
- Test-campaign protocol (xattr clean, no timeout, delete probes)
- PR-5 execution plan (identity map + one-book import)
- MirageIdentityMap.swift (stratum load/store)
- MirageImportFlow.swift (import orchestrator)
- Pinned-case matrix (duplicate/changed/ambiguous/missing/cancel/crash/schema floor)
- import_epub payload contract (extract from MirageV1.0, logged as M-022)
- ID-SYNTH-9001: RT never infers mirageEditionID
- RT Mirage Codebase Merge Playbook (governing playbook)
- Parent-child hierarchy (RT parent app, Mirage optional capability)
- Explicit non-goals (no store unification, no repo deletion, no auto-analysis)
- MirageIntegration module (typed integration boundary)
- Evidence labels (SOURCE-VERIFIED / TEST-VERIFIED / README-REPORTED / INFERRED / DECISION-REQUIRED / BLOCKED)
- PR-1...PR-8 integration ladder
- ADR register (§17, ADR-1...ADR-11 slots)
- Identity mapping is a first-class subsystem (no title guessing)
- Spoiler-cursor boundary (highest-risk semantic boundary)
- S10-ES-1 explicit-gesture pre-flight doctrine
- S16-ES-1 PR gate ladder (per-PR acceptance gates)
- S8-ES-5 house suite standard
- §21 impossibility rule + W3 (no invented wire fields / no ID synthesis)
- Playbook §22 Titanium Bridge specification (TB-* pipeline)
- Git risk classes Ω/Δ/Π (owner countersign gates)
- MirageV1.0 (local-first, spoiler-safe literary knowledge graph)
- MirageService (Python API embedding surface)
- mirage CLI (CLI embedding surface)
- mirage --serve-web local browser UI
- ledger@0.0.10 SQLite ledger of truth (graph is projection)
- Spoiler visibility deterministic by cursor and source evidence
- D-010 corrections overlay (audited, append-only, never book truth)
- crates/mirage-core Rust reference core (demoted per ADR-0002)
- One analysis job at a time (8 GB budget, incremental processing)
- unread | reading@cursor | read state vocabulary
- Unified NDJSON serve/sidecar protocol
- Managed stdio NDJSON sidecar transport decision
- Operational handshake (health banner → version → api_version pin)
- mirageProtocolIncompatible mask (feature masked to status row)
- Single-instance supervision + bounded restart (≤3 attempts, 2/4/8 s backoff)
- S2-ES-4 wire discipline (one compact JSON per LF line, no invented fields)
- S12-ES-3: localhost is not a trusted call (HTTP disabled inside RT)
- Pipe I/O on nonisolated worker (no MainActor-blocked work ≥5 ms)
- id-echo request correlation
- ADR-3: packaged runtime distribution (engine + interpreter bundled)
- Bundled runtime decision (RT.app/Contents/Resources/mirage-runtime)
- RUNTIME-MANIFEST.json (pinned checksums, honest provenance)
- Pinned python-build-standalone CPython (relocatable, redistributable)
- Runtime locator ladder (bundled → dev gate → unavailable copy)
- MIRAGE_REAL_ENGINE_DIR dev-opt-in gate
- Clean-machine gate (fresh-clone build + bundle spawn + census subset)
- MirageBundledRuntimeTests
- Ledger stratum: ReadTracker/mirage/mirage.sqlite3 (exclusive Mirage-write territory)
- S0-ES-3 disjoint write-sets doctrine
- Ledger backup ownership = Mirage's own doctrine (RT never fabricates ledger backups)
- Ledger.backup is in-process only (not a NDJSON action)
- RT restoreState invariance (restore ≠ ledger deletion)
- MirageLedgerPathPinsTests
- MirageRestoreInvarianceTests
- identity-map.json stratum (schema mirage-identity-map@1)
- Identity entry contract (rtBookID, mirageBookID, mirageEditionID, sourceFingerprint, status)
- Fail-Closed Identity (no title inference; degrade instead of guess)
- identityDrift rule (RT recomputes byte-hash vs sourceFingerprint)
- Orphaned mapping states (source-changed / edition-gone, no auto-cleanup)
- degraded_import receipt rejected as mapping input
- reused:true idempotent import receipt
- Content-derived EPUB identity (edition_<digest>)
- MirageIdentityMapContractTests
- MirageIdentityDriftTests
- ADR-6: Mirage feature lifecycle (canonical §17 seat)
- mirage.enabled plain switch (Settings ▸ Mirage, default ON)
- OFF means NO engine, NO spawn (defense-in-depth gating)
- Disable-deletes-nothing doctrine
- One analyze gesture = one clean sidecar lifecycle
- MirageFeatureLifecycleTests
- ADR-6a: Mirage import-path independence (NEW-DE-5 discharge)
- Independence-by-construction argument (no addBook, no goal machinery)
- Structural census gate (zero banned symbols in Mirage feature files)
- Onboarding bypass anatomy (OnboardingView.importBook → BookImporter direct; commitGoal overwrites goals)
- ADR-7: spoiler-cursor contract (+ S10-ES-3 annex)
- No-conversion-is-the-safe-conversion (spoiler detail surface ships disabled)
- Fail-closed cursor refusals (CURSOR-MISSING / SPOILER-CURSOR-UNVERIFIED / SPOILER-PROBE-REJECTED)
- State transduction table (read / reading-page-N-of-M / unread, no Mirage declaration)
- Page-turn non-trigger pin (no Mirage calls from reader events)
- MirageCursorContractTests
- MirageSpoilerProbeTests
- Titanium Bridge (continuous convergence: same bytes inside RT by +1 min)
- Two rings, one bridge (dev ring flag / release ring gates)
- Generation model inviolable (whole-directory atomic swap only)
- Owner custody of promotion signing keys (fail-closed on unsigned material)
- TB-M0...TB-M5 owner-gated milestones (gates are the only brake)
- ADR-8 — Repository Strategy (Two Canonical Repositories, One Verified Vendor)
- Verified Vendor Pattern (byte-verbatim, digest re-verifiable, refusal pins)
- OPE-001 — Class Δ Stub-Cover Deletion (38 files, archived list)
- §19 Evidence Bundle — Assembly Manifest (2026-10-18)
- §15.4 Operational Handoff Bundle (2026-10-18)
- Honest Deltas (five ledgered, not acceptance-blocking)
- Mirage Protocol Extraction (Phase 1/2, pinned SHA 81422613…)
- Mirage NDJSON Wire Protocol (P-1…P-10, no version field, banner-first framing)
- MirageService (api/service.py, 28-action run_command dispatcher)
- Mirage Ledger (SQLite WAL, schema ledger@0.0.10, migrate refuses newer)
- Import Identity (sha256 digest-derived edition_/book_ ids, reused:true, collision refusal)
- Spoiler Safety Predicate (fail-closed future-evidence gate, I-SP1/I-SP2)
- Fail-Closed Doctrine (refuse rather than degrade silently)
- AdapterPositionResolver (page↔unit mapping, persisted position_mappings)
- Ledger.backup(dst) (SQLite online backup + PRAGMA integrity_check, in-process only)
- Mirage ADR-0001 (deterministic classical-only, no network providers)
- Mirage ADR-0002 (Rust core demoted; Python API only sanctioned surface)
- RT Normative-Document Extraction (12 docs, dirty tree 8fbd5357)
- Fix-Finality Triad (Finality statement + fix-log entry + pinned test)
- NEW-DE-1…13 Audit Punch List (audit-era ledger, all OPEN)
- Feature-Module Isolation Doctrine (self-contained module, zero feature deps)
- RT Release Blockers ×4 (AppIcon, WeatherKit entitlement, CFBundleIdentifier, readonly build setting)
- 08-deep-audit (October deep audit)
- Touchpoint Inventory (16 integration touchpoints, path:line anchored)
- MainActor-Default Isolation (SWIFT_DEFAULT_ACTOR_ISOLATION, three sanctioned idioms)
- PersistenceWriter (sole serial-queue write path for library JSON)
- DataStore3 (library.json/library-state.json owner, debounce, degraded fallback)
- Cursor Semantics (RT pages ≠ Mirage unit indexes; adapter mandatory)
- Sandbox Capability Boundary (no inherit entitlement; RT owns scoped bytes)
- §15.3 Recovery Rehearsal Log (S15-ES-3 artifacts, 2026-10-18)
- R1 — Code Rollback Rehearsal (in vivo, PR-6→PR-5 census, 1/4 executed)
- R2 — Sidecar Crash-Recovery Rehearsal (test-anchored)
- R3 — Failed-Initialization Rehearsal (contained posture)
- R4 — Invalid-Mapping Recovery Rehearsal (drift refusals)
- R5 — Backup-Restore Rehearsal (Ledger.backup verified from source)
- R6 — Packaged-Runtime Staging/Swap Rehearsal (live, PR-8/ADR-3)
- TB-M0 Gate Plan (manifest + hash-verify, observe mode)
- TB-M0 Observation Gate (§22.19.1 exit bar: 7 days, 0 false-green, tamper drill)
- Observe Mode (verify · record · notify; no swap machinery built)
- Subset Manifest (whole-subset declaration of RT's vendored Mirage copy)
- Tamper Drill (flipped byte → TB-VERIFY-HASH refusal, red-side proof)
- Verify Instrument (scripts/tib/observe.py, std-lib digest verify)
- TB-M0 Observation Ledger (append-only, day-one GREEN + tamper refusal)
- 06 · RSVP Feature Plan (preserved design record; shipped as P5-B2)
- RSVP Speed Reading (shipped P5-B2 f5ec995, tokenizer→playback→UI)
- readrrr (iOS prior art, direct model for feature)
- Testing Strategy
- AsterismaV1.0 Project Report (README)
- RT-Mirage Merge Log
- Bedrock Session Record (2026-10-24)
- Bedrock Master Plan
- AsterismaV1.0 Release Package
- Stage B — Bedrock / Asterisma

## God Nodes (most connected - your core abstractions)
1. `DataStore` - 131 edges
2. `Foundation` - 118 edges
3. `ReadingSession` - 66 edges
4. `BehavioralEnvironmentType` - 62 edges
5. `ContextConfidence` - 53 edges
6. `ReadingContextRecord` - 51 edges
7. `BehavioralEvent` - 48 edges
8. `BehaviorContextAccessKit` - 46 edges
9. `WeatherAnalysisEngine` - 46 edges
10. `SwiftUI` - 45 edges

## Surprising Connections (you probably didn't know these)
- `Finality / Log / Pin Fix Protocol` --semantically_similar_to--> `Defect-Named Pin Convention`  [INFERRED] [semantically similar]
  README.md → docs/method/07-testing-strategy.md
- `Distribution Readiness Gap` --semantically_similar_to--> `Notarization / Developer ID Gap`  [INFERRED] [semantically similar]
  README.md → docs/plans/bedrock/DISTRIBUTION.md
- `Merge-Presence Receipt` --conceptually_related_to--> `Standing Census 212/0/9`  [INFERRED]
  .github/workflows/census.yml → README.md
- `AsterismaV1.0 Project Report (README)` --conceptually_related_to--> `Documentation Drift`  [EXTRACTED]
  README.md → docs/audits/11-completion-and-health-report-2026-10-24.md
- `Mirage Companion Engine` --conceptually_related_to--> `RT-Mirage Merge Log`  [INFERRED]
  README.md → docs/integration/merge-log.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Bedrock Gate Review Pipeline** — docs_plans_bedrock_bedrock_master_plan_2026_10_24_master_plan, docs_plans_bedrock_gate_template_gate_review_template, docs_plans_bedrock_gate_log_gate_log, docs_plans_bedrock_baseline_baseline, docs_plans_bedrock_gates_gate_g1_gate_g1 [EXTRACTED 1.00]
- **Mirage One-Way Sidecar Boundary** — readme_mirage_integration_boundary, docs_integration_merge_log_adr_2_transport_protocol, docs_integration_merge_log_sidecar_supervisor, docs_integration_merge_log_mirage_identity_map, docs_integration_merge_log_adr_7_spoiler_cursor [INFERRED 0.85]
- **JSON Monolith to SQLite Data-Layer Migration** — readme_grdb_sqlite_summary_store, docs_plans_bedrock_bedrock_master_plan_2026_10_24_decision_d_004_grdb_sqlite, docs_plans_bedrock_session_2026_10_24_sqlite_foundation, readme_library_json_monolith, docs_audits_11_completion_and_health_report_2026_10_24_json_monolith_scaling_risk [INFERRED 0.85]
- **Bedrock G2–G8 release gate chain** — docs_plans_bedrock_gates_gate_g2_local_distribution_baseline, docs_plans_bedrock_gates_gate_g2b_mirage_embedded_runtime, docs_plans_bedrock_gates_gate_g3a_grdb_sqlite_foundation, docs_plans_bedrock_gates_gate_g3b_lazy_page_timings, docs_plans_bedrock_gates_gate_g3c_real_data_cutover, docs_plans_bedrock_gates_gate_g4_open_meteo_provider, docs_plans_bedrock_gates_gate_g5_library_metadata_pipeline, docs_plans_bedrock_gates_gate_g6_behavior_context_v3, docs_plans_bedrock_gates_gate_g7_debt_retirement, docs_plans_bedrock_gates_gate_g8_acceptance_checklist [EXTRACTED 1.00]
- **SQLite migration program** — docs_plans_bedrock_gates_gate_g3a_grdb_sqlite_foundation, docs_plans_bedrock_gates_gate_g3a_library_database, docs_plans_bedrock_gates_gate_g3b_lazy_page_timings, docs_plans_bedrock_gates_gate_g3c_real_data_cutover, docs_plans_bedrock_gates_gate_g3c_library_grdb_sqlite [EXTRACTED 1.00]
- **Receipt-driven Asterisma release governance** — docs_registers_02_defect_register_defect_register, docs_registers_03_fix_log_fix_protocol, docs_registers_03_fix_log_fix_log, docs_plans_bedrock_gates_gate_g8_release_receipt, docs_registers_04_handoff_handoff_document [INFERRED 0.90]
- **Fail-closed doctrine family (no synthesis / no inference under uncertainty)** — docs_integration_adr_adr_5_identity_mapping_fail_closed_identity, docs_integration_adr_adr_7_spoiler_cursor_contract_fail_closed_cursor, docs_integration_twin_readmes_2026_10_18_spoiler_visibility, docs_integration_adr_adr_2_transport_and_protocol_protocol_incompatible_mask, docs_integration_pr5_execution_plan_2026_10_18_id_synth_rule [INFERRED 0.85]
- **Mirage strata ownership (ledger / identity / RT territory, disjoint write-sets)** — docs_integration_adr_adr_4_ledger_placement_and_backup_ownership_ledger_stratum, docs_integration_adr_adr_5_identity_mapping_identity_map_json, readme_mirage_stratum, docs_integration_adr_adr_4_ledger_placement_and_backup_ownership_disjoint_write_sets [INFERRED 0.85]
- **Sidecar transport stack (managed stdio NDJSON + raw read(2) fix)** — docs_integration_adr_adr_2_transport_and_protocol_managed_sidecar, docs_integration_pr4_defect_analysis_2026_10_18_mirageprocesstransport, docs_integration_pr4_defect_analysis_2026_10_18_miragechildprocess, docs_integration_pr4_defect_analysis_2026_10_18_miragesidecarsupervisor, readme_mirage_wire_types [INFERRED 0.85]
- **TB-M0 Observe-Mode Instrument Chain (manifest → verify → ledger)** — docs_integration_merge_log_adr_12, docs_integration_tib_tb_m0_gate_plan_tb_m0, docs_integration_tib_tb_m0_gate_plan_tb_m0_gate_plan, docs_integration_tib_tb_m0_gate_plan_subset_manifest, docs_integration_tib_tb_m0_gate_plan_verify_instrument, docs_integration_tib_tb_m0_gate_plan_tamper_drill, docs_integration_tib_observe_ledger_observe_ledger [EXTRACTED 1.00]

## Communities (416 total, 190 thin omitted)

### Community 50 - "SessionCoordinator"
Cohesion: 0.12
Nodes (14): AsterismaApp, App, Scene, ReadingHUD, Book, TimeInterval, String, SessionCoordinator (+6 more)

### Community 38 - "SwiftUI"
Cohesion: 0.06
Nodes (25): SwiftUI, SentinelReportCardView, Int, String, Void, OnlineBookDetailView, OnlineBook, OnlineBook (+17 more)

### Community 88 - "AnalyticsCache"
Cohesion: 0.25
Nodes (8): AnalyticsCache, Signature, Int, UInt64, Book, Bool, TrendAnalytics, TimeOfDayAnalytics

### Community 27 - "Foundation"
Cohesion: 0.13
Nodes (8): Foundation, CryptoKit, Testing, AsterismaV1_0, G6EvidencePersistenceTests, MirageCursor, MirageRealEngineSmokeTests, AsterismaV1_0Tests

### Community 155 - ".dataRootURL"
Cohesion: 0.24
Nodes (5): AppIdentity, URL, RuntimeEnvironment, Bool, URL

### Community 19 - "ReadingSession"
Cohesion: 0.16
Nodes (27): Book, UUID, String, URL, Int, Bool, Date, Data (+19 more)

### Community 21 - "Identifiable"
Cohesion: 0.15
Nodes (15): Identifiable, Int, DataMaturityContextV1Adapter, BehaviorContextEngine, ReadingSessionRecord, DateInterval, BehaviorEvidence, ReadingContextRecord (+7 more)

### Community 12 - "Sendable"
Cohesion: 0.12
Nodes (41): Codable, Hashable, Sendable, HistoricalBehaviorPattern, BehavioralCorrelation, BehavioralSequencePattern, BehavioralDiversityMetrics, ContextDistributionMetrics (+33 more)

### Community 44 - "CodingKeys"
Cohesion: 0.07
Nodes (29): CodingKeys, id, title, author, fileURL, fileType, totalPages, currentPage (+21 more)

### Community 184 - "CodingKeys"
Cohesion: 0.29
Nodes (7): CodingKey, CodingKeys, id, timestamp, thermalState, CodingKeys, imageJPEG

### Community 100 - "BookDeadline"
Cohesion: 0.21
Nodes (9): Decoder, ReadingGoalSet, TimeInterval, BookDeadline, UUID, Date, Bool, GoalProgressViewModel (+1 more)

### Community 57 - "CaseIterable"
Cohesion: 0.08
Nodes (24): CaseIterable, InsightCategory, preferredSoundtrack, distractionPattern, optimalEnvironment, genrePreference, temporalPattern, behaviorShift (+16 more)

### Community 85 - "ReadingGenre"
Cohesion: 0.10
Nodes (20): ReadingGenre, unknown, fiction, nonFiction, fantasy, scienceFiction, mystery, thriller (+12 more)

### Community 196 - "NoteTag"
Cohesion: 0.33
Nodes (6): NoteTag, general, highlight, question, idea, vocabulary

### Community 117 - "DailyActivity"
Cohesion: 0.21
Nodes (10): DailyActivity, Set, ReadingWindow, morning, afternoon, evening, night, ReadingInsightsDashboard (+2 more)

### Community 1 - "DataStore"
Cohesion: 0.08
Nodes (23): LibraryState, DataStore, Book, PersistenceStatus, healthy, degraded, String, StorageEngine (+15 more)

### Community 154 - "AppKit"
Cohesion: 0.22
Nodes (6): AppKit, Book, NSImage, Bool, BookCoverThumbnail, CGFloat

### Community 17 - "View"
Cohesion: 0.10
Nodes (21): View, AdvancedContextView, String, Double, AnnualReportView, Void, Int, VolumeSlide (+13 more)

### Community 42 - "CoverStore"
Cohesion: 0.13
Nodes (13): CoverStore, URL, UUID, String, Data, NSImage, CGFloat, Bool (+5 more)

### Community 16 - ".validate"
Cohesion: 0.09
Nodes (24): SchemaVersion, v1, v2, v3, ValidationIssue, Severity, warning, error (+16 more)

### Community 43 - "ReadingInsight"
Cohesion: 0.16
Nodes (16): Int, ReaderProfileAnalytics, ReadingInsight, UUID, String, Double, InsightPriority, critical (+8 more)

### Community 0 - "MaturityEvidenceDigest"
Cohesion: 0.06
Nodes (52): CustomStringConvertible, MaturityDomain, String, ClaimTypeIdentifier, NarrativeStrengthTier, Int, Bool, ClaimDisposition (+44 more)

### Community 118 - "Combine"
Cohesion: 0.12
Nodes (7): Combine, CoreGraphics, DesignGrid, CGFloat, Double, GRDB, Network

### Community 9 - "BehavioralCategory"
Cohesion: 0.05
Nodes (38): ObservableObject, BehavioralCategory, gaming, entertainment, communication, browsing, productivity, development (+30 more)

### Community 20 - ".addBook"
Cohesion: 0.09
Nodes (12): AnalyticsCachePinsTests, URL, String, Book, DurabilityPinsTests, URL, String, Int (+4 more)

### Community 59 - "LibraryDatabase"
Cohesion: 0.16
Nodes (10): LibraryDatabase, DatabasePool, URL, DatabaseMigrator, JSONEncoder, JSONDecoder, Book, Database (+2 more)

### Community 91 - ".updateGoalSet"
Cohesion: 0.14
Nodes (7): GoalEditorPane, GoalPersistenceTests, URL, String, Book, RebindIdempotenceTests, Bool

### Community 183 - "AnnualReportArchiveView"
Cohesion: 0.38
Nodes (3): AnnualReportArchiveView, Int, Bool

### Community 68 - "LibraryArchive"
Cohesion: 0.16
Nodes (13): LibraryArchive, Int, Date, String, Book, Data, LibraryArchiveError, emptyLibrary (+5 more)

### Community 22 - ".generateBooks"
Cohesion: 0.13
Nodes (21): LocalizedError, DemoProfileLabView, SeededRNG, UInt64, String, Double, ClosedRange, Int (+13 more)

### Community 109 - ".enqueue"
Cohesion: 0.23
Nodes (8): PersistenceWriter, DispatchQueue, String, Task, Never, WriteResult, CheckedContinuation, G1PersistenceWriterPinsTests

### Community 119 - "DemoRapidSwitchTests"
Cohesion: 0.19
Nodes (5): SentinelDataBridge, URL, DemoRapidSwitchTests, String, Int

### Community 103 - ".runCycle"
Cohesion: 0.34
Nodes (4): UserDefaults, SentinelPinsTests, Book, Void

### Community 146 - "SentinelEngine.swift"
Cohesion: 0.47
Nodes (9): SentinelProbe, IntegrityProbe, PersistenceHealthProbe, StoreWritabilityProbe, OrphanedActiveSessionProbe, StaleBookmarkProbe, DiskSpaceProbe, DeadlineOverdueProbe (+1 more)

### Community 65 - "SentinelFinding"
Cohesion: 0.13
Nodes (13): SentinelFinding, Severity, info, warning, critical, Outcome, detected, autoFixed (+5 more)

### Community 54 - "String"
Cohesion: 0.14
Nodes (20): String, DayPeriod, dawn, morning, afternoon, evening, night, UUID (+12 more)

### Community 104 - "SentinelEngine"
Cohesion: 0.20
Nodes (5): URL, SentinelEngine, Int, Timer, Bool

### Community 3 - "RSVPPlaybackEngine"
Cohesion: 0.06
Nodes (33): stripHTML(), String, decodeHTMLEntities(), decodeNumericEntities(), normalizeWhitespace(), wordCount(), Bool, Int (+25 more)

### Community 89 - ".versionIsSupported"
Cohesion: 0.17
Nodes (9): Comparable, ClosedRange, Self, MirageProtocolConstants, String, Data, Bool, SemVer (+1 more)

### Community 60 - "AnalyticsEngine.swift"
Cohesion: 0.10
Nodes (22): Int, AnalyticsPeriod, today, thisWeek, thisMonth, thisYear, custom, Date (+14 more)

### Community 13 - "AnalyticsEngine"
Cohesion: 0.12
Nodes (12): AnalyticsEngine, Book, Double, TimeInterval, UInt64, UUID, ChapterPredictionAnalytics, ImprovementAnalytics (+4 more)

### Community 75 - ".gate"
Cohesion: 0.13
Nodes (15): ProductiveContextResult, ProductiveContextFinder, ConsistentContextResult, ConsistentContextFinder, NarrativeCategory, routine, environment, transition (+7 more)

### Community 33 - ".estimate"
Cohesion: 0.20
Nodes (15): ReadingContext, Int, UUID, Bool, Date, SpeedComponents, Double, SpeedModel (+7 more)

### Community 76 - "AchievementDefinition"
Cohesion: 0.15
Nodes (13): AchievementDefinition, AchievementTier, bronze, silver, gold, platinum, AchievementPanel, String (+5 more)

### Community 53 - "AchievementKind"
Cohesion: 0.08
Nodes (26): AchievementKind, pages100, pages500, pages1000, pages5000, pages10000, sessions5, sessions25 (+18 more)

### Community 120 - "AchievementEngine"
Cohesion: 0.26
Nodes (7): UUID, Date, AchievementEngine, Book, Void, Bool, Int

### Community 69 - "AudioContextProfile"
Cohesion: 0.23
Nodes (17): InferredMood, calm, focused, energetic, melancholic, upbeat, neutral, unavailable (+9 more)

### Community 30 - "AudioCategory"
Cohesion: 0.13
Nodes (24): AudioCategory, silence, music, podcast, audioBook, spokenWord, videoAudio, ambientSoundscape (+16 more)

### Community 127 - "AudioSource"
Cohesion: 0.15
Nodes (13): AudioSource, appleMusicApp, spotifyApp, podcastsApp, audiobooksApp, quickTimePlayer, vlcPlayer, iinaPlayer (+5 more)

### Community 26 - "MusicalAnalysisEngine"
Cohesion: 0.20
Nodes (5): AudioSessionRecord, AudioCorrelation, Double, MusicalAnalysisEngine, Book

### Community 34 - "AudioMonitorService"
Cohesion: 0.14
Nodes (14): CoreAudio, AudioTrackMetadata, String, TimeInterval, UUID, AudioMonitorService, Bool, Timer (+6 more)

### Community 168 - "AudioProfileStore"
Cohesion: 0.39
Nodes (4): AudioProfileStore, URL, JSONEncoder, JSONDecoder

### Community 105 - "AudioFactor"
Cohesion: 0.12
Nodes (16): AudioFactor, audioCategory, audioSource, listeningIntensity, silenceFraction, genreMood, genreEnergy, trackDiversity (+8 more)

### Community 10 - "BehaviorContextEngine2.swift"
Cohesion: 0.08
Nodes (29): Sequence, Element, BehavioralDiversityAnalyzer, ContextDistributionAnalyzer, RoutineDisruptionAnalyzer, EnvironmentStabilityAnalyzer, ContextEvidenceChainBuilder, ContextCorrelationAnalyzer (+21 more)

### Community 47 - "InactivityGapRecord"
Cohesion: 0.09
Nodes (20): Configuration, TimeInterval, ContextWindowPreset, narrow, standard, extended, fullDay, custom (+12 more)

### Community 35 - "Double"
Cohesion: 0.11
Nodes (17): Double, Bool, SignificanceAssessment, AdvancedSignificanceAssessment, BehavioralSignificanceClassification, incidentalNoise, weakSignal, moderateSignal (+9 more)

### Community 5 - "UUID"
Cohesion: 0.07
Nodes (32): String, Int, UUID, BehavioralEnvironmentType, development, research, gaming, entertainment (+24 more)

### Community 70 - "Date"
Cohesion: 0.13
Nodes (14): Date, ContextWindow, FatigueSignalType, increasingGaps, multipleExtendedGaps, overnightFollowedByBrief, FatigueSignal, EnvironmentEvolutionPeriod (+6 more)

### Community 58 - "BehaviorCategory"
Cohesion: 0.10
Nodes (18): BehaviorCategory, productivity, development, research, gaming, entertainment, learning, social (+10 more)

### Community 7 - "MirageProcessTransport"
Cohesion: 0.08
Nodes (33): work, MirageTransportFailure, spawnFailed, String, pipeWriteFailed, pipeReadFailed, pipeEOFWhileAwaitingResponse, responseTimeout (+25 more)

### Community 61 - "RoutineCategory"
Cohesion: 0.11
Nodes (17): RoutineCategory, morningReading, afternoonReading, eveningReading, lateNightReading, weekdayReading, weekendReading, weatherAssociated (+9 more)

### Community 149 - "ContextContinuityType"
Cohesion: 0.25
Nodes (7): ContextContinuityType, continuous, partialTransition, majorTransition, isolatedReading, ContextContinuityRecord, ContextContinuityAnalyzer

### Community 157 - "ContextTrend"
Cohesion: 0.27
Nodes (7): ContextTrendDirection, increasing, decreasing, stable, emerging, ContextTrend, ContextTrendAnalyzer

### Community 45 - "BehavioralEvent"
Cohesion: 0.18
Nodes (10): BehaviorContextAdapterInput, BehavioralEvent, ApplicationUsageSession, DeviceStateEvent, InactivityRecord, BehaviorEvidenceArchive, BehavioralEventStore, BehavioralTimelineValidator (+2 more)

### Community 110 - ".gap"
Cohesion: 0.27
Nodes (6): FatigueIndicatorAnalyzer, BehavioralSessionGapAnalyzer, FatigueAnalyzerTests, Int, Double, UUID

### Community 158 - ".evidence"
Cohesion: 0.29
Nodes (4): BehaviorEvidenceBuilder, Int, Date, Double

### Community 40 - "BehavioralCategory.swift"
Cohesion: 0.09
Nodes (15): IOKit, IOKit.pwr_mgt, BehavioralEvidencePersistence, BehavioralSequenceGenerator, UInt64, SequencedBehavioralEvent, BehavioralEventJournal, SessionConflictResolver (+7 more)

### Community 77 - "DeviceStateType"
Cohesion: 0.12
Nodes (11): DeviceStateType, active, inactive, sleeping, awake, locked, unlocked, BehavioralSnapshot (+3 more)

### Community 24 - "Date"
Cohesion: 0.11
Nodes (19): ApplicationDescriptor, UUID, Int32, Date, BehavioralTimelineSegment, BehavioralEventBatch, BehavioralReplayFrame, BehavioralTimelineBuilder (+11 more)

### Community 41 - "BehaviorContextAccessKit"
Cohesion: 0.14
Nodes (8): URL, BehaviorContextAccessKit, NSObjectProtocol, Timer, Notification, NSRunningApplication, BehavioralRetentionController, ObserverLifecycleTests

### Community 39 - "Int"
Cohesion: 0.10
Nodes (16): TimeInterval, ApplicationBehaviorProfile, Int, BehavioralStatistics, Self, Bool, BehavioralRetentionPolicy, BehavioralIntegrityReport (+8 more)

### Community 156 - "BehavioralObservationWindow"
Cohesion: 0.29
Nodes (4): BehavioralObservationWindow, BehavioralStoragePartition, BehavioralWindowCache, BehavioralPartitionBuilder

### Community 147 - "ThermalStateEvent"
Cohesion: 0.25
Nodes (6): ThermalStateEvent, ProcessInfo, Decoder, Encoder, BehavioralExportEncoder, Data

### Community 23 - "Equatable"
Cohesion: 0.09
Nodes (25): Equatable, MirageIdentityMapSchema, MirageIdentityMapTime, Date, MirageIdentityMapEntry, Status, active, orphaned (+17 more)

### Community 148 - "BehavioralObserverStatus"
Cohesion: 0.25
Nodes (7): BehavioralObserverHealth, active, inactive, degraded, failed, BehavioralObserverStatus, BehavioralObserverDiagnostics

### Community 78 - "Color"
Cohesion: 0.15
Nodes (10): ContextInsightPanel, Int, String, RoutineRow, GoalsDashboard, BookDeadlineRow, Color, ActivityHeatmapView (+2 more)

### Community 150 - "PersonaDetail"
Cohesion: 0.29
Nodes (6): String, PersonaRow, Bool, Void, PersonaDetail, Content

### Community 128 - "DeveloperConsoleDashboardView"
Cohesion: 0.27
Nodes (7): DeveloperConsoleKnownSubsystem, String, DeveloperConsoleKnownSubsystems, DeveloperConsoleDashboardView, FlaggedItem, Bool, ConsolePalette

### Community 2 - "ConsoleSubsystemSnapshot"
Cohesion: 0.04
Nodes (40): DeveloperConsoleObservable, AnyObject, DeveloperConsoleStaticObservable, DeveloperConsoleRegistry, String, Int, T, DeveloperConsoleStaticEngineManifest (+32 more)

### Community 71 - "DeveloperConsoleSection"
Cohesion: 0.10
Nodes (19): DeveloperConsoleWindowID, DeveloperConsoleSection, dashboard, sentinel, demoLab, subsystemExplorer, eventTimeline, stateInspector (+11 more)

### Community 169 - "DeveloperConsoleSystemMetrics"
Cohesion: 0.31
Nodes (4): DeveloperConsoleSystemMetrics, String, UInt64, Double

### Community 95 - "State"
Cohesion: 0.13
Nodes (17): Darwin, State, disabled, handshaking, ready, protocolIncompatible, String, engineUnavailable (+9 more)

### Community 129 - "SentinelPaneView"
Cohesion: 0.19
Nodes (5): SentinelPaneView, Int, Story, Bool, Date

### Community 197 - "BookDiscoveryView"
Cohesion: 0.40
Nodes (3): BookDiscoveryView, OnlineBook, String

### Community 130 - "AvailabilityState"
Cohesion: 0.23
Nodes (11): BookSource, openLibrary, gutenberg, worldCat, AvailabilityState, free, referenceOnly, unknown (+3 more)

### Community 131 - "BookDiscoveryService"
Cohesion: 0.36
Nodes (5): BookDiscoveryService, String, OnlineBook, Int, Bool

### Community 132 - "BookDiscoveryViewModel"
Cohesion: 0.24
Nodes (7): BookDiscoveryViewModel, OnlineBook, String, Task, Void, Never, Bool

### Community 133 - "GutendexBook"
Cohesion: 0.27
Nodes (9): BookProvider, GutenbergProvider, String, OnlineBook, GutendexResponse, GutendexBook, Int, GutendexAuthor (+1 more)

### Community 111 - "CodingKeys"
Cohesion: 0.19
Nodes (12): OpenLibraryProvider, String, OnlineBook, OpenLibrarySearchResponse, OpenLibraryDocument, Int, CodingKeys, key (+4 more)

### Community 112 - "EnvironmentAnchorPeriod"
Cohesion: 0.15
Nodes (11): EnvironmentAnchorPeriod, night, morning, midday, afternoon, AnchorClock, Date, Calendar (+3 more)

### Community 113 - "EnvironmentColor"
Cohesion: 0.29
Nodes (8): EnvironmentColor, Double, String, EnvironmentGradientStop, EnvironmentPaletteSnapshot, Double, EnvironmentPalette, TimedKeyframe

### Community 92 - "EnvironmentEngine"
Cohesion: 0.22
Nodes (9): EnvironmentEngine, Task, Void, Never, Duration, Calendar, Date, Bool (+1 more)

### Community 121 - "SeededGenerator"
Cohesion: 0.15
Nodes (11): SeededGenerator, RandomNumberGenerator, UInt64, EnvironmentBackgroundView, CGSize, Animation, StarField, Double (+3 more)

### Community 170 - ".clampUnit"
Cohesion: 0.20
Nodes (8): EnvironmentMath, Double, ClosedRange, ShootingStarView, Date, GraphicsContext, CGSize, Double

### Community 159 - "EnvironmentState"
Cohesion: 0.20
Nodes (7): EnvironmentState, Double, Bool, WeatherEnvironmentModifier, Double, TimeInterval, Date

### Community 99 - "ShootingStarManager"
Cohesion: 0.15
Nodes (14): ShootingStar, UUID, Date, CGPoint, Double, CGSize, ShootingStarManager, Task (+6 more)

### Community 135 - "Star"
Cohesion: 0.19
Nodes (10): Star, UUID, CGPoint, Double, CGFloat, StarFieldView, Double, Bool (+2 more)

### Community 114 - "OpenMeteoProvider.swift"
Cohesion: 0.23
Nodes (13): OpenMeteoError, Int, malformedResponse, noHistoricalData, String, Double, CurrentResponse, Decodable (+5 more)

### Community 213 - "OpenMeteoLiveSmokeTests.swift"
Cohesion: 0.40
Nodes (3): CoreLocation, liveWeatherEnabled(), Bool

### Community 36 - "WeatherSnapshot"
Cohesion: 0.13
Nodes (15): WeatherProviding, WeatherSnapshot, EnvironmentalForecastInput, WeatherKitService, WeatherSnapshotStore, Date, Int, CLAuthorizationStatus (+7 more)

### Community 48 - "LocationProvider"
Cohesion: 0.11
Nodes (21): Error, SQLite3, WeatherKit, WeatherKitServiceError, locationUnavailable, noHistoricalDataAvailable, noForecastAvailable, storeWriteFailure (+13 more)

### Community 55 - "OpenMeteoProvider"
Cohesion: 0.14
Nodes (13): badStatus, Date, OpenMeteoProvider, Fetch, URLSession, CLLocation, URL, Data (+5 more)

### Community 136 - ".archiveSnapshot"
Cohesion: 0.27
Nodes (12): CodingKeys, temperature2m, relativeHumidity2m, apparentTemperature, precipitation, snowfall, cloudCover, pressureMsl (+4 more)

### Community 101 - "WeatherAnalysisEngine.swift"
Cohesion: 0.24
Nodes (14): Int, ConfidenceReport, TemperatureProfile, ClosedRange, SeasonalProfile, WeatherInfluenceProfile, EnvironmentalReadingProfile, EnvironmentalForecast (+6 more)

### Community 137 - "WeatherConditionCategory"
Cohesion: 0.15
Nodes (13): WeatherConditionCategory, clear, partlyCloudy, cloudy, fog, rain, heavyRain, snow (+5 more)

### Community 143 - "SeasonalPeriod"
Cohesion: 0.30
Nodes (7): SeasonalPeriod, spring, summer, autumn, winter, Double, WeatherAnalysisEngineIntegrationTests

### Community 28 - "Double"
Cohesion: 0.23
Nodes (5): Double, EnvironmentalCorrelation, WeatherAnalysisEngine, EnvironmentalSessionRecord, Bool

### Community 102 - "EnvironmentalFactor"
Cohesion: 0.12
Nodes (16): EnvironmentalFactor, temperature, feelsLikeTemperature, humidity, pressure, cloudCover, visibility, windSpeed (+8 more)

### Community 86 - "ReadingBehaviorMetric"
Cohesion: 0.10
Nodes (20): ReadingBehaviorMetric, readingDuration, pagesRead, chaptersCompleted, booksCompleted, readingSpeed, readingConsistency, readingFrequency (+12 more)

### Community 151 - "CorrelationLifecycle"
Cohesion: 0.18
Nodes (10): CorrelationLifecycle, emerging, strengthening, stable, weakening, declining, recurring, seasonal (+2 more)

### Community 122 - "WeatherInsightPanel"
Cohesion: 0.30
Nodes (5): WeatherInsightPanel, String, WeatherStatCard, CorrelationRow, Bool

### Community 198 - ".assembleAtSessionEnd"
Cohesion: 0.67
Nodes (4): Double, String, Bool, ReadingSessionMetrics

### Community 66 - ".normalise"
Cohesion: 0.19
Nodes (7): WeatherSnapshotNormaliser, CurrentWeather, Forecast, HourWeather, WeatherCondition, WeatherSnapshotNormaliserTests, Int

### Community 87 - "Coordinator"
Cohesion: 0.16
Nodes (10): NSObject, Context, PDFView, Coordinator, Coordinator, PDFViewDelegate, Timer, URL (+2 more)

### Community 79 - "GoalStatus"
Cohesion: 0.27
Nodes (10): GoalStatusCard, String, Int, GoalStatus, Double, String, BookDeadlineStatus, Book (+2 more)

### Community 199 - "GoalKind"
Cohesion: 0.33
Nodes (6): GoalKind, dailyPages, dailyTime, annualBooks, weeklyStreak, bookDeadline

### Community 93 - "SettingsRootView.swift"
Cohesion: 0.14
Nodes (10): SettingsRootView, DeadlineEditorPane, UUID, String, Date, RSVPSettingsPane, Double, MirageSettingsPane (+2 more)

### Community 123 - "InsightKind"
Cohesion: 0.14
Nodes (14): InsightKind, bestReadingTime, readingTrend, difficultyMatch, streakRisk, speedImprovement, goalOnTrack, goalBehind (+6 more)

### Community 185 - "ReadingInsightsDashboard.swift"
Cohesion: 0.29
Nodes (4): StatCard, InsightCard, ConfidencePip, Double

### Community 160 - "BookDetailsView"
Cohesion: 0.24
Nodes (3): BookDetailsView, UUID, Book

### Community 49 - "BookImporter.swift"
Cohesion: 0.16
Nodes (18): ZIPFoundation, Compression, String, Book, Int, DifficultyAnalyzer, ImportAnalyticsReport, Double (+10 more)

### Community 116 - "PDFReaderView"
Cohesion: 0.22
Nodes (10): PDFKit, NSViewRepresentable, PDFReaderView, Book, Int, Void, String, PDFReaderScreen (+2 more)

### Community 80 - ".importEPUB"
Cohesion: 0.21
Nodes (11): ImportError, unsupportedFileType, fileNotReadable, URL, epubMissingOPF, epubParseFailure, epubUnzipFailure, pdfOpenFailure (+3 more)

### Community 138 - ".importPDF"
Cohesion: 0.23
Nodes (6): PDFOutline, BookCoverCapture, CGFloat, PDFDocument, NSImage, NSSize

### Community 222 - "ImportWarningLevel"
Cohesion: 0.50
Nodes (4): ImportWarningLevel, info, warning, critical

### Community 186 - "LibraryFilterSidebarView"
Cohesion: 0.33
Nodes (5): LibraryFilterSidebarView, Book, String, Bool, Void

### Community 72 - "LibraryFilterState"
Cohesion: 0.13
Nodes (12): ReadingStatusFilter, all, notStarted, inProgress, completed, LibraryFilterState, Bool, UUID (+4 more)

### Community 187 - "AdaptiveLayoutTier"
Cohesion: 0.29
Nodes (5): AdaptiveLayoutTier, floatingCluster, shallowPerspective, fullSpatialNavigator, Int

### Community 51 - "BookVisualState"
Cohesion: 0.09
Nodes (20): BookVisualState, RotationStyle, flat, threeDimensional, CGSize, Double, Bool, View (+12 more)

### Community 115 - "SpatialNavigatorCard"
Cohesion: 0.18
Nodes (11): SpatialNavigatorCard, Book, CGFloat, Bool, Void, SpatialNavigatorView, Book, Bool (+3 more)

### Community 8 - "MirageImportOutcome"
Cohesion: 0.05
Nodes (37): MirageAnalysisSheet, Book, Status, Status, idle, running, done, String (+29 more)

### Community 25 - "MirageClient"
Cohesion: 0.14
Nodes (18): MirageAnalyzeSession, Bool, MirageClient, MirageIdentityMapStore, URL, JSONEncoder, JSONDecoder, Bool (+10 more)

### Community 11 - "MirageSidecarSupervisor"
Cohesion: 0.11
Nodes (26): MirageChildLauncher, MirageSidecarSupervisor, Configuration, URL, TimeInterval, async, Void, Bool (+18 more)

### Community 29 - ".perform"
Cohesion: 0.10
Nodes (17): String, Outcome, success, MirageJSONValue, engineError, Fault, responseUnparsable, correlationFailure (+9 more)

### Community 94 - "MirageCursorGateError"
Cohesion: 0.18
Nodes (12): MirageCursor, absent, estimated, Double, Int, page, unit, MirageCursorGateError (+4 more)

### Community 139 - "MirageDetailRequest"
Cohesion: 0.29
Nodes (7): String, detailProbeRejected, MirageDetailRequest, MirageDetailQuery, MirageSpoilerProbeTests, MirageCursor, String

### Community 56 - ".makeFixture"
Cohesion: 0.23
Nodes (11): MirageSourceFingerprint, Data, mirageReceiptFixture(), String, Bool, Data, mirageBooksListFixture(), MirageIdentityDriftTests (+3 more)

### Community 18 - "MirageBundledRuntimeTests"
Cohesion: 0.11
Nodes (17): MirageRuntimeChannel, bundled, dev, MirageRuntime, URL, MirageRuntimeManifest, Data, MirageRuntimeLocator (+9 more)

### Community 211 - "MirageSettings.swift"
Cohesion: 0.40
Nodes (3): MirageSettings, Bool, MirageSettingsCopy

### Community 31 - "MirageAnalysisStatus"
Cohesion: 0.12
Nodes (21): MirageInventoryEntry, String, Int, MirageAnalysisStatus, LinkState, notImported, linked, MirageIdentityMapEntry (+13 more)

### Community 67 - "MirageStatusSurfaceTests"
Cohesion: 0.16
Nodes (9): MirageJSONValue, MirageStatusInventory, MirageStatusSurfaceTests, EngineFixture, URL, RecordingBooksListTransport, String, Data (+1 more)

### Community 73 - "MirageJSONValue"
Cohesion: 0.11
Nodes (15): Encodable, MirageJSONValue, null, bool, Bool, int, double, Double (+7 more)

### Community 46 - "MirageWireAction"
Cohesion: 0.07
Nodes (29): MirageWireAction, health, version, importEpub, analyze, projection, search, checkpoint (+21 more)

### Community 14 - "NotificationCandidate"
Cohesion: 0.14
Nodes (25): NotificationCategory, readingOpportunity, streakProtection, completionEncouragement, momentumReinforcement, inactivityRecovery, chapterCompletion, sessionContinuation (+17 more)

### Community 144 - "OnboardingView"
Cohesion: 0.21
Nodes (5): UniformTypeIdentifiers, OnboardingView, Book, Bool, String

### Community 4 - "EPUBReaderScreen"
Cohesion: 0.06
Nodes (35): os, EPUBSpineItem, String, URL, EPUBPackageError, securityScopeUnavailable, cannotReadContainerXML, opfPathNotFound (+27 more)

### Community 62 - ".recommend"
Cohesion: 0.25
Nodes (11): BookRecommendationScoreV3, UUID, String, Double, RecommendationResultV3, Date, TimeInterval, PredictiveRecommendationEngineV3 (+3 more)

### Community 140 - "RecommendationCard"
Cohesion: 0.21
Nodes (11): RecommendationPanel, Bool, UUID, RecommendationCard, Int, Book, Void, ScoreGauge (+3 more)

### Community 37 - ".generate"
Cohesion: 0.17
Nodes (18): Int, Calendar, sessions(), Book, booksRead(), booksCompleted(), AnnualReportData, Date (+10 more)

### Community 188 - "analyticsPeriod"
Cohesion: 0.62
Nodes (3): analyticsPeriod(), NonGregorianCalendarTests, Calendar

### Community 106 - "NewYearTransitionMonitor.swift"
Cohesion: 0.20
Nodes (6): NewYearTransitionMonitor, Timer, DebugCelebrationBus, NewYearTransitionAwareModifier, Content, View

### Community 124 - "NewYearCelebrationOverlay"
Cohesion: 0.27
Nodes (7): Bool, NewYearCelebrationOverlay, Void, Task, Never, TimeInterval, CelebrationTimeline

### Community 189 - "SnowParticle"
Cohesion: 0.38
Nodes (6): Double, SnowParticle, UUID, CGFloat, Date, SnowflakeParticleView

### Community 212 - "CelebrationPhase"
Cohesion: 0.40
Nodes (5): CelebrationPhase, toast, expanding, fullscreen, exiting

### Community 223 - "Step"
Cohesion: 0.50
Nodes (4): Step, expand, fullscreen, autoExit

### Community 200 - "SheetDismissAffordance"
Cohesion: 0.33
Nodes (4): ViewModifier, SheetDismissAffordance, Content, View

### Community 171 - "SessionHistoryView"
Cohesion: 0.28
Nodes (7): SessionHistoryView, Int, Book, SessionHistoryRow, String, AudioPill, AudioDetailView

### Community 152 - "ContentView"
Cohesion: 0.18
Nodes (13): View, ContentView, Book, DispatchWorkItem, String, Bool, Int, URL (+5 more)

### Community 96 - "LibrarySortMode"
Cohesion: 0.25
Nodes (8): LibrarySortMode, dateAddedDesc, dateAddedAsc, titleAsc, titleDesc, author, recentlyRead, progress

### Community 224 - "BedrockBaselineTests.swift"
Cohesion: 0.50
Nodes (3): benchmarkEnv(), String, BedrockBaselineTests

### Community 161 - "DismissalFlag"
Cohesion: 0.33
Nodes (3): DismissalFlag, Bool, CelebrationTimelineTests

### Community 141 - ".disabledFeatureNeverRunsTheStatusRunner"
Cohesion: 0.24
Nodes (6): MirageFeatureLifecycleTests, Bool, Book, MirageIdentityMapEntry, CountingRunnerForLifecycle, Int

### Community 172 - "MirageIdentityRealEngineImportTests.swift"
Cohesion: 0.33
Nodes (7): mirageZipFixtureDirectory(), URL, MirageImportFault, String, writeMinimalRealEpubFixture(), Bool, MirageIdentityRealEngineImportTests

### Community 226 - "ProbeTripwireTransport"
Cohesion: 0.50
Nodes (3): ProbeTripwireTransport, Int, Data

### Community 162 - "GoalStreakTests"
Cohesion: 0.56
Nodes (3): GoalStreakTests, Int, UUID

### Community 190 - "SQLiteFoundationTests.swift"
Cohesion: 0.38
Nodes (4): sqliteEnv(), String, SQLiteFoundationTests, URL

### Community 177 - "SchemaEvolutionTests"
Cohesion: 0.25
Nodes (3): SchemaEvolutionTests, JSONEncoder, JSONDecoder

### Community 145 - ".record"
Cohesion: 0.35
Nodes (4): WeatherConfidencePinsTests, Date, Double, String

### Community 125 - "WeatherSnapshotStoreTests"
Cohesion: 0.25
Nodes (6): Date, WeatherSnapshotStoreTests, WeatherSnapshotStore, URL, WeatherSnapshotStore, UUID

### Community 107 - "AsterismaV1_0UITests"
Cohesion: 0.16
Nodes (7): XCTest, AsterismaV1_0UITests, XCTestCase, AsterismaV1_0UITestsLaunchTests, Bool, makeIsolatedApp(), XCUIApplication

### Community 210 - "generate-app-icon.py"
Cohesion: 0.60
Nodes (5): lerp(), rounded_mask(), radial_gradient(), star(), main()

### Community 182 - "observe.py"
Cohesion: 0.50
Nodes (7): sha256(), tree_digest(), load_manifest(), compute(), check(), append_row(), main()

### Community 32 - "08 · Deep Audit (Oct 2026)"
Cohesion: 0.06
Nodes (34): 08 · Deep Audit (Oct 2026), 0. TL;DR — the 60-second version, 1. What this project is, 2. Method & verification performed THIS audit (nothing inherited), 3. Where we are project-wise (the honest scoreboard), 4. The numbers (all directly validated today), 5. Strengths (verified, not flattery), 6. Weaknesses (verified) (+26 more)

### Community 126 - "09 · Final Traces performance marathon"
Cohesion: 0.14
Nodes (13): Execution order (risk-graded), Standing lessons that shape every decision, BASELINE, PHASE A LOG — Covers → files + NSCache, PHASE A SHIPPED, PHASE B LOG — Upgrade #5 AnalyticsCache, PHASE C/D LOG — Upgrade #4 safe slice (#3 groundwork next session), REMAINING BLUEPRINTS (for next sessions) (+5 more)

### Community 81 - "10 · Profiler fix (freeze post-mortem)"
Cohesion: 0.10
Nodes (20): Reading Tracker — Developer Console Freeze / Crash Fix, Summary, What We Were Seeing, The Important Debugging Decision, What `sample` Showed, What an `EnvironmentObject` Means, What We Found in `DemoProfileLabView`, Why the Developer Console Was Different (+12 more)

### Community 15 - "PR-4 Current-State Defect Analysis — Real Sidecar Lifecycle"
Cohesion: 0.04
Nodes (46): PR-4 Current-State Defect Analysis — Real Sidecar Lifecycle, Table of Contents, 1. Executive Summary, 2. Investigation Scope and Current-State Snapshot, 2.1 Scope boundaries, 2.2 Repository snapshot (verified 2026-10-18 ~18:0x Eastern), 2.3 Merge-distance snapshot (management estimate, unchanged from session), 3. Environment and Reproduction Context (+38 more)

### Community 180 - "PR-5 Execution Plan — Identity Map + One-Book Import (drafted 2026-10-18 evening)"
Cohesion: 0.25
Nodes (7): PR-5 Execution Plan — Identity Map + One-Book Import (drafted 2026-10-18 evening), 0. Gate contract + pre-decided locks (nothing below may be silently renegotiated), 1. Runtime file plan (feature-module only; RT store untouched), 2. Wire interaction — the one unpinned fact to extract FIRST, 3. Pinned-case matrix (the gate's seven), 4. Sequencing (next session, in order), 5. Owner questions reserved for the next session (do not decide silently)

### Community 84 - "🧭 Navigation Hub — read this first"
Cohesion: 0.10
Nodes (20): Reading Tracker + Mirage — Safe Codebase Integration Playbook, 🧭 Navigation Hub — read this first, Document map, Reading paths by role, Table of contents, Conventions & code registries, 0. Executive directive, 0.1 Required outcome (+12 more)

### Community 227 - "1. Source-derived baseline and confidence rules"
Cohesion: 0.50
Nodes (4): 1. Source-derived baseline and confidence rules, 1.1 Reading Tracker baseline stated in the README, 1.2 Mirage baseline stated in the README, 1.3 Evidence labels required throughout this project

### Community 205 - "2. Product and architecture contract"
Cohesion: 0.33
Nodes (6): 2. Product and architecture contract, 2.1 Parent-child relationship, 2.2 Proposed logical component layout, 2.3 Integration transport: evaluate before choosing, 2.4 Protocol rules, 2.5 Optional feature behavior

### Community 193 - "3. Data ownership, identity, and synchronization"
Cohesion: 0.29
Nodes (7): 3. Data ownership, identity, and synchronization, 3.1 One system of truth per domain, 3.2 Identity mapping is a first-class subsystem, 3.3 Importing a book into Mirage, 3.4 Reading position and spoiler cursor, 3.5 Series and cross-book context, 3.6 Corrections and user suggestions

### Community 206 - "4. Repository strategy and GitHub safety"
Cohesion: 0.33
Nodes (6): 4. Repository strategy and GitHub safety, 4.1 Decide runtime integration before repository consolidation, 4.2 Repository inventory before any migration, 4.3 Safe Git procedure, 4.4 If the repositories are eventually consolidated, 4.5 Repository-level acceptance checklist

### Community 228 - "5. Phase 0 — Governance, scope, and stop conditions"
Cohesion: 0.50
Nodes (4): 5. Phase 0 — Governance, scope, and stop conditions, 5.1 Assign accountable owners, 5.2 Define scope and acceptance in writing, 5.3 Stop conditions

### Community 207 - "6. Phase 1 — Establish and verify both baselines"
Cohesion: 0.33
Nodes (6): 6. Phase 1 — Establish and verify both baselines, 6.1 Freeze exact source revisions, 6.2 RT baseline commands, 6.3 Mirage baseline commands, 6.4 Read normative documents before implementation, 6.5 Baseline exit gate

### Community 219 - "7. Phase 2 — Source-code discovery and contract extraction"
Cohesion: 0.40
Nodes (5): 7. Phase 2 — Source-code discovery and contract extraction, 7.1 Inventory actual code, not just READMEs, 7.2 Create an interface inventory, 7.3 Inspect persistence and migration boundaries, 7.4 Publish three review artifacts

### Community 220 - "8. Phase 3 — Fix or isolate pre-existing RT risks"
Cohesion: 0.40
Nodes (5): 8. Phase 3 — Fix or isolate pre-existing RT risks, 8.1 Do not bury known defects in the merge, 8.2 Define a pre-existing-defect policy, 8.3 Protect RT's concurrency model, 8.4 Phase exit gate

### Community 208 - "9. Phase 4 — Build the integration boundary first"
Cohesion: 0.33
Nodes (6): 9. Phase 4 — Build the integration boundary first, 9.1 Implement a host-owned service abstraction, 9.2 Implement lifecycle management, 9.3 Validate every message, 9.4 Keep UI independent, 9.5 Integration-boundary tests

### Community 202 - "10. Phase 5 — Implement the book/edition and cursor adapter"
Cohesion: 0.33
Nodes (6): 10. Phase 5 — Implement the book/edition and cursor adapter, 10.1 Start with one explicit user-selected book, 10.2 Verify identity after import, 10.3 Establish the cursor contract, 10.4 Synchronization timing, 10.5 Adapter acceptance gate

### Community 216 - "11. Phase 6 — Expose Mirage as an optional RT feature"
Cohesion: 0.40
Nodes (5): 11. Phase 6 — Expose Mirage as an optional RT feature, 11.1 Feature entry point and settings, 11.2 Query experience, 11.3 Loading, errors, and accessibility, 11.4 User-facing data controls

### Community 217 - "12. Phase 7 — Security, privacy, and local-first guarantees"
Cohesion: 0.40
Nodes (5): 12. Phase 7 — Security, privacy, and local-first guarantees, 12.1 Preserve local-only operation, 12.2 File and process boundary, 12.3 Logs and diagnostics, 12.4 Dependency and supply-chain checks

### Community 192 - "13. Phase 8 — Testing strategy and quality gates"
Cohesion: 0.29
Nodes (7): 13. Phase 8 — Testing strategy and quality gates, 13.1 Preserve independent test suites, 13.2 Unit tests, 13.3 Integration tests, 13.4 Regression and failure injection, 13.5 UI and accessibility testing, 13.6 Performance budgets

### Community 203 - "14. Phase 9 — Build, packaging, and release engineering"
Cohesion: 0.33
Nodes (6): 14. Phase 9 — Build, packaging, and release engineering, 14.1 Decide how Mirage is distributed with RT, 14.2 Reproducible build process, 14.3 macOS signing, sandbox, and entitlements, 14.4 CI design, 14.5 Release gate

### Community 218 - "15. Phase 10 — Rollback, recovery, and operational support"
Cohesion: 0.40
Nodes (5): 15. Phase 10 — Rollback, recovery, and operational support, 15.1 Code rollback and data rollback are different, 15.2 Rollback triggers, 15.3 Recovery rehearsal, 15.4 Operational handoff

### Community 167 - "16. Implementation sequence and pull-request plan"
Cohesion: 0.20
Nodes (10): 16. Implementation sequence and pull-request plan, PR 1 — Baseline and documentation only, PR 2 — Architecture and protocol ADR, PR 3 — Host interface and fake transport, PR 4 — Real sidecar lifecycle and handshake, PR 5 — Identity mapping and one-book import, PR 6 — Cursor-safe read-only query, PR 7 — Optional-feature settings and lifecycle polish (+2 more)

### Community 204 - "18. Final acceptance checklist"
Cohesion: 0.33
Nodes (6): 18. Final acceptance checklist, Product and architecture, Data safety and correctness, Stability, testing, and performance, Security, privacy, and release, Repository governance

### Community 209 - "Appendix D — Multi-pass document audit"
Cohesion: 0.33
Nodes (6): Appendix D — Multi-pass document audit, D.1 Audit method, D.2 Required source-fidelity reminder, D.3 Final reviewer sign-off, D.4 Automated concurrent scan results, D.5 Final-artifact rescan

### Community 64 - "21. Technical escalation addendum (section-by-section ≥21× intensification layer)"
Cohesion: 0.08
Nodes (24): 21. Technical escalation addendum (section-by-section ≥21× intensification layer), 21.0 Escalation metric, doctrine, and non-execution charter, 21.1 Escalation of §0 — Executive directive → composition-theoretic topology, 21.2 Escalation of §1 — Baseline evidence hardening and reproducibility lattice, 21.3 Escalation of §2 — Integration contract, transport, protocol, and feature behavior, 21.4 Escalation of §3 — Data ownership, identity, and synchronization, 21.5 Escalation of §4 — Repository governance, Git safety, and supply-chain custody, 21.6 Escalation of §5 — Governance topology, scope calculus, and stop-condition lattice (+16 more)

### Community 194 - "Appendix F — Quick reference (one-page cheat sheet)"
Cohesion: 0.29
Nodes (7): Appendix F — Quick reference (one-page cheat sheet), F.1 The ten rules that rule everything, F.2 Phase & gate map, F.3 PR ladder, F.4 Key facts & versions (README-REPORTED — re-verify at the pinned SHA), F.5 Templates, F.6 Where to file things

### Community 74 - "22. The Titanium Bridge (TiB) — continuous-convergence subsystem"
Cohesion: 0.09
Nodes (22): 22. The Titanium Bridge (TiB) — continuous-convergence subsystem, 22.0 The contract — formal SLO and the four sub-guarantees, 22.1 Identity model — commits, generations, and why diffs are the wrong unit, 22.2 Topology — one bridge, two rings, one direction of truth, 22.3 Generation manifest, transport, and determinism of assembly, 22.4 The change-classification engine — not every line is "just a line", 22.5 The 60-second pipeline, hop by hop — and the 4:00 PM story, 22.6 Atomic swap engineering — pointer flips on APFS (+14 more)

### Community 52 - "🖥️ Part 2 — MirageV1.0"
Cohesion: 0.07
Nodes (26): 📚 Twin READMES, ⚡ At a glance, 📇 How to navigate, 😴 Part 1 — “Reading Tracker”, A macOS reading-analytics app, 1 · What it is, 2 · The numbers (validated by direct count, Oct 17 2026), 3 · Current health (verified live, not inherited) (+18 more)

### Community 215 - "ADR-12 — Titanium Bridge (TiB) charter: continuous convergence across the guarded boundary"
Cohesion: 0.40
Nodes (4): ADR-12 — Titanium Bridge (TiB) charter: continuous convergence across the guarded boundary, Problem statement, Decision (proposed), Consequences

### Community 163 - "ADR-2: integration transport & protocol (managed stdio NDJSON sidecar)"
Cohesion: 0.20
Nodes (9): Problem statement, Context (evidence-anchored), Alternatives considered, Decision, Consequences, Security & privacy impact, Rollback implications, Tests required (named; implemented in the PR that introduces them) (+1 more)

### Community 173 - "ADR-3 — Packaged runtime distribution (engine + interpreter bundled with RT)"
Cohesion: 0.22
Nodes (8): ADR-3 — Packaged runtime distribution (engine + interpreter bundled with RT), Problem statement, Source-anchored comparative analysis, Decision (PR-8 implementation charter), Consequences, Security & privacy impact, Tests, Approving owners

### Community 164 - "ADR-4 — Data directories, Mirage ledger placement & backup ownership"
Cohesion: 0.20
Nodes (9): ADR-4 — Data directories, Mirage ledger placement & backup ownership, Problem statement, Context (evidence-anchored), Alternatives considered, Decision, Consequences, Security & privacy impact, Rollback implications (+1 more)

### Community 165 - "ADR-5: identity-mapping contract (RT Book ↔ Mirage book/edition)"
Cohesion: 0.20
Nodes (9): Problem statement, Context (evidence-anchored), Alternatives considered, Decision, Consequences, Security & privacy impact, Rollback implications, Tests required (named; implemented in the PR that introduces them) (+1 more)

### Community 174 - "ADR-6 — Mirage as an optional RT feature: lifecycle governance (canonical §17 seat)"
Cohesion: 0.22
Nodes (8): ADR-6 — Mirage as an optional RT feature: lifecycle governance (canonical §17 seat), Problem statement, Decision, Alternatives considered, Consequences, Tests, Approving owners, Supersedes / superseded-by

### Community 191 - "ADR-6a — Mirage import-path independence from RT's onboarding-import bypass (NEW-DE-5)"
Cohesion: 0.29
Nodes (6): ADR-6a — Mirage import-path independence from RT's onboarding-import bypass (NEW-DE-5), Context, Decision (the independence argument, path-anchored), Boundaries (what this ADR is NOT), Structural-census gate (verified each merge-log census, first at M-024), Countersign

### Community 82 - "ADR-7 — Spoiler-cursor contract (with S10-ES-3 formal sub-document as annex)"
Cohesion: 0.10
Nodes (20): ADR-7 — Spoiler-cursor contract (with S10-ES-3 formal sub-document as annex), Problem statement, Context (source-anchored), Decision, Alternatives (considered, rejected), Consequences, Security & privacy impact, Rollback implications (+12 more)

### Community 201 - "ADR-8 — Repository strategy: two canonical repositories, one verified vendored copy (canonical §17 seat)"
Cohesion: 0.33
Nodes (5): ADR-8 — Repository strategy: two canonical repositories, one verified vendored copy (canonical §17 seat), Problem statement, Context, Decision, Consequences

### Community 178 - "§15.4 Operational handoff bundle — RT ⇄ Mirage integration (2026-10-18)"
Cohesion: 0.25
Nodes (7): §15.4 Operational handoff bundle — RT ⇄ Mirage integration (2026-10-18), Identify the running Mirage process, Check version / protocol compatibility, Locate the approved ledger (and what may touch it), Backups (both systems, independently — §18 row), Feature on/off and failure states (operator-facing), The packaged runtime (PR-8)

### Community 179 - "§18 Final Acceptance Checklist (2026-10-18, ladder complete)"
Cohesion: 0.25
Nodes (7): Product and architecture, Data safety and correctness, Stability, testing, performance, Security, privacy, release, Repository governance, Honest deltas (not acceptance-blocking, ledgered), §18 Final Acceptance Checklist (2026-10-18, ladder complete)

### Community 175 - "Evidence artifact — MirageV1.0 normative docs + wire protocol extraction (Phase 1/2)"
Cohesion: 0.22
Nodes (8): Evidence artifact — MirageV1.0 normative docs + wire protocol extraction (Phase 1/2), Version boundaries (embedding.md:16-20 + source), Wire protocol (P-1 … P-10, PROVEN unless marked), Doctrine (mission statement — binding on RT as host), Storage facts, Import identity (service.py:84-174), Reading state & cursor (host-supplied truth), Protocol-pinning tests (server-of-record for the wire contract)

### Community 176 - "Binding claims (path:line-anchored)"
Cohesion: 0.22
Nodes (8): Evidence artifact — RT normative-document extraction (Phase 1/2), Binding claims (path:line-anchored), Persistence & write path, NEW-DE defect register (lives ONLY in the audit's §7 — NOT in 02-defect-register.md; grep-verified absence), Integration-relevant standing rules (RT house standards), Architectural tracks (planned-not-executed; do NOT combine with integration), Cross-document conflicts (PR-1 must resolve), Live-verified (TEST-VERIFIED, this session)

### Community 142 - "RT critical facts (root `/Users/johanrembeci/Desktop/Reading Tracker Main /`)"
Cohesion: 0.15
Nodes (12): Evidence artifact — cross-codebase touchpoint inventory (Phase 1/2), RT critical facts (root `/Users/johanrembeci/Desktop/Reading Tracker Main /`), Entry & surfaces, Persistence (single-writer discipline), Reader position (authoritative model), Import & sessions fan-out, Concurrency idioms (under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, project.pbxproj:441-442/477-478), Build settings & sandbox (uniform Debug/Release; pbxproj lines Debug/Release) (+4 more)

### Community 166 - "§15.3 recovery rehearsal log — S15-ES-3 artifacts (2026-10-18 session)"
Cohesion: 0.20
Nodes (9): §15.3 recovery rehearsal log — S15-ES-3 artifacts (2026-10-18 session), R1 — Code rollback rehearsal (in vivo), R2 — Sidecar crash recovery (test-anchored, live receipt from tonight's census), R3 — Failed initialization (corrupt/disabled state → contained posture), R4 — Invalid mapping recovery (stale/mismatched fingerprint flow), R5 — Documented data-backup restore (disposable data), SQLite discipline verified from source, Census receipts for this scaffold, R6 — Packaged-runtime staging + spawn-from-bundle (PR-8 / ADR-3, executed live) (+1 more)

### Community 195 - "TB-M0 gate plan — manifest + hash-verify in observe mode (OPEN — ADR-12 countersigned 2026-10-18)"
Cohesion: 0.29
Nodes (6): TB-M0 gate plan — manifest + hash-verify in observe mode (OPEN — ADR-12 countersigned 2026-10-18), Goal, Scope (what TB-M0 will materially add per §22.19.1), Exit evidence (per §22.19.1, verbatim bar), Operating rules while TB-M0 runs, What TB-M0 will NOT decide

### Community 108 - "06 · RSVP Feature Plan"
Cohesion: 0.12
Nodes (15): 06 · RSVP Feature Plan, What this document is, 1. What is readrrr doing?, 2. How does it work?, 3. Why build this?, 4. How can we integrate it?, 5. Why is this plausible on this platform?, 6. What do we need to do, in order? (+7 more)

### Community 153 - "Reaction wave (badge/goal recompute on main after bulk swap)"
Cohesion: 0.18
Nodes (11): THE LAST DEFEAT — demo profile freeze saga, Winter Romantic persona (≈620 sessions / 185,000 page-timings), DemoDataService (fabricates deterministic fake history), DemoProfileLabView (console screen with Install button), Reaction wave (badge/goal recompute on main after bulk swap), LibraryBatchUpdate bracket (suspend listeners during bulk swap), SentinelEngine (implementation of the Sentinel), AchievementEngine (badge thresholds walker) (+3 more)

### Community 214 - "Diagnostics: xcodebuild test run 2026-08-26"
Cohesion: 0.40
Nodes (5): NEW-DE-12: test hygiene (CoverStore.shared side effects), Upgrade #2: CoverStore content-addressed cover files + NSCache, Diagnostics: xcodebuild test run 2026-08-26, DurabilityPinsTests.exportImportRoundTrip failure (Aug 26), OPE-001: stub-cover debris corpus (hash-family cleanup, Class Δ gate)

### Community 98 - "Testing Strategy"
Cohesion: 0.15
Nodes (17): Census CI Workflow, Merge-Presence Receipt, Owner Actions Toggle Prerequisite, Standing Census 212/0/9, Finality / Log / Pin Fix Protocol, Test Coverage and Isolation Gaps, BUG-003 iCloud File Provider CodeSign Failure, OPE-001 Stub Cover Cleanup (+9 more)

### Community 97 - "AsterismaV1.0 Project Report (README)"
Cohesion: 0.14
Nodes (18): AsterismaV1.0 Project Report (README), Mirage Companion Engine, One Analyze, One Sidecar Lifecycle, DataStore3 Persistence Layer, PersistenceWriter Serial Write Queue, AnalyticsCache Memoization, Sentinel Self-Repair Watchdog, Sentinel Security Doctrine S1-S7 (+10 more)

### Community 83 - "RT-Mirage Merge Log"
Cohesion: 0.15
Nodes (21): Typed One-Way Spawn Boundary, RT/Mirage Store Ownership Doctrine, RT-Mirage Merge Log, 8-PR Integration Ladder (PR-1 to PR-8), NDJSON Stdio Wire Protocol, ADR-2 Transport and Protocol, ADR-3 Packaged Runtime Distribution, ADR-4 Ledger Placement and Backup Ownership (+13 more)

### Community 90 - "Bedrock Session Record (2026-10-24)"
Cohesion: 0.13
Nodes (19): GRDB/SQLite Summary Store, library.json Monolith, Asterisma Rebrand Record, AppIdentity Migration, Data Root Migration ReadTracker to Asterisma, Pre-Rename Rollback Snapshot, Duplicate Achievements Bug, Persistence Write Reordering Defect (+11 more)

### Community 63 - "Bedrock Master Plan"
Cohesion: 0.12
Nodes (24): Behavior Context V3, Open-Meteo Weather Provider, Completion and Health Report (2026-10-24), Byte-Weighted Completion Model (67.1%), Crash-Window Time Inflation, WeatherKit/Location Entitlement Gap, Behavior Context Evidence Starvation, Dead/Dormant Code Inventory (+16 more)

### Community 181 - "AsterismaV1.0 Release Package"
Cohesion: 0.32
Nodes (8): AsterismaV1.0 Release Package, Distribution Readiness Gap, Bundle Identifier MVP Constraint, D-001 Local-First Distribution, Local Distribution Guide, One-Time Gatekeeper Right-Click Step, Notarization / Developer ID Gap, Final Merge to main at aba8aa4

### Community 6 - "Stage B — Bedrock / Asterisma"
Cohesion: 0.07
Nodes (57): Gate G2 — Local distribution baseline, Ad-hoc signed Release package, Embedded Mirage runtime, RUNTIME-MANIFEST.json, GRDB SQLite foundation, LibraryDatabase, Transactional JSON-to-SQLite import, Lazy page-timing loading (+49 more)

## Knowledge Gaps
- **1165 isolated node(s):** `id`, `title`, `author`, `fileURL`, `fileType` (+1160 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **190 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Foundation` connect `Foundation` to `MaturityEvidenceDigest`, `DataStore`, `ConsoleSubsystemSnapshot`, `RSVPPlaybackEngine`, `AvailabilityState`, `BookDiscoveryService`, `GutendexBook`, `MirageProcessTransport`, `MirageImportOutcome`, `EPUBReaderScreen`, `BehaviorContextEngine2.swift`, `MirageSidecarSupervisor`, `NotificationCandidate`, `.validate`, `SentinelEngine.swift`, `ReadingSession`, `MirageBundledRuntimeTests`, `.generateBooks`, `Equatable`, `MirageClient`, `AppKit`, `.dataRootURL`, `.perform`, `AudioCategory`, `.evidence`, `EnvironmentState`, `.estimate`, `AudioMonitorService`, `MirageAnalysisStatus`, `DismissalFlag`, `.generate`, `BehavioralCategory.swift`, `DeveloperConsoleSystemMetrics`, `ReadingInsight`, `MirageIdentityRealEngineImportTests.swift`, `LocationProvider`, `BookImporter.swift`, `SchemaEvolutionTests`, `.makeFixture`, `AdaptiveLayoutTier`, `AnalyticsEngine.swift`, `.recommend`, `SQLiteFoundationTests.swift`, `LibraryArchive`, `AudioContextProfile`, `LibraryFilterState`, `MirageJSONValue`, `AchievementDefinition`, `MirageSettings.swift`, `OpenMeteoLiveSmokeTests.swift`, `AnalyticsCache`, `.versionIsSupported`, `MirageCursorGateError`, `State`, `BedrockBaselineTests.swift`, `G1CorrectnessPinsTests.swift`, `BookDeadline`, `WeatherAnalysisEngine.swift`, `AnalyticsCachePinsTests.swift`, `WeatherLivePipelineTests.swift`, `.enqueue`, `CodingKeys`, `EnvironmentAnchorPeriod`, `EnvironmentColor`, `OpenMeteoProvider.swift`, `Combine`, `DemoRapidSwitchTests`, `SeededGenerator`?**
  _High betweenness centrality (0.158) - this node is a cross-community bridge._
- **Why does `DataStore` connect `DataStore` to `SentinelPaneView`, `ConsoleSubsystemSnapshot`, `BehavioralCategory`, `RecommendationCard`, `AnalyticsEngine`, `OnboardingView`, `.validate`, `.addBook`, `.generateBooks`, `ContentView`, `Double`, `BookDetailsView`, `AudioProfileStore`, `CoverStore`, `SessionHistoryView`, `SchemaEvolutionTests`, `SessionCoordinator`, `AnnualReportArchiveView`, `LibraryDatabase`, `SQLiteFoundationTests.swift`, `SentinelFinding`, `LibraryArchive`, `LibraryFilterState`, `AchievementDefinition`, `Color`, `.updateGoalSet`, `SettingsRootView.swift`, `BookDeadline`, `.runCycle`, `SentinelEngine`, `.enqueue`, `DailyActivity`, `DemoRapidSwitchTests`, `WeatherInsightPanel`?**
  _High betweenness centrality (0.058) - this node is a cross-community bridge._
- **Why does `WeatherSnapshot` connect `WeatherSnapshot` to `.normalise`, `WeatherAnalysisEngine.swift`, `.archiveSnapshot`, `WeatherConditionCategory`, `Sendable`, `SeasonalPeriod`, `.record`, `Identifiable`, `String`, `OpenMeteoProvider`, `Double`, `WeatherSnapshotStoreTests`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **What connects `id`, `title`, `author` to the rest of the system?**
  _1165 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `SessionCoordinator` be split into smaller, more focused modules?**
  _Cohesion score 0.1168091168091168 - nodes in this community are weakly interconnected._
- **Should `SwiftUI` be split into smaller, more focused modules?**
  _Cohesion score 0.06060606060606061 - nodes in this community are weakly interconnected._
- **Should `Foundation` be split into smaller, more focused modules?**
  _Cohesion score 0.12955465587044535 - nodes in this community are weakly interconnected._