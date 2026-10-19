import Foundation

// PR-5 app glue: bridges RT's Book (owned data) into the Mirage import flow,
// borrowing ONLY read-only referents (`Book.resolveURL()`) — it never creates
// books, never touches goals, and never writes RT's own store (ADR-6 census
// gate; the RT-side NEW-DE-5 bypass stays path-independent by construction).
//
// Engine-location policy is DEV-OPT-IN for PR-5: the same MIRAGE_REAL_ENGINE_DIR
// environment variable the opt-in test suites use. No hardcoded paths, no
// production semantics — the packaged-runtime policy belongs to ADR-3 / PR-8
// and will replace this lookup wholesale.
//
// Lifecycle doctrine (until PR-7's settings session): one analyze = ONE sidecar
// lifecycle — spawn, import, clean shutdown. A cancelled/failed analyze always
// tears down too. This also honors the machinery boundary recorded M-024: one
// process hosts one spawn at a time; sequential user analyzes each get their
// own clean epoch.

@MainActor
final class MirageAnalyzeSession {
    private(set) var supervisor: MirageSidecarSupervisor
    private let store: MirageIdentityMapStore
    private var transport: MirageProcessTransport?

    init(engineCheckout: URL) throws {
        // ADR-4 stratum directory — <Application Support>/ReadTracker is RT's
        // same data root (DataStore3:91-95); mirage/ inside it is Mirage-write
        // territory (ledger db + identity map + pid guard). RT creates the
        // directory with an existence check before the first spawn.
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            .map { $0.appendingPathComponent("ReadTracker", isDirectory: true)
                .appendingPathComponent("mirage", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
                .appendingPathComponent("ReadTracker-degraded/mirage", isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: false)
        }
        var config = MirageProcessTransportConfig()
        config.bannerTimeout = 25 // import requests wait on real engine work
        config.responseTimeout = 25
        supervisor = MirageSidecarSupervisor(
            configuration: .init(
                launcher: MirageProcessLauncher(
                    executableURL: try MiragePythonLocator.shared.executableURL(),
                    arguments: [engineCheckout.path + "/examples/mirage_sidecar.py",
                                base.appendingPathComponent("mirage.sqlite3").path]),
                pidFileURL: base.appendingPathComponent("guard.pid"),
                transportConfig: config))
        store = MirageIdentityMapStore(
            fileURL: base.appendingPathComponent("identity-map.json"))
    }

    /// Idempotent within the session: repeated providers inside one flow see
    /// the established handshake; a dead child forces a fresh handshake epoch.
    private func acquire() async throws -> MirageClient {
        if let existingTransport = transport, existingTransport.isChildAlive() {
            return MirageClient(transport: existingTransport,
                                idProvider: { UUID().uuidString })
        }
        let fresh = try await supervisor.acquireTransport()
        transport = fresh
        return MirageClient(transport: fresh, idProvider: { UUID().uuidString })
    }

    /// Runs the one-book analyze and ALWAYS ends with a clean shutdown.
    func performImport(
        source: MirageImportSource,
        checkCancelled: @escaping () async -> Bool = { false }
    ) async -> MirageImportOutcome {
        // Acquire first so a spawn failure types as `.sidecarUnavailable`
        // before anything else runs (the environment's provider then reuses
        // the established handshake).
        do { _ = try await acquire() }
        catch { await shutdown(); return .sidecarUnavailable(reason: String(describing: error)) }
        let environment = MirageImportEnvironment(store: store, acquireClient: {
            try await self.acquire()
        })
        let outcome = await MirageImportFlow(environment: environment)
            .performImport(source: source, checkCancelled: checkCancelled)
        await shutdown()
        return outcome
    }

    func shutdown() async {
        await supervisor.shutdown()
        transport = nil
    }
}

nonisolated enum MirageAppImportMount {
    /// Engine checkout discovery for PR-5: the dev-opt-in environment gate.
    static func engineCheckoutDirectory() -> URL? {
        let dir = ProcessInfo.processInfo.environment["MIRAGE_REAL_ENGINE_DIR"] ?? ""
        guard !dir.isEmpty,
              FileManager.default.fileExists(atPath: dir + "/examples/mirage_sidecar.py")
        else { return nil }
        return URL(fileURLWithPath: dir)
    }

    /// The single RT borrow (ADR-6 item 5): a Book's identity + file-type gate
    /// + read-only referent resolver. Nothing else of the book is consumed and
    /// nothing is written back to RT's data layer.
    static func importSource(for book: Book) -> MirageImportSource {
        let snapshot = book
        return MirageImportSource(
            rtBookID: snapshot.id,
            fileTypeIsEpub: snapshot.fileType == .epub,
            resolveURL: { snapshot.resolveURL() })
    }
}

// ---- plain-language outcome copy (S10-ES-1 honesty doctrine) ----------------
//
// Rules baked into every line below: never claim an undo that didn't happen
// (.cancelled(engineCommitted:) says exactly which world the cancel happened
// in — owner-approved wording, 2026-10-18); never imply the RT store changed
// (it never does); never invent numbers the receipt didn't give.

nonisolated enum MirageOutcomeCopy {
    static func headline(_ outcome: MirageImportOutcome) -> String {
        switch outcome {
        case .linked(_, false): return "Mirage analyzed this book"
        case .linked(_, true): return "This book was already analyzed"
        case .degradedImport: return "Mirage refused this book's file"
        case .invalidReceipt: return "The analysis answer didn't match what RT expected"
        case .sourceUnavailable: return "The book's file could not be read"
        case .notApplicableFileType: return "Only EPUB books can be analyzed with Mirage"
        case .mapUnreadable: return "RT's Mirage records could not be read safely"
        case .mapWriteFailed: return "RT could not record the link safely"
        case .engineError: return "Mirage's engine refused this request"
        case .sidecarUnavailable: return "Mirage's engine is not available"
        case .cancelled(let engineCommitted):
            return engineCommitted
                ? "Canceled after Mirage stored its work"
                : "Canceled — nothing was run"
        }
    }

    static func detail(_ outcome: MirageImportOutcome) -> String {
        switch outcome {
        case .linked(_, false):
            return "Mirage stored its analysis of this book on this Mac. RT's library and your goals were not touched — Mirage keeps its own files."
        case .linked(_, true):
            return "Mirage reused the analysis it had already stored — nothing was run twice."
        case .degradedImport(let skipped):
            return "\(skipped) section\(skipped == 1 ? "" : "s") of this file could not be read safely, so Mirage kept nothing from it and RT recorded no link. Repairing the source file may help."
        case .invalidReceipt(let reason):
            return "Nothing was linked and no settings changed. (Detail: \(reason))"
        case .sourceUnavailable(let reason):
            return "\(reason). Nothing was linked."
        case .notApplicableFileType(let reason):
            return reason
        case .mapUnreadable(let reason):
            return "To stay safe, Mirage analysis is paused for this book until the records file is repaired. (Detail: \(reason))"
        case .mapWriteFailed(let reason):
            return "Nothing partial was saved — the link was not recorded. You can try again. (Detail: \(reason))"
        case .engineError(let payload):
            return "Mirage's engine answered with an error, so no link was recorded. (Detail: \(payload))"
        case .sidecarUnavailable(let reason):
            return reason.contains("MIRAGE_REAL_ENGINE_DIR")
                ? "The Mirage engine isn't set up on this Mac yet. RT will bundle it in a future release — nothing else was affected."
                : "Mirage's engine could not be reached, so nothing was analyzed and no link was recorded. (Detail: \(reason))"
        case .cancelled(let engineCommitted):
            return engineCommitted
                ? "Mirage has already stored its analysis of this book, and that stays. RT just didn't record the link — analyze it again anytime and Mirage will reuse that stored work."
                : "You canceled before Mirage did anything. Nothing was run, and nothing was linked."
        }
    }
}
