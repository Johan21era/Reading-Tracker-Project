import Combine
import Foundation

// PR-6 — ADR-7 (countersigned 2026-10-18): the read-only STATUS surface.
//
// What PR-6 ships, and only this:
//   • the RT-Mirage LINK state, locally (identity map, no engine) and
//     engine-verified (read-only `books_list`, which also carries the pinned
//     inventory row: book_id / title / edition_id / units / claims /
//     max_cursor / first_entity_id / created_at — wrapped {"books":[...]});
//   • engine-attested counts, rendered with provenance labels and NEVER
//     promoted into RT's own store (corrections-never-truth discipline);
//   • RT's read-state line, rendered in RT's own words per the A.7
//     transduction table — no Mirage declaration is ever transmitted;
//   • the detail-disabled note (ADR-7 Decision 1) — the spoiler-sensitive
//     surfaces stay off until a countersigned calibration amendment.
//
// The ONLY new wire calls are read-only `books_list`. No `projection`, no
// `search`, nothing state-ful: `MirageDetailQuery` refuses them upstream.

/// One book's inventory row, decoded verbatim from the engine's `books_list`
/// export (MirageV1.0 `api/service.py:505-554`). Required keys are strict — a
/// row missing any of them refuses to decode (fail-closed shapes, S9-ES-5).
nonisolated struct MirageInventoryEntry: Sendable, Equatable {
    let bookID: String
    let title: String?
    let editionID: String
    let units: Int
    let claims: Int
    let maxCursor: Int
    let firstEntityID: String?
    let createdAt: String?

    static func decode(_ wire: MirageJSONValue) -> MirageInventoryEntry? {
        guard case .object(let fields) = wire,
              case .string(let bookID)? = fields["book_id"],
              case .string(let editionID)? = fields["edition_id"],
              case .int(let units)? = fields["units"],
              case .int(let claims)? = fields["claims"],
              case .int(let maxCursor)? = fields["max_cursor"]
        else { return nil }
        var title: String?
        if case .string(let t)? = fields["title"] { title = t }
        var firstEntityID: String?
        if case .string(let f)? = fields["first_entity_id"] { firstEntityID = f }
        var createdAt: String?
        if case .string(let c)? = fields["created_at"] { createdAt = c }
        return MirageInventoryEntry(
            bookID: bookID, title: title, editionID: editionID,
            units: units, claims: claims, maxCursor: maxCursor,
            firstEntityID: firstEntityID, createdAt: createdAt)
    }
}

nonisolated enum MirageStatusInventory {
    /// Engine wire export (verified against MirageV1.0, M-025): the service's
    /// bare list surfaces wrapped as {"books": [...]}. Returns nil for any
    /// unexpected shape — the caller treats nil as unverifiable, never as data.
    static func decodeBooksListResult(_ result: MirageJSONValue) -> [MirageInventoryEntry]? {
        guard case .object(let wrapped) = result,
              case .array(let books)? = wrapped["books"] else { return nil }
        var decoded: [MirageInventoryEntry] = []
        for row in books {
            guard let entry = MirageInventoryEntry.decode(row) else { return nil }
            decoded.append(entry)
        }
        return decoded
    }
}

/// The status the sheet renders. Both properties are data, never prose;
/// `MirageStatusCopy` turns each into the owner-approved plain language.
nonisolated struct MirageAnalysisStatus: Sendable, Equatable {
    enum LinkState: Sendable, Equatable {
        case notImported
        /// Engine-verified active link; the counts row when the engine's
        /// inventory decoded. `nil` counts with engine-verified true is not a
        /// shape RT ever produces (presence and counts come from one call).
        case linked(entry: MirageIdentityMapEntry, counts: MirageInventoryEntry?)
        case orphaned(reason: String)
        case unverifiable(reason: String)
        case mapUnreadable(reason: String)
        /// The check was cancelled before any dispatch (S10-ES-1(e) honesty:
        /// nothing ran, and the copy says so).
        case checkCancelled
    }
    enum Channel: Sendable, Equatable {
        case localMap
        case engineVerified
    }
    let linkState: LinkState
    let channel: Channel
}

