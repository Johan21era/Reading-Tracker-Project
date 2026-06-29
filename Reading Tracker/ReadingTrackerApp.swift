//
//  ReadingTrackerApp.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/28/26.
//


//
//  ReadingTrackerApp.swift
//  Reading Tracker
//
//  The @main entry point. Owns every long-lived ObservableObject and
//  injects them into the SwiftUI environment so all views share one
//  canonical instance of each.
//
//  Wires:
//    - GoalProgressViewModel  → DataStore.bind()       (reactive goal tracking)
//    - SessionEventRouter     → DataStore.bind()       (post-session engine cascade)
//    - NotificationScheduler  → UNUserNotificationCenter (permission request)
//    - scenePhase .background → SessionCoordinator.endAllActiveSessions()
//                             → DataStore.saveImmediately()
//    - New Year celebration   → .newYearTransitionAware() on root ContentView
//

import SwiftUI

@main
struct ReadingTrackerApp: App {

    // MARK: - Owned State

    @StateObject private var dataStore:   DataStore
    @StateObject private var coordinator: SessionCoordinator
    @StateObject private var goalVM       = GoalProgressViewModel()
    @StateObject private var eventRouter  = SessionEventRouter()

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Init
    //
    // SessionCoordinator must receive the same DataStore instance owned by the
    // App struct — not a second ephemeral copy. The two-step StateObject init
    // pattern is the standard solution when one StateObject depends on another.

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
                // One-time setup on first appearance — bind reactive pipelines
                // and request notification permission.
                .task {
                    goalVM.bind(
                        to: dataStore,
                        goalSet: dataStore.libraryState.goalSet,
                        deadlines: dataStore.libraryState.deadlines
                    )
                    eventRouter.bind(to: dataStore)
                    await NotificationScheduler.shared.requestAuthorization()
                }
                // Wire the New Year celebration overlay. The modifier creates its
                // own NewYearTransitionMonitor @StateObject internally and handles
                // its own startMonitoring() / stopMonitoring() calls.
                .newYearTransitionAware()
        }
        // Flush state when the app moves to the background so no session
        // accumulates unbounded time across a process suspension.
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background else { return }
            coordinator.endAllActiveSessions()
            dataStore.saveImmediately()
        }
    }
}