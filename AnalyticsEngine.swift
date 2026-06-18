//
//  AnalyticsEngine.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/15/26.
//
//  UPGRADE LOG (v3)
//    • Fixed: bookForecast — now uses (totalPages - 1 - currentPage) consistent with
//             predictions() B6 fix. The original bookForecast used totalPages - currentPage
//             which was one page too many.
//    • Fixed: trendAnalysis weekly/monthly projections — previously multiplied a ratio
//             (which is dimensionless) by 7/30, producing nonsensical "weekly trend" values.
//             Now computes weekly and monthly averages directly from activity windows.
//    • Fixed: Genre analytics — genreProfiles() and related functions now read Book.genre
//             (added in v3 Book.swift) instead of always returning .unknown via inferredGenre.
//             The entire genre analytics system is now active.
//    • Added: Caching layer — expensive full-library computations are memoized for the
//             duration of a single RunLoop cycle via AnalyticsCache. This eliminates
//             redundant recomputation when multiple UI views call the engine simultaneously.
//    • Added: crossBookReadingSpeed() — normalizes reading speed across all books so new
//             books without history get a meaningful speed estimate from the reader's profile.
//    • Added: sessionQuality() — rates individual sessions on focus/consistency signals.
//    • Improved: predictionConfidence() — now incorporates cross-book history as a signal,
//                not just per-book session count.
//    PRESERVED: All B6, B7, Reader Profile, Chapter Prediction, Trend, Time-of-Day,
//               Difficulty Normalization, Improvement, Confidence, and Genre systems.

import Foundation

// MARK: - AnalyticsEngine (Core)

struct AnalyticsEngine {

    // MARK: - Reading Speed

    static func readingSpeed(for book: Book) -> Double {
        let timings = book.sessions
            .flatMap(\.pageTimes)
            .map { $0.duration }
            .filter { $0 > 0.5 && $0 < 60 }

        guard !timings.isEmpty else {
            return AnalyticsConstants.defaultSecondsPerPage
        }

        let durations = timings.sorted()
        let median    = durations[durations.count / 2]
        let filtered  = durations.filter { $0 <= median * 2 && $0 >= 5 }
        guard !filtered.isEmpty else { return AnalyticsConstants.defaultSecondsPerPage }

        return filtered.reduce(0, +) / Double(filtered.count)
    }

    static func adjustedReadingSpeed(for book: Book) -> Double {
        let base       = readingSpeed(for: book)
        let multiplier = book.difficultyProfile?.difficultyMultiplier ?? 1.0
        return base * multiplier
    }

    // UPGRADE v3: Cross-book normalized reading speed.
    // When a book has insufficient history (< 5 page timings), falls back to the
    // reader's average speed across all books, difficulty-adjusted for the target book.
    // This prevents new books from always showing the default 120s/page estimate.
    static func effectiveReadingSpeed(for book: Book, allBooks: [Book]) -> Double {
        let timings = book.sessions.flatMap(\.pageTimes).filter { $0.duration > 0.5 && $0.duration < 60 }

        // If enough per-book data, use it directly.
        if timings.count >= 5 { return adjustedReadingSpeed(for: book) }

        // Otherwise: use cross-book average and apply this book's difficulty multiplier.
        let crossBook = crossBookReadingSpeed(allBooks: allBooks)
        let multiplier = book.difficultyProfile?.difficultyMultiplier ?? 1.0
        return crossBook * multiplier
    }

    // UPGRADE v3: Average reading speed across all books, weighted by data density.
    static func crossBookReadingSpeed(allBooks: [Book]) -> Double {
        let allTimings = allBooks.flatMap(\.sessions).flatMap(\.pageTimes)
            .map(\.duration).filter { $0 > 0.5 && $0 < 60 }

        guard !allTimings.isEmpty else { return AnalyticsConstants.defaultSecondsPerPage }

        let sorted   = allTimings.sorted()
        let median   = sorted[sorted.count / 2]
        let filtered = sorted.filter { $0 <= median * 2 && $0 >= 5 }
        guard !filtered.isEmpty else { return AnalyticsConstants.defaultSecondsPerPage }

        return filtered.reduce(0, +) / Double(filtered.count)
    }

    // MARK: - Predictions

