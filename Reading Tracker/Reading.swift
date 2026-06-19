//  Reading.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/18/26.
//


//
//  Reading_TrackerApp.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/15/26.
//
//  FIX F2: scenePhase is now observed at the Scene level.
//  When the app moves to .background or .inactive (quit, Command-H, screen lock),
//  endAllActiveSessions() + saveImmediately() are called so no reading session
//  is ever left open or unsaved on disk.
//

import SwiftUI

@main
struct Reading_TrackerApp: App {
    @StateObject private var dataStore: DataStore
    @StateObject private var sessionCoordinator: SessionCoordinator

    // Observes the overall app lifecycle phase.
    // At the App level this reflects the "highest" active scene —
    // i.e. it goes .inactive / .background when the whole app quits or hides.
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let dataStore = DataStore()
        _dataStore = StateObject(wrappedValue: dataStore)
        _sessionCoordinator = StateObject(wrappedValue: SessionCoordinator(dataStore: dataStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(sessionCoordinator)
                .onAppear {
                    restoreActiveSession()
                }
        }
        // FIX F2: wire the lifecycle save that previously had no callers.
        // SessionCoordinator.endAllActiveSessions() and DataStore.saveImmediately()
        // both existed and were documented as "called by the app lifecycle" —
        // but nothing ever called them. This is that call.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                sessionCoordinator.endAllActiveSessions()
                dataStore.saveImmediately()
            }
        }
    }

    // MARK: - Session Restore

    private func restoreActiveSession() {
        for book in dataStore.books {
            if let activeSessionID = book.activeSessionID,
               book.sessions.first(where: { $0.id == activeSessionID }) != nil {
                sessionCoordinator.restoreSession(
                    bookID: book.id,
                    sessionID: activeSessionID,
                    page: book.currentPage
                )
                break // Only one active session can be restored at a time
            }
        }
    }
}
