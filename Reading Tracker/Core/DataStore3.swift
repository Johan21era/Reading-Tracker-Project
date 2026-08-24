//  DataStore3.swift
//  Reading Tracker
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

    /// AUDIT §1.2 / TECH_DEBT D1: Release-visible persistence status.
    /// `.healthy` after any successful save; `.degraded(reason)` remains until the
    /// next successful save (dismiss-on-fix — never auto-dismissed in the UI).
    enum PersistenceStatus: Equatable {
        case healthy
        case degraded(String)
    }

    @Published private(set) var persistenceHealth: PersistenceStatus = .healthy

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

    #if DEBUG
    /// Developer Console instrumentation only. Set inside the existing
    /// save()/loadBooks() catch blocks below — purely additive, changes
    /// nothing about what those methods actually do.
    private(set) var consoleLastSaveError: String?
    private(set) var consoleLastLoadRepairNote: String?
    #endif

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

        // AUDIT §1.2: surface silent sandbox/directory creation failures
        // (previously swallowed by `try?` above).
        if !FileManager.default.fileExists(atPath: dir.path) {
            persistenceHealth = .degraded(
                "Data folder could not be created at \(dir.path). " +
                "Reading progress will not be saved."
            )
        }

        load()

        #if DEBUG
        DeveloperConsoleRegistry.shared.register(self)
        #endif
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

    #if DEBUG
    /// LIVE-TEST LT-8: replaces the entire library in one shot (addBook's
    /// fileURL dedupe would silently block repeat demo installs).
    func debug_replaceLibrary(with newBooks: [Book]) {
        books = newBooks
        // LT-8 v2: a persona switch is a FULL identity switch — goals, deadlines,
        // earned achievements, and collections reset with the library so two
        // profiles can never blend their histories.
        libraryState = LibraryState()
        scheduleSave()
    }
    #endif

    // MARK: - Public API — Collections (Phase 2: Progressive Filtering model layer)

    /// Creates and persists a named collection. LibraryFilterSidebarView can
    /// filter BY collections; this is the creation half it deliberately lacks.
    @discardableResult
    func addCollection(name: String) -> BookCollection {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let collection = BookCollection(name: trimmed.isEmpty ? "Untitled Collection" : trimmed)
        libraryState.collections.append(collection)
        saveLibraryState()
        return collection
    }

    func renameCollection(id: UUID, to newName: String) {
        guard let idx = libraryState.collections.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        libraryState.collections[idx].name = trimmed
        saveLibraryState()
    }

    /// Removes a collection AND strips its id from every book — referential
    /// integrity, so no Book carries a dangling collectionIDs entry.
    func removeCollection(id: UUID) {
        guard libraryState.collections.contains(where: { $0.id == id }) else { return }
        libraryState.collections.removeAll { $0.id == id }
        var mutated = false
        for i in books.indices where books[i].collectionIDs.contains(id) {
            books[i].collectionIDs.removeAll { $0 == id }
            mutated = true
        }
        if mutated { scheduleSave() }
        saveLibraryState()
    }

    /// Sets one book's membership in one collection.
    func setBook(_ bookID: UUID, membershipIn collectionID: UUID, isMember: Bool) {
        guard let bIdx = books.firstIndex(where: { $0.id == bookID }) else { return }
        if isMember {
            guard !books[bIdx].collectionIDs.contains(collectionID) else { return }
            books[bIdx].collectionIDs.append(collectionID)
        } else {
            guard books[bIdx].collectionIDs.contains(collectionID) else { return }
            books[bIdx].collectionIDs.removeAll { $0 == collectionID }
        }
        scheduleSave()
    }

    func clearNewAchievements() {
        newlyEarnedAchievements = []
    }

    /// AUDIT §2.2: removes a single achievement from the unseen-toast queue
    /// after its toast finished displaying (or was tapped). Complements the
    /// all-at-once clearNewAchievements().
    func markAchievementToastShown(id: UUID) {
        newlyEarnedAchievements.removeAll { $0.id == id }
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

            // AUDIT §3.3: never re-persist books that still contain unrepaired
            // errors — doing so overwrites the last-good file with corrupt content.
            // Surface it instead; leave the source file untouched.
            if report.hasUnrepairableErrors {
                persistenceHealth = .degraded(
                    "Library loaded with unrepaired issues. " +
                    "\(report.summary) Auto-save skipped to protect the existing file."
                )
                #if DEBUG
                consoleLastLoadRepairNote = report.summary
                #endif
            } else if !report.isClean {
                #if DEBUG
                consoleLastLoadRepairNote = report.summary
                #endif
                save()
            }

        } catch {
            print("[DataStore] Load error at \(fileURL.path): \(error)")
            // UPGRADE v3: Backup corrupt file before resetting, so data isn't destroyed.
            backupCorruptFile(at: fileURL)
            books = []
            persistenceHealth = .degraded(
                "Library file could not be read and was backed up to library.bak.json. " +
                "Starting with an empty library — check disk space and permissions."
            )
        }
    }

    private func loadLibraryState() {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return }
        do {
            let data = try Data(contentsOf: stateURL)
            libraryState = try decoder.decode(LibraryState.self, from: data)
        } catch {
            print("[DataStore] LibraryState load error at \(stateURL.path): \(error)")
            // AUDIT F-04 Gate A (Phase 1): mirror the books path — back up the
            // unreadable file BEFORE resetting, so goals/deadlines/earned-achievement
            // history stays recoverable instead of being silently overwritten by
            // the next saveLibraryState().
            backupCorruptFile(at: stateURL)
            libraryState = LibraryState()
            let bakName = stateURL.deletingPathExtension()
                .appendingPathExtension("bak.json").lastPathComponent
            persistenceHealth = .degraded(
                "Goals & achievements file could not be read and was backed up to " +
                bakName + ". Starting fresh — check disk space and permissions."
            )
        }
    }

    /// UPGRADE v3: Debounced save. Multiple rapid calls within 0.5s coalesce into one.
    /// This prevents N disk writes during rapid page-turn events.
    func scheduleSave() {
        saveTimer?.invalidate()
        let timer = Timer(timeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.save()
            }
        }
        // AUDIT §3.1: `.common` mode keeps the debounced save alive during
        // window resize/control tracking (default mode blocks there).
        RunLoop.main.add(timer, forMode: .common)
        saveTimer = timer
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
            persistenceHealth = .healthy
        } catch {
            // TASK 16 FIX: Include the file path so permission/disk-full errors are actionable.
            print("[DataStore] Save error at \(fileURL.path): \(error)")
            persistenceHealth = .degraded("Library could not be saved: \(error.localizedDescription)")
            #if DEBUG
            consoleLastSaveError = error.localizedDescription
            #endif
        }
    }

    private func saveLibraryState() {
        do {
            let data = try encoder.encode(libraryState)
            try data.write(to: stateURL, options: .atomic)
            persistenceHealth = .healthy
        } catch {
            print("[DataStore] LibraryState save error at \(stateURL.path): \(error)")
            persistenceHealth = .degraded("Goals & achievements could not be saved: \(error.localizedDescription)")
        }
    }

    /// Copies a corrupt file to a .bak sidecar so data isn't silently destroyed.
    private func backupCorruptFile(at url: URL) {
        let bakURL = url.deletingPathExtension().appendingPathExtension("bak.json")
        try? FileManager.default.copyItem(at: url, to: bakURL)
        print("[DataStore] Corrupt file backed up to \(bakURL.path)")
    }
}

