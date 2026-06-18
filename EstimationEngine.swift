//
//  EstimationEngine.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/17/26.
//


//
//  EstimationEngine.swift
//  Reading Tracker
//
//  Stateless deterministic prediction layer built on AnalyticsEngine
//

import Foundation

// MARK: - ReadingContext

/// Optional runtime context used to adjust predictions for non-linear reading behavior.
/// This does NOT persist state and is purely input-driven.
struct ReadingContext {
    var currentPage: Int?
    var selectedChapterID: UUID?
    var isTableOfContentsMode: Bool
    var timeOfDay: Date?
    var dayOfWeek: Int? // 1...7 (Calendar weekday)
}

// MARK: - Speed Components

private struct SpeedComponents {
    let base: Double?
    let genre: Double?
    let trend: Double?
    let crossBook: Double?
}

// MARK: - Speed Model

struct SpeedModel {
    let baseSpeed: Double
    let genreAdjustedSpeed: Double
    let trendAdjustedSpeed: Double
    let crossBookSpeed: Double
    let effectiveSpeed: Double
    let volatility: Double
}

// MARK: - Confidence Model

struct ConfidenceModel {
    let score: Double
    let level: ConfidenceLevel
}

// MARK: - Chapter Estimation

struct ChapterEstimation {
    let chapterID: UUID
    let estimatedSeconds: TimeInterval
    let estimatedFormatted: String
    let pages: Int
    let completionDate: Date
}

// MARK: - Book Estimation Result

struct BookEstimationResult {
    let remainingSeconds: TimeInterval
    let remainingHours: Double
    let formattedRemaining: String

    let estimatedCompletionDate: Date
    let estimatedDaysRemaining: Int

    let expectedSessionDuration: TimeInterval
    let expectedPagesPerSession: Double

    let probabilityFinishChapterInOneSession: Double

    let speedModel: SpeedModel
    let confidence: ConfidenceModel

    let chapterEstimates: [ChapterEstimation]
}

// MARK: - EstimationEngine

struct EstimationEngine {

    // MARK: Public API

    static func estimate(for book: Book, allBooks: [Book]) -> BookEstimationResult {
        let context = buildContext(book: book)

        let baseSpeed = AnalyticsEngine.adjustedReadingSpeed(for: book)

        let genreSpeed = AnalyticsEngine.genreAdjustedReadingSpeed(
            for: book,
            books: allBooks
        )

        let trend = AnalyticsEngine.trendAnalysis(books: allBooks)
        let trendMultiplier = trendMultiplier(from: trend)

        let crossSpeed = AnalyticsEngine.crossBookReadingSpeed(allBooks: allBooks)

        let speedModel = buildSpeedModel(
            base: baseSpeed,
            genre: genreSpeed,
            trendMultiplier: trendMultiplier,
            cross: crossSpeed
        )

        let effectiveSpeed = speedModel.effectiveSpeed

        let remainingPages = max(0, book.totalPages - 1 - book.currentPage)

        let remainingSeconds = Double(remainingPages) * effectiveSpeed
        let remainingHours = remainingSeconds / 3600.0

        let completionDate = Date().addingTimeInterval(remainingSeconds)

        let daysRemaining = max(
            0,
            Calendar.current.dateComponents([.day], from: Date(), to: completionDate).day ?? 0
        )

        let chapterEstimates = estimateChapters(
            book: book,
            speed: effectiveSpeed
        )

        let confidence = AnalyticsEngine.predictionConfidence(for: book, allBooks: allBooks)

        let confidenceModel = ConfidenceModel(
            score: confidence.value,
            level: confidence.level
        )

        return BookEstimationResult(
            remainingSeconds: remainingSeconds,
            remainingHours: remainingHours,
            formattedRemaining: formatTime(remainingSeconds),

            estimatedCompletionDate: completionDate,
            estimatedDaysRemaining: daysRemaining,

            expectedSessionDuration: estimateSessionDuration(book: book, speed: effectiveSpeed),
            expectedPagesPerSession: estimatePagesPerSession(book: book, speed: effectiveSpeed),

            probabilityFinishChapterInOneSession: estimateChapterCompletionProbability(book: book, speed: effectiveSpeed),

            speedModel: speedModel,
            confidence: confidenceModel,

            chapterEstimates: chapterEstimates
        )
    }

