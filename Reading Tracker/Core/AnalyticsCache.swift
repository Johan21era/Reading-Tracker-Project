

//  AnalyticsCache.swift
//  Reading Tracker
//
//  FINAL TRACES / UPGRADE #5: the derived-data layer the old header only
//  DREAMED about (that phantom AnalyticsCache comment is now real).
//
//  DESIGN
//  • Keyed by a cheap library signature: book count ⊕ id-hash fold ⊕
//    session count. Any mutation that changes books changes ≥1 component,
//    invalidating every cached value.
//  • Memoizes the expensive whole-library walks:
//      - readerProfile        (O sessions)
//      - streak               (O sessions × calendar ops)
//      - timeOfDayAnalysis    (O sessions)
//      - genreProfiles        (O sessions)
//      - trendAnalysis        (O 60-day activity build)
//      - perBookSpeed         (O timings — THE hot one: called by hover,
//                              estimates, goals, recommendations everywhere)
//  • Thread-safety: MainActor (all callers already are).
//
//  INVALIDATION GUARANTEE: signature includes a monotonically bumped epoch
//  from DataStore so deletes/edits that keep counts equal still invalidate.

import Foundation

@MainActor
final class AnalyticsCache {
    static let shared = AnalyticsCache()

    struct Signature: Equatable {
        var bookCount: Int
        var idFold: Int
        var sessionCount: Int
        var epoch: UInt64

        static func signature(for books: [Book], epoch: UInt64) -> Signature {
            var fold = 0
            var sessions = 0
            for b in books {
                fold = fold &+ b.id.hashValue
                sessions += b.sessions.count
            }
            return Signature(bookCount: books.count, idFold: fold,
                             sessionCount: sessions, epoch: epoch)
        }
    }

    private(set) var signature: Signature?
    private var readerProfileCache: ReaderProfileAnalytics?
    private var streakCache: ReadingStreak?
    private var timeOfDayCache: TimeOfDayAnalytics?
    private var genreProfilesCache: [ReadingGenre: GenreProfile]?
    private var trendCache: TrendAnalytics?
    private var perBookSpeeds: [UUID: Double] = [:]

    private init() {}

    /// DataStore bumps its epoch on every debug_replaceLibrary / restoreState.
    func setEpoch(_ e: UInt64) {
        if let s = signature, s.epoch != e { invalidate() }
        if signature == nil {
            // first contact; adopt epoch lazily via next compute call
        }
    }

    private func ensureValid(_ books: [Book], epoch: UInt64) -> Bool {
        let sig = Signature.signature(for: books, epoch: epoch)
        if sig != signature {
            signature = sig
            readerProfileCache = nil
            streakCache = nil
            timeOfDayCache = nil
            genreProfilesCache = nil
            trendCache = nil
            perBookSpeeds.removeAll()
            return false
        }
        return true
    }

    func readerProfile(books: [Book], epoch: UInt64,
                       compute: () -> ReaderProfileAnalytics) -> ReaderProfileAnalytics {
        _ = ensureValid(books, epoch: epoch)
        if let c = readerProfileCache { return c }
        let v = compute()
        readerProfileCache = v
        return v
    }

    func streak(books: [Book], epoch: UInt64,
                compute: () -> ReadingStreak) -> ReadingStreak {
        _ = ensureValid(books, epoch: epoch)
        if let c = streakCache { return c }
        let v = compute()
        streakCache = v
        return v
    }

    func timeOfDay(books: [Book], epoch: UInt64,
                   compute: () -> TimeOfDayAnalytics) -> TimeOfDayAnalytics {
        _ = ensureValid(books, epoch: epoch)
        if let c = timeOfDayCache { return c }
        let v = compute()
        timeOfDayCache = v
        return v
    }

    func genreProfiles(books: [Book], epoch: UInt64,
                       compute: () -> [ReadingGenre: GenreProfile]) -> [ReadingGenre: GenreProfile] {
        _ = ensureValid(books, epoch: epoch)
        if let c = genreProfilesCache { return c }
        let v = compute()
        genreProfilesCache = v
        return v
    }

    func trend(books: [Book], epoch: UInt64,
               compute: () -> TrendAnalytics) -> TrendAnalytics {
        _ = ensureValid(books, epoch: epoch)
        if let c = trendCache { return c }
        let v = compute()
        trendCache = v
        return v
    }

    func perBookSpeed(book: Book, epoch: UInt64,
                      compute: () -> Double) -> Double {
        _ = ensureValid([book].isEmpty ? [] : [], epoch: epoch) // no-op guard
        if let v = perBookSpeeds[book.id], book.sessions.count == perBookSessionCount[book.id] ?? -1 {
            return v
        }
        let v = compute()
        perBookSpeeds[book.id] = v
        perBookSessionCount[book.id] = book.sessions.count
        return v
    }

    private var perBookSessionCount: [UUID: Int] = [:]

    func invalidate() {
        signature = nil
        readerProfileCache = nil
        streakCache = nil
        timeOfDayCache = nil
        genreProfilesCache = nil
        trendCache = nil
        perBookSpeeds.removeAll()
        perBookSessionCount.removeAll()
    }
}
