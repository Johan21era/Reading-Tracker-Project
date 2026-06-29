//
//  ReadingTrackerApp.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/29/26.
//


//
//  ReadingTrackerApp.swift
//  Reading Tracker
//
//  The @main entry point. Owns every long-lived ObservableObject and injects
//  them into the SwiftUI environment.
//
//  Full engine wiring:
//    DataStore + SessionCoordinator     — core read/write pipeline (unchanged)
//    GoalProgressViewModel.bind()       — reactive goal tracking after init
//    SessionEventRouter.bind()          — post-session cascade (weather, notifs, context)
//    BehaviorContextAccessKit           — starts observing NSWorkspace automatically
//    BehaviorContextEngine              — populated by SessionEventRouter at session end
//    NotificationScheduler              — permission requested once at launch
//    scenePhase .background             — clean session teardown + immediate save
//    .newYearTransitionAware()          — celebration overlay (self-contained modifier)
//

import SwiftUI

@main
struct ReadingTrackerApp: App {

    // MARK: - Owned State

    @StateObject private var dataStore:        DataStore
    @StateObject private var coordinator:      SessionCoordinator
    @StateObject private var goalVM            = GoalProgressViewModel()
    @StateObject private var eventRouter       = SessionEventRouter()
    @StateObject private var behaviorKit       = BehaviorContextAccessKit()
    @StateObject private var contextEngine     = BehaviorContextEngine()

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Init
    //
    // SessionCoordinator must receive the exact same DataStore instance owned
    // by the App — not a second ephemeral copy. Two-step StateObject init is
    // the standard pattern when one StateObject depends on another.

    init() {
        let store = DataStore()
        _dataStore   = StateObject(wrappedValue: store)
        _coordinator = StateObject(wrappedValue: SessionCoordinator(dataStore: store))
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(coordinator)
                .environmentObject(goalVM)
                .environmentObject(contextEngine)   // read by ContextInsightPanel
                .task {
                    // ── One-time pipeline bindings ──────────────────────────
                    // GoalProgressViewModel: subscribes to dataStore.$books via Combine.
                    // Refreshes automatically on every books change from this point on.
                    goalVM.bind(
                        to: dataStore,
                        goalSet: dataStore.libraryState.goalSet,
                        deadlines: dataStore.libraryState.deadlines
                    )

                    // SessionEventRouter: watches dataStore.$books for session close
                    // events and fans out to WeatherKit, notifications, and context engine.
                    eventRouter.bind(
                        to: dataStore,
                        behaviorKit: behaviorKit,
                        contextEngine: contextEngine
                    )

                    // BehaviorContextAccessKit: self-contained NSWorkspace observer.
                    // Calling startMonitoring() is all that is needed — it wires up
                    // all notification observers internally.
                    behaviorKit.startMonitoring()

                    // Notification permission — idempotent after first call.
                    await NotificationScheduler.shared.requestAuthorization()
                }
                // The New Year celebration modifier manages its own
                // NewYearTransitionMonitor @StateObject internally.
                .newYearTransitionAware()
        }
        // Safe teardown when the app moves to the background.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                coordinator.endAllActiveSessions()
                dataStore.saveImmediately()
                behaviorKit.stopMonitoring()
            }
            if newPhase == .active {
                behaviorKit.startMonitoring()
            }
        }
    }
}