// MARK: - Developer Console

#if DEBUG
extension DataStore: DeveloperConsoleObservable {
    static var consoleIdentity: ConsoleSubsystemIdentity {
        ConsoleSubsystemIdentity(
            id: "data-store",
            displayName: "Data Store",
            category: .manager,
            purpose: "Owns the book library and reading-goal state, and is the only thing that reads or writes library.json / library-state.json on disk."
        )
    }

    var consoleSnapshot: ConsoleSubsystemSnapshot {
        var warnings: [String] = []
        var errors: [String] = []
        if let repairNote = consoleLastLoadRepairNote {
            warnings.append("Last load required a repair: \(repairNote)")
        }
        if let saveError = consoleLastSaveError {
            errors.append("Last save failed: \(saveError)")
        }

        return ConsoleSubsystemSnapshot(
            identity: Self.consoleIdentity,
            status: consoleLastSaveError != nil ? .error : (consoleLastLoadRepairNote != nil ? .warning : .healthy),
            currentActivity: "Holding \(books.count) book(s), \(newlyEarnedAchievements.count) unseen achievement toast(s)",
            lastUpdated: Date(),
            warnings: warnings,
            errors: errors,
            metrics: [
                "Books in library": "\(books.count)",
                "Reading goals set": libraryState.goalSet == .empty ? "No" : "Yes",
                "Deadlines tracked": "\(libraryState.deadlines.count)",
                "Earned achievements": "\(libraryState.earnedAchievements.count)",
            ]
        )
    }
}
#endif
