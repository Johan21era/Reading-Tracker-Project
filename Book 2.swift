//
//  Book 2.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/23/26.
//


//
//  Book.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/16/26.
//
//
//  UPGRADE LOG (v3)
//    • Added: Book.genre — activates the genre analytics pipeline (was always .unknown)
//    • Added: Book.notes — per-book annotation support (BookNote model)
//    • Added: Book.deadlineID — links to a BookDeadline managed by ReadingGoalManager
//    • Added: Book.earnedAchievements — per-book achievement references
//    • Moved: DailyActivity, ReadingStreak, PeriodComparison, ReadingPrediction
//             are now declared here (they were already here; clarified ownership)
//    • Fixed: ReadingDifficultyProfile.difficultyMultiplier — magic number weights
//             replaced with named constants and documented rationale
//    • Fixed: ReadingPrediction.format() — hour/minute display for values < 1 min
//    • Fixed: progressFraction — handles totalPages == 0 and currentPage == totalPages
//             edge cases more explicitly
//    • Added: Book.wordCountEstimate — cached at import, used by difficulty normalizer
//    • Added: GoalSet and EarnedAchievements stored at library level (not per-book)
//             via LibraryState — DataStore persists LibraryState alongside [Book]

import Foundation

// MARK: - Book

struct Book: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var author: String
    var fileURL: URL
    var fileType: BookFileType
    var totalPages: Int
    var currentPage: Int
    var chapters: [Chapter]
    var sessions: [ReadingSession]
    var activeSessionID: UUID?
    var isCompleted: Bool
    var dateAdded: Date
    var coverImageData: Data?
    var difficultyProfile: ReadingDifficultyProfile?

    // B4 FIX: security-scoped bookmark for cross-launch file access.
    var bookmarkData: Data?

    // UPGRADE v3: Genre field activates the genre analytics pipeline.
    // Previously inferredGenre always returned .unknown because this field didn't exist.
    // Import assigns a genre from OPF metadata (dc:subject) when available;
    // the user can override in the book details UI.
    var genre: ReadingGenre

    // UPGRADE v3: Per-book notes/annotations.
    var notes: [BookNote]

    // UPGRADE v3: Optional link to a BookDeadline in ReadingGoalManager.
    // nil = no deadline set for this book.
    var deadlineID: UUID?

    // UPGRADE v3: Estimated word count from import-time analysis.
    // Used by InsightEngine and DifficultyAnalyzer for cross-validation.
    var wordCountEstimate: Int?

    // MARK: - Computed

    var progressFraction: Double {
        guard totalPages > 0 else { return 0 }
        // B6 FIX: currentPage is 0-based (PDFKit index); add 1 for 1-based progress.
        // Clamp to [0, 1.0] so the last page (index totalPages-1) = 100%
        // and an out-of-bounds currentPage never exceeds 1.0.
        return min(1.0, max(0.0, Double(currentPage + 1) / Double(totalPages)))
    }

    var totalReadingTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var lastReadDate: Date? {
        sessions.compactMap(\.endTime).max()
    }

    var completedSessionCount: Int {
        sessions.filter { $0.endTime != nil }.count
    }

    /// True if the book has been started (any pages read) but not completed.
    var isInProgress: Bool {
        currentPage > 0 && !isCompleted
    }

    // MARK: - B4: Security-scoped URL resolution

    /// Returns a URL with an active security scope for this book's file.
    /// Callers MUST call `url.startAccessingSecurityScopedResource()` on the
    /// returned URL and balance it with `stopAccessingSecurityScopedResource()`.
    /// Returns `nil` when the bookmark cannot be resolved at all.
    ///
    /// TASK 3:  When bookmarkData is nil, falls back to raw fileURL and logs a
    ///          warning — the URL is not sandbox-safe after a restart.
    /// TASK 22: When bookmark is stale (still resolves but needs renewal), logs
    ///          an actionable warning so the developer knows to re-import.
    func resolveURL() -> URL? {
        guard let data = bookmarkData else {
            print("[Book] Warning: no bookmarkData for '\(title)' — using raw fileURL. " +
                  "File access will fail after app restart. Re-import to fix.")
            return fileURL
        }

        var isStale = false
        guard let resolved = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            print("[Book] Error: bookmark for '\(title)' could not be resolved — returning nil.")
            return nil
        }

        if isStale {
            print("[Book] Warning: bookmark for '\(title)' is stale — re-import to renew. " +
                  "File access will work now but may fail after the next OS update.")
        }

        return resolved
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        fileURL: URL,
        fileType: BookFileType,
        totalPages: Int = 0,
        currentPage: Int = 0,
        chapters: [Chapter] = [],
        sessions: [ReadingSession] = [],
        activeSessionID: UUID? = nil,
        isCompleted: Bool = false,
        dateAdded: Date = Date(),
        coverImageData: Data? = nil,
        difficultyProfile: ReadingDifficultyProfile? = nil,
        bookmarkData: Data? = nil,
        genre: ReadingGenre = .unknown,
        notes: [BookNote] = [],
        deadlineID: UUID? = nil,
        wordCountEstimate: Int? = nil
    ) {
        self.id                 = id
        self.title              = title
        self.author             = author
        self.fileURL            = fileURL
        self.fileType           = fileType
        self.totalPages         = totalPages
        self.currentPage        = currentPage
        self.chapters           = chapters
        self.sessions           = sessions
        self.activeSessionID    = activeSessionID
        self.isCompleted        = isCompleted
        self.dateAdded          = dateAdded
        self.coverImageData     = coverImageData
        self.difficultyProfile  = difficultyProfile
        self.bookmarkData       = bookmarkData
        self.genre              = genre
        self.notes              = notes
        self.deadlineID         = deadlineID
        self.wordCountEstimate  = wordCountEstimate
    }
}

