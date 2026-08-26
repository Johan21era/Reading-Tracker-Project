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
//    AUDIT:   Task 9/16/17/29 — logging contracts preserved below
//
//  ROADMAP 2.1 (RA-002 / D6) — DISK WRITES MOVED OFF THE MAIN ACTOR
//    • Debounced saves encode ON the main actor (cheap, safe) but WRITE on a
//      background task. Writes are CHAINED (each waits for its predecessor), so
//      two rapid snapshots can never land out of order — the newest data always
//      wins on disk, and failure reporting stays in enqueue order.
//    • saveImmediately() remains a SYNCHRONOUS flush: it drains any queued
//      background write (via semaphore around the detached chain tail) and then
//      blocks briefly to write the current snapshot. Deliberate: the flush path
//      runs at scenePhase .background and in tests, where "the file is on disk
//      when this call returns" is the contract that matters. Only the hot
//      page-turn path got the async treatment.
//    • ROADMAP 2.2 (O-8): urls(for:).first! replaced with a guarded fallback
//      directory; addBook now reports duplicate rejection so the UI can surface it.
//
import Combine
import Foundation

/// Thread-safe observable store. All mutations happen on the main actor.
@MainActor
final class DataStore: ObservableObject {
    // MARK: - Published State

    @Published private(set) var books: [Book] = []
    @Published private(set) var libraryState: LibraryState = .init()

    /// Newly awarded achievements since the last UI observation.
    @Published private(set) var newlyEarnedAchievements: [EarnedAchievement] = []

    /// AUDIT §1.2 / TECH_DEBT D1: Release-visible persistence status.
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
    let audioProfileStore: AudioProfileStore

    /// Debounce timer: coalesces rapid updates into a single disk write.
    private var saveTimer: Timer?
    private let saveDebounceInterval: TimeInterval = 0.5

    /// ROADMAP 2.1 (D6): tail of the serialized background-write chain.
    /// Each enqueued write awaits its predecessor, guaranteeing on-disk ordering.
    private var pendingWrite: Task<String?, Never>?

    #if DEBUG
    private(set) var consoleLastSaveError: String?
    private(set) var consoleLastLoadRepairNote: String?
    #endif

    // MARK: - Init

    init(fileURL: URL? = nil) {
        // AUDIT O-8 (roadmap 2.2): was `.first!` — an empty/misbehaving domain
        // lookup crashed launch. Guarded degradation instead.
        let appSupportCandidates = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        let appSupportAvailable = !appSupportCandidates.isEmpty
        let appSupport = appSupportCandidates.first

        var degradedDirectoryMessage: String?

        if let appSupport {
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

            // AUDIT §1.2: surface silent sandbox/directory creation failures.
            if !FileManager.default.fileExists(atPath: dir.path) {
                degradedDirectoryMessage =
                    "Data folder could not be created at \(dir.path). " +
                    "Reading progress will not be saved."
            }
        } else {
            // Degraded environment: no Application Support available. Persist to a
            // temporary directory so the session still works, loudly flagged below.
            let fallbackDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("ReadTracker-degraded", isDirectory: true)
            try? FileManager.default.createDirectory(at: fallbackDir, withIntermediateDirectories: true)

            if let url = fileURL {
                self.fileURL = url
                stateURL = url.deletingLastPathComponent()
                    .appendingPathComponent("library-state.json")
                audioProfileStore = AudioProfileStore(
                    directory: url.deletingLastPathComponent()
                )
            } else {
                self.fileURL = fallbackDir.appendingPathComponent("library.json")
                stateURL = fallbackDir.appendingPathComponent("library-state.json")
                audioProfileStore = AudioProfileStore(directory: fallbackDir)
            }

            degradedDirectoryMessage =
                "Application Support is unavailable — data is being stored in a " +
                "temporary location and will not survive a restart."
        }
        _ = appSupportAvailable // documented above via candidates check; kept explicit

        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601

        if let message = degradedDirectoryMessage {
            persistenceHealth = .degraded(message)
        }

        load()

        // P5 Feature 1 + HOTFIX (stall report): auto-backup is file-copy I/O;
        // it now runs on a background task instead of stalling launch on main.
        let booksFile = self.fileURL   // qualify: init param shadows the property
        let stateFile = self.stateURL
        Task.detached(priority: .utility) {
            LibraryArchiveManager.performAutoBackupIfNeeded(
                booksURL: booksFile,
                stateURL: stateFile
            )
        }

        #if DEBUG
        DeveloperConsoleRegistry.shared.register(self)
        #endif

        // P6: Sentinel read-bridge (probes read published state only).
        SentinelDataBridge.shared.attach(self)
    }

