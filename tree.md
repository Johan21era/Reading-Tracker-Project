# Reading Tracker — Project Tree

**Regenerated:** RA-002 remediation session close-out (all four roadmap phases complete).

| Target | Swift files | Non-blank/non-comment LOC |
|---|---|---|
| Reading Tracker (app) | 85 | ~26,411 |
| Reading TrackerTests | 12 | ~1,230 |
| Reading TrackerUITests | 2 | ~37 |
| **Total** | **99** | **~27,678** |

Notable changes this session: NEW `Features/Goals/SettingsRootView.swift` (goal/deadline editors),
NEW `Reading Tracker/PrivacyInfo.xcprivacy`, NEW `RemediationPinsTests.swift`,
`default.profraw` removed. Full detail: fix-log.md §RA-002.

```
Reading Tracker Main/
|   |-- 2026-08-23/
|   |   |-- graph.json
|   |   |-- GRAPH_REPORT.md
|   |   `-- manifest.json
|   |-- 2026-08-26/
|   |   |-- graph.json
|   |   |-- GRAPH_REPORT.md
|   |   `-- manifest.json
|   |-- cache/
|   |   |-- ast/
|   |   |   `-- v0.9.15/
|   |   `-- stat-index.json
|   |-- graph.html
|   |-- graph.json
|   |-- GRAPH_REPORT.md
|   `-- manifest.json
|-- Reading Tracker/
|   |-- Assets.xcassets/
|   |   |-- AccentColor.colorset/
|   |   |   `-- Contents.json
|   |   |-- AppIcon.appiconset/
|   |   |   `-- Contents.json
|   |   `-- Contents.json
|   |-- Core/
|   |   |-- Book2.swift
|   |   |-- DataIntegrityValidator.swift
|   |   |-- DataStore3.swift
|   |   `-- SharedTextUtilities.swift
|   |-- Engines/
|   |   |-- AnalyticsEngine.swift
|   |   |-- DataMaturityEngine.swift
|   |   |-- DataMaturityEngineAdapters.swift
|   |   `-- EstimationEngine.swift
|   |-- Features/
|   |   |-- Achievements/
|   |   |   |-- AchievementEngine2.swift
|   |   |   `-- AchievementPanel.swift
|   |   |-- Audio/
|   |   |   |-- AudioSnapshot.swift
|   |   |   |-- AudioTrackerMetadata2.swift
|   |   |   `-- MusicalAnalysisEngine.swift
|   |   |-- BehaviorContext/
|   |   |   |-- BehavioralCategory.swift
|   |   |   |-- BehaviorContextEngine2.swift
|   |   |   |-- BehaviorEvidenceBuilder.swift
|   |   |   `-- ContextInsightPanel.swift
|   |   |-- DeveloperConsole/
|   |   |   |-- DemoProfileLabView.swift
|   |   |   |-- DeveloperConsoleDashboardView.swift
|   |   |   |-- DeveloperConsoleObservable.swift
|   |   |   |-- DeveloperConsoleRegistry.swift
|   |   |   |-- DeveloperConsoleRootView.swift
|   |   |   |-- DeveloperConsoleSystemMetrics.swift
|   |   |   `-- DeveloperConsoleTypes.swift
|   |   |-- Discovery/
|   |   |   |-- Providers/
|   |   |   |-- BookDiscoveryView.swift
|   |   |   |-- DemoDataService.swift
|   |   |   |-- OnlineBook.swift
|   |   |   |-- OnlineBookDetailView.swift
|   |   |   |-- OnlineBookDiscoveryService.swift
|   |   |   |-- OnlineBookDiscoveryViewModel.swift
|   |   |   |-- OnlineBookProvider.swift
|   |   |   `-- OnlineBookRow.swift
|   |   |-- Environment/
|   |   |   |-- Engine/
|   |   |   |-- Stars/
|   |   |   |-- Weather/
|   |   |   `-- EnvironmentBackgroundView2.swift
|   |   |-- Goals/
|   |   |   |-- GoalsDashboard.swift
|   |   |   |-- ReadingGoalManager2.swift
|   |   |   `-- SettingsRootView.swift
|   |   |-- Insights/
|   |   |   |-- InsightEngine.swift
|   |   |   `-- ReadingInsightsDashboard.swift
|   |   |-- Library/
|   |   |   |-- Spatial/
|   |   |   |-- BookImporter.swift
|   |   |   |-- LibraryExplorerView2.swift
|   |   |   |-- LibraryFilterSidebarView.swift
|   |   |   |-- LibraryFilterState.swift
|   |   |   `-- LibraryView.swift
|   |   |-- Notifications/
|   |   |   |-- IntelligentNotificationEngine.swift
|   |   |   `-- NotificationScheduler2.swift
|   |   |-- Reader/
|   |   |   |-- EPUBPackage.swift
|   |   |   |-- EPUBReaderScreen.swift
|   |   |   `-- PDFReaderView2.swift
|   |   |-- Recommendations/
|   |   |   |-- PredictiveRecommendationEngine.swift
|   |   |   `-- RecommendationPanel2.swift
|   |   |-- Reports/
|   |   |   |-- AnnualReportArchiveView2.swift
|   |   |   |-- AnnualReportData2.swift
|   |   |   |-- AnnualReportView.swift
|   |   |   `-- NewYearTransitionMonitor.swift
|   |   `-- Sessions/
|   |       |-- SessionCoordinator2.swift
|   |       |-- SessionEventRouter2.swift
|   |       `-- SessionHistoryView.swift
|   |-- NewContentView.swift
|   |-- PrivacyInfo.xcprivacy
|   `-- ReadingTrackerApp 2.swift
|-- Reading Tracker.xcodeproj/
|   |-- project.xcworkspace/
|   |   |-- xcshareddata/
|   |   |   `-- swiftpm/
|   |   |-- xcuserdata/
|   |   |   `-- johanrembeci.xcuserdatad/
|   |   `-- contents.xcworkspacedata
|   |-- xcuserdata/
|   |   `-- johanrembeci.xcuserdatad/
|   |       |-- xcdebugger/
|   |       `-- xcschemes/
|   `-- project.pbxproj
|-- Reading TrackerTests/
|   |-- CelebrationTimelineTests.swift
|   |-- DemoProfileServiceTests.swift
|   |-- EnvironmentEngineTests.swift
|   |-- FatigueAnalyzerTests.swift
|   |-- LibraryCollectionTests.swift
|   |-- NonGregorianCalendarTests.swift
|   |-- Reading_TrackerTests.swift
|   |-- ReliabilityTests.swift
|   |-- RemediationPinsTests.swift
|   |-- SchemaEvolutionTests.swift
|   |-- TextExtractionTests.swift
|   `-- WeatherTests.swift
|-- Reading TrackerUITests/
|   |-- Reading_TrackerUITests.swift
|   `-- Reading_TrackerUITestsLaunchTests.swift
|-- CURRENT_AUDIT.md
|-- fix-log.md
|-- handoff.md
|-- Reading Tracker.entitlements
|-- Reading-Tracker-Info.plist
|-- README.md
|-- REMEDIATION_ROADMAP.md
|-- rsvp-speed-reading-feature-plan.md
|-- TESTING_STRATEGY.md
|-- tree.md
`-- UI REVIEW.rtf
```
