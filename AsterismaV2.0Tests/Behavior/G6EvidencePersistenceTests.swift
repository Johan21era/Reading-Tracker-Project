import Foundation
import Testing
@testable import AsterismaV2_0

@Suite("G6 · Evidence persistence", .serialized)
@MainActor
final class G6EvidencePersistenceTests {

    @Test("Behavioral evidence archive loads application sessions on init")
    func archiveLoads() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("behavior-evidence.json")

        let app = ApplicationDescriptor(
            applicationName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            processIdentifier: 1,
            category: .browsing,
            executableURL: nil)
        let session = ApplicationUsageSession(
            application: app,
            startTime: Date().addingTimeInterval(-300),
            endTime: Date())
        let archive = BehaviorContextAccessKit.BehaviorEvidenceArchive(
            events: [],
            applicationSessions: [session],
            inactivityRecords: [],
            deviceStateEvents: [])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(archive).write(to: url)

        let kit = BehaviorContextAccessKit(archiveURL: url)
        #expect(kit.applicationSessions.count == 1)
        #expect(kit.applicationSessions.first?.application.applicationName == "Safari")
    }
}