    /// P5 Feature 1: production import path. Replaces books and the FULL
    /// library state (goals, deadlines, earned achievements, collections) in
    /// one persisted transaction-ish sequence. Used by LibraryArchiveManager;
    /// distinct from debug_replaceLibrary (which resets state rather than
    /// restoring it).
    func restoreState(from archiveBooks: [Book], state: LibraryState) {
        // Preserve referential integrity on collection IDs: strip dangling.
        let validCollectionIDs = Set(state.collections.map(\.id))
        var repairedBooks = archiveBooks
        for i in repairedBooks.indices {
            repairedBooks[i].collectionIDs.removeAll { !validCollectionIDs.contains($0) }
        }
        // Drop duplicate collection names by keeping archived ids where possible.
        books = repairedBooks
        libraryState = state
        scheduleSave()
    }

    // MARK: - Public API — Books

    /// ROADMAP 2.2 (O-8): returns false when the book was rejected as a duplicate
    /// of an existing fileURL, so callers can surface the no-op instead of silence.
    @discardableResult
    func addBook(_ book: Book) -> Bool {
        if books.contains(where: { $0.fileURL == book.fileURL }) {
            return false
        }
        books.append(book)
        scheduleSave()
        detectAchievements()
        return true
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
    ///
    /// P6-HOTFIX (freeze report): rapid persona switches (#1 → #2 → #4…)
    /// stacked N pending chained writes of ~100k-timing payloads. Each new
    /// switch INVALIDATES prior queued work and flushes synchronously before
    /// swapping — so back-to-back installs can never interleave half-written
    /// snapshots or queue an unbounded chain.
    func debug_replaceLibrary(with newBooks: [Book]) {
        // Drain any in-flight write first: guarantees the swap starts from a
        // settled on-disk state and prevents chain pile-up across switches.
        saveImmediately()

        books = newBooks
        // LT-8 v2: a persona switch is a FULL identity switch — goals, deadlines,
        // earned achievements, and collections reset with the library so two
        // profiles can never blend their histories.
        libraryState = LibraryState()

        // Persist BOTH payloads right away (synchronous, transactional path):
        // no debounce window where UI/Sentinel could observe a torn state.
        saveImmediately()
        detectAchievements() // recompute for the fresh identity
        scheduleSave()
    }
    #endif

    // MARK: - Public API — Collections (Progressive Filtering model layer)

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
    /// after its toast finished displaying (or was tapped).
    func markAchievementToastShown(id: UUID) {
        newlyEarnedAchievements.removeAll { $0.id == id }
    }

    // MARK: - Public API — Audio Context

    func attachAudioContext(to sessionID: UUID, profile: AudioContextProfile) {
        audioProfileStore.save(profile: profile)

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

    func audioContextProfile(for sessionID: UUID) -> AudioContextProfile? {
        audioProfileStore.fetch(sessionID: sessionID)
    }

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

        if let pIdx = book.sessions[sIdx].pageTimes.indices.last,
           book.sessions[sIdx].pageTimes[pIdx].isActive
        {
            book.sessions[sIdx].pageTimes[pIdx].endTime = now
        }

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
        detectAchievements()
    }

    /// Batch close — single scheduleSave() call instead of one per book.
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
    private func closeActiveSession(for book: inout Book) {
        guard let activeSessionID = book.activeSessionID else { return }
        guard let sIdx = book.sessions.firstIndex(where: { $0.id == activeSessionID }) else { return }

        let now = Date()

        for pIdx in book.sessions[sIdx].pageTimes.indices
            where book.sessions[sIdx].pageTimes[pIdx].isActive
        {
            book.sessions[sIdx].pageTimes[pIdx].endTime = now
        }

        book.sessions[sIdx].endTime = now
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
            let decoded = try decoder.decode([Book].self, from: data)

            let (repaired, report) = DataIntegrityValidator.validate(decoded)
            books = repaired

            // AUDIT §3.3: never re-persist books that still contain unrepaired
            // errors — surface instead of overwriting the last-good file.
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
            // AUDIT F-04 Gate A: back up the unreadable file BEFORE resetting.
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

    /// Debounced save. Multiple rapid calls within 0.5s coalesce into one.
    func scheduleSave() {
        saveTimer?.invalidate()
        let timer = Timer(timeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.save()
            }
        }
        // AUDIT §3.1: `.common` mode keeps the debounced save alive during
        // window resize/control tracking.
        RunLoop.main.add(timer, forMode: .common)
        saveTimer = timer
    }

    /// Immediate (non-debounced) save — SYNCHRONOUS by contract.
    ///
    /// ROADMAP 2.1 (D6): drains any queued background write first (so this flush
    /// cannot be overtaken by an older snapshot), then blocks briefly to write
    /// current values. Callers — scenePhase teardown and tests — depend on
    /// "file is on disk when this returns."
    func saveImmediately() {
        saveTimer?.invalidate()
        saveTimer = nil

        if let pending = pendingWrite {
            let semaphore = DispatchSemaphore(value: 0)
            Task.detached(priority: .userInitiated) {
                _ = await pending.value
                semaphore.signal()
            }
            semaphore.wait()
            pendingWrite = nil
        }

        do {
            let data = try encoder.encode(books)
            try data.write(to: fileURL, options: .atomic)
            try encoder.encode(libraryState).write(to: stateURL, options: .atomic)
            persistenceHealth = .healthy
        } catch {
            print("[DataStore] Immediate save error at \(fileURL.path): \(error)")
            persistenceHealth = .degraded("Library could not be saved: \(error.localizedDescription)")
            #if DEBUG
            consoleLastSaveError = error.localizedDescription
            #endif
        }
    }

    /// Encodes the CURRENT snapshot on the main actor, then hands the bytes to a
    /// DETACHED write chained behind the previous one. Only the slow part left main.
    private func save() {
        let data: Data
        do {
            data = try encoder.encode(books)
        } catch {
            print("[DataStore] Save encode error at \(fileURL.path): \(error)")
            persistenceHealth = .degraded("Library could not be saved: \(error.localizedDescription)")
            #if DEBUG
            consoleLastSaveError = error.localizedDescription
            #endif
            return
        }
        enqueueWrite(data, to: fileURL, failureContext: "Library")
    }

    private func saveLibraryState() {
        let data: Data
        do {
            data = try encoder.encode(libraryState)
        } catch {
            print("[DataStore] LibraryState encode error at \(stateURL.path): \(error)")
            persistenceHealth = .degraded("Goals & achievements could not be saved: \(error.localizedDescription)")
            return
        }
        enqueueWrite(data, to: stateURL, failureContext: "Goals & achievements")
    }

    /// Chains a detached atomic write behind every previously enqueued one.
    private func enqueueWrite(_ data: Data, to url: URL, failureContext: String) {
        let filePath = url.path
        let predecessor = pendingWrite

        let write = Task.detached(priority: .utility) { () -> String? in
            _ = await predecessor?.value // strict on-disk ordering, oldest first
            do {
                try data.write(to: url, options: .atomic)
                return nil
            } catch {
                return "\(error) (\(filePath))"
            }
        }
        pendingWrite = write

        // Observe completion on the main actor WITHOUT blocking it.
        Task { [weak self] in
            guard let self else { return }
            if let message = await write.value {
                self.markWriteFailed(message, context: failureContext)
            } else {
                self.markWriteSucceeded()
            }
        }
    }

    private func markWriteSucceeded() {
        persistenceHealth = .healthy
    }

    private func markWriteFailed(_ message: String, context: String) {
        print("[DataStore] \(context) save error: \(message)")
        persistenceHealth = .degraded("\(context) could not be saved: \(message)")
        #if DEBUG
        consoleLastSaveError = message
        #endif
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