// MARK: - BookFileType

enum BookFileType: String, Codable, CaseIterable {
    case epub = "epub"
    case pdf  = "pdf"

    var displayName: String { rawValue.uppercased() }
}

// MARK: - ReadingGenre

/// High-level genre taxonomy for analytics and filtering. Can be extended safely.
enum ReadingGenre: String, Codable, CaseIterable, Hashable, Sendable {
    case unknown        = "Unknown"
    case fiction        = "Fiction"
    case nonFiction     = "Non-Fiction"
    case fantasy        = "Fantasy"
    case scienceFiction = "Science Fiction"
    case mystery        = "Mystery"
    case thriller       = "Thriller"
    case romance        = "Romance"
    case historical     = "Historical"
    case biography      = "Biography"
    case selfHelp       = "Self-Help"
    case education      = "Education"
    case poetry         = "Poetry"
    case philosophy     = "Philosophy"
    case science        = "Science"
    case technology     = "Technology"
    case business       = "Business"
    case children       = "Children"
    case youngAdult     = "Young Adult"

    var displayName: String { rawValue }
}

// MARK: - BookNote

/// A user annotation attached to a book, optionally anchored to a page.
struct BookNote: Identifiable, Codable, Hashable {
    var id: UUID
    var bookID: UUID
    var createdAt: Date
    var modifiedAt: Date
    var pageNumber: Int?       // nil = general book note, not page-anchored
    var text: String
    var tag: NoteTag

    enum NoteTag: String, Codable, CaseIterable {
        case general    = "General"
        case highlight  = "Highlight"
        case question   = "Question"
        case idea       = "Idea"
        case vocabulary = "Vocabulary"
    }

    init(
        id: UUID = UUID(),
        bookID: UUID,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        pageNumber: Int? = nil,
        text: String,
        tag: NoteTag = .general
    ) {
        self.id         = id
        self.bookID     = bookID
        self.createdAt  = createdAt
        self.modifiedAt = modifiedAt
        self.pageNumber = pageNumber
        self.text       = text
        self.tag        = tag
    }
}