    // MARK: Context

    private static func buildContext(book: Book) -> ReadingContext {
        ReadingContext(
            currentPage: book.currentPage,
            selectedChapterID: nil,
            isTableOfContentsMode: false,
            timeOfDay: Date(),
            dayOfWeek: Calendar.current.component(.weekday, from: Date())
        )
    }

    // MARK: Speed Model Builder

    private static func buildSpeedModel(
        base: Double,
        genre: Double,
        trendMultiplier: Double,
        cross: Double
    ) -> SpeedModel {

        // Normalize speeds into weights
        let components: SpeedComponents = SpeedComponents(
            base: base,
            genre: genre,
            trend: cross * trendMultiplier,
            crossBook: cross
        )

        let values = [
            components.base,
            components.genre,
            components.trend,
            components.crossBook
        ].compactMap { $0 }

        let weightBase: Double = 0.40
        let weightGenre: Double = 0.25
        let weightTrend: Double = 0.20
        let weightCross: Double = 0.15

        let totalWeight = Double(values.count)

        let adjustedBase  = components.base ?? cross
        let adjustedGenre = components.genre ?? adjustedBase
        let adjustedTrend = components.trend ?? adjustedBase
        let adjustedCross = components.crossBook ?? adjustedBase

        let effective =
            adjustedBase  * weightBase +
            adjustedGenre * weightGenre +
            adjustedTrend * weightTrend +
            adjustedCross * weightCross

        let volatility = computeVolatility(base: base, cross: cross)

        return SpeedModel(
            baseSpeed: base,
            genreAdjustedSpeed: genre,
            trendAdjustedSpeed: base * trendMultiplier,
            crossBookSpeed: cross,
            effectiveSpeed: effective,
            volatility: volatility
        )
    }

    // MARK: Trend

    private static func trendMultiplier(from trend: TrendAnalytics) -> Double {
        let raw = 1.0 + trend.dailyTrend
        return min(1.15, max(0.85, raw))
    }

    // MARK: Chapter Estimation (Part 2 continues this)

    private static func estimateChapters(book: Book, speed: Double) -> [ChapterEstimation] {
        book.chapters.map { chapter in
            let seconds = Double(chapter.pageCount) * speed
            let date = Date().addingTimeInterval(seconds)

            return ChapterEstimation(
                chapterID: chapter.id,
                estimatedSeconds: seconds,
                estimatedFormatted: formatTime(seconds),
                pages: chapter.pageCount,
                completionDate: date
            )
        }
    }

    // MARK: Session Estimation Helpers

    private static func estimateSessionDuration(book: Book, speed: Double) -> TimeInterval {
        let avgPages = max(1, book.totalPages / max(1, book.sessions.count + 1))
        return Double(avgPages) * speed
    }

    private static func estimatePagesPerSession(book: Book, speed: Double) -> Double {
        let avgSessionTime = book.sessions.map { $0.duration }.reduce(0, +) /
            Double(max(1, book.sessions.count))

        return avgSessionTime / max(speed, 1)
    }

    private static func estimateChapterCompletionProbability(book: Book, speed: Double) -> Double {
        let avgPages = Double(book.totalPages) / Double(max(1, book.chapters.count))
        let sessionCapacity = estimatePagesPerSession(book: book, speed: speed)

        let ratio = sessionCapacity / max(avgPages, 1)

        return min(1.0, max(0.0, ratio))
    }

    // MARK: Volatility

    private static func computeVolatility(base: Double, cross: Double) -> Double {
        let diff = abs(base - cross) / max(base, 1)
        return min(1.5, max(0.7, 1.0 + diff))
    }

    // MARK: Formatting

    private static func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds >= 60 else { return "<1m" }

        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
// MARK: - PART 2: CONTEXT + PAGE + CHAPTER REFINEMENTS

extension EstimationEngine {

    // MARK: - Public Chapter APIs

