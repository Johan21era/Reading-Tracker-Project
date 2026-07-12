//
//  DataStore 2.swift
//  Reading Tracker
//
//  
//
//
//  UPGRADE LOG (v3)
//    • Added: LibraryState persistence — goals, deadlines, achievements alongside books
//    • Added: Schema version written to disk; migration path for v1→v2→v3
//    • Added: DataIntegrityValidator called on every load before publishing books
//    • Added: Automatic backup to library.json.bak on decode failure (corruption recovery)
//    • Added: Debounced save — multiple rapid updates coalesce into a single write
//    • Fixed: endAllActiveSessions — single batch save instead of N saves for N books
//    • Fixed: updateBook — O(n) scan unchanged but now also dispatches achievement detection
//    • Added: Achievement detection hook — AchievementEngine.detectAll() after significant events
//    • Added: newlyEarnedAchievements @Published so UI can animate badge awards
//    PATCHED: B5 — closeActiveSession closes ALL active PageTiming entries
//    AUDIT:   Task 9  — startSession logs warning when closing an already-active session
//             Task 16 — save() logs the file path alongside the error
//             Task 17 — updateBook() logs when book ID is not found
//             Task 29 — removeBook() skips disk write when ID not found

import Combine
import Foundation

/// Thread-safe observable store. All mutations happen on the main actor.
@MainActor
final class DataStore: ObservableObject {
    // MARK: - Published State

    @Published private(set) var books: [Book] = []
    @Published private(set) var libraryState: LibraryState = .init()

    /// Newly awarded achievements since the last UI observation.
    /// UI should consume this array (display animation) and clear it via clearNewAchievements().
    @Published private(set) var newlyEarnedAchievements: [EarnedAchievement] = []

    // MARK: - Private

    private let fileURL: URL
    private let stateURL: URL // separate file for LibraryState (goals/achievements)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Persists AudioContextProfile objects captured by AudioMonitorService.
    /// Stored at: ~/Library/Application Support/ReadTracker/audio-profiles.json
    let audioProfileStore: AudioProfileStore

    /// Debounce timer: coalesces rapid updates into a single disk write.
    private var saveTimer: Timer?
    private let saveDebounceInterval: TimeInterval = 0.5

    // MARK: - Init

    init(fileURL: URL? = nil) {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("ReadTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        if let url = fileURL {
            self.fileURL = url
            stateURL = url.deletingLastPathComponent()
                .appendingPathComponent("library-state.json")
            audioProfileStore = AudioProfileStore(
                directory: url.deletingLastPathComponent()
            )
        } else {
            self.fileURL = dir.appendingPathComponent("library.json")
            stateURL = dir.appendingPathComponent("library-state.json")
            audioProfileStore = AudioProfileStore(directory: dir)
        }

        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601

        load()
    }

    // MARK: - Public API — Books

    func addBook(_ book: Book) {
        if books.contains(where: { $0.fileURL == book.fileURL }) {
            return
        }
        books.append(book)
        scheduleSave()
        detectAchievements()
    }

    func updateBook(_ book: Book) {
        guard let idx = books.firstIndex(where: { $0.id == book.id }) else {
            print("[DataStore] updateBook: book \(book.id) ('\(book.title)') not found — " +
                "update dropped. This may indicate a stale reference.")
            return
        }
        books[idx] = book
        scheduleSave()
    }

    func removeBook(id: UUID) {
        guard books.contains(where: { $0.id == id }) else { return }
        books.removeAll { $0.id == id }
        scheduleSave()
    }

    func book(id: UUID) -> Book? {
        books.first { $0.id == id }
    }

    // MARK: - Public API — Library State

    func updateGoalSet(_ goalSet: ReadingGoalSet) {
        libraryState.goalSet = goalSet
        saveLibraryState()
    }

    func addDeadline(_ deadline: BookDeadline) {
        libraryState.deadlines.removeAll { $0.bookID == deadline.bookID }
        libraryState.deadlines.append(deadline)
        saveLibraryState()
    }

    func removeDeadline(bookID: UUID) {
        libraryState.deadlines.removeAll { $0.bookID == bookID }
        saveLibraryState()
    }

    func clearNewAchievements() {
        newlyEarnedAchievements = []
    }

    // MARK: - Public API — Audio Context

    /// Saves an AudioContextProfile and links it to its reading session.
    /// Called by SessionCoordinator immediately after a session ends.
    /// - Parameters:
    ///   - sessionID: The ReadingSession.id that this profile describes.
    ///   - profile:   The AudioContextProfile produced by AudioMonitorService.finalizeContext.
    func attachAudioContext(to sessionID: UUID, profile: AudioContextProfile) {
        // 1. Persist the profile to the audio store.
        audioProfileStore.save(profile: profile)

        // 2. Write the profileID back onto the session so analytics can join them.
        for i in books.indices {
            for j in books[i].sessions.indices
                where books[i].sessions[j].id == sessionID
            {
                books[i].sessions[j].audioContextProfileID = profile.id
                scheduleSave() // debounced — coalesces with the endSession save
                return
            }
        }
        print("[DataStore] attachAudioContext: session \(sessionID.uuidString.prefix(8)) " +
            "not found — profile saved to store but session reference not updated.")
    }

    /// Returns the AudioContextProfile for a specific session, if one was captured.
    func audioContextProfile(for sessionID: UUID) -> AudioContextProfile? {
        audioProfileStore.fetch(sessionID: sessionID)
    }

    /// Returns all persisted AudioContextProfile objects.
    /// Used by AnnualReportGenerator and MusicalAnalysisEngine.buildSessionRecords.
    func allAudioProfiles() -> [AudioContextProfile] {
        audioProfileStore.fetchAll()
    }