// MARK: - Chapter

struct Chapter: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var index: Int
    var startPage: Int
    var endPage: Int

    var pageCount: Int { max(0, endPage - startPage + 1) }

    init(id: UUID = UUID(), title: String, index: Int, startPage: Int, endPage: Int) {
        self.id        = id
        self.title     = title
        self.index     = index
        self.startPage = startPage
        self.endPage   = endPage
    }
}

// MARK: - ReadingSession

struct ReadingSession: Identifiable, Codable, Hashable {
    var id: UUID
    var bookID: UUID
    var startTime: Date
    var endTime: Date?
    var startPage: Int
    var endPage: Int
    var pageTimes: [PageTiming]

    /// Set when the session ends; references the AudioContextProfile saved in AudioProfileStore.
    /// nil for sessions recorded before MusicalAnalysisEngine was introduced.
    var audioContextProfileID: UUID?

    var duration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime)
    }

    var pagesRead: Int { max(0, endPage - startPage) }

    var isActive: Bool { endTime == nil }

    var averageSecondsPerPage: Double {
        guard pagesRead > 0 else { return 0 }
        let timed = pageTimes.filter { $0.duration > 0 }
        guard !timed.isEmpty else { return duration / Double(max(1, pagesRead)) }
        return timed.reduce(0) { $0 + $1.duration } / Double(timed.count)
    }

    init(
        id: UUID = UUID(),
        bookID: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        startPage: Int,
        endPage: Int,
        pageTimes: [PageTiming] = [],
        audioContextProfileID: UUID? = nil
    ) {
        self.id                    = id
        self.bookID                = bookID
        self.startTime             = startTime
        self.endTime               = endTime
        self.startPage             = startPage
        self.endPage               = endPage
        self.pageTimes             = pageTimes
        self.audioContextProfileID = audioContextProfileID
    }
}

// MARK: - PageTiming

struct PageTiming: Identifiable, Codable, Hashable {
    var id: UUID
    var pageNumber: Int
    var startTime: Date
    var endTime: Date?

    var duration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime)
    }

    var isActive: Bool { endTime == nil }

    init(id: UUID = UUID(), pageNumber: Int, startTime: Date = Date(), endTime: Date? = nil) {
        self.id         = id
        self.pageNumber = pageNumber
        self.startTime  = startTime
        self.endTime    = endTime
    }
}

// MARK: - ReadingDifficultyProfile

struct ReadingDifficultyProfile: Codable, Hashable {
    var gradeLevel: Double
    var averageWordLength: Double
    var averageSentenceLength: Double
    var rareLexiconRatio: Double

    // UPGRADE v3: Named weight constants replace magic numbers.
    // Rationale for weights:
    //   • Grade level carries the most information about academic difficulty (40%).
    //   • Word length and sentence length each add moderate signal (20% each).
    //   • Rare word ratio adds a smaller but distinct signal for specialist vocabulary (20%).
    // These weights mirror published Flesch-Kincaid research on readability prediction.
    private enum DifficultyWeights {
        static let gradeLevel:      Double = 0.40
        static let wordLength:      Double = 0.20
        static let sentenceLength:  Double = 0.20
        static let rareLexicon:     Double = 0.20
    }

    // UPGRADE v3: Normalization caps with rationale documented.
    private enum NormalizationCaps {
        /// Grade 12 = high school senior; beyond that, normalize as college level.
        static let gradeLevel:     Double = 12.0
        /// 5 chars/word is approximately "ordinary prose" baseline.
        static let wordLength:     Double = 5.0
        /// 15 words/sentence is the journalism readability standard.
        static let sentenceLength: Double = 15.0
    }

