import Foundation

// PR-6 — ADR-7 (countersigned 2026-10-18): the spoiler-cursor machinery.
//
// Doctrine (ADR-7 Decision 1 + Annex A.2): NO verified chapter→unit conversion
// exists — Mirage discloses by paragraph-unit index, RT only knows pages and
// chapters, and the only estimate (fraction × inventory max_cursor) cannot
// guarantee "≤ the reader's position". So this machinery is built and pinned,
// but GATED: nothing in RT may feed a spoiler-sensitive wire request a cursor
// it cannot prove verified. Under the today-policy, that gate refuses every
// cursor a caller could possibly offer — a future countersigned amendment is
// the only thing that can widen it.
//
// Three typed failures (ADR-7 body, S9-ES-5 classes; Annex A.6):
//   CURSOR-MISSING              — no mapped identity / no position data
//   SPOILER-CURSOR-UNVERIFIED   — a cursor offered without verified evidence
//   SPOILER-PROBE-REJECTED      — a request seeking detail disclosure at all

nonisolated enum MirageCursor: Sendable, Equatable {
    /// No position data at all (Annex A.6: fail closed).
    case absent
    /// The rejected estimate (progress fraction × the edition's `max_cursor`).
    /// Present as a case ONLY so the refusals below are testable; no RT code
    /// ever constructs it in production paths (ADR-7 "Alternatives — rejected").
    case estimated(fraction: Double, maxUnitIndex: Int)
    /// An RT-native page coordinate (Annex A.1 provenance) — a different
    /// coordinate space than the ledger's `unit_index`; unverifiable by space.
    case page(page: Int, totalPages: Int)
    /// A ledger unit index. Today NOTHING can verify one (Annex A.2); only a
    /// future countersigned calibration amendment may feed this case.
    case unit(Int)
}

nonisolated enum MirageCursorGateError: Error, Equatable, Sendable {
    /// CURSOR-MISSING
    case missingCursor(reason: String)
    /// SPOILER-CURSOR-UNVERIFIED
    case unverifiedCursor(reason: String)
    /// SPOILER-PROBE-REJECTED
    case detailProbeRejected(reason: String)

    var pinnedCode: String {
        switch self {
        case .missingCursor: return "CURSOR-MISSING"
        case .unverifiedCursor: return "SPOILER-CURSOR-UNVERIFIED"
        case .detailProbeRejected: return "SPOILER-PROBE-REJECTED"
        }
    }
}

nonisolated enum MirageCursorGate {
    /// Annex A.3 (edition-identity requirement): a cursor is valid only against
    /// its mapped `mirageEditionID`. Unmapped book ⇒ no cursor at all.
    /// Annex A.2 (conversion): under the no-conversion doctrine every offered
    /// cursor is unverified — refused with `SPOILER-CURSOR-UNVERIFIED`.
    static func validatedDisclosureUnits(
        for cursor: MirageCursor,
        mappedEditionID: String?
    ) throws -> Int {
        guard let mappedEditionID, !mappedEditionID.isEmpty else {
            throw MirageCursorGateError.missingCursor(
                reason: "no active Mirage identity mapping for this book (ADR-7 Annex A.3)")
        }
        switch cursor {
        case .absent:
            throw MirageCursorGateError.missingCursor(
                reason: "no position data available for the mapped edition")
        case .estimated, .page, .unit:
            throw MirageCursorGateError.unverifiedCursor(
                reason: "no verified chapter→unit calibration exists (ADR-7 Decision 1) — the cursor is refused")
        }
    }
}

/// What a spoiler-sensitive detail request would have been, typed for the
/// record. `action` is one of the wire's detail-disclosure endpoints
/// (`.projection` / `.search`); nothing here is ever transmitted under ADR-7.
nonisolated struct MirageDetailRequest: Sendable, Equatable {
    let action: MirageWireAction
    let editionID: String
    let cursor: MirageCursor
}

/// The DISABLED detail call-site (ADR-7 Decision 2): every spoiler-sensitive
/// query refuses at preflight, before the transport is ever contacted.
nonisolated enum MirageDetailQuery {
    /// Throws `SPOILER-PROBE-REJECTED` unconditionally (no-conversion doctrine):
    /// even a well-formed unit cursor cannot be verified by anything RT has, so
    /// NO detail request is composed, sent, or retried.
    static func preflight(
        _ request: MirageDetailRequest,
        mappedEditionID: String?
    ) throws -> MirageWireRequestLine {
        throw MirageCursorGateError.detailProbeRejected(
            reason: "spoiler-sensitive detail queries are disabled by ADR-7 "
                + "(no verified chapter→unit calibration); request for action "
                + "\"\(request.action.rawValue)\" was never transmitted")
    }

    /// The wired-but-gated dispatch the future amendment takes over. The client
    /// parameter documents the intended path; nothing reaches it under ADR-7.
    static func dispatch(
        _ request: MirageDetailRequest,
        mappedEditionID: String?,
        client: MirageClient
    ) async throws -> MirageClient.Outcome {
        do {
            _ = try preflight(request, mappedEditionID: mappedEditionID)
        } catch let gate as MirageCursorGateError {
            throw gate
        } catch {
            throw MirageCursorGateError.detailProbeRejected(
                reason: "preflight raised an unexpected error: \(error)")
        }
        // Unreachable under ADR-7: preflight throws unconditionally. Kept only
        // so the future amendment's sole change is widening the gate body.
        throw MirageCursorGateError.detailProbeRejected(
            reason: "unreachable under ADR-7 — widen the gate only via a countersigned amendment")
    }
}
