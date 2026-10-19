import Foundation
import Testing
@testable import Reading_Tracker

// ADR-7 (countersigned 2026-10-18) — cursor contract pins: the gate refuses
// EVERY cursor under the no-conversion doctrine, the edition-identity
// requirement comes first, and the three typed failures carry their pinned
// S9-ES-5 code names. Pure value-level: no transport, no processes.

@Suite("Mirage Cursor Contract (PR-6)", .serialized)
struct MirageCursorContractTests {
    // ---- ADR-7 Decision 1 + Annex A.2: every cursor is refused today --------

    @Test func everyOfferedCursorIsUnverifiedUnderTheDoctrine() throws {
        let edition = "edition_0123456789abcdef"
        let offered: [MirageCursor] = [
            .estimated(fraction: 0.42, maxUnitIndex: 311),
            .page(page: 77, totalPages: 240),
            .unit(143), // even a well-formed unit index cannot be verified by RT
        ]
        for cursor in offered {
            #expect(throws: MirageCursorGateError.unverifiedCursor(
                reason: "no verified chapter→unit calibration exists (ADR-7 Decision 1) — the cursor is refused")
            ) {
                _ = try MirageCursorGate.validatedDisclosureUnits(
                    for: cursor, mappedEditionID: edition)
            }
        }
    }

    @Test func absentCursorFailsClosedAsMissing() {
        #expect(throws: MirageCursorGateError.missingCursor(
            reason: "no position data available for the mapped edition")
        ) {
            _ = try MirageCursorGate.validatedDisclosureUnits(
                for: .absent, mappedEditionID: "edition_0123456789abcdef")
        }
    }

    // ---- Annex A.3: edition-identity requirement precedes everything --------

    @Test func noMappedEditionMeansNoCursorAtAll() {
        for cursor in MirageCursor.allTestShapes {
            #expect(throws: MirageCursorGateError.missingCursor(
                reason: "no active Mirage identity mapping for this book (ADR-7 Annex A.3)")
            ) {
                _ = try MirageCursorGate.validatedDisclosureUnits(
                    for: cursor, mappedEditionID: nil)
            }
            #expect(throws: MirageCursorGateError.missingCursor(
                reason: "no active Mirage identity mapping for this book (ADR-7 Annex A.3)")
            ) {
                _ = try MirageCursorGate.validatedDisclosureUnits(
                    for: cursor, mappedEditionID: "")
            }
        }
    }

    // ---- Pinned S9-ES-5 failure codes ---------------------------------------

    @Test func failureCodesCarryTheirPinnedNames() {
        #expect(MirageCursorGateError.missingCursor(reason: "x").pinnedCode == "CURSOR-MISSING")
        #expect(MirageCursorGateError.unverifiedCursor(reason: "x").pinnedCode == "SPOILER-CURSOR-UNVERIFIED")
        #expect(MirageCursorGateError.detailProbeRejected(reason: "x").pinnedCode == "SPOILER-PROBE-REJECTED")
    }
}

private extension MirageCursor {
    static var allTestShapes: [MirageCursor] {
        [.absent, .estimated(fraction: 0.1, maxUnitIndex: 10), .page(page: 2, totalPages: 9), .unit(1)]
    }
}
