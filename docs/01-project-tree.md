# 01 · Project Tree

(Regenerated Oct 17, 2026. 100 app · 18 tests · 2 UITest Swift files; 39,900 raw app LOC / 28,697 code; 108 tests. `graphify-out/` and `.git/` omitted; machine-local xcuserdata omitted.)

```
|-- docs
|   |-- audits
|   |   `-- 08-deep-audit.md
|   |-- history
|   |   |-- 09-final-traces.md
|   |   |-- 10-profiler-fix.md
|   |   |-- diagnostics-2026-08-26.txt
|   |   |-- freeze.txt
|   |   `-- LAST_DEFEAT_demo_profiles.txt
|   |-- method
|   |   `-- 07-testing-strategy.md
|   |-- registers
|   |   |-- 02-defect-register.md
|   |   |-- 03-fix-log.md
|   |   `-- 04-handoff.md
|   |-- roadmap
|   |   |-- 05-remediation-roadmap.md
|   |   `-- 06-rsvp-feature-plan.md
|   `-- 01-project-tree.md
|-- Reading Tracker
|   |-- Assets.xcassets
|   |   |-- AccentColor.colorset
|   |   |   `-- Contents.json
|   |   |-- AppIcon.appiconset
|   |   |   `-- Contents.json
|   |   `-- Contents.json
|   |-- Core
|   |   |-- AnalyticsCache.swift
|   |   |-- Book2.swift
|   |   |-- BookCoverSupport.swift
|   |   |-- CoverStore.swift
|   |   |-- DataIntegrityValidator.swift
|   |   |-- DataStore3.swift
|   |   |-- DesignGrid.swift
|   |   |-- LibraryArchiveManager.swift
|   |   |-- PersistenceWriter.swift
|   |   |-- SentinelDataBridge.swift
|   |   |-- SentinelEngine.swift
|   |   `-- SharedTextUtilities.swift
|   |-- Engines
|   |   |-- AnalyticsEngine.swift
|   |   |-- DataMaturityEngine.swift
|   |   |-- DataMaturityEngineAdapters.swift
|   |   `-- EstimationEngine.swift
|   |-- Features
|   |   |-- Achievements
|   |   |   |-- AchievementEngine2.swift
|   |   |   `-- AchievementPanel.swift
|   |   |-- Audio
|   |   |   |-- AudioSnapshot.swift
|   |   |   |-- AudioTrackerMetadata2.swift
|   |   |   `-- MusicalAnalysisEngine.swift
|   |   |-- BehaviorContext
|   |   |   |-- BehavioralCategory.swift
|   |   |   |-- BehaviorContextEngine2.swift
|   |   |   |-- BehaviorEvidenceBuilder.swift
|   |   |   `-- ContextInsightPanel.swift
|   |   |-- DeveloperConsole
|   |   |   |-- DemoProfileLabView.swift
|   |   |   |-- DeveloperConsoleDashboardView.swift
|   |   |   |-- DeveloperConsoleObservable.swift
|   |   |   |-- DeveloperConsoleRegistry.swift
|   |   |   |-- DeveloperConsoleRootView.swift
|   |   |   |-- DeveloperConsoleSystemMetrics.swift
|   |   |   |-- DeveloperConsoleTypes.swift
|   |   |   |-- SentinelPaneView.swift
|   |   |   `-- SentinelReportCardView.swift
|   |   |-- Discovery
|   |   |   |-- Providers
|   |   |   |   |-- GutenbergProvider.swift
|   |   |   |   `-- OpenLibraryProvider.swift
|   |   |   |-- BookDiscoveryView.swift
|   |   |   |-- DemoDataService.swift
|   |   |   |-- OnlineBook.swift
|   |   |   |-- OnlineBookDetailView.swift
|   |   |   |-- OnlineBookDiscoveryService.swift
|   |   |   |-- OnlineBookDiscoveryViewModel.swift
|   |   |   |-- OnlineBookProvider.swift
|   |   |   `-- OnlineBookRow.swift
|   |   |-- Environment
|   |   |   |-- Engine
|   |   |   |   |-- EnvironmentAnchorPeriod.swift
|   |   |   |   |-- EnvironmentColor.swift
|   |   |   |   |-- EnvironmentEngine2.swift
|   |   |   |   |-- EnvironmentMath.swift
|   |   |   |   |-- EnvironmentPalette.swift
|   |   |   |   `-- EnvironmentState.swift
|   |   |   |-- Stars
|   |   |   |   |-- ShootingStar.swift
|   |   |   |   |-- ShootingStarManager.swift
|   |   |   |   |-- ShootingStarView.swift
|   |   |   |   |-- Star.swift
|   |   |   |   |-- StarField.swift
|   |   |   |   `-- StarFieldView.swift
|   |   |   |-- Weather
|   |   |   |   |-- WeatherAnalysisEngine.swift
|   |   |   |   |-- WeatherEnvironmentModifier.swift
|   |   |   |   |-- WeatherInsightPanel2.swift
|   |   |   |   `-- WeatherKitService2.swift
|   |   |   `-- EnvironmentBackgroundView2.swift
|   |   |-- Goals
|   |   |   |-- GoalsDashboard.swift
|   |   |   |-- ReadingGoalManager2.swift
|   |   |   `-- SettingsRootView.swift
|   |   |-- Insights
|   |   |   |-- InsightEngine.swift
|   |   |   `-- ReadingInsightsDashboard.swift
|   |   |-- Library
|   |   |   |-- Spatial
|   |   |   |   |-- AdaptiveLayoutTier.swift
|   |   |   |   |-- BookCoverCardView.swift
|   |   |   |   |-- BookVisualState.swift
|   |   |   |   |-- FloatingClusterView2.swift
|   |   |   |   |-- ShallowPerspectiveView2.swift
|   |   |   |   |-- SpatialLibraryView2.swift
|   |   |   |   |-- SpatialNavigatorCard2.swift
|   |   |   |   `-- SpatialNavigatorView2.swift
|   |   |   |-- BookImporter.swift
|   |   |   |-- LibraryExplorerView2.swift
|   |   |   |-- LibraryFilterSidebarView.swift
|   |   |   |-- LibraryFilterState.swift
|   |   |   `-- LibraryView.swift
|   |   |-- Notifications
|   |   |   |-- IntelligentNotificationEngine.swift
|   |   |   `-- NotificationScheduler2.swift
|   |   |-- Onboarding
|   |   |   `-- OnboardingView.swift
|   |   |-- Reader
|   |   |   |-- EPUBPackage.swift
|   |   |   |-- EPUBReaderScreen.swift
|   |   |   `-- PDFReaderView2.swift
|   |   |-- Recommendations
|   |   |   |-- PredictiveRecommendationEngine.swift
|   |   |   `-- RecommendationPanel2.swift
|   |   |-- Reports
|   |   |   |-- AnnualReportArchiveView2.swift
|   |   |   |-- AnnualReportData2.swift
|   |   |   |-- AnnualReportView.swift
|   |   |   `-- NewYearTransitionMonitor.swift
|   |   |-- RSVP
|   |   |   |-- RSVPPlaybackEngine.swift
|   |   |   |-- RSVPReaderView.swift
|   |   |   `-- RSVPTokenizer.swift
|   |   `-- Sessions
|   |       |-- ReadingHUD.swift
|   |       |-- SessionCoordinator2.swift
|   |       |-- SessionEventRouter2.swift
|   |       `-- SessionHistoryView.swift
|   |-- NewContentView.swift
|   |-- PrivacyInfo.xcprivacy
|   `-- ReadingTrackerApp 2.swift
|-- Reading Tracker.xcodeproj
|   |-- project.xcworkspace
|   |   |-- xcshareddata
|   |   |   `-- swiftpm
|   |   |       |-- configuration
|   |   |       `-- Package.resolved
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- Reading TrackerTests
|   |-- AnalyticsCachePinsTests.swift
|   |-- CelebrationTimelineTests.swift
|   |-- CoverStorePinsTests.swift
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
|   |-- SentinelPinsTests.swift
|   |-- TextExtractionTests.swift
|   |-- WeatherConfidencePinsTests.swift
|   `-- WeatherTests.swift
|-- Reading TrackerUITests
|   |-- Reading_TrackerUITests.swift
|   `-- Reading_TrackerUITestsLaunchTests.swift
|-- .gitignore
|-- Reading Tracker.entitlements
|-- Reading-Tracker-Info.plist
`-- README.md
```
