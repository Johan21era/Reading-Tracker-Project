//
//  SessionEventRouter 2.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 7/9/26.
//


//
//  SessionEventRouter.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/29/26.
//


//
//  SessionEventRouter.swift
//  Reading Tracker
//
//  Observes DataStore for session-close events and fans out to engines that
//  act at session end. Contains NO engine logic — only calls existing APIs.
//
//  Cascade at session close:
//    1. WeatherKitService              — captures a weather snapshot
//    2. IntelligentNotificationEngine  — evaluates a reading prompt
//    3. NotificationScheduler          — delivers the prompt if score qualifies
//    4. BehaviorContextEngine.analyze()— updates behavioral context summary
//

import Foundation
import Combine

@MainActor
final class SessionEventRouter: ObservableObject {

    // MARK: - Private

    private weak var dataStore:    DataStore?
    private weak var behaviorKit:  BehaviorContextAccessKit?
    private weak var contextEngine: BehaviorContextEngine?

    /// Books that had an open activeSessionID on the last observed update.
    /// Diffing against the next emission reveals which sessions just closed.
    private var previouslyActiveBookIDs: Set<UUID> = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Bind

    /// Attaches the router to the three objects it needs. Call once at app launch.
    func bind(
        to dataStore: DataStore,
        behaviorKit: BehaviorContextAccessKit,
        contextEngine: BehaviorContextEngine
    ) {
        self.dataStore     = dataStore
        self.behaviorKit   = behaviorKit
        self.contextEngine = contextEngine

        // Seed the initial set so the first diff is accurate.
        previouslyActiveBookIDs = Set(
            dataStore.books.filter { $0.activeSessionID != nil }.map(\.id)
        )

        dataStore.$books
            .dropFirst()
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
        let justClosed = previouslyActiveBookIDs.subtracting(currentlyActive)
        previouslyActiveBookIDs = currentlyActive

        guard !justClosed.isEmpty else { return }

        Task {
            await runPostSessionCascade(allBooks: books)
        }
    }

    private func runPostSessionCascade(allBooks: [Book]) async {

        // ── 1. Weather snapshot ──────────────────────────────────────────
        // Find sessions that ended in the last 2 minutes and capture weather.
        // Failures are swallowed — weather data enriches analytics but is never
        // critical to the core reading function.
        let twoMinutesAgo = Date().addingTimeInterval(-120)
        let recentlyClosed = allBooks
            .flatMap(\.sessions)
            .filter { s in
                guard let end = s.endTime else { return false }
                return end >= twoMinutesAgo
            }

        for session in recentlyClosed {
            try? await WeatherKitService.shared.snapshotForCurrentConditions(
                sessionID: session.id
            )
        }

        // ── 2. Notification evaluation ───────────────────────────────────
        // IntelligentNotificationEngine.evaluate() is a pure function.
        // Its shouldNotify flag already applies the engine's own threshold.
        let result = IntelligentNotificationEngine.evaluate(
            books: allBooks,
            date: Date()
        )
        if result.shouldNotify, let candidate = result.selectedNotification {
            // A push notification is the one pathway in this app where a
            // claim reaches the user completely outside SwiftUI — the
            // engine's own shouldNotify/rankingScore threshold is a
            // real-time targeting decision, not evidence gating. This is
            // the actual "has this earned the right to exist" check.
            let verdict = DataMaturityNotificationAdapter.evaluate(candidate)
            if verdict.maySurface {
                await NotificationScheduler.shared.schedule(candidate: candidate)
            }
        }

        // ── 3. Behavioral context analysis ──────────────────────────────
        // Convert BehaviorContextAccessKit's raw event data into the types
        // BehaviorContextEngine.analyze() expects, then call analyze().
        // analyze() sets contextEngine.summary (the @Published property)
        // internally — no return value needs to be stored here.
        guard let kit = behaviorKit, let engine = contextEngine else { return }

        let allSessions = allBooks.flatMap(\.sessions)

        let readingRecords = BehaviorEvidenceBuilder.readingSessionRecords(
            from: allSessions
        )
        let evidence = BehaviorEvidenceBuilder.evidence(
            from: kit.applicationSessions,
            readingSessions: allSessions
        )

        // Only run the analysis when there is meaningful data.
        // The engine handles sparse input gracefully, but calling it with
        // zero records produces a low-confidence summary with no content.
        guard !readingRecords.isEmpty, !evidence.isEmpty else { return }

        // analyze() is a synchronous method on a @MainActor class.
        // We are already on MainActor so the call is safe here.
        _ = engine.analyze(sessions: readingRecords, evidence: evidence)
    }
}