# Reading Tracker Main — Project Tree

**Generated:** Phase 2 close-out (post Great Wiring)
**Exclusions (declared, not hidden):** `.git/` internals and `.DS_Store` files;
the Graphify AST cache body is collapsed with a count.
Everything else on disk is listed exactly as it exists.

```
├── .git/   [ omitted — version-control internals ]
├── graphify-out/
│   ├── 2026-08-23/
│   │   ├── .graphify_analysis.json
│   │   ├── .graphify_labels.json
│   │   ├── graph.json
│   │   ├── GRAPH_REPORT.md
│   │   └── manifest.json
│   ├── cache/
│   │   ├── ast/v0.9.15/   [ collapsed — 115 cached Graphify AST files ]
│   │   └── stat-index.json
│   ├── .graphify_analysis.json
│   ├── .graphify_labels.json
│   ├── .graphify_labels.json.sig
│   ├── .graphify_root
│   ├── graph.html
│   ├── graph.json
│   ├── GRAPH_REPORT.md
│   └── manifest.json
├── Reading Tracker/
│   ├── Assets.xcassets/
│   │   ├── AccentColor.colorset/
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset/
│   │   │   └── Contents.json
│   │   └── Contents.json
│   ├── Core/
│   │   ├── Book2.swift
│   │   ├── DataIntegrityValidator.swift
│   │   ├── DataStore3.swift
│   │   └── SharedTextUtilities.swift
│   ├── Engines/
│   │   ├── AnalyticsEngine.swift
│   │   ├── DataMaturityEngine.swift
│   │   ├── DataMaturityEngineAdapters.swift
│   │   └── EstimationEngine.swift
│   ├── Features/
│   │   ├── Achievements/
│   │   │   ├── AchievementEngine2.swift
│   │   │   └── AchievementPanel.swift
│   │   ├── Audio/
│   │   │   ├── AudioSnapshot.swift
│   │   │   ├── AudioTrackerMetadata2.swift
│   │   │   └── MusicalAnalysisEngine.swift
│   │   ├── BehaviorContext/
│   │   │   ├── BehavioralCategory.swift
│   │   │   ├── BehaviorContextEngine2.swift
│   │   │   ├── BehaviorEvidenceBuilder.swift
│   │   │   └── ContextInsightPanel.swift
│   │   ├── DeveloperConsole/
│   │   │   ├── DeveloperConsoleDashboardView.swift
│   │   │   ├── DeveloperConsoleObservable.swift
│   │   │   ├── DeveloperConsoleRegistry.swift
│   │   │   ├── DeveloperConsoleRootView.swift
│   │   │   ├── DeveloperConsoleSystemMetrics.swift
│   │   │   └── DeveloperConsoleTypes.swift
│   │   ├── Discovery/
│   │   │   ├── Providers/
│   │   │   │   ├── GutenbergProvider.swift
│   │   │   │   └── OpenLibraryProvider.swift
│   │   │   ├── BookDiscoveryView.swift
│   │   │   ├── OnlineBook.swift
│   │   │   ├── OnlineBookDetailView.swift
│   │   │   ├── OnlineBookDiscoveryService.swift
│   │   │   ├── OnlineBookDiscoveryViewModel.swift
│   │   │   ├── OnlineBookProvider.swift
│   │   │   ├── OnlineBookRow.swift
│   │   │   └── OnlineBookSearchDrawer.swift
│   │   ├── Environment/
│   │   │   ├── Engine/
│   │   │   │   ├── EnvironmentAnchorPeriod.swift
│   │   │   │   ├── EnvironmentColor.swift
│   │   │   │   ├── EnvironmentEngine2.swift
│   │   │   │   ├── EnvironmentMath.swift
│   │   │   │   ├── EnvironmentPalette.swift
│   │   │   │   └── EnvironmentState.swift
│   │   │   ├── Stars/
│   │   │   │   ├── ShootingStar.swift
│   │   │   │   ├── ShootingStarManager.swift
│   │   │   │   ├── ShootingStarView.swift
│   │   │   │   ├── Star.swift
│   │   │   │   ├── StarField.swift
│   │   │   │   └── StarFieldView.swift
│   │   │   ├── Weather/
│   │   │   │   ├── WeatherAnalysisEngine.swift
│   │   │   │   ├── WeatherEnvironmentModifier.swift
│   │   │   │   ├── WeatherInsightPanel2.swift
│   │   │   │   └── WeatherKitService2.swift
│   │   │   └── EnvironmentBackgroundView2.swift
│   │   ├── Goals/
│   │   │   ├── GoalsDashboard.swift
│   │   │   └── ReadingGoalManager2.swift
│   │   ├── Insights/
│   │   │   ├── InsightEngine.swift
│   │   │   └── ReadingInsightsDashboard.swift
│   │   ├── Library/
│   │   │   ├── Spatial/
│   │   │   │   ├── AdaptiveLayoutTier.swift
│   │   │   │   ├── BookCoverCardView.swift
│   │   │   │   ├── BookVisualState.swift
│   │   │   │   ├── FloatingClusterView2.swift
│   │   │   │   ├── ShallowPerspectiveView2.swift
│   │   │   │   ├── SpatialLibraryView2.swift
│   │   │   │   ├── SpatialNavigatorCard2.swift
│   │   │   │   └── SpatialNavigatorView2.swift
│   │   │   ├── BookImporter.swift
│   │   │   ├── LibraryExplorerView2.swift
│   │   │   ├── LibraryFilterSidebarView.swift
│   │   │   ├── LibraryFilterState.swift
│   │   │   └── LibraryView.swift
│   │   ├── Notifications/
│   │   │   ├── IntelligentNotificationEngine.swift
│   │   │   └── NotificationScheduler2.swift
│   │   ├── Reader/
│   │   │   ├── EPUBPackage.swift
│   │   │   ├── EPUBReaderScreen.swift
│   │   │   └── PDFReaderView2.swift
│   │   ├── Recommendations/
│   │   │   ├── PredictiveRecommendationEngine.swift
│   │   │   └── RecommendationPanel2.swift
│   │   ├── Reports/
│   │   │   ├── AnnualReportArchiveView2.swift
│   │   │   ├── AnnualReportData2.swift
│   │   │   ├── AnnualReportView.swift
│   │   │   └── NewYearTransitionMonitor.swift
│   │   └── Sessions/
│   │       ├── SessionCoordinator2.swift
│   │       ├── SessionEventRouter2.swift
│   │       └── SessionHistoryView.swift
│   ├── default.profraw
│   ├── NewContentView.swift
│   └── ReadingTrackerApp 2.swift
├── Reading Tracker.xcodeproj/
│   ├── project.xcworkspace/
│   │   ├── xcshareddata/
│   │   │   └── swiftpm/
│   │   │       ├── configuration/
│   │   │       └── Package.resolved
│   │   ├── xcuserdata/
│   │   │   └── johanrembeci.xcuserdatad/
│   │   │       └── UserInterfaceState.xcuserstate
│   │   └── contents.xcworkspacedata
│   ├── xcuserdata/
│   │   └── johanrembeci.xcuserdatad/
│   │       ├── xcdebugger/
│   │       │   └── Breakpoints_v2.xcbkptlist
│   │       └── xcschemes/
│   │           └── xcschememanagement.plist
│   └── project.pbxproj
├── Reading TrackerTests/
│   ├── CelebrationTimelineTests.swift
│   ├── EnvironmentEngineTests.swift
│   ├── FatigueAnalyzerTests.swift
│   ├── LibraryCollectionTests.swift
│   ├── NonGregorianCalendarTests.swift
│   ├── Reading_TrackerTests.swift
│   ├── ReliabilityTests.swift
│   ├── SchemaEvolutionTests.swift
│   ├── TextExtractionTests.swift
│   └── WeatherTests.swift
├── Reading TrackerUITests/
│   ├── Reading_TrackerUITests.swift
│   └── Reading_TrackerUITestsLaunchTests.swift
├── .gitignore
├── CURRENT_AUDIT.md
├── fix-log.md
├── handoff.md
├── Reading-Tracker-Info.plist
├── README.md
└── tree.md
42 directories, 128 files
```
