//
//  Reading_TrackerApp.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/15/26.
//

import SwiftUI

@main
struct Reading_TrackerApp: App {
    @StateObject private var dataStore: DataStore
    @StateObject private var sessionCoordinator: SessionCoordinator

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
    }

    private func restoreActiveSession() {
        // Find any book with an active session and restore SessionCoordinator state
        for book in dataStore.books {
            if let activeSessionID = book.activeSessionID,
               let session = book.sessions.first(where: { $0.id == activeSessionID }) {
                sessionCoordinator.restoreSession(bookID: book.id, sessionID: activeSessionID, page: book.currentPage)
                break // Only restore one active session at a time
            }
        }
    }
}