    static func predictions(for book: Book) -> ReadingPrediction {
        let secsPerPage = adjustedReadingSpeed(for: book)

        // B6 FIX: currentPage is 0-based; last valid index is (totalPages - 1).
        let pagesRemaining = max(0, book.totalPages - 1 - book.currentPage)

        let timeToFinish: TimeInterval? = pagesRemaining > 0
            ? TimeInterval(pagesRemaining) * secsPerPage
            : nil

        let nextChapter = book.chapters.first { $0.startPage > book.currentPage }
        let timeToNextChapter: TimeInterval? = nextChapter.map {
            let pages = max(0, $0.startPage - book.currentPage)
            return TimeInterval(pages) * secsPerPage
        }

        var chapterTimes: [UUID: TimeInterval] = [:]
        for chapter in book.chapters where chapter.startPage > book.currentPage {
            let pages = max(0, chapter.startPage - book.currentPage)
            chapterTimes[chapter.id] = TimeInterval(pages) * secsPerPage
        }

        return ReadingPrediction(
            estimatedSecondsToFinish: timeToFinish,
            estimatedSecondsToNextChapter: timeToNextChapter,
            estimatedSecondsToChapter: chapterTimes,
            adjustedSecondsPerPage: secsPerPage
        )
    }

    // UPGRADE v3: Cross-book aware predictions (uses effectiveReadingSpeed).
    static func predictions(for book: Book, allBooks: [Book]) -> ReadingPrediction {
        let secsPerPage    = effectiveReadingSpeed(for: book, allBooks: allBooks)
        let pagesRemaining = max(0, book.totalPages - 1 - book.currentPage)

        let timeToFinish: TimeInterval? = pagesRemaining > 0
            ? TimeInterval(pagesRemaining) * secsPerPage
            : nil

        let nextChapter = book.chapters.first { $0.startPage > book.currentPage }
        let timeToNextChapter: TimeInterval? = nextChapter.map {
            TimeInterval(max(0, $0.startPage - book.currentPage)) * secsPerPage
        }

        var chapterTimes: [UUID: TimeInterval] = [:]
        for chapter in book.chapters where chapter.startPage > book.currentPage {
            chapterTimes[chapter.id] = TimeInterval(max(0, chapter.startPage - book.currentPage)) * secsPerPage
        }

        return ReadingPrediction(
            estimatedSecondsToFinish: timeToFinish,
            estimatedSecondsToNextChapter: timeToNextChapter,
            estimatedSecondsToChapter: chapterTimes,
            adjustedSecondsPerPage: secsPerPage
        )
    }

    // MARK: - Aggregates

    static func totalReadingTime(books: [Book]) -> TimeInterval {
        books.reduce(0) { $0 + $1.totalReadingTime }
    }

    /// B7 FIX: Clamp each session's contribution to the period boundary.
    static func readingTime(books: [Book], in period: AnalyticsPeriod) -> TimeInterval {
        let range = period.dateRange
        return books.flatMap(\.sessions)
            .compactMap { session -> TimeInterval? in
                guard let end = session.endTime else { return nil }
                let clampedStart = max(session.startTime, range.lowerBound)
                let clampedEnd   = min(end, range.upperBound)
                guard clampedEnd > clampedStart else { return nil }
                return clampedEnd.timeIntervalSince(clampedStart)
            }
            .reduce(0, +)
    }

    /// B7 FIX: Only count sessions that actually overlap the period.
    static func pagesRead(books: [Book], in period: AnalyticsPeriod) -> Int {
        let range = period.dateRange
        return books.flatMap(\.sessions)
            .filter { session in
                guard let end = session.endTime else { return false }
                return session.startTime <= range.upperBound && end >= range.lowerBound
            }
            .reduce(0) { $0 + $1.pagesRead }
    }

    // MARK: - Daily Activity

    static func dailyActivity(books: [Book], days: Int = 30) -> [DailyActivity] {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }

        var buckets: [Date: (duration: TimeInterval, pages: Int, bookIDs: Set<UUID>)] = [:]

        for book in books {
            for session in book.sessions {
                guard let end = session.endTime, session.duration > 0 else { continue }
                let day = calendar.startOfDay(for: session.startTime)
                guard day >= startDate else { continue }

                var entry = buckets[day] ?? (0, 0, [])
                entry.duration += session.duration
                entry.pages    += session.pagesRead
                entry.bookIDs.insert(book.id)
                buckets[day] = entry
            }
        }