nonisolated enum MirageStatusCopy {
    /// The engine-attested counts line — always provenance-labelled (ADR-7:
    /// "counts are engine-attested inventory facts … never promoted to RT truth").
    static func countsLine(_ counts: MirageInventoryEntry?) -> String? {
        guard let counts else { return nil }
        return "Mirage's ledger shows \(counts.units) content units and "
            + "\(counts.claims) claims for this edition "
            + "(engine-attested counts, read-only — RT keeps none of them)."
    }

    /// The detail-disabled note — the one thing PR-6 never hides (ADR-7
    /// Decision 1: the gap is ledgered, not hidden).
    static let detailDisabledNote =
        "Analysis detail (claims, evidence, reading graphs) is disabled in RT for now — "
        + "Mirage's stored analysis stays safe on this Mac; this status only reports it. (ADR-7)"

    /// The A.7 transduction table, rendered read-only in RT's own words.
    static func readStateLine(
        isCompleted: Bool, isInProgress: Bool, currentPage: Int, totalPages: Int
    ) -> String {
        if isCompleted {
            return "Read state: you've finished this book in RT. No state was sent to Mirage."
        }
        if isInProgress {
            return totalPages > 0
                ? "Read state: you're reading — page \(currentPage) of \(totalPages). No state was sent to Mirage."
                : "Read state: you have this book in progress. No state was sent to Mirage."
        }
        return "Read state: you haven't started this book in RT. No state was sent to Mirage."
    }

    static func headline(_ status: MirageAnalysisStatus) -> String {
        switch status.linkState {
        case .notImported: return "RT has no Mirage link for this book yet"
        case .linked: return "Mirage has a stored analysis for this book"
        case .orphaned(let reason): return "RT's Mirage link is paused for safety (\(reason))"
        case .unverifiable(let reason): return "RT couldn't verify the Mirage link safely this time"
        case .mapUnreadable: return "RT's Mirage records could not be read safely"
        case .checkCancelled: return "The status check was canceled — nothing was run"
        }
    }
}

/// Local (map-only) status — NO engine, NO sidecar spawn, safe to compute the
/// moment the sheet opens. Engine verification stays behind the explicit
/// "Check with Mirage" gesture (one analyze-equivalent = one clean lifecycle).
nonisolated enum MirageStatusSurface {
    static func localStatus(
        store: MirageIdentityMapStore,
        source: MirageImportSource
    ) -> MirageAnalysisStatus {
        let flow = MirageImportFlow(environment: MirageImportEnvironment(
            store: store, acquireClient: { throw
                MirageCursorGateError.detailProbeRejected(reason: "local status never acquires a client") }))
        let identity = flow.identityState(for: source)
        let linkState: MirageAnalysisStatus.LinkState
        switch identity {
        case .notImported: linkState = .notImported
        case .linked(let entry): linkState = .linked(entry: entry, counts: nil)
        case .orphaned(let reason): linkState = .orphaned(reason: reason.rawValue)
        case .unverifiable(let reason): linkState = .unverifiable(reason: reason)
        case .mapUnreadable(let reason): linkState = .mapUnreadable(reason: reason)
        }
        return MirageAnalysisStatus(linkState: linkState, channel: .localMap)
    }
}

// MARK: - The sheet's controller (@MainActor; no SwiftUI dependencies in logic)

@MainActor
final class MirageStatusController: ObservableObject {
    let book: Book

    @Published private(set) var localStatus: MirageAnalysisStatus
    @Published private(set) var engineStatus: MirageAnalysisStatus?
    @Published private(set) var checking = false

    private var cancelledRequested = false

    /// Production runner: one clean sidecar lifecycle carrying the read-only
    /// status call, torn down before this method returns. Injectable so tests
    /// can prove the page-turn non-trigger pin (MiragePageTurnNonTriggerTests)
    /// without a real engine. The closure is MainActor-confined: it constructs
    /// and awaits the @MainActor analyze session, so it IS MainActor code.
    private let runner: @MainActor (
        MirageImportSource, @escaping () async -> Bool
    ) async -> MirageAnalysisStatus