    static func estimateAllChapters(for book: Book, allBooks: [Book]) -> [ChapterEstimation] {
        let baseSpeed = resolveEffectiveSpeed(book: book, allBooks: allBooks)

        return book.chapters.map { chapter in
            let adjusted = applyPositionalAdjustment(
                chapterIndex: chapter.index,
                total: book.chapters.count,
                baseSpeed: baseSpeed
            )

            let seconds = Double(chapter.pageCount) * adjusted
            let date = Date().addingTimeInterval(seconds)

            return ChapterEstimation(
                chapterID: chapter.id,
                estimatedSeconds: seconds,
                estimatedFormatted: formatTime(seconds),
                pages: chapter.pageCount,
                completionDate: date
            )
        }
    }

    static func estimateChapter(
        for book: Book,
        chapterID: UUID,
        allBooks: [Book]
    ) -> ChapterEstimation? {

        guard let chapter = book.chapters.first(where: { $0.id == chapterID }) else {
            return nil
        }

        let baseSpeed = resolveEffectiveSpeed(book: book, allBooks: allBooks)

        let adjusted = applyPositionalAdjustment(
            chapterIndex: chapter.index,
            total: book.chapters.count,
            baseSpeed: baseSpeed
        )

        let seconds = Double(chapter.pageCount) * adjusted
        let date = Date().addingTimeInterval(seconds)

        return ChapterEstimation(
            chapterID: chapter.id,
            estimatedSeconds: seconds,
            estimatedFormatted: formatTime(seconds),
            pages: chapter.pageCount,
            completionDate: date
        )
    }

    // MARK: - Page-Level Estimation

    static func estimatePageTime(
        for book: Book,
        page: Int,
        context: ReadingContext?,
        allBooks: [Book]
    ) -> TimeInterval {

        let baseSpeed = resolveEffectiveSpeed(book: book, allBooks: allBooks)

        let volatility = computeVolatility(
            book: book,
            allBooks: allBooks
        )

        let contextMultiplier = contextAdjustment(context: context)

        let finalSpeed = baseSpeed * volatility * contextMultiplier

        return finalSpeed
    }

    // MARK: - Context Adjustment

    private static func contextAdjustment(context: ReadingContext?) -> Double {
        guard let context else { return 1.0 }

        var multiplier: Double = 1.0

        // Time of day adjustment
        if let hour = context.timeOfDay.map({ Calendar.current.component(.hour, from: $0) }) {
            switch hour {
            case 6..<12:  multiplier *= 0.95   // morning faster
            case 12..<17: multiplier *= 1.0
            case 17..<22: multiplier *= 1.05   // evening slightly slower
            default:      multiplier *= 1.1    // night slower
            }
        }

        // Day of week adjustment
        if let day = context.dayOfWeek {
            if day == 1 || day == 7 {
                multiplier *= 0.97 // weekend slight focus boost
            }
        }

        // Table of contents mode (non-linear reading)
        if context.isTableOfContentsMode {
            multiplier *= 1.08
        }

        return min(1.5, max(0.7, multiplier))
    }

    // MARK: - Speed Resolution

    private static func resolveEffectiveSpeed(book: Book, allBooks: [Book]) -> Double {

        let base = AnalyticsEngine.adjustedReadingSpeed(for: book)
        let genre = AnalyticsEngine.genreAdjustedReadingSpeed(for: book, books: allBooks)
        let cross = AnalyticsEngine.crossBookReadingSpeed(allBooks: allBooks)

        let trend = AnalyticsEngine.trendAnalysis(books: allBooks)
        let trendMultiplier = trendMultiplier(from: trend)

        let weighted =
            base  * 0.40 +
            genre * 0.25 +
            cross * 0.15 +
            (base * trendMultiplier) * 0.20

        return weighted
    }

    // MARK: - Volatility (context-aware)

