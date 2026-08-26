# Reading Tracker — Project Tree

**Regenerated:** P5 close-out (five production features; four shipped + one honestly reverted).

| Target | Swift files | Non-blank/non-comment LOC |
|---|---|---|
| Reading Tracker (app) | 92 | ~27,489 |
| Reading TrackerTests | 15 | ~1,610 |
| **Total** | **107** | **~29,099** |

New this session: Features/RSVP/ (tokenizer+engine+reader), Features/Onboarding/,
Features/Sessions/ReadingHUD.swift, Core/BookCoverSupport.swift,
Core/LibraryArchiveManager.swift. Tests: WeatherConfidencePinsTests,
RSVPLogicTests, DurabilityPinsTests. See fix-log §P5.

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
|   |   |-- BookCoverSupport.swift
|   |   |-- DataIntegrityValidator.swift
|   |   |-- DataStore3.swift
|   |   |-- LibraryArchiveManager.swift
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
|   |   |-- Onboarding/
|   |   |   `-- OnboardingView.swift
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
|   |   |-- RSVP/
|   |   |   |-- RSVPPlaybackEngine.swift
|   |   |   |-- RSVPReaderView.swift
|   |   |   `-- RSVPTokenizer.swift
|   |   `-- Sessions/
|   |       |-- ReadingHUD.swift
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
|   |-- DurabilityPinsTests.swift
|   |-- EnvironmentEngineTests.swift
|   |-- FatigueAnalyzerTests.swift
|   |-- LibraryCollectionTests.swift
|   |-- NonGregorianCalendarTests.swift
|   |-- Reading_TrackerTests.swift
|   |-- ReliabilityTests.swift
|   |-- RemediationPinsTests.swift
|   |-- RSVPLogicTests.swift
|   |-- SchemaEvolutionTests.swift
|   |-- TextExtractionTests.swift
|   |-- WeatherConfidencePinsTests.swift
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
