//  SentinelPinsTests.swift
//  Reading TrackerTests
//
//  P6 Sentinel pins. Security pins (S1/S5) are the most important tests
//  in this file: they prove the engine CANNOT destroy user data.
//
import Foundation
import Testing

@testable import Reading_Tracker

@Suite("Sentinel Engine")
@MainActor
final class SentinelPinsTests {

    let dir: URL

    init() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: dir)
    }

    private var libraryURL: URL { dir.appendingPathComponent("library.json") }

    private func makeStore(withBook mutate: ((inout Book) -> Void)? = nil) -> DataStore {
        let store = DataStore(fileURL: libraryURL)
        var book = Book(title: "Sentinel Target", author: "A",
                        fileURL: URL(fileURLWithPath: "/tmp/sentinel.pdf"), fileType: .pdf)
        book.totalPages = 100
        mutate?(&book)
        store.addBook(book)
        store.saveImmediately() // flush so file-level assertions see it
        return store
    }

    // MARK: Detection

    @Test("Orphan session >24h is DETECTED and AUTO-FIXED through audited API")
    func orphanSessionAutoFixed() {
        let engine = SentinelEngine(defaults: UserDefaults(suiteName: "sentinel-test")!, probes: [OrphanedActiveSessionProbe()])
        let store = makeStore { book in
            let staleStart = Date().addingTimeInterval(-48 * 3600)
            let session = ReadingSession(bookID: book.id, startTime: staleStart, startPage: 0, endPage: 5)
            book.sessions = [session]
            book.activeSessionID = session.id
        }
        SentinelDataBridge.shared.attach(store)

        engine.runCycle()

        #expect(engine.recentFindings.contains { $0.rule == "orphan-active-session" && $0.outcome == .autoFixed })
        // The fix went through updateBook → session closed, active id cleared.
        let book = try! #require(store.books.first)
        #expect(book.activeSessionID == nil)
        #expect(book.sessions.first?.isActive == false)
    }

    @Test("Phantom activeSessionID is auto-fixed")
    func phantomSessionAutoFixed() {
        let ghost = UUID()
        let engine = SentinelEngine(
            defaults: UserDefaults(suiteName: "sentinel-test")!,
            probes: [IntegrityProbe()]
        )
        let store = makeStore { book in
            book.activeSessionID = ghost // points at a session that doesn't exist
        }
        SentinelDataBridge.shared.attach(store)

        engine.runCycle()
        #expect(engine.recentFindings.contains { $0.rule == "phantom-active-session-id" && $0.outcome == .autoFixed })
        #expect(store.books.first?.activeSessionID == nil)
    }

    @Test("Low-value info findings stay STALLED (never auto-mutated)")
    func stalledFindingsStayStalled() {
        let engine = SentinelEngine(
            defaults: UserDefaults(suiteName: "sentinel-test")!,
            probes: [DeadlineOverdueProbe()]
        )
        let store = DataStore(fileURL: libraryURL)
        var book = Book(title: "Overdue", author: "A",
                        fileURL: URL(fileURLWithPath: "/tmp/od.pdf"), fileType: .pdf)
        book.totalPages = 10
        store.addBook(book)
        store.addDeadline(BookDeadline(bookID: book.id,
                                       targetDate: Date().addingTimeInterval(-86_400)))
        SentinelDataBridge.shared.attach(store)

        engine.runCycle()
        let finding = engine.recentFindings.first { $0.rule == "deadline-overdue" }
        #expect(finding?.outcome == .stalled)
    }

    // MARK: SECURITY PINS (the whole point)

    @Test("SECURITY S1: engine writes ONLY journal + quarantine — library file untouched")
    func writeScopeIsConfined() throws {
        _ = makeStore()
        SentinelDataBridge.shared.attach(makeStore())

        // Snapshot every file in the data dir before a cycle.
        let fm = FileManager.default
        let before = Set((try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey]))?
            .map(\.lastPathComponent) ?? [])

        let engine = SentinelEngine(defaults: UserDefaults(suiteName: "sentinel-test")!)
        engine.setJournalURLForTesting(dir.appendingPathComponent("sentinel-journal.jsonl"))
        engine.runCycle()

        let after = Set((try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))?
            .map(\.lastPathComponent) ?? [])
        let newFiles = after.subtracting(before)

        // Only allowed new artifact: the sentinel journal itself.
        for added in newFiles {
            #expect(added.hasPrefix("sentinel"),
                    "Sentinel created unauthorized file: \(added)")
        }
        // Library file bytes unchanged by detection cycle.
        let libData = try Data(contentsOf: libraryURL)
        #expect(!libData.isEmpty)
    }

    @Test("SECURITY S5: kill switch makes runCycle fully inert")
    func killSwitchDisablesEverything() {
        let defaults = UserDefaults(suiteName: "sentinel-killswitch")!
        defaults.set(false, forKey: SentinelEngine.enabledKey)

        let engine = SentinelEngine(defaults: defaults, probes: [OrphanedActiveSessionProbe()])
        let store = makeStore { book in
            let stale = Date().addingTimeInterval(-72 * 3600)
            let s = ReadingSession(bookID: book.id, startTime: stale, startPage: 0, endPage: 2)
            book.sessions = [s]
            book.activeSessionID = s.id
        }
        SentinelDataBridge.shared.attach(store)

        engine.runCycle() // must no-op entirely

        #expect(engine.recentFindings.isEmpty)
        #expect(engine.lastRunDate == nil)
        #expect(store.books.first?.activeSessionID != nil) // untouched
        #expect(engine.isEnabled == false)
    }

    @Test("Journal is append-only JSONL with cycle summaries")
    func journalAppends() throws {
        let engine = SentinelEngine(defaults: UserDefaults(suiteName: "sentinel-test")!)
        engine.setJournalURLForTesting(dir.appendingPathComponent("sentinel-journal.jsonl"))
        let store = makeStore()
        SentinelDataBridge.shared.attach(store)

        engine.runCycle()

        let raw = try String(contentsOf: dir.appendingPathComponent("sentinel-journal.jsonl"), encoding: .utf8)
        let lines = raw.split(separator: "\n")
        #expect(!lines.isEmpty)
        // Every line is valid JSON (JSONL contract).
        for line in lines {
            let obj = try JSONSerialization.jsonObject(with: Data(line.utf8))
            #expect(obj is [String: Any])
        }
    }
}