    private static func computeVolatility(book: Book, allBooks: [Book]) -> Double {

        let sessions = book.sessions.filter { $0.endTime != nil }
        guard sessions.count >= 2 else { return 1.0 }

        let speeds = sessions.map { $0.averageSecondsPerPage }
        let avg = speeds.reduce(0, +) / Double(speeds.count)

        let variance = speeds
            .map { pow($0 - avg, 2) }
            .reduce(0, +) / Double(speeds.count)

        let stdDev = sqrt(variance)

        let normalized = avg > 0 ? stdDev / avg : 0

        // Cross-book stabilization
        let cross = AnalyticsEngine.crossBookReadingSpeed(allBooks: allBooks)
        let stabilityFactor = cross / max(avg, 1)

        let raw = 1.0 + (normalized * 0.5) + (stabilityFactor * 0.3)

        return min(1.5, max(0.7, raw))
    }

    // MARK: - Chapter Position Adjustment

    private static func applyPositionalAdjustment(
        chapterIndex: Int,
        total: Int,
        baseSpeed: Double
    ) -> Double {

        guard total > 1 else { return baseSpeed }

        let position = Double(chapterIndex) / Double(total - 1)

        // Early chapters slightly faster, later slightly slower
        let adjustment =
            position < 0.3 ? 0.95 :
            position > 0.7 ? 1.05 :
            1.0

        return baseSpeed * adjustment
    }
}
// MARK: - PART 3: CONFIDENCE + FINAL UTILITIES + CLEANUP

extension EstimationEngine {

    // MARK: - Confidence Mapping (deterministic refinement)

    private static func mapConfidence(_ confidence: ConfidenceAnalytics) -> ConfidenceModel {

        let clamped = min(1.0, max(0.0, confidence.value))

        let level: ConfidenceLevel =
            clamped < 0.30 ? .low :
            clamped < 0.70 ? .medium :
            .high

        return ConfidenceModel(
            score: clamped,
            level: level
        )
    }

    // MARK: - Global Safety Clamp

    private static func clamp(_ value: Double, min: Double = 0.7, max: Double = 1.5) -> Double {
        Swift.max(min, Swift.min(max, value))
    }

    // MARK: - Final Speed Normalization Helper

    private static func normalizeSpeed(_ speed: Double, fallback: Double) -> Double {
        guard speed.isFinite && speed > 0 else { return fallback }
        return speed
    }

    // MARK: - Final Validation Layer

    /// Ensures all outputs are deterministic and bounded.
    static func validate(result: BookEstimationResult) -> BookEstimationResult {

        let safeRemaining = max(0, result.remainingSeconds)
        let safeHours = max(0, result.remainingHours)

        let safeSessions = max(0, result.expectedSessionDuration)
        let safePages = max(0, result.expectedPagesPerSession)

        let safeProbability = min(1.0, max(0.0, result.probabilityFinishChapterInOneSession))

        let cleanedChapters = result.chapterEstimates.map {
            ChapterEstimation(
                chapterID: $0.chapterID,
                estimatedSeconds: max(0, $0.estimatedSeconds),
                estimatedFormatted: $0.estimatedFormatted,
                pages: max(0, $0.pages),
                completionDate: $0.completionDate
            )
        }

        return BookEstimationResult(
            remainingSeconds: safeRemaining,
            remainingHours: safeHours,
            formattedRemaining: result.formattedRemaining,

            estimatedCompletionDate: result.estimatedCompletionDate,
            estimatedDaysRemaining: result.estimatedDaysRemaining,

            expectedSessionDuration: safeSessions,
            expectedPagesPerSession: safePages,

            probabilityFinishChapterInOneSession: safeProbability,

            speedModel: result.speedModel,
            confidence: result.confidence,

            chapterEstimates: cleanedChapters
        )
    }

    // MARK: - Debug Snapshot (optional utility)

    static func debugSnapshot(for book: Book, allBooks: [Book]) -> String {

        let result = estimate(for: book, allBooks: allBooks)

        return """
        --- EstimationEngine Snapshot ---
        Book: \(book.title)
        Remaining Hours: \(result.remainingHours)
        Remaining Seconds: \(result.remainingSeconds)
        Finish Date: \(result.estimatedCompletionDate)
        Confidence: \(result.confidence.score) (\(result.confidence.level))
        Speed: \(result.speedModel.effectiveSpeed)s/page
        Volatility: \(result.speedModel.volatility)
        Chapters: \(result.chapterEstimates.count)
        ----------------------------------
        """
    }
}

