//
//  SessionEventRouter.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/28/26.
//


//
//  SessionEventRouter.swift
//  Reading Tracker
//
//  Observes DataStore for reading session lifecycle events and fans out to
//  the engines that should act at session close. This file contains NO engine
//  logic — it only calls existing engine APIs.
//
//  Engines triggered at session end:
//    1. WeatherKitService              — captures a weather snapshot
//    2. IntelligentNotificationEngine  — evaluates a reading prompt
//    3. NotificationScheduler          — delivers the prompt if score qualifies
//
//  GoalProgressViewModel does NOT need to be called here — its bind() already
//  sets up a Combine subscription to dataStore.$books that refreshes statuses
//  automatically whenever books change (which includes session close events).
//

import Foundation
import Combine

@MainActor
final class SessionEventRouter: ObservableObject {

    // MARK: - Private

    private weak var dataStore: DataStore?

    /// IDs of books that had an open activeSessionID on the last observed books update.
    /// Diffing against the next update reveals which sessions just closed.
    private var previouslyActiveBookIDs: Set<UUID> = []

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Bind

    /// Attaches the router to a DataStore. Call once at app startup.
    /// Subsequent calls are safe but redundant — the existing subscription
    /// handles all future updates.
    func bind(to dataStore: DataStore) {
        self.dataStore = dataStore

        // Seed the initial snapshot so the first diff is accurate.
        previouslyActiveBookIDs = Set(
            dataStore.books
                .filter { $0.activeSessionID != nil }
                .map(\.id)
        )

        dataStore.$books
            .dropFirst()                     // skip the seeded initial value
            .receive(on: RunLoop.main)
            .sink { [weak self] newBooks in
                self?.handleBooksUpdate(newBooks)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private

    private func handleBooksUpdate(_ books: [Book]) {
        let currentlyActive = Set(
            books.filter { $0.activeSessionID != nil }.map(\.id)
        )

        // Books that had an open session on the previous tick but don't now —
        // these are the sessions that just closed.
        let justClosed = previouslyActiveBookIDs.subtracting(currentlyActive)
        previouslyActiveBookIDs = currentlyActive

        guard !justClosed.isEmpty else { return }

        Task {
            await runPostSessionCascade(allBooks: books)
        }
    }

    private func runPostSessionCascade(allBooks: [Book]) async {

        // ── 1. Weather snapshot ──────────────────────────────────────────────
        //
        // Find sessions that closed in the last 2 minutes. This window handles
        // slight timing differences between the Combine update and the cascade
        // firing. Failures are swallowed — weather data enriches analytics but
        // is never critical to the app's core reading function.

        let twoMinutesAgo = Date().addingTimeInterval(-120)

        let recentlyClosed = allBooks
            .flatMap(\.sessions)
            .filter { session in
                guard let end = session.endTime else { return false }
                return end >= twoMinutesAgo && session.audioContextProfileID != nil || end >= twoMinutesAgo
            }

        for session in recentlyClosed {
            try? await WeatherKitService.shared.snapshotForCurrentConditions(
                sessionID: session.id
            )
        }

        // ── 2. Intelligent notification evaluation ───────────────────────────
        //
        // IntelligentNotificationEngine.evaluate() is a pure function: it scores
        // the user's behavioral state and returns a result with a shouldNotify flag
        // and a top-ranked NotificationCandidate. We respect its own gating logic
        // (shouldNotify reflects the engine's built-in 0.55 threshold) and only
        // deliver when it says to.

        let result = IntelligentNotificationEngine.evaluate(
            books: allBooks,
            date: Date()
        )

        if result.shouldNotify, let candidate = result.selectedNotification {
            await NotificationScheduler.shared.schedule(candidate: candidate)
        }
    }
}