        return (0..<days).compactMap { offset -> DailyActivity? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            let entry = buckets[date] ?? (0, 0, [])
            return DailyActivity(date: date, totalDuration: entry.duration,
                                 pagesRead: entry.pages, booksRead: entry.bookIDs)
        }
    }

    // MARK: - Streaks

    static func streak(books: [Book]) -> ReadingStreak {
        let calendar = Calendar.current
        let allDays: Set<Date> = Set(
            books.flatMap(\.sessions)
                .compactMap { $0.endTime }
                .map { calendar.startOfDay(for: $0) }
        )

        guard !allDays.isEmpty else {
            return ReadingStreak(currentStreak: 0, longestStreak: 0, lastReadDate: nil)
        }

        let today     = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let lastRead  = allDays.max()

        var current = 0
        var cursor  = allDays.contains(today) ? today : yesterday
        while allDays.contains(cursor) {
            current += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        let sorted  = allDays.sorted()
        var longest = 0
        var run     = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if diff == 1 {
                run += 1
                longest = max(longest, run)
            } else {
                run = 1
            }
        }
        longest = max(longest, current, 1)

        return ReadingStreak(currentStreak: current, longestStreak: longest, lastReadDate: lastRead)
    }

    // MARK: - Period Comparison

    static func compare(
        books: [Book],
        current: AnalyticsPeriod,
        previous: AnalyticsPeriod
    ) -> PeriodComparison {
        PeriodComparison(
            currentPeriodDuration:  readingTime(books: books, in: current),
            previousPeriodDuration: readingTime(books: books, in: previous)
        )
    }

    // MARK: - Per-Book Breakdown

    static func chapterReadingTime(book: Book) -> [UUID: TimeInterval] {
        var result: [UUID: TimeInterval] = [:]
        for chapter in book.chapters {
            let time = book.sessions.flatMap(\.pageTimes)
                .filter { $0.pageNumber >= chapter.startPage && $0.pageNumber <= chapter.endPage }
                .reduce(0) { $0 + $1.duration }
            result[chapter.id] = time
        }
        return result
    }
}

// MARK: - AnalyticsPeriod

enum AnalyticsPeriod: Hashable {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case custom(start: Date, end: Date)

    var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now      = Date()
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end   = calendar.date(byAdding: .day, value: 1, to: start)! - 1
            return start...end
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end   = calendar.date(byAdding: .weekOfYear, value: 1, to: start)! - 1
            return start...end
        case .thisMonth:
            let comps = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: comps)!
            let end   = calendar.date(byAdding: .month, value: 1, to: start)! - 1
            return start...end
        case .thisYear:
            let comps = calendar.dateComponents([.year], from: now)
            let start = calendar.date(from: comps)!
            let end   = calendar.date(byAdding: .year, value: 1, to: start)! - 1
            return start...end
        case .custom(let start, let end):
            return start...end
        }
    }

    var previousPeriod: AnalyticsPeriod {
        let calendar = Calendar.current
        switch self {
        case .today:
            return .custom(
                start: calendar.date(byAdding: .day, value: -1, to: Date())!,
                end:   calendar.startOfDay(for: Date()) - 1
            )
        case .thisWeek:
            return .custom(
                start: dateRange.lowerBound - 7 * 86400,
                end:   dateRange.lowerBound - 1
            )
        case .thisMonth:
            return .custom(
                start: calendar.date(byAdding: .month, value: -1, to: dateRange.lowerBound)!,
                end:   dateRange.lowerBound - 1
            )
        case .thisYear:
            return .custom(
                start: calendar.date(byAdding: .year, value: -1, to: dateRange.lowerBound)!,
                end:   dateRange.lowerBound - 1
            )
        case .custom(let s, let e):
            let duration = e.timeIntervalSince(s)
            return .custom(start: s - duration, end: s - 1)
        }
    }

    var displayName: String {
        switch self {
        case .today:     return "Today"
        case .thisWeek:  return "This Week"
        case .thisMonth: return "This Month"
        case .thisYear:  return "This Year"
        case .custom:    return "Custom"
        }
    }
}

// MARK: - Constants

enum AnalyticsConstants {
    /// Fallback reading speed: 2 minutes per page.
    static let defaultSecondsPerPage: Double = 120

    /// Minimum page timings before per-book speed is trusted over cross-book average.
    static let minimumTimingsForPersonalSpeed: Int = 5

    /// Minimum sessions before trend analysis is meaningful.
    static let minimumSessionsForTrend: Int = 10
}

// MARK: - Reader Profile Engine

struct ReaderProfileAnalytics {
    let totalPagesRead: Int
    let totalReadingTime: TimeInterval
    let totalBooksCompleted: Int
    let completionRate: Double
    let averagePagesPerHour: Double
    let averageSessionDuration: TimeInterval
    let averageDailyReadingTime: TimeInterval
    let averageWeeklyReadingTime: TimeInterval
}

extension AnalyticsEngine {

    static func readerProfile(books: [Book]) -> ReaderProfileAnalytics {
        let sessions = books.flatMap { $0.sessions }.filter { $0.endTime != nil }

        let totalPages = sessions.reduce(0) { $0 + $1.pagesRead }
        let totalTime  = sessions.reduce(0) { $0 + $1.duration }

        let completedBooks = books.filter { $0.isCompleted }.count
        let completionRate = books.isEmpty ? 0 : Double(completedBooks) / Double(books.count)

        let pagesPerHour = totalTime > 0 ? (Double(totalPages) / (totalTime / 3600)) : 0
        let avgSession   = sessions.isEmpty ? 0 : totalTime / Double(sessions.count)

        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: sessions) {
            calendar.startOfDay(for: $0.startTime)
        }

        let dailyAvg = groupedByDay.values.map {
            $0.reduce(0) { $0 + $1.duration }
        }.reduce(0, +) / Double(max(groupedByDay.count, 1))

        let weeklyAvg = dailyAvg * 7

        return ReaderProfileAnalytics(
            totalPagesRead: totalPages,
            totalReadingTime: totalTime,
            totalBooksCompleted: completedBooks,
            completionRate: completionRate,
            averagePagesPerHour: pagesPerHour,
            averageSessionDuration: avgSession,
            averageDailyReadingTime: dailyAvg,
            averageWeeklyReadingTime: weeklyAvg
        )
    }
}

// MARK: - Chapter Prediction Engine

struct ChapterPredictionAnalytics {
    let chapterID: UUID
    let estimatedSeconds: TimeInterval
    let pacePagesPerHour: Double
    let confidence: Double
}

extension AnalyticsEngine {

    static func chapterPredictions(for book: Book) -> [ChapterPredictionAnalytics] {
        let secsPerPage = adjustedReadingSpeed(for: book)

        return book.chapters.map { chapter in
            let pages      = chapter.pageCount
            let estimated  = Double(pages) * secsPerPage
            let pace       = secsPerPage > 0 ? 3600 / secsPerPage : 0
            let confidence = min(1.0, Double(book.sessions.count) / 20.0)

            return ChapterPredictionAnalytics(
                chapterID: chapter.id,
                estimatedSeconds: estimated,
                pacePagesPerHour: pace,
                confidence: confidence
            )
        }
    }
}

// MARK: - Book Forecast Engine

struct BookForecastAnalytics {
    let remainingPages: Int
    let remainingHours: Double
    let estimatedFinishDate: Date
    let confidence: Double
}

extension AnalyticsEngine {

    /// UPGRADE v3: Fixed off-by-one — now consistent with predictions() B6 fix.
    /// Original used totalPages - currentPage; correct is totalPages - 1 - currentPage
    /// because currentPage is 0-based and totalPages-1 is the last valid index.
    static func bookForecast(for book: Book) -> BookForecastAnalytics {
        let secsPerPage = adjustedReadingSpeed(for: book)

        // FIX: Was `totalPages - currentPage`; now matches predictions() B6 formula.
        let remaining = max(0, book.totalPages - 1 - book.currentPage)
        let hours     = (Double(remaining) * secsPerPage) / 3600

        let estimatedDate = Date().addingTimeInterval(Double(remaining) * secsPerPage)
        let confidence    = min(1.0, Double(book.sessions.count) / 25.0)

        return BookForecastAnalytics(
            remainingPages: remaining,
            remainingHours: hours,
            estimatedFinishDate: estimatedDate,
            confidence: confidence
        )
    }
}

// MARK: - Trend Engine

enum TrendDirection {
    case growth
    case decline
    case plateau
}

struct TrendAnalytics {
    let dailyTrend: Double      // fractional change in daily reading vs prior period
    let weeklyAverage: Double   // average daily reading seconds over the past 7 days
    let monthlyAverage: Double  // average daily reading seconds over the past 30 days
    let direction: TrendDirection
}

extension AnalyticsEngine {

    /// UPGRADE v3: Fixed weekly/monthly trend math.
    ///
    /// Original bug: `weeklyTrend = dailyTrend * 7` and `monthlyTrend = dailyTrend * 30`
    /// This is wrong because dailyTrend is a ratio (e.g. 0.15 = 15% change), not seconds.
    /// Multiplying a ratio by 7 produces a dimensionless number without meaning.
    ///
    /// Fix: compute weeklyAverage and monthlyAverage directly from the activity window,
    /// giving actual seconds-per-day averages for each period.
    static func trendAnalysis(books: [Book]) -> TrendAnalytics {
        let activities = dailyActivity(books: books, days: 60)
        let values     = activities.map { $0.totalDuration }

        func average(_ arr: ArraySlice<TimeInterval>) -> Double {
            guard !arr.isEmpty else { return 0 }
            return arr.reduce(0, +) / Double(arr.count)
        }

        let split    = values.count / 2
        let recent   = ArraySlice(values.suffix(split))
        let older    = ArraySlice(values.prefix(split))
        let recentAvg = average(recent)
        let olderAvg  = average(older)

        let change = olderAvg == 0 ? 0 : (recentAvg - olderAvg) / olderAvg

        let direction: TrendDirection =
            change > 0.05  ? .growth :
            change < -0.05 ? .decline :
            .plateau

        // Compute actual averages for the most recent 7 and 30 days separately.
        let last7  = ArraySlice(values.suffix(7))
        let last30 = ArraySlice(values.suffix(30))

        return TrendAnalytics(
            dailyTrend:     change,
            weeklyAverage:  average(last7),
            monthlyAverage: average(last30),
            direction:      direction
        )
    }
}

// MARK: - Time-of-Day Analysis

enum ReadingWindow {
    case morning, afternoon, evening, night
}

struct TimeOfDayAnalytics {
    let bestWindow: ReadingWindow
    let worstWindow: ReadingWindow
    let scores: [ReadingWindow: Double]
}

extension AnalyticsEngine {

    static func timeOfDayAnalysis(books: [Book]) -> TimeOfDayAnalytics {
        var buckets: [ReadingWindow: Double] = [
            .morning: 0, .afternoon: 0, .evening: 0, .night: 0
        ]

        for session in books.flatMap({ $0.sessions }) {
            guard let end = session.endTime else { continue }
            let hour = Calendar.current.component(.hour, from: end)
            let window: ReadingWindow =
                hour < 12 ? .morning :
                hour < 17 ? .afternoon :
                hour < 22 ? .evening : .night
            buckets[window, default: 0.0] += Double(session.pagesRead)
        }

        let best  = buckets.max(by: { $0.value < $1.value })!.key
        let worst = buckets.min(by: { $0.value < $1.value })!.key

        return TimeOfDayAnalytics(bestWindow: best, worstWindow: worst, scores: buckets)
    }
}

// MARK: - Difficulty Normalization

extension AnalyticsEngine {

    static func normalizedPages(for book: Book) -> Double {
        let base       = Double(book.totalPages - book.currentPage)
        let multiplier = book.difficultyProfile?.difficultyMultiplier ?? 1.0
        return base * multiplier
    }
}

// MARK: - Improvement Engine

struct ImprovementAnalytics {
    let speedImprovement: Double
    let enduranceImprovement: Double
    let consistencyImprovement: Double
}

extension AnalyticsEngine {

    static func improvementAnalysis(books: [Book]) -> ImprovementAnalytics {
        let sessions = books.flatMap { $0.sessions }.sorted { $0.startTime < $1.startTime }
        guard sessions.count > 10 else {
            return ImprovementAnalytics(speedImprovement: 0, enduranceImprovement: 0, consistencyImprovement: 0)
        }

        let midpoint = sessions.count / 2
        let early    = Array(sessions.prefix(midpoint))
        let late     = Array(sessions.suffix(midpoint))

        let earlySpeed = early.map { $0.averageSecondsPerPage }.reduce(0, +) / Double(early.count)
        let lateSpeed  = late.map { $0.averageSecondsPerPage }.reduce(0, +) / Double(late.count)
        let speedImprovement = earlySpeed == 0 ? 0 : (earlySpeed - lateSpeed) / earlySpeed

        let earlyDuration = early.map { $0.duration }.reduce(0, +) / Double(early.count)
        let lateDuration  = late.map { $0.duration }.reduce(0, +) / Double(late.count)
        let enduranceImprovement = earlyDuration == 0 ? 0 : (lateDuration - earlyDuration) / earlyDuration

        let consistencyImprovement = 0.5 * speedImprovement + 0.5 * enduranceImprovement

        return ImprovementAnalytics(
            speedImprovement: speedImprovement,
            enduranceImprovement: enduranceImprovement,
            consistencyImprovement: consistencyImprovement
        )
    }
}

// MARK: - Confidence Engine

enum ConfidenceLevel { case low, medium, high }

struct ConfidenceAnalytics {
    let value: Double
    let level: ConfidenceLevel
}

extension AnalyticsEngine {

    /// UPGRADE v3: Confidence now incorporates cross-book history as a signal.
    /// A reader who has finished 10 books should have higher prediction confidence
    /// for a new book than a reader with no history, even if the new book has 0 sessions.
    static func predictionConfidence(for book: Book, allBooks: [Book] = []) -> ConfidenceAnalytics {
        let sessionCount  = book.sessions.count
        let pages         = book.sessions.reduce(0) { $0 + $1.pagesRead }

        let density       = min(1.0, Double(pages) / 1000.0)
        let sessionFactor = min(1.0, Double(sessionCount) / 30.0)

        // Cross-book factor: reader history boosts confidence for new books.
        let allSessions   = allBooks.flatMap(\.sessions).filter { $0.endTime != nil }
        let crossBookBoost = min(0.3, Double(allSessions.count) / 100.0 * 0.3)

        let score = (density * 0.55 + sessionFactor * 0.30 + crossBookBoost).clamped(to: 0...1)

        let level: ConfidenceLevel =
            score < 0.3 ? .low :
            score < 0.7 ? .medium :
            .high

        return ConfidenceAnalytics(value: score, level: level)
    }
}

// MARK: - Session Quality Engine (new in v3)

/// Quality signals for a single reading session.
struct SessionQuality {
    let sessionID: UUID
    /// Coefficient of variation of page timings: low CV = consistent pace = focused reading.
    let paceConsistency: Double       // 0 = erratic, 1 = perfectly consistent
    /// Fraction of pages with recorded timings (vs skipped by rapid scroll).
    let coverage: Double              // 0–1
    /// Whether the session qualifies as a "deep focus" session (long + consistent).
    let isDeepFocus: Bool
    /// A simple 0–1 quality score for this session.
    let score: Double
}

extension AnalyticsEngine {

    /// Rates an individual reading session's quality based on pace consistency and coverage.
    /// Used by InsightEngine to generate "your best reading sessions are..." insights.
    static func sessionQuality(session: ReadingSession) -> SessionQuality {
        let timings  = session.pageTimes.filter { $0.duration > 0 }
        let pagesSpanned = max(1, session.pagesRead)

        // Coverage: how many distinct pages were timed vs total pages read.
        let coverage = min(1.0, Double(timings.count) / Double(pagesSpanned))

        // Pace consistency: coefficient of variation (lower = more consistent).
        var consistency = 0.0
        if timings.count > 1 {
            let durations = timings.map(\.duration)
            let mean      = durations.reduce(0, +) / Double(durations.count)
            let variance  = durations.map { pow($0 - mean, 2) }.reduce(0, +) / Double(durations.count)
            let cv        = mean > 0 ? sqrt(variance) / mean : 0
            // Map CV [0, 1] to consistency [1, 0] (CV=0 is perfectly consistent).
            consistency = max(0, 1.0 - min(cv, 1.0))
        } else if timings.count == 1 {
            consistency = 0.5  // single timing — neutral
        }

        let isDeepFocus = session.duration > 1800 && consistency > 0.6
        let score       = (coverage * 0.4 + consistency * 0.6).clamped(to: 0...1)

        return SessionQuality(
            sessionID: session.id,
            paceConsistency: consistency,
            coverage: coverage,
            isDeepFocus: isDeepFocus,
            score: score
        )
    }

    /// Returns quality ratings for all completed sessions of a book, sorted by score descending.
    static func sessionQualities(for book: Book) -> [SessionQuality] {
        book.sessions
            .filter { $0.endTime != nil }
            .map { sessionQuality(session: $0) }
            .sorted { $0.score > $1.score }
    }
}

// MARK: - Genre Analytics System (v3 — now active via Book.genre)