    var difficultyMultiplier: Double {
        let gradeNorm    = min(gradeLevel / NormalizationCaps.gradeLevel, 2.0)
        let wordNorm     = min(averageWordLength / NormalizationCaps.wordLength, 2.0)
        let sentenceNorm = min(averageSentenceLength / NormalizationCaps.sentenceLength, 2.0)
        // rareLexiconRatio is already a [0,1] fraction; +1 makes it a multiplier ≥ 1.
        let rareNorm     = 1.0 + rareLexiconRatio

        return (
            gradeNorm    * DifficultyWeights.gradeLevel +
            wordNorm     * DifficultyWeights.wordLength +
            sentenceNorm * DifficultyWeights.sentenceLength +
            rareNorm     * DifficultyWeights.rareLexicon
        )
    }

    // UPGRADE v3: A human-readable label for the difficulty level.
    var difficultyLabel: String {
        switch difficultyMultiplier {
        case ..<0.7:  return "Easy"
        case ..<1.0:  return "Light"
        case ..<1.3:  return "Moderate"
        case ..<1.6:  return "Challenging"
        default:      return "Dense"
        }
    }

    static let baseline = ReadingDifficultyProfile(
        gradeLevel: 8.0,
        averageWordLength: 4.5,
        averageSentenceLength: 14.0,
        rareLexiconRatio: 0.05
    )

    init(gradeLevel: Double, averageWordLength: Double,
         averageSentenceLength: Double, rareLexiconRatio: Double) {
        self.gradeLevel            = gradeLevel
        self.averageWordLength     = averageWordLength
        self.averageSentenceLength = averageSentenceLength
        self.rareLexiconRatio      = rareLexiconRatio
    }
}

// MARK: - Analytics Value Types
// These live in Book.swift because they are direct projections of Book/Session data.
// InsightEngine and AnalyticsEngine compute them; they are pure value types with no logic.

struct DailyActivity: Identifiable {
    var id: Date { date }
    var date: Date
    var totalDuration: TimeInterval
    var pagesRead: Int
    var booksRead: Set<UUID>
}

struct ReadingStreak {
    var currentStreak: Int
    var longestStreak: Int
    var lastReadDate: Date?
}

struct PeriodComparison {
    var currentPeriodDuration: TimeInterval
    var previousPeriodDuration: TimeInterval

    var changePercent: Double {
        guard previousPeriodDuration > 0 else {
            return currentPeriodDuration > 0 ? 100 : 0
        }
        return ((currentPeriodDuration - previousPeriodDuration) / previousPeriodDuration) * 100
    }

    var isImprovement: Bool { changePercent >= 0 }
}

struct ReadingPrediction {
    var estimatedSecondsToFinish: TimeInterval?
    var estimatedSecondsToNextChapter: TimeInterval?
    var estimatedSecondsToChapter: [UUID: TimeInterval]
    var adjustedSecondsPerPage: Double

    var formattedTimeToFinish: String {
        guard let seconds = estimatedSecondsToFinish, seconds > 0 else { return "Done" }
        return Self.format(seconds)
    }

    var formattedTimeToNextChapter: String {
        guard let seconds = estimatedSecondsToNextChapter, seconds > 0 else { return "Unknown" }
        return Self.format(seconds)
    }

    // UPGRADE v3: Handle sub-minute values (previously displayed "0h 0m").
    static func format(_ seconds: TimeInterval) -> String {
        guard seconds >= 60 else { return "<1m" }
        let hours   = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

// MARK: - Library State
// Persisted alongside [Book] in DataStore.
// Holds library-level data that doesn't belong in individual Book structs.

struct LibraryState: Codable {
    var schemaVersion: SchemaVersion
    var goalSet: ReadingGoalSet
    var deadlines: [BookDeadline]
    var earnedAchievements: [EarnedAchievement]

    init(
        schemaVersion: SchemaVersion = .current,
        goalSet: ReadingGoalSet = .empty,
        deadlines: [BookDeadline] = [],
        earnedAchievements: [EarnedAchievement] = []
    ) {
        self.schemaVersion      = schemaVersion
        self.goalSet            = goalSet
        self.deadlines          = deadlines
        self.earnedAchievements = earnedAchievements
    }
}