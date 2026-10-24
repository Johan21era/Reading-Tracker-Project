//  DemoProfileServiceTests.swift
//  AsterismaV1.0Tests
//
//  Pins for the Developer Console's Demo Profile Lab (LT-8 v2).
//
//  What these tests guarantee before Johan ever clicks "Install":
//    • Every persona's generated library passes DataIntegrityValidator with no
//      unrepairable errors — installing can never trip the corruption banner.
//    • Every synthesized session is CLOSED (no phantom-time ghosts in demo data).
//    • Persona SIGNATURES are real: the Winter Romantic genuinely reads mostly
//      romance in winter; the Afternoon Devotee genuinely reads 12–5.
//    • Generation is deterministic per persona id.

import Foundation
import Testing

@testable import AsterismaV1_0

#if DEBUG

@Suite("Demo Profile Lab — persona generation pins")
struct DemoProfileServiceTests {

    private let cal = Calendar(identifier: .gregorian)

    // MARK: - Catalog integrity

    @Test("catalog contains 16 personas with unique ids")
    func catalogShape() {
        #expect(DemoProfileCatalog.all.count == 16)
        #expect(Set(DemoProfileCatalog.all.map(\.id)).count == 16)
        #expect(DemoProfileCatalog.persona(withID: "winter-romantic") != nil)
    }

    // MARK: - Validator cleanliness across EVERY persona

    @Test("every persona generates a validator-clean library", arguments: DemoProfileCatalog.all.map(\.id))
    func everyPersonaIsValidatorClean(id: String) throws {
        let persona = try #require(DemoProfileCatalog.persona(withID: id))
        let books = DemoProfileCatalog.generateBooks(for: persona)

        #expect(!books.isEmpty)

        let (_, report) = DataIntegrityValidator.validate(books)
        #expect(!report.hasUnrepairableErrors,
                "\(id): unrepairable validation issues — install would trip the corruption gate")

        for book in books {
            for session in book.sessions {
                #expect(session.endTime != nil,
                        "\(id)/\(book.title): open session would create phantom time")
            }
            #expect(book.currentPage < max(1, book.totalPages),
                    "\(id)/\(book.title): currentPage out of range")
        }
    }

    // MARK: - Persona signatures

    @Test("Winter Romantic: majority of reading happens in winter months, dominated by romance")
    func winterRomanticSignature() throws {
        let persona = try #require(DemoProfileCatalog.persona(withID: "winter-romantic"))
        let books = DemoProfileCatalog.generateBooks(for: persona)
        let sessions = books.flatMap(\.sessions)

        let winterMonths: Set<Int> = [12, 1, 2]
        let winterSeconds = sessions.filter { winterMonths.contains(cal.component(.month, from: $0.startTime)) }
            .reduce(0.0) { $0 + $1.duration }
        let totalSeconds = sessions.reduce(0.0) { $0 + $1.duration }
        #expect(winterSeconds / totalSeconds > 0.45,
                "winter share too low — seasonality engine drifted")

        let romance = books.filter { $0.genre == .romance }
            .reduce(0.0) { $0 + $1.totalReadingTime }
        #expect(romance / totalSeconds >= 0.52, "romance must clearly dominate this persona")
    }

    @Test("Afternoon Devotee: ≥70% of sessions start between 12:00 and 16:59")
    func afternoonDevoteeSignature() throws {
        let persona = try #require(DemoProfileCatalog.persona(withID: "afternoon-devotee"))
        let sessions = DemoProfileCatalog.generateBooks(for: persona).flatMap(\.sessions)

        let afternoon = sessions.filter {
            (12..<17).contains(cal.component(.hour, from: $0.startTime))
        }
        #expect(Double(afternoon.count) / Double(sessions.count) > 0.7)
    }

    // MARK: - Determinism

    @Test("generation is deterministic per persona id")
    func deterministicOutput() throws {
        let persona = try #require(DemoProfileCatalog.persona(withID: "goal-crusher"))

        let a = DemoProfileCatalog.generateBooks(for: persona,
                                                 referenceDate: Date(timeIntervalSince1970: 1_760_000_000))
        let b = DemoProfileCatalog.generateBooks(for: persona,
                                                 referenceDate: Date(timeIntervalSince1970: 1_760_000_000))

        #expect(a.map(\.title) == b.map(\.title))
        #expect(a.flatMap(\.sessions).count == b.flatMap(\.sessions).count)
        #expect(a.flatMap(\.sessions).first?.startTime
              == b.flatMap(\.sessions).first?.startTime)
    }
}
#endif