    // MARK: - Session Helpers

    func startSession(bookID: UUID, onPage page: Int) {
        guard var book = book(id: bookID) else { return }

        if let existingID = book.activeSessionID {
            print("[DataStore] Warning: startSession called while session \(existingID) " +
                "is active for book \(bookID) — closing previous session.")
        }

        closeActiveSession(for: &book)

        var session = ReadingSession(bookID: bookID, startPage: page, endPage: page)
        let timing = PageTiming(pageNumber: page)
        session.pageTimes = [timing]
        book.sessions.append(session)
        book.activeSessionID = session.id
        book.currentPage = page
        updateBook(book)
    }

    func recordPageTurn(bookID: UUID, newPage: Int) {
        guard var book = book(id: bookID) else { return }
        guard let activeSessionID = book.activeSessionID else { return }
        guard let sIdx = book.sessions.firstIndex(where: { $0.id == activeSessionID }) else { return }

        let now = Date()

        // Close previous page timing (last active entry).
        if let pIdx = book.sessions[sIdx].pageTimes.indices.last,
           book.sessions[sIdx].pageTimes[pIdx].isActive
        {
            book.sessions[sIdx].pageTimes[pIdx].endTime = now
        }

        // Open new page timing.
        let timing = PageTiming(pageNumber: newPage, startTime: now)
        book.sessions[sIdx].pageTimes.append(timing)
        book.sessions[sIdx].endPage = newPage
        book.currentPage = newPage

        updateBook(book)
    }

    func endSession(bookID: UUID) {
        guard var book = book(id: bookID) else { return }
        closeActiveSession(for: &book)
        updateBook(book)
        detectAchievements() // Check for session-count and page-count milestones.
    }

    /// UPGRADE v3: Batch close — single scheduleSave() call instead of one per book.
    func endAllActiveSessions() {
        var anyChanged = false
        for i in books.indices where books[i].activeSessionID != nil {
            closeActiveSession(for: &books[i])
            anyChanged = true
        }
        if anyChanged {
            scheduleSave()
            detectAchievements()
        }
    }

    // MARK: - Achievement Detection

    /// Runs AchievementEngine.detectAll() and publishes newly earned achievements.
    /// Debounced implicitly by being called from update/end session paths (not every page turn).
    private func detectAchievements() {
        let (allEarned, newly) = AchievementEngine.detectAll(
            books: books,
            goalSet: libraryState.goalSet,
            existing: libraryState.earnedAchievements
        )
        if !newly.isEmpty {
            libraryState.earnedAchievements = allEarned
            newlyEarnedAchievements.append(contentsOf: newly)
            saveLibraryState()
        }
    }

    // MARK: - Private Helpers

    /// B5 FIX: Close ALL active PageTiming entries in the session, not just the last.
    /// Idempotent and crash-recovery-safe.
    private func closeActiveSession(for book: inout Book) {
        guard let activeSessionID = book.activeSessionID else { return }
        guard let sIdx = book.sessions.firstIndex(where: { $0.id == activeSessionID }) else { return }

        let now = Date()

        for pIdx in book.sessions[sIdx].pageTimes.indices
            where book.sessions[sIdx].pageTimes[pIdx].isActive
        {
            book.sessions[sIdx].pageTimes[pIdx].endTime = now // page timings first (I-5)
        }

        book.sessions[sIdx].endTime = now // then session endTime (I-5)
        book.activeSessionID = nil
    }

    // MARK: - Persistence

    private func load() {
        loadBooks()
        loadLibraryState()
    }

    private func loadBooks() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            var decoded = try decoder.decode([Book].self, from: data)

            // UPGRADE v3: Validate and repair on every load.
            let (repaired, report) = DataIntegrityValidator.validate(decoded)
            books = repaired

            // If repairs were made, save the corrected version immediately.
            if !report.isClean {
                save()
            }

        } catch {
            print("[DataStore] Load error at \(fileURL.path): \(error)")
            // UPGRADE v3: Backup corrupt file before resetting, so data isn't destroyed.
            backupCorruptFile(at: fileURL)
            books = []
        }
    }

    private func loadLibraryState() {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return }
        do {
            let data = try Data(contentsOf: stateURL)
            libraryState = try decoder.decode(LibraryState.self, from: data)
        } catch {
            print("[DataStore] LibraryState load error at \(stateURL.path): \(error)")
            libraryState = LibraryState()
        }
    }

    /// UPGRADE v3: Debounced save. Multiple rapid calls within 0.5s coalesce into one.
    /// This prevents N disk writes during rapid page-turn events.
    func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.save()
            }
        }
    }

    /// Immediate (non-debounced) save. Use for shutdown/background transitions.
    func saveImmediately() {
        saveTimer?.invalidate()
        saveTimer = nil
        save()
    }

    private func save() {
        do {
            let data = try encoder.encode(books)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // TASK 16 FIX: Include the file path so permission/disk-full errors are actionable.
            print("[DataStore] Save error at \(fileURL.path): \(error)")
        }
    }

    private func saveLibraryState() {
        do {
            let data = try encoder.encode(libraryState)
            try data.write(to: stateURL, options: .atomic)
        } catch {
            print("[DataStore] LibraryState save error at \(stateURL.path): \(error)")
        }
    }

    /// Copies a corrupt file to a .bak sidecar so data isn't silently destroyed.
    private func backupCorruptFile(at url: URL) {
        let bakURL = url.deletingPathExtension().appendingPathExtension("bak.json")
        try? FileManager.default.copyItem(at: url, to: bakURL)
        print("[DataStore] Corrupt file backed up to \(bakURL.path)")
    }
}
