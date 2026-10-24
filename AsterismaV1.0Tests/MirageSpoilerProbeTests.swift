import Foundation
import Testing
@testable import AsterismaV1_0

// ADR-7 (countersigned 2026-10-18) — spoiler probe pins: the disabled detail
// call-site refuses EVERY detail request at preflight (SPOILER-PROBE-REJECTED),
// before the transport is ever contacted — no mapped edition required, no
// cursor required, no payload composed. The engine is never reached.

@Suite("Mirage Spoiler Probe Refusals (PR-6)", .serialized)
struct MirageSpoilerProbeTests {
    /// A transport whose job is to PROVE it never gets contacted: any call
    /// records an issue and increments a counter (both assertions each test).
    private final class ProbeTripwireTransport: MirageTransport, @unchecked Sendable {
        private let lock = NSLock()
        private var exchanges = 0

        var exchangeCount: Int {
            lock.lock(); defer { lock.unlock() }
            return exchanges
        }

        func exchange(_ requestLine: Data) async throws -> Data {
            lock.lock(); exchanges += 1; lock.unlock()
            Issue.record("TRANSPORT CONTACTED BY A DETAIL PROBE — ADR-7 violation")
            return Data()
        }
    }

    private func probe(
        _ action: MirageWireAction, cursor: MirageCursor, edition: String = "edition_0123456789abcdef"
    ) -> MirageDetailRequest {
        MirageDetailRequest(action: action, editionID: edition, cursor: cursor)
    }

    @Test func projectionProbeRejectedForEveryCursorShape() throws {
        let edition = "edition_0123456789abcdef"
        for cursor in [MirageCursor.absent, .estimated(fraction: 0.5, maxUnitIndex: 9),
                       .page(page: 1, totalPages: 9), .unit(9)] {
            #expect(throws: MirageCursorGateError.detailProbeRejected(
                reason: "spoiler-sensitive detail queries are disabled by ADR-7 "
                    + "(no verified chapter→unit calibration); request for action "
                    + "\"projection\" was never transmitted")
            ) {
                _ = try MirageDetailQuery.preflight(probe(.projection, cursor: cursor),
                                                    mappedEditionID: edition)
            }
        }
    }

    @Test func searchProbeRejectedWithoutAnyMappingOrCursor() throws {
        let request = probe(.search, cursor: .absent, edition: "edition_unmapped_0000")
        #expect(throws: MirageCursorGateError.detailProbeRejected(
            reason: "spoiler-sensitive detail queries are disabled by ADR-7 "
                + "(no verified chapter→unit calibration); request for action "
                + "\"search\" was never transmitted")
        ) {
            _ = try MirageDetailQuery.preflight(request, mappedEditionID: nil)
        }
    }

    @Test func dispatchNeverTouchesTheTransport() async throws {
        let tripwire = ProbeTripwireTransport()
        let client = MirageClient(transport: tripwire, idProvider: { "test-id" })
        for action in [MirageWireAction.projection, .search] {
            do {
                _ = try await MirageDetailQuery.dispatch(
                    probe(action, cursor: .unit(11)), mappedEditionID: nil, client: client)
                Issue.record("dispatch returned — it must always refuse")
            } catch let gate as MirageCursorGateError {
                #expect(gate.pinnedCode == "SPOILER-PROBE-REJECTED")
            } catch {
                Issue.record("unexpected error type from dispatch: \(error)")
            }
        }
        #expect(tripwire.exchangeCount == 0)
    }
}