    init(book: Book) {
        self.book = book
        // Local status is computed synchronously — the map file read is cheap
        // and side-effect-free (absent file ⇒ empty map ⇒ notImported).
        let source = MirageAppImportMount.importSource(for: book)
        localStatus = MirageStatusSurface.localStatus(
            store: MirageStatusController.inertStore(),
            source: source)
        runner = { source, checkCancelled in
            await MirageStatusController.productionRunner(source, checkCancelled: checkCancelled)
        }
    }

    init(
        book: Book,
        localStatus: MirageAnalysisStatus,
        runner: @escaping @MainActor (
            MirageImportSource, @escaping () async -> Bool
        ) async -> MirageAnalysisStatus
    ) {
        self.book = book
        self.localStatus = localStatus
        self.runner = runner
    }

    private static func inertStore() -> MirageIdentityMapStore {
        MirageIdentityMapStore(fileURL: MirageSupportPaths.mirageDirectory()
            .appendingPathComponent("identity-map.json"))
    }

    @MainActor private static func productionRunner(
        _ source: MirageImportSource,
        checkCancelled: @escaping () async -> Bool
    ) async -> MirageAnalysisStatus {
        guard await checkCancelled() == false else {
            return MirageAnalysisStatus(linkState: .checkCancelled, channel: .engineVerified)
        }
        guard let engineDir = MirageAppImportMount.engineCheckoutDirectory() else {
            return MirageAnalysisStatus(
                linkState: .unverifiable(
                    reason: "the Mirage engine isn't set up on this Mac yet (dev gate MIRAGE_REAL_ENGINE_DIR)"),
                channel: .engineVerified)
        }
        do {
            let session = try MirageAnalyzeSession(engineCheckout: engineDir)
            defer { Task { await session.shutdown() } }
            if await checkCancelled() {
                return MirageAnalysisStatus(linkState: .checkCancelled, channel: .engineVerified)
            }
            let client = try await session.acquireTransportClient()
            let flow = MirageImportFlow(environment: MirageImportEnvironment(
                store: session.identityStore,
                acquireClient: { try await session.acquireTransportClient() }))
            return try await MirageAnalysisStatus.fromEngineVerified(
                flow: flow, source: source, client: client, checkCancelled: checkCancelled)
        } catch {
            return MirageAnalysisStatus(
                linkState: .unverifiable(reason: String(describing: error)),
                channel: .engineVerified)
        }
    }

    /// The explicit user gesture — the ONLY way engine verification happens.
    /// PR-7: the settings gate wins even here (a disabled feature never spawns).
    func refreshEngineStatus() async {
        guard MirageSettings.isEnabled else { return }
        guard !checking else { return }
        checking = true
        cancelledRequested = false
        let checkCancelled = { [weak self] () async -> Bool in
            guard let self else { return true }
            return await MainActor.run { self.cancelledRequested }
        }
        engineStatus = await runner(MirageAppImportMount.importSource(for: book), checkCancelled)
        checking = false
    }

    func cancelRequested() {
        cancelledRequested = true
    }
}

extension MirageAnalysisStatus {
    static func fromEngineVerified(
        flow: MirageImportFlow,
        source: MirageImportSource,
        client: MirageClient,
        checkCancelled: @escaping () async -> Bool
    ) async throws -> MirageAnalysisStatus {
        if await checkCancelled() {
            return MirageAnalysisStatus(linkState: .checkCancelled, channel: .engineVerified)
        }
        let pair = try await flow.engineVerifiedIdentityAndInventory(
            for: source, client: client)
        let linkState: MirageAnalysisStatus.LinkState
        switch pair.identity {
        case .notImported: linkState = .notImported
        case .linked(let entry):
            if await checkCancelled() {
                return MirageAnalysisStatus(linkState: .checkCancelled, channel: .engineVerified)
            }
            linkState = .linked(entry: entry, counts: pair.counts)
        case .orphaned(let reason): linkState = .orphaned(reason: reason.rawValue)
        case .unverifiable(let reason): linkState = .unverifiable(reason: reason)
        case .mapUnreadable(let reason): linkState = .mapUnreadable(reason: reason)
        }
        return MirageAnalysisStatus(linkState: linkState, channel: .engineVerified)
    }
}