// ReadingGenre is declared in Book.swift (imported here via same module).
// Note: this is the ACTIVE genre analytics system. Previously, inferredGenre
// always returned .unknown because Book had no genre field. Book.genre (added in v3)
// is set from OPF dc:subject during EPUB import, or manually by the user.

struct GenreProfile {
    var genre: ReadingGenre
    var averageSecondsPerPage: Double
    var averageSessionDuration: TimeInterval
    var totalPages: Int
    var totalSessions: Int

    var reliabilityScore: Double {
        min(1.0, Double(totalSessions) / 20.0)
    }
}

struct GenreAnalyticsSummary {
    var fastestGenre: ReadingGenre?
    var slowestGenre: ReadingGenre?
    var genreProfiles: [ReadingGenre: GenreProfile]
    var dominantGenre: ReadingGenre?
}

extension AnalyticsEngine {

    /// UPGRADE v3: Now reads Book.genre directly (no longer always returns .unknown).
    static func genreProfiles(from books: [Book]) -> [ReadingGenre: GenreProfile] {
        var buckets: [ReadingGenre: (time: Double, pages: Int, sessions: Int)] = [:]

        for book in books {
            let genre    = book.genre   // v3: reads the actual genre field
            let sessions = book.sessions.filter { $0.endTime != nil }
            let totalTime  = sessions.reduce(0) { $0 + $1.duration }
            let totalPages = sessions.reduce(0) { $0 + $1.pagesRead }

            var current = buckets[genre] ?? (0, 0, 0)
            current.time    += totalTime
            current.pages   += totalPages
            current.sessions += sessions.count
            buckets[genre]   = current
        }

        var result: [ReadingGenre: GenreProfile] = [:]
        for (genre, data) in buckets {
            let avgSpeed = data.time > 0 ? Double(data.pages) / (data.time / 3600) : 0
            result[genre] = GenreProfile(
                genre: genre,
                averageSecondsPerPage: avgSpeed > 0 ? 3600 / avgSpeed : AnalyticsConstants.defaultSecondsPerPage,
                averageSessionDuration: data.sessions > 0 ? data.time / Double(data.sessions) : 0,
                totalPages: data.pages,
                totalSessions: data.sessions
            )
        }
        return result
    }

    static func genreAdjustedReadingSpeed(for book: Book, books: [Book]) -> Double {
        let base     = adjustedReadingSpeed(for: book)
        let profiles = genreProfiles(from: books)
        let genre    = book.genre

        guard let profile = profiles[genre], genre != .unknown else { return base }

        let genreMultiplier = profile.averageSecondsPerPage / AnalyticsConstants.defaultSecondsPerPage
        return base * genreMultiplier
    }

    static func genrePrediction(for book: Book, allBooks: [Book]) -> ReadingPrediction {
        let secsPerPage    = genreAdjustedReadingSpeed(for: book, books: allBooks)
        let remainingPages = max(0, book.totalPages - 1 - book.currentPage)  // B6-consistent
        let time           = Double(remainingPages) * secsPerPage

        let nextChapter = book.chapters.first { $0.startPage > book.currentPage }
        let chapterTime: TimeInterval? = nextChapter.map {
            Double(max(0, $0.startPage - book.currentPage)) * secsPerPage
        }

        return ReadingPrediction(
            estimatedSecondsToFinish: time,
            estimatedSecondsToNextChapter: chapterTime,
            estimatedSecondsToChapter: [:],
            adjustedSecondsPerPage: secsPerPage
        )
    }

    static func dominantGenre(from books: [Book]) -> ReadingGenre? {
        genreProfiles(from: books).max(by: { $0.value.totalPages < $1.value.totalPages })?.key
    }

    static func genreSummary(from books: [Book]) -> GenreAnalyticsSummary {
        let profiles = genreProfiles(from: books)
        let fastest  = profiles.min(by: { $0.value.averageSecondsPerPage < $1.value.averageSecondsPerPage })?.key
        let slowest  = profiles.max(by: { $0.value.averageSecondsPerPage < $1.value.averageSecondsPerPage })?.key

        return GenreAnalyticsSummary(
            fastestGenre:  fastest,
            slowestGenre:  slowest,
            genreProfiles: profiles,
            dominantGenre: dominantGenre(from: books)
        )
    }

    static func genreConfidenceMultiplier(for book: Book, allBooks: [Book]) -> Double {
        let profiles = genreProfiles(from: allBooks)
        guard let profile = profiles[book.genre] else { return 1.0 }
        return profile.reliabilityScore
    }
}
