//
//  BehaviorContextEngine.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/20/26.
//
import Foundation
import Combine

/// -----------------------------------------------------------------------------
/// MARK: - Behavior Context Engine
/// -----------------------------------------------------------------------------
///
/// BehaviorContextEngine is the contextual reconstruction layer for the reading
/// application.
///
/// Architectural purpose:
///
/// Traditional analytics systems answer:
/// - How much was read?
/// - How fast was reading?
/// - Was a goal completed?
///
/// This engine answers:
/// - What was happening before reading?
/// - What was happening during reading?
/// - What was happening after reading?
/// - Which routines repeatedly lead into reading?
/// - Which environments consistently surround reading?
///
/// The engine intentionally operates above evidence collection systems.
///
/// BehaviorContextAccessKit records observations.
/// BehaviorContextEngine interprets observations.
///
/// The engine aggressively distinguishes meaningful recurring behavior from
/// incidental noise.
///
/// Example:
///
/// Evidence:
/// - Dictionary opened once for 2 seconds.
///
/// Interpretation:
/// - Incidental behavior.
///
/// Evidence:
/// - Notes used daily before reading for 45 days.
///
/// Interpretation:
/// - Stable recurring pre-reading routine.
///
/// The engine never derives context from absence alone.
/// Absence is only meaningful when evaluating disruption of established routines.
///
@MainActor
public final class BehaviorContextEngine: ObservableObject {

    // MARK: Configuration

    public struct Configuration: Sendable, Codable, Hashable {

        public var preReadingWindow: TimeInterval
        public var postReadingWindow: TimeInterval
        public var significanceThreshold: Double

        public init(
            preReadingWindow: TimeInterval = 60 * 60,
            postReadingWindow: TimeInterval = 60 * 60,
            significanceThreshold: Double = 0.35
        ) {
            self.preReadingWindow = preReadingWindow
            self.postReadingWindow = postReadingWindow
            self.significanceThreshold = significanceThreshold
        }
    }

    @Published public private(set) var summary: BehavioralContextSummary?

    public let configuration: Configuration

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    // MARK: Public API

    public func analyze(
        sessions: [ReadingSessionRecord],
        evidence: [BehaviorEvidence],
        weatherRecords: [WeatherContextRecord] = []
    ) -> BehavioralContextSummary {

        let assessments = evidence.map(significanceAssessment)

        let significantEvidence = zip(evidence, assessments)
            .filter { $0.1.isSignificant }
            .map(\.0)

        let routines = detectRoutines(
            sessions: sessions,
            evidence: significantEvidence
        )

        let transitions = buildTransitions(
            sessions: sessions,
            evidence: significantEvidence
        )

        let contexts = reconstructContexts(
            sessions: sessions,
            evidence: significantEvidence,
            weather: weatherRecords
        )

        let profiles = buildProfiles(
            contexts: contexts,
            routines: routines,
            transitions: transitions
        )

        let narratives = buildNarratives(
            profiles: profiles,
            routines: routines,
            transitions: transitions
        )

        let confidence = calculateOverallConfidence(
            sessions: sessions,
            routines: routines,
            transitions: transitions
        )

        let summary = BehavioralContextSummary(
            generatedAt: Date(),
            contextRecords: contexts,
            routines: routines,
            transitions: transitions,
            profiles: profiles,
            narratives: narratives,
            confidence: confidence
        )

        self.summary = summary

        return summary
    }
}

private extension BehaviorContextEngine {

    func significanceAssessment(
        for evidence: BehaviorEvidence
    ) -> SignificanceAssessment {

        let normalizedDuration =
            min(evidence.totalDuration / (60 * 30), 1.0)

        let normalizedFrequency =
            min(Double(evidence.frequency) / 30.0, 1.0)

        let normalizedRecurrence =
            min(Double(evidence.recurrenceCount) / 20.0, 1.0)

        let normalizedConsistency =
            min(max(evidence.consistency, 0), 1)

        let normalizedProximity =
            min(max(evidence.proximityToReading, 0), 1)

        let score =
            (normalizedDuration * 0.25) +
            (normalizedFrequency * 0.20) +
            (normalizedRecurrence * 0.25) +
            (normalizedConsistency * 0.15) +
            (normalizedProximity * 0.15)

        return SignificanceAssessment(
            score: score,
            isSignificant: score >= configuration.significanceThreshold,
            rationale: rationale(for: score)
        )
    }

    func rationale(for score: Double) -> String {
        switch score {
        case 0.80...:
            return "Strong recurring behavior"
        case 0.60..<0.80:
            return "Meaningful contextual signal"
        case 0.35..<0.60:
            return "Moderately relevant activity"
        default:
            return "Likely incidental behavior"
        }
    }
}

private extension BehaviorContextEngine {

    func reconstructContexts(
        sessions: [ReadingSessionRecord],
        evidence: [BehaviorEvidence],
        weather: [WeatherContextRecord]
    ) -> [ReadingContextRecord] {

        sessions.map { session in

            let preWindow = ContextWindow(
                start: session.startDate.addingTimeInterval(
                    -configuration.preReadingWindow
                ),
                end: session.startDate
            )

            let postWindow = ContextWindow(
                start: session.endDate,
                end: session.endDate.addingTimeInterval(
                    configuration.postReadingWindow
                )
            )

            let preEvidence = evidence.filter {
                preWindow.contains($0.timestamp)
            }

            let inEvidence = evidence.filter {
                session.interval.contains($0.timestamp)
            }

            let postEvidence = evidence.filter {
                postWindow.contains($0.timestamp)
            }

            let weatherRecord = weather.min {
                abs($0.timestamp.timeIntervalSince(session.startDate))
                <
                abs($1.timestamp.timeIntervalSince(session.startDate))
            }

            return ReadingContextRecord(
                sessionID: session.id,
                readingDate: session.startDate,
                preReadingContext: buildEnvironment(from: preEvidence),
                inSessionContext: buildEnvironment(from: inEvidence),
                postReadingContext: buildEnvironment(from: postEvidence),
                weatherContext: weatherRecord,
                confidence: contextConfidence(
                    evidenceCount:
                        preEvidence.count +
                        inEvidence.count +
                        postEvidence.count
                )
            )
        }
    }

    func buildEnvironment(
        from evidence: [BehaviorEvidence]
    ) -> BehavioralEnvironment {

        guard !evidence.isEmpty else {
            return BehavioralEnvironment(
                type: .unknown,
                contributingActivities: [],
                confidence: .low
            )
        }

        let categories = evidence.map(\.category)

        let dominant = categories
            .reduce(into: [:]) { $0[$1, default: 0] += 1 }
            .max { $0.value < $1.value }?
            .key

        return BehavioralEnvironment(
            type: environmentType(from: dominant),
            contributingActivities: evidence.map(\.name),
            confidence: confidenceForEvidence(evidence)
        )
    }

    func environmentType(
        from category: BehaviorCategory?
    ) -> BehavioralEnvironmentType {

        switch category {
        case .development:
            return .development
        case .research:
            return .research
        case .gaming:
            return .gaming
        case .learning:
            return .learning
        case .social:
            return .social
        case .entertainment:
            return .entertainment
        case .administrative:
            return .administrative
        case .browsing:
            return .browsing
        case .creative:
            return .creative
        case .productivity:
            return .work
        case .idle:
            return .idle
        case nil:
            return .unknown
        }
    }
}

private extension BehaviorContextEngine {

    func detectRoutines(
        sessions: [ReadingSessionRecord],
        evidence: [BehaviorEvidence]
    ) -> [BehavioralRoutine] {

        let grouped = Dictionary(
            grouping: sessions
        ) { session in
            Calendar.current.component(
                .hour,
                from: session.startDate
            )
        }

        return grouped.map { hour, sessions in

            let confidence = ContextConfidence(
                score: min(
                    Double(sessions.count) / 20.0,
                    1.0
                )
            )

            return BehavioralRoutine(
                title: "\(hour):00 Reading Routine",
                recurrenceCount: sessions.count,
                averageHour: hour,
                dominantEnvironment: dominantEnvironment(
                    sessions: sessions,
                    evidence: evidence
                ),
                confidence: confidence
            )
        }
        .sorted {
            $0.recurrenceCount > $1.recurrenceCount
        }
    }

    func dominantEnvironment(
        sessions: [ReadingSessionRecord],
        evidence: [BehaviorEvidence]
    ) -> BehavioralEnvironmentType {

        var counts: [BehavioralEnvironmentType: Int] = [:]

        for session in sessions {

            let start = session.startDate
                .addingTimeInterval(-configuration.preReadingWindow)

            let related = evidence.filter {
                $0.timestamp >= start &&
                $0.timestamp <= session.startDate
            }

            let environment = buildEnvironment(from: related)

            counts[environment.type, default: 0] += 1
        }

        return counts.max {
            $0.value < $1.value
        }?.key ?? .unknown
    }
}

private extension BehaviorContextEngine {

    func buildTransitions(
        sessions: [ReadingSessionRecord],
        evidence: [BehaviorEvidence]
    ) -> [ContextTransition] {

        var transitions: [ContextTransition] = []

        for session in sessions {

            let pre = evidence.filter {
                $0.timestamp >= session.startDate
                    .addingTimeInterval(-configuration.preReadingWindow)
                &&
                $0.timestamp <= session.startDate
            }

            let post = evidence.filter {
                $0.timestamp >= session.endDate
                &&
                $0.timestamp <= session.endDate
                    .addingTimeInterval(configuration.postReadingWindow)
            }

            let from = buildEnvironment(from: pre).type
            let to = buildEnvironment(from: post).type

            transitions.append(
                ContextTransition(
                    from: from,
                    to: to,
                    occurrenceDate: session.startDate,
                    strength: transitionStrength(
                        from: pre.count,
                        to: post.count
                    )
                )
            )
        }

        return transitions
    }

    func transitionStrength(
        from preCount: Int,
        to postCount: Int
    ) -> Double {

        min(Double(preCount + postCount) / 20.0, 1.0)
    }
}

private extension BehaviorContextEngine {

    func buildProfiles(
        contexts: [ReadingContextRecord],
        routines: [BehavioralRoutine],
        transitions: [ContextTransition]
    ) -> [ContextProfile] {

        var profiles: [ContextProfile] = []

        if let commonPre = contexts
            .map(\.preReadingContext.type)
            .mostCommon {

            profiles.append(
                ContextProfile(
                    kind: .mostCommonPreReadingEnvironment,
                    value: commonPre.rawValue
                )
            )
        }

        if let commonPost = contexts
            .map(\.postReadingContext.type)
            .mostCommon {

            profiles.append(
                ContextProfile(
                    kind: .mostCommonPostReadingEnvironment,
                    value: commonPost.rawValue
                )
            )
        }

        if let routine = routines.first {

            profiles.append(
                ContextProfile(
                    kind: .mostStableRoutine,
                    value: routine.title
                )
            )
        }

        if let transition = transitions.first {

            profiles.append(
                ContextProfile(
                    kind: .mostFrequentTransition,
                    value:
                        "\(transition.from.rawValue) → \(transition.to.rawValue)"
                )
            )
        }

        return profiles
    }
}

private extension BehaviorContextEngine {

    func buildNarratives(
        profiles: [ContextProfile],
        routines: [BehavioralRoutine],
        transitions: [ContextTransition]
    ) -> [ContextNarrative] {

        var narratives: [ContextNarrative] = []

        for profile in profiles {

            switch profile.kind {

            case .mostCommonPreReadingEnvironment:
                narratives.append(
                    ContextNarrative(
                        text:
                            "Reading most often followed \(profile.value.lowercased()) activity."
                    )
                )

            case .mostCommonPostReadingEnvironment:
                narratives.append(
                    ContextNarrative(
                        text:
                            "Reading commonly transitioned into \(profile.value.lowercased()) activity."
                    )
                )

            case .mostStableRoutine:
                narratives.append(
                    ContextNarrative(
                        text:
                            "A stable recurring reading routine was observed."
                    )
                )

            case .mostFrequentTransition:
                narratives.append(
                    ContextNarrative(
                        text:
                            "A recurring behavioral transition frequently surrounded reading sessions."
                    )
                )
            }
        }

        if narratives.isEmpty {
            narratives.append(
                ContextNarrative(
                    text:
                        "Insufficient recurring evidence exists to establish reliable contextual patterns."
                )
            )
        }

        return narratives
    }
}

private extension BehaviorContextEngine {

    func contextConfidence(
        evidenceCount: Int
    ) -> ContextConfidence {

        ContextConfidence(
            score: min(Double(evidenceCount) / 25.0, 1.0)
        )
    }

    func confidenceForEvidence(
        _ evidence: [BehaviorEvidence]
    ) -> ContextConfidence {

        contextConfidence(
            evidenceCount: evidence.count
        )
    }

    func calculateOverallConfidence(
        sessions: [ReadingSessionRecord],
        routines: [BehavioralRoutine],
        transitions: [ContextTransition]
    ) -> ContextConfidence {

        let sessionScore =
            min(Double(sessions.count) / 50.0, 1.0)

        let routineScore =
            min(Double(routines.count) / 10.0, 1.0)

        let transitionScore =
            min(Double(transitions.count) / 25.0, 1.0)

        return ContextConfidence(
            score:
                (sessionScore * 0.4) +
                (routineScore * 0.3) +
                (transitionScore * 0.3)
        )
    }
}

public struct ReadingSessionRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
    }

    public var interval: DateInterval {
        DateInterval(start: startDate, end: endDate)
    }
}

public struct BehaviorEvidence: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let name: String
    public let category: BehaviorCategory
    public let totalDuration: TimeInterval
    public let frequency: Int
    public let recurrenceCount: Int
    public let consistency: Double
    public let proximityToReading: Double

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        name: String,
        category: BehaviorCategory,
        totalDuration: TimeInterval,
        frequency: Int,
        recurrenceCount: Int,
        consistency: Double,
        proximityToReading: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.name = name
        self.category = category
        self.totalDuration = totalDuration
        self.frequency = frequency
        self.recurrenceCount = recurrenceCount
        self.consistency = consistency
        self.proximityToReading = proximityToReading
    }
}

public enum BehaviorCategory: String, Codable, Hashable, Sendable {
    case productivity
    case development
    case research
    case gaming
    case entertainment
    case learning
    case social
    case browsing
    case creative
    case administrative
    case idle
}

public enum BehavioralEnvironmentType: String, Codable, Hashable, CaseIterable, Sendable {
    case work
    case development
    case research
    case gaming
    case entertainment
    case learning
    case social
    case browsing
    case creative
    case administrative
    case idle
    case recovery
    case mixed
    case unknown
}

public struct BehavioralEnvironment: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let type: BehavioralEnvironmentType
    public let contributingActivities: [String]
    public let confidence: ContextConfidence

    public init(
        id: UUID = UUID(),
        type: BehavioralEnvironmentType,
        contributingActivities: [String],
        confidence: ContextConfidence
    ) {
        self.id = id
        self.type = type
        self.contributingActivities = contributingActivities
        self.confidence = confidence
    }
}

public struct ReadingContextRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let sessionID: UUID
    public let readingDate: Date
    public let preReadingContext: BehavioralEnvironment
    public let inSessionContext: BehavioralEnvironment
    public let postReadingContext: BehavioralEnvironment
    public let weatherContext: WeatherContextRecord?
    public let confidence: ContextConfidence

    public init(
        id: UUID = UUID(),
        sessionID: UUID,
        readingDate: Date,
        preReadingContext: BehavioralEnvironment,
        inSessionContext: BehavioralEnvironment,
        postReadingContext: BehavioralEnvironment,
        weatherContext: WeatherContextRecord?,
        confidence: ContextConfidence
    ) {
        self.id = id
        self.sessionID = sessionID
        self.readingDate = readingDate
        self.preReadingContext = preReadingContext
        self.inSessionContext = inSessionContext
        self.postReadingContext = postReadingContext
        self.weatherContext = weatherContext
        self.confidence = confidence
    }
}

public struct WeatherContextRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let descriptor: String

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        descriptor: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.descriptor = descriptor
    }
}

public struct ContextWindow: Codable, Hashable, Sendable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }
}

public struct ContextTransition: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let from: BehavioralEnvironmentType
    public let to: BehavioralEnvironmentType
    public let occurrenceDate: Date
    public let strength: Double

    public init(
        id: UUID = UUID(),
        from: BehavioralEnvironmentType,
        to: BehavioralEnvironmentType,
        occurrenceDate: Date,
        strength: Double
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.occurrenceDate = occurrenceDate
        self.strength = strength
    }
}

public struct BehavioralRoutine: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let recurrenceCount: Int
    public let averageHour: Int
    public let dominantEnvironment: BehavioralEnvironmentType
    public let confidence: ContextConfidence

    public init(
        id: UUID = UUID(),
        title: String,
        recurrenceCount: Int,
        averageHour: Int,
        dominantEnvironment: BehavioralEnvironmentType,
        confidence: ContextConfidence
    ) {
        self.id = id
        self.title = title
        self.recurrenceCount = recurrenceCount
        self.averageHour = averageHour
        self.dominantEnvironment = dominantEnvironment
        self.confidence = confidence
    }
}

public struct SignificanceAssessment: Codable, Hashable, Sendable {
    public let score: Double
    public let isSignificant: Bool
    public let rationale: String

    public init(
        score: Double,
        isSignificant: Bool,
        rationale: String
    ) {
        self.score = score
        self.isSignificant = isSignificant
        self.rationale = rationale
    }
}

public struct ContextConfidence: Codable, Hashable, Sendable {
    public let score: Double

    public init(score: Double) {
        self.score = max(0, min(score, 1))
    }

    public static let low = ContextConfidence(score: 0.25)
    public static let medium = ContextConfidence(score: 0.50)
    public static let high = ContextConfidence(score: 0.85)
}

public struct ContextNarrative: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let text: String

    public init(
        id: UUID = UUID(),
        text: String
    ) {
        self.id = id
        self.text = text
    }
}

public struct ContextProfile: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let kind: ContextProfileKind
    public let value: String

    public init(
        id: UUID = UUID(),
        kind: ContextProfileKind,
        value: String
    ) {
        self.id = id
        self.kind = kind
        self.value = value
    }
}

public enum ContextProfileKind: String, Codable, Hashable, Sendable {
    case mostCommonPreReadingEnvironment
    case mostCommonPostReadingEnvironment
    case mostStableRoutine
    case mostFrequentTransition
}

public struct ContextSequence: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let sequence: [BehavioralEnvironmentType]
    public let recurrenceCount: Int
    public let strength: Double

    public init(
        id: UUID = UUID(),
        sequence: [BehavioralEnvironmentType],
        recurrenceCount: Int,
        strength: Double
    ) {
        self.id = id
        self.sequence = sequence
        self.recurrenceCount = recurrenceCount
        self.strength = strength
    }
}

public struct HistoricalBehaviorPattern: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let confidence: ContextConfidence

    public init(
        id: UUID = UUID(),
        title: String,
        confidence: ContextConfidence
    ) {
        self.id = id
        self.title = title
        self.confidence = confidence
    }
}

public struct ContextTimeline: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let records: [ReadingContextRecord]

    public init(
        id: UUID = UUID(),
        records: [ReadingContextRecord]
    ) {
        self.id = id
        self.records = records
    }
}

public struct BehavioralCorrelation: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let description: String
    public let strength: Double

    public init(
        id: UUID = UUID(),
        description: String,
        strength: Double
    ) {
        self.id = id
        self.description = description
        self.strength = strength
    }
}

public struct ReadingEnvironmentAnalysis: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let environment: BehavioralEnvironmentType
    public let confidence: ContextConfidence

    public init(
        id: UUID = UUID(),
        environment: BehavioralEnvironmentType,
        confidence: ContextConfidence
    ) {
        self.id = id
        self.environment = environment
        self.confidence = confidence
    }
}

public struct BehavioralContextSummary: Codable, Hashable, Sendable {
    public let generatedAt: Date
    public let contextRecords: [ReadingContextRecord]
    public let routines: [BehavioralRoutine]
    public let transitions: [ContextTransition]
    public let profiles: [ContextProfile]
    public let narratives: [ContextNarrative]
    public let confidence: ContextConfidence

    public init(
        generatedAt: Date,
        contextRecords: [ReadingContextRecord],
        routines: [BehavioralRoutine],
        transitions: [ContextTransition],
        profiles: [ContextProfile],
        narratives: [ContextNarrative],
        confidence: ContextConfidence
    ) {
        self.generatedAt = generatedAt
        self.contextRecords = contextRecords
        self.routines = routines
        self.transitions = transitions
        self.profiles = profiles
        self.narratives = narratives
        self.confidence = confidence
    }
}

private extension Sequence where Element: Hashable {

    var mostCommon: Element? {

        let counts = reduce(into: [:]) {
            $0[$1, default: 0] += 1
        }

        return counts.max {
            $0.value < $1.value
        }?.key
    }
}
// MARK: - Advanced Behavioral Sequence Analysis

/// A recurring contextual pathway observed around reading behavior.
///
/// Unlike simple transitions, sequences represent recurring chains of
/// environments that repeatedly appear throughout a user's behavioral history.
///
/// Example:
///
/// Development → Research → Reading
///
/// If this pattern occurs repeatedly across weeks or months it becomes
/// a meaningful behavioral sequence rather than an isolated transition.
public struct BehavioralSequencePattern:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID
    public let environments: [BehavioralEnvironmentType]
    public let recurrenceCount: Int
    public let averageIntervalMinutes: Double
    public let consistencyScore: Double
    public let strength: Double

    public init(
        id: UUID = UUID(),
        environments: [BehavioralEnvironmentType],
        recurrenceCount: Int,
        averageIntervalMinutes: Double,
        consistencyScore: Double,
        strength: Double
    ) {
        self.id = id
        self.environments = environments
        self.recurrenceCount = recurrenceCount
        self.averageIntervalMinutes = averageIntervalMinutes
        self.consistencyScore = consistencyScore
        self.strength = strength
    }
}

/// Detects recurring environment chains surrounding reading activity.
struct BehavioralSequenceAnalyzer {

    func analyze(
        contexts: [ReadingContextRecord]
    ) -> [BehavioralSequencePattern] {

        guard contexts.count > 2 else {
            return []
        }

        let sequences = contexts.map {
            [
                $0.preReadingContext.type,
                $0.inSessionContext.type,
                $0.postReadingContext.type
            ]
        }

        var counts: [[BehavioralEnvironmentType]: Int] = [:]

        for sequence in sequences {
            counts[sequence, default: 0] += 1
        }

        return counts
            .map { sequence, count in

                let consistency =
                    min(Double(count) / Double(max(contexts.count, 1)), 1.0)

                return BehavioralSequencePattern(
                    environments: sequence,
                    recurrenceCount: count,
                    averageIntervalMinutes: 0,
                    consistencyScore: consistency,
                    strength: (
                        Double(count) * consistency
                    )
                )
            }
            .sorted { $0.strength > $1.strength }
    }
}

// MARK: - Behavioral Diversity Metrics

public struct BehavioralDiversityMetrics:
    Codable,
    Hashable,
    Sendable {

    public let uniqueEnvironmentCount: Int
    public let diversityScore: Double
    public let dominantEnvironmentPercentage: Double

    public init(
        uniqueEnvironmentCount: Int,
        diversityScore: Double,
        dominantEnvironmentPercentage: Double
    ) {
        self.uniqueEnvironmentCount = uniqueEnvironmentCount
        self.diversityScore = diversityScore
        self.dominantEnvironmentPercentage = dominantEnvironmentPercentage
    }
}

struct BehavioralDiversityAnalyzer {

    func analyze(
        contexts: [ReadingContextRecord]
    ) -> BehavioralDiversityMetrics {

        let environments =
            contexts.map(\.preReadingContext.type)

        let uniqueCount =
            Set(environments).count

        let total =
            max(environments.count, 1)

        let dominantCount =
            environments
                .reduce(into: [:]) {
                    $0[$1, default: 0] += 1
                }
                .values
                .max() ?? 0

        let dominantPercentage =
            Double(dominantCount) /
            Double(total)

        let diversity =
            Double(uniqueCount) /
            Double(max(
                BehavioralEnvironmentType.allCases.count,
                1
            ))

        return BehavioralDiversityMetrics(
            uniqueEnvironmentCount: uniqueCount,
            diversityScore: diversity,
            dominantEnvironmentPercentage: dominantPercentage
        )
    }
}

// MARK: - Context Distribution Metrics

public struct ContextDistributionMetrics:
    Codable,
    Hashable,
    Sendable {

    public let distribution:
        [BehavioralEnvironmentType: Double]

    public init(
        distribution:
            [BehavioralEnvironmentType: Double]
    ) {
        self.distribution = distribution
    }
}

struct ContextDistributionAnalyzer {

    func analyze(
        contexts: [ReadingContextRecord]
    ) -> ContextDistributionMetrics {

        let environments =
            contexts.map(\.preReadingContext.type)

        let total =
            Double(max(environments.count, 1))

        var values:
            [BehavioralEnvironmentType: Double] = [:]

        for environment in environments {

            values[environment, default: 0] += 1
        }

        for key in values.keys {

            values[key] =
                values[key, default: 0] / total
        }

        return ContextDistributionMetrics(
            distribution: values
        )
    }
}

// MARK: - Routine Disruption Detection

/// Absence is normally ignored.
///
/// However, disruption of a historically stable recurring routine is
/// a meaningful contextual signal.
///
/// Example:
///
/// Work → Reading observed 80 times.
///
/// Suddenly:
///
/// Reading occurs without Work.
///
/// This is considered a disruption event.
public struct RoutineDisruption:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID
    public let routineTitle: String
    public let occurrenceDate: Date
    public let disruptionScore: Double

    public init(
        id: UUID = UUID(),
        routineTitle: String,
        occurrenceDate: Date,
        disruptionScore: Double
    ) {
        self.id = id
        self.routineTitle = routineTitle
        self.occurrenceDate = occurrenceDate
        self.disruptionScore = disruptionScore
    }
}

struct RoutineDisruptionAnalyzer {

    func detect(
        routines: [BehavioralRoutine],
        contexts: [ReadingContextRecord]
    ) -> [RoutineDisruption] {

        guard let dominantRoutine = routines.first else {
            return []
        }

        return contexts.compactMap { context in

            let matches =
                context.preReadingContext.type ==
                dominantRoutine.dominantEnvironment

            guard !matches else {
                return nil
            }

            return RoutineDisruption(
                routineTitle: dominantRoutine.title,
                occurrenceDate: context.readingDate,
                disruptionScore:
                    dominantRoutine.confidence.score
            )
        }
    }
}

// MARK: - Environment Stability Analysis

public struct EnvironmentStabilityMetrics:
    Codable,
    Hashable,
    Sendable {

    public let stabilityScore: Double
    public let dominantEnvironment:
        BehavioralEnvironmentType

    public init(
        stabilityScore: Double,
        dominantEnvironment:
            BehavioralEnvironmentType
    ) {
        self.stabilityScore = stabilityScore
        self.dominantEnvironment = dominantEnvironment
    }
}

struct EnvironmentStabilityAnalyzer {

    func analyze(
        contexts: [ReadingContextRecord]
    ) -> EnvironmentStabilityMetrics {

        let environments =
            contexts.map(\.preReadingContext.type)

        guard let dominant =
            environments.mostCommon else {

            return EnvironmentStabilityMetrics(
                stabilityScore: 0,
                dominantEnvironment: .unknown
            )
        }

        let matching =
            environments.filter {
                $0 == dominant
            }.count

        let stability =
            Double(matching) /
            Double(max(environments.count, 1))

        return EnvironmentStabilityMetrics(
            stabilityScore: stability,
            dominantEnvironment: dominant
        )
    }
}

// MARK: - Historical Pattern Builder

public struct HistoricalPatternAnalysis:
    Codable,
    Hashable,
    Sendable {

    public let patterns:
        [HistoricalBehaviorPattern]

    public let sequencePatterns:
        [BehavioralSequencePattern]

    public let diversity:
        BehavioralDiversityMetrics

    public let distribution:
        ContextDistributionMetrics

    public let stability:
        EnvironmentStabilityMetrics

    public init(
        patterns: [HistoricalBehaviorPattern],
        sequencePatterns:
            [BehavioralSequencePattern],
        diversity:
            BehavioralDiversityMetrics,
        distribution:
            ContextDistributionMetrics,
        stability:
            EnvironmentStabilityMetrics
    ) {
        self.patterns = patterns
        self.sequencePatterns = sequencePatterns
        self.diversity = diversity
        self.distribution = distribution
        self.stability = stability
    }
}

extension BehaviorContextEngine {

    func buildHistoricalPatternAnalysis(
        contexts: [ReadingContextRecord]
    ) -> HistoricalPatternAnalysis {

        let sequenceAnalyzer =
            BehavioralSequenceAnalyzer()

        let diversityAnalyzer =
            BehavioralDiversityAnalyzer()

        let distributionAnalyzer =
            ContextDistributionAnalyzer()

        let stabilityAnalyzer =
            EnvironmentStabilityAnalyzer()

        let sequences =
            sequenceAnalyzer.analyze(
                contexts: contexts
            )

        let diversity =
            diversityAnalyzer.analyze(
                contexts: contexts
            )

        let distribution =
            distributionAnalyzer.analyze(
                contexts: contexts
            )

        let stability =
            stabilityAnalyzer.analyze(
                contexts: contexts
            )

        let patterns =
            sequences.prefix(5).map {

                HistoricalBehaviorPattern(
                    title:
                        $0.environments
                        .map(\.rawValue)
                        .joined(separator: " → "),
                    confidence:
                        ContextConfidence(
                            score: min(
                                $0.strength,
                                1.0
                            )
                        )
                )
            }

        return HistoricalPatternAnalysis(
            patterns: patterns,
            sequencePatterns: sequences,
            diversity: diversity,
            distribution: distribution,
            stability: stability
        )
    }
}
// MARK: - Advanced Significance Evaluation Engine

/// The significance engine is responsible for distinguishing meaningful
/// behavioral evidence from incidental activity.
///
/// This subsystem exists because contextual reconstruction should be driven
/// primarily by stable recurring behavior rather than isolated observations.
///
/// Examples:
///
/// Significant:
/// - Notes used 40 minutes daily for months.
/// - Safari repeatedly active before reading.
/// - Music active during most evening reading sessions.
///
/// Incidental:
/// - Preview opened for 4 seconds.
/// - Calculator launched once.
/// - Dictionary opened accidentally.
///
/// The engine intentionally favors:
/// - recurrence
/// - temporal stability
/// - routine participation
/// - reading proximity
/// - historical persistence
///
/// over isolated activity.
public struct AdvancedSignificanceAssessment:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID

    public let evidenceID: UUID

    public let durationScore: Double
    public let recurrenceScore: Double
    public let frequencyScore: Double
    public let consistencyScore: Double
    public let stabilityScore: Double
    public let routineParticipationScore: Double
    public let readingProximityScore: Double

    public let overallScore: Double
    public let confidence: ContextConfidence

    public let classification:
        BehavioralSignificanceClassification

    public init(
        id: UUID = UUID(),
        evidenceID: UUID,
        durationScore: Double,
        recurrenceScore: Double,
        frequencyScore: Double,
        consistencyScore: Double,
        stabilityScore: Double,
        routineParticipationScore: Double,
        readingProximityScore: Double,
        overallScore: Double,
        confidence: ContextConfidence,
        classification:
            BehavioralSignificanceClassification
    ) {
        self.id = id
        self.evidenceID = evidenceID
        self.durationScore = durationScore
        self.recurrenceScore = recurrenceScore
        self.frequencyScore = frequencyScore
        self.consistencyScore = consistencyScore
        self.stabilityScore = stabilityScore
        self.routineParticipationScore =
            routineParticipationScore
        self.readingProximityScore =
            readingProximityScore
        self.overallScore = overallScore
        self.confidence = confidence
        self.classification = classification
    }
}

public enum BehavioralSignificanceClassification:
    String,
    Codable,
    Hashable,
    Sendable {

    case incidentalNoise
    case weakSignal
    case moderateSignal
    case strongSignal
    case dominantBehavior
}

struct AdvancedSignificanceEngine {

    func evaluate(
        evidence: BehaviorEvidence,
        historicalOccurrences: Int,
        routineOccurrences: Int,
        ageInDays: Double
    ) -> AdvancedSignificanceAssessment {

        let duration =
            normalize(
                evidence.totalDuration,
                maxValue: 7200
            )

        let recurrence =
            normalize(
                Double(evidence.recurrenceCount),
                maxValue: 180
            )

        let frequency =
            normalize(
                Double(evidence.frequency),
                maxValue: 365
            )

        let consistency =
            clamp(
                evidence.consistency
            )

        let stability =
            stabilityScore(
                recurrenceCount:
                    historicalOccurrences,
                ageInDays:
                    ageInDays
            )

        let routineParticipation =
            normalize(
                Double(routineOccurrences),
                maxValue: 120
            )

        let proximity =
            clamp(
                evidence.proximityToReading
            )

        let score =
            weightedScore(
                duration: duration,
                recurrence: recurrence,
                frequency: frequency,
                consistency: consistency,
                stability: stability,
                routineParticipation:
                    routineParticipation,
                proximity: proximity
            )

        return AdvancedSignificanceAssessment(
            evidenceID: evidence.id,
            durationScore: duration,
            recurrenceScore: recurrence,
            frequencyScore: frequency,
            consistencyScore: consistency,
            stabilityScore: stability,
            routineParticipationScore:
                routineParticipation,
            readingProximityScore:
                proximity,
            overallScore: score,
            confidence:
                ContextConfidence(
                    score: confidence(
                        score: score,
                        recurrence: recurrence
                    )
                ),
            classification:
                classification(
                    score: score
                )
        )
    }

    private func weightedScore(
        duration: Double,
        recurrence: Double,
        frequency: Double,
        consistency: Double,
        stability: Double,
        routineParticipation: Double,
        proximity: Double
    ) -> Double {

        (
            duration * 0.10
        ) +
        (
            recurrence * 0.25
        ) +
        (
            frequency * 0.15
        ) +
        (
            consistency * 0.15
        ) +
        (
            stability * 0.15
        ) +
        (
            routineParticipation * 0.10
        ) +
        (
            proximity * 0.10
        )
    }

    private func classification(
        score: Double
    ) -> BehavioralSignificanceClassification {

        switch score {

        case 0.85...:
            return .dominantBehavior

        case 0.70..<0.85:
            return .strongSignal

        case 0.45..<0.70:
            return .moderateSignal

        case 0.20..<0.45:
            return .weakSignal

        default:
            return .incidentalNoise
        }
    }

    private func confidence(
        score: Double,
        recurrence: Double
    ) -> Double {

        min(
            (
                score * 0.7
            ) +
            (
                recurrence * 0.3
            ),
            1.0
        )
    }

    private func stabilityScore(
        recurrenceCount: Int,
        ageInDays: Double
    ) -> Double {

        guard ageInDays > 0 else {
            return 0
        }

        let density =
            Double(recurrenceCount) /
            ageInDays

        return min(
            density,
            1.0
        )
    }

    private func normalize(
        _ value: Double,
        maxValue: Double
    ) -> Double {

        guard maxValue > 0 else {
            return 0
        }

        return min(
            value / maxValue,
            1.0
        )
    }

    private func clamp(
        _ value: Double
    ) -> Double {

        max(
            0,
            min(
                value,
                1
            )
        )
    }
}

// MARK: - Context Evidence Chains

/// A contextual chain represents the evidence path that produced a contextual
/// interpretation.
///
/// This provides explainability and auditability.
///
/// Example:
///
/// Notes
/// → Safari
/// → Research Environment
/// → Reading Session
///
/// The engine should always be capable of explaining why a context was created.
public struct ContextEvidenceChain:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID

    public let readingSessionID: UUID

    public let evidenceIDs: [UUID]

    public let environment:
        BehavioralEnvironmentType

    public let confidence:
        ContextConfidence

    public init(
        id: UUID = UUID(),
        readingSessionID: UUID,
        evidenceIDs: [UUID],
        environment:
            BehavioralEnvironmentType,
        confidence:
            ContextConfidence
    ) {
        self.id = id
        self.readingSessionID =
            readingSessionID
        self.evidenceIDs =
            evidenceIDs
        self.environment =
            environment
        self.confidence =
            confidence
    }
}

struct ContextEvidenceChainBuilder {

    func build(
        session: ReadingSessionRecord,
        evidence: [BehaviorEvidence],
        environment:
            BehavioralEnvironmentType
    ) -> ContextEvidenceChain {

        let ids =
            evidence.map(\.id)

        let confidence =
            ContextConfidence(
                score:
                    min(
                        Double(ids.count) / 20.0,
                        1.0
                    )
            )

        return ContextEvidenceChain(
            readingSessionID:
                session.id,
            evidenceIDs:
                ids,
            environment:
                environment,
            confidence:
                confidence
        )
    }
}

// MARK: - Context Correlation Analysis

public struct ContextCorrelationMatrix:
    Codable,
    Hashable,
    Sendable {

    public let correlations:
        [BehavioralCorrelation]

    public init(
        correlations:
            [BehavioralCorrelation]
    ) {
        self.correlations =
            correlations
    }
}

struct ContextCorrelationAnalyzer {

    func analyze(
        contexts:
            [ReadingContextRecord]
    ) -> ContextCorrelationMatrix {

        var results:
            [BehavioralCorrelation] = []

        let grouped =
            Dictionary(
                grouping: contexts
            ) {
                $0.preReadingContext.type
            }

        for (
            environment,
            records
        ) in grouped {

            guard records.count > 1 else {
                continue
            }

            let strength =
                min(
                    Double(records.count) /
                    Double(
                        max(
                            contexts.count,
                            1
                        )
                    ),
                    1.0
                )

            results.append(
                BehavioralCorrelation(
                    description:
                        "\(environment.rawValue) before reading",
                    strength:
                        strength
                )
            )
        }

        return ContextCorrelationMatrix(
            correlations:
                results.sorted {
                    $0.strength >
                    $1.strength
                }
        )
    }
}

// MARK: - Environment Clustering

/// Environment clusters aggregate related environments into broader behavioral
/// domains.
///
/// Example:
///
/// Development
/// Research
/// Administrative
///
/// may cluster into:
///
/// Productive Work
///
/// This enables higher-level contextual reconstruction.
public struct EnvironmentCluster:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID

    public let title: String

    public let environments:
        [BehavioralEnvironmentType]

    public let confidence:
        ContextConfidence

    public init(
        id: UUID = UUID(),
        title: String,
        environments:
            [BehavioralEnvironmentType],
        confidence:
            ContextConfidence
    ) {
        self.id = id
        self.title = title
        self.environments =
            environments
        self.confidence =
            confidence
    }
}

struct EnvironmentClusterBuilder {

    func clusters(
        from contexts:
            [ReadingContextRecord]
    ) -> [EnvironmentCluster] {

        let productive:
            [BehavioralEnvironmentType] = [
                .work,
                .development,
                .research,
                .administrative
            ]

        let leisure:
            [BehavioralEnvironmentType] = [
                .gaming,
                .social,
                .entertainment
            ]

        let learning:
            [BehavioralEnvironmentType] = [
                .learning,
                .research
            ]

        return [

            EnvironmentCluster(
                title:
                    "Productive Work",
                environments:
                    productive,
                confidence:
                    clusterConfidence(
                        productive,
                        contexts
                    )
            ),

            EnvironmentCluster(
                title:
                    "Leisure",
                environments:
                    leisure,
                confidence:
                    clusterConfidence(
                        leisure,
                        contexts
                    )
            ),

            EnvironmentCluster(
                title:
                    "Learning",
                environments:
                    learning,
                confidence:
                    clusterConfidence(
                        learning,
                        contexts
                    )
            )
        ]
    }

    private func clusterConfidence(
        _ environments:
            [BehavioralEnvironmentType],
        _ contexts:
            [ReadingContextRecord]
    ) -> ContextConfidence {

        let matches =
            contexts.filter {

                environments.contains(
                    $0.preReadingContext.type
                )
            }

        let score =
            Double(matches.count) /
            Double(
                max(
                    contexts.count,
                    1
                )
            )

        return ContextConfidence(
            score: score
        )
    }
}
// MARK: - Advanced Routine Detection Engine

/// Routine classification used for contextual reconstruction.
///
/// Routines are not simply time-based patterns. A routine is a recurring
/// behavioral pathway that repeatedly surrounds reading activity.
public enum RoutineCategory:
    String,
    Codable,
    Hashable,
    Sendable,
    CaseIterable {

    case morningReading
    case afternoonReading
    case eveningReading
    case lateNightReading

    case weekdayReading
    case weekendReading

    case weatherAssociated
    case activityAssociated

    case workTransition
    case learningTransition
    case entertainmentTransition
    case socialTransition

    case stableRoutine
    case emergingRoutine
}

public struct RoutineOccurrence:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID

    public let routine:
        RoutineCategory

    public let date: Date

    public let confidence:
        ContextConfidence

    public init(
        id: UUID = UUID(),
        routine: RoutineCategory,
        date: Date,
        confidence: ContextConfidence
    ) {
        self.id = id
        self.routine = routine
        self.date = date
        self.confidence = confidence
    }
}

public struct AdvancedRoutineAnalysis:
    Codable,
    Hashable,
    Sendable {

    public let detectedRoutines:
        [BehavioralRoutine]

    public let occurrences:
        [RoutineOccurrence]

    public let stabilityScore:
        Double

    public let consistencyScore:
        Double

    public init(
        detectedRoutines:
            [BehavioralRoutine],
        occurrences:
            [RoutineOccurrence],
        stabilityScore:
            Double,
        consistencyScore:
            Double
    ) {
        self.detectedRoutines =
            detectedRoutines
        self.occurrences =
            occurrences
        self.stabilityScore =
            stabilityScore
        self.consistencyScore =
            consistencyScore
    }
}

struct AdvancedRoutineDetector {

    func analyze(
        contexts:
            [ReadingContextRecord]
    ) -> AdvancedRoutineAnalysis {

        let occurrences =
            buildOccurrences(
                contexts
            )

        let routines =
            buildRoutines(
                occurrences
            )

        return AdvancedRoutineAnalysis(
            detectedRoutines:
                routines,
            occurrences:
                occurrences,
            stabilityScore:
                stability(
                    occurrences
                ),
            consistencyScore:
                consistency(
                    occurrences
                )
        )
    }

    private func buildOccurrences(
        _ contexts:
            [ReadingContextRecord]
    ) -> [RoutineOccurrence] {

        var results:
            [RoutineOccurrence] = []

        let calendar =
            Calendar.current

        for context in contexts {

            let hour =
                calendar.component(
                    .hour,
                    from:
                        context.readingDate
                )

            let weekday =
                calendar.component(
                    .weekday,
                    from:
                        context.readingDate
                )

            if hour >= 5 && hour < 12 {

                results.append(
                    RoutineOccurrence(
                        routine:
                            .morningReading,
                        date:
                            context.readingDate,
                        confidence:
                            .medium
                    )
                )
            }

            if hour >= 12 && hour < 17 {

                results.append(
                    RoutineOccurrence(
                        routine:
                            .afternoonReading,
                        date:
                            context.readingDate,
                        confidence:
                            .medium
                    )
                )
            }

            if hour >= 17 && hour < 22 {

                results.append(
                    RoutineOccurrence(
                        routine:
                            .eveningReading,
                        date:
                            context.readingDate,
                        confidence:
                            .medium
                    )
                )
            }

            if hour >= 22 || hour < 5 {

                results.append(
                    RoutineOccurrence(
                        routine:
                            .lateNightReading,
                        date:
                            context.readingDate,
                        confidence:
                            .medium
                    )
                )
            }

            if weekday == 1 ||
                weekday == 7 {

                results.append(
                    RoutineOccurrence(
                        routine:
                            .weekendReading,
                        date:
                            context.readingDate,
                        confidence:
                            .medium
                    )
                )
            } else {

                results.append(
                    RoutineOccurrence(
                        routine:
                            .weekdayReading,
                        date:
                            context.readingDate,
                        confidence:
                            .medium
                    )
                )
            }

            switch context.preReadingContext.type {

            case .work,
                 .development,
                 .administrative:

                results.append(
                    RoutineOccurrence(
                        routine:
                            .workTransition,
                        date:
                            context.readingDate,
                        confidence:
                            .high
                    )
                )

            case .learning,
                 .research:

                results.append(
                    RoutineOccurrence(
                        routine:
                            .learningTransition,
                        date:
                            context.readingDate,
                        confidence:
                            .high
                    )
                )

            case .social:

                results.append(
                    RoutineOccurrence(
                        routine:
                            .socialTransition,
                        date:
                            context.readingDate,
                        confidence:
                            .high
                    )
                )

            case .entertainment,
                 .gaming:

                results.append(
                    RoutineOccurrence(
                        routine:
                            .entertainmentTransition,
                        date:
                            context.readingDate,
                        confidence:
                            .high
                    )
                )

            default:
                break
            }
        }

        return results
    }

    private func buildRoutines(
        _ occurrences:
            [RoutineOccurrence]
    ) -> [BehavioralRoutine] {

        let grouped =
            Dictionary(
                grouping:
                    occurrences
            ) {
                $0.routine
            }

        return grouped.map {

            category,
            entries

            in

            BehavioralRoutine(
                title:
                    category.rawValue,
                recurrenceCount:
                    entries.count,
                averageHour:
                    0,
                dominantEnvironment:
                    .unknown,
                confidence:
                    ContextConfidence(
                        score:
                            min(
                                Double(
                                    entries.count
                                ) / 50,
                                1
                            )
                    )
            )
        }
        .sorted {
            $0.recurrenceCount >
            $1.recurrenceCount
        }
    }

    private func stability(
        _ occurrences:
            [RoutineOccurrence]
    ) -> Double {

        let grouped =
            Dictionary(
                grouping:
                    occurrences
            ) {
                $0.routine
            }

        guard let maxCount =
            grouped.values
                .map(\.count)
                .max() else {

            return 0
        }

        return min(
            Double(maxCount) /
            Double(
                max(
                    occurrences.count,
                    1
                )
            ),
            1
        )
    }

    private func consistency(
        _ occurrences:
            [RoutineOccurrence]
    ) -> Double {

        let grouped =
            Dictionary(
                grouping:
                    occurrences
            ) {
                $0.routine
            }

        guard !grouped.isEmpty else {
            return 0
        }

        let average =
            Double(
                occurrences.count
            ) /
            Double(
                grouped.count
            )

        let variance =
            grouped.values
                .map {
                    pow(
                        Double(
                            $0.count
                        ) - average,
                        2
                    )
                }
                .reduce(
                    0,
                    +
                ) /
            Double(
                grouped.count
            )

        return max(
            0,
            1 -
            (
                variance /
                (
                    average *
                    average +
                    1
                )
            )
        )
    }
}

// MARK: - Reading Context Continuity

/// Context continuity evaluates whether reading occurred as a continuation
/// of an existing behavioral environment or represented a contextual shift.
public enum ContextContinuityType:
    String,
    Codable,
    Hashable,
    Sendable {

    case continuous
    case partialTransition
    case majorTransition
    case isolatedReading
}

public struct ContextContinuityRecord:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID

    public let sessionID: UUID

    public let continuityType:
        ContextContinuityType

    public let continuityScore:
        Double

    public init(
        id: UUID = UUID(),
        sessionID: UUID,
        continuityType:
            ContextContinuityType,
        continuityScore:
            Double
    ) {
        self.id = id
        self.sessionID = sessionID
        self.continuityType =
            continuityType
        self.continuityScore =
            continuityScore
    }
}

struct ContextContinuityAnalyzer {

    func analyze(
        contexts:
            [ReadingContextRecord]
    ) -> [ContextContinuityRecord] {

        contexts.map {

            context in

            let pre =
                context.preReadingContext
                .type

            let reading =
                context.inSessionContext
                .type

            let post =
                context.postReadingContext
                .type

            let score =
                continuity(
                    pre,
                    reading,
                    post
                )

            return ContextContinuityRecord(
                sessionID:
                    context.sessionID,
                continuityType:
                    classify(
                        score
                    ),
                continuityScore:
                    score
            )
        }
    }

    private func continuity(
        _ pre:
            BehavioralEnvironmentType,
        _ reading:
            BehavioralEnvironmentType,
        _ post:
            BehavioralEnvironmentType
    ) -> Double {

        var score: Double = 0

        if pre == reading {
            score += 0.5
        }

        if reading == post {
            score += 0.5
        }

        return score
    }

    private func classify(
        _ score: Double
    ) -> ContextContinuityType {

        switch score {

        case 1.0:
            return .continuous

        case 0.5:
            return .partialTransition

        case 0..<0.5:
            return .majorTransition

        default:
            return .isolatedReading
        }
    }
}

// MARK: - Reading Context Trend Analysis

public enum ContextTrendDirection:
    String,
    Codable,
    Hashable,
    Sendable {

    case increasing
    case decreasing
    case stable
    case emerging
}

public struct ContextTrend:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID

    public let environment:
        BehavioralEnvironmentType

    public let direction:
        ContextTrendDirection

    public let strength:
        Double

    public init(
        id: UUID = UUID(),
        environment:
            BehavioralEnvironmentType,
        direction:
            ContextTrendDirection,
        strength:
            Double
    ) {
        self.id = id
        self.environment =
            environment
        self.direction =
            direction
        self.strength =
            strength
    }
}

struct ContextTrendAnalyzer {

    func analyze(
        contexts:
            [ReadingContextRecord]
    ) -> [ContextTrend] {

        let grouped =
            Dictionary(
                grouping:
                    contexts
            ) {
                $0.preReadingContext.type
            }

        return grouped.map {

            environment,
            records

            in

            let strength =
                min(
                    Double(
                        records.count
                    ) /
                    Double(
                        max(
                            contexts.count,
                            1
                        )
                    ),
                    1
                )

            return ContextTrend(
                environment:
                    environment,
                direction:
                    direction(
                        count:
                            records.count,
                        total:
                            contexts.count
                    ),
                strength:
                    strength
            )
        }
    }

    private func direction(
        count: Int,
        total: Int
    ) -> ContextTrendDirection {

        let ratio =
            Double(count) /
            Double(
                max(
                    total,
                    1
                )
            )

        switch ratio {

        case 0.50...:
            return .increasing

        case 0.25..<0.50:
            return .stable

        case 0.10..<0.25:
            return .emerging

        default:
            return .decreasing
        }
    }
}

// MARK: - Weather Associated Context Reconstruction

/// Weather is not analyzed here.
///
/// Existing weather systems own weather interpretation.
///
/// BehaviorContextEngine only consumes weather outputs and evaluates
/// whether weather repeatedly appears around reading behavior.
public struct WeatherRoutinePattern:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID

    public let weatherDescriptor: String

    public let occurrenceCount: Int

    public let readingAssociationStrength: Double

    public let confidence: ContextConfidence

    public init(
        id: UUID = UUID(),
        weatherDescriptor: String,
        occurrenceCount: Int,
        readingAssociationStrength: Double,
        confidence: ContextConfidence
    ) {
        self.id = id
        self.weatherDescriptor = weatherDescriptor
        self.occurrenceCount = occurrenceCount
        self.readingAssociationStrength =
            readingAssociationStrength
        self.confidence = confidence
    }
}

struct WeatherRoutineAnalyzer {

    func analyze(
        contexts: [ReadingContextRecord]
    ) -> [WeatherRoutinePattern] {

        let descriptors =
            contexts.compactMap {
                $0.weatherContext?.descriptor
            }

        let grouped =
            Dictionary(
                grouping: descriptors
            ) {
                $0
            }

        let total =
            Double(
                max(
                    descriptors.count,
                    1
                )
            )

        return grouped.map {

            descriptor,
            records

            in

            let strength =
                Double(records.count) /
                total

            return WeatherRoutinePattern(
                weatherDescriptor:
                    descriptor,
                occurrenceCount:
                    records.count,
                readingAssociationStrength:
                    strength,
                confidence:
                    ContextConfidence(
                        score:
                            strength
                    )
            )
        }
        .sorted {
            $0.readingAssociationStrength >
            $1.readingAssociationStrength
        }
    }
}

// MARK: - Environmental Influence Analysis

public struct EnvironmentalInfluence:
    Codable,
    Hashable,
    Identifiable,
    Sendable {

    public let id: UUID

    public let source: String

    public let influenceScore: Double

    public let confidence:
        ContextConfidence

    public init(
        id: UUID = UUID(),
        source: String,
        influenceScore: Double,
        confidence: ContextConfidence
    ) {
        self.id = id
        self.source = source
        self.influenceScore =
            influenceScore
        self.confidence =
            confidence
    }
}

struct EnvironmentalInfluenceAnalyzer {

    func analyze(
        contexts: [ReadingContextRecord]
    ) -> [EnvironmentalInfluence] {

        let grouped =
            Dictionary(
                grouping:
                    contexts.compactMap {
                        $0.weatherContext?.descriptor
                    }
            ) {
                $0
            }

        let total =
            Double(
                max(
                    contexts.count,
                    1
                )
            )

        return grouped.map {

            descriptor,
            values

            in

            let score =
                Double(values.count) /
                total

            return EnvironmentalInfluence(
                source:
                    descriptor,
                influenceScore:
                    score,
                confidence:
                    ContextConfidence(
                        score:
                            score
                    )
            )
        }
    }
}

// MARK: - Contextual Narrative Builder V2

/// Deterministic narrative generation.
///
/// No AI.
/// No probabilistic text.
/// No external services.
///
/// Every narrative must be reproducible from evidence.
struct DeterministicNarrativeBuilder {

    func build(
        contexts: [ReadingContextRecord],
        routines: [BehavioralRoutine],
        trends: [ContextTrend],
        disruptions: [RoutineDisruption]
    ) -> [ContextNarrative] {

        var narratives:
            [ContextNarrative] = []

        if let dominant =
            contexts
            .map(\.preReadingContext.type)
            .mostCommon {

            narratives.append(
                ContextNarrative(
                    text:
                        """
                        Reading most frequently occurred after \(dominant.rawValue.lowercased()) activity.
                        """
                )
            )
        }

        if let routine =
            routines.first {

            narratives.append(
                ContextNarrative(
                    text:
                        """
                        A recurring routine centered around \(routine.title) was repeatedly observed.
                        """
                )
            )
        }

        if let trend =
            trends.max(
                by: {
                    $0.strength <
                    $1.strength
                }
            ) {

            narratives.append(
                ContextNarrative(
                    text:
                        """
                        \(trend.environment.rawValue.capitalized) activity showed the strongest contextual relationship with reading behavior.
                        """
                )
            )
        }

        if !disruptions.isEmpty {

            narratives.append(
                ContextNarrative(
                    text:
                        """
                        Established reading routines experienced occasional contextual disruption events.
                        """
                )
            )
        }

        if narratives.isEmpty {

            narratives.append(
                ContextNarrative(
                    text:
                        """
                        Contextual evidence remains insufficient for reliable reconstruction.
                        """
                )
            )
        }

        return narratives
    }
}

// MARK: - Master Analysis Bundle

/// Intended future aggregation object.
///
/// Provides a single high-level contextual intelligence result.
public struct ContextIntelligenceReport:
    Codable,
    Hashable,
    Sendable {

    public let generatedAt: Date

    public let patterns:
        HistoricalPatternAnalysis

    public let routines:
        AdvancedRoutineAnalysis

    public let trends:
        [ContextTrend]

    public let disruptions:
        [RoutineDisruption]

    public let weatherPatterns:
        [WeatherRoutinePattern]

    public let environmentalInfluences:
        [EnvironmentalInfluence]

    public let correlations:
        ContextCorrelationMatrix

    public let clusters:
        [EnvironmentCluster]

    public let narratives:
        [ContextNarrative]

    public init(
        generatedAt: Date,
        patterns:
            HistoricalPatternAnalysis,
        routines:
            AdvancedRoutineAnalysis,
        trends:
            [ContextTrend],
        disruptions:
            [RoutineDisruption],
        weatherPatterns:
            [WeatherRoutinePattern],
        environmentalInfluences:
            [EnvironmentalInfluence],
        correlations:
            ContextCorrelationMatrix,
        clusters:
            [EnvironmentCluster],
        narratives:
            [ContextNarrative]
    ) {
        self.generatedAt =
            generatedAt
        self.patterns =
            patterns
        self.routines =
            routines
        self.trends =
            trends
        self.disruptions =
            disruptions
        self.weatherPatterns =
            weatherPatterns
        self.environmentalInfluences =
            environmentalInfluences
        self.correlations =
            correlations
        self.clusters =
            clusters
        self.narratives =
            narratives
    }
}

// MARK: - Future Engine Entry Point

extension BehaviorContextEngine {

    func buildIntelligenceReport(
        contexts: [ReadingContextRecord],
        routines: [BehavioralRoutine]
    ) -> ContextIntelligenceReport {

        let patternAnalysis =
            buildHistoricalPatternAnalysis(
                contexts: contexts
            )

        let routineAnalysis =
            AdvancedRoutineDetector()
            .analyze(
                contexts: contexts
            )

        let trends =
            ContextTrendAnalyzer()
            .analyze(
                contexts: contexts
            )

        let disruptions =
            RoutineDisruptionAnalyzer()
            .detect(
                routines: routines,
                contexts: contexts
            )

        let weatherPatterns =
            WeatherRoutineAnalyzer()
            .analyze(
                contexts: contexts
            )

        let influences =
            EnvironmentalInfluenceAnalyzer()
            .analyze(
                contexts: contexts
            )

        let correlations =
            ContextCorrelationAnalyzer()
            .analyze(
                contexts: contexts
            )

        let clusters =
            EnvironmentClusterBuilder()
            .clusters(
                from: contexts
            )

        let narratives =
            DeterministicNarrativeBuilder()
            .build(
                contexts: contexts,
                routines: routineAnalysis.detectedRoutines,
                trends: trends,
                disruptions: disruptions
            )

        return ContextIntelligenceReport(
            generatedAt: Date(),
            patterns: patternAnalysis,
            routines: routineAnalysis,
            trends: trends,
            disruptions: disruptions,
            weatherPatterns: weatherPatterns,
            environmentalInfluences: influences,
            correlations: correlations,
            clusters: clusters,
            narratives: narratives
        )
    }
}

// ============================================================================
// MARK: - DEVELOPMENT CHECKLIST FOR NEXT AI
// ============================================================================
//
// COMPLETED SO FAR
//
// [x] Core BehaviorContextEngine skeleton
// [x] ReadingContextRecord models
// [x] BehavioralEnvironment models
// [x] ContextTransition models
// [x] ContextProfile models
// [x] ContextNarrative models
// [x] ContextConfidence system
// [x] SignificanceAssessment system
// [x] Context reconstruction
// [x] Environment classification
// [x] Environment mapping
// [x] Basic routine detection
// [x] Basic transition analysis
// [x] Profile generation
// [x] Narrative generation v1
// [x] HistoricalPatternAnalysis
// [x] BehavioralSequencePattern
// [x] Sequence analysis engine
// [x] Diversity metrics
// [x] Distribution metrics
// [x] Environment stability analysis
// [x] Routine disruption detection
// [x] Advanced significance engine
// [x] ContextEvidenceChain
// [x] Correlation analysis
// [x] Environment clustering
// [x] Advanced routine detection
// [x] Context continuity analysis
// [x] Context trend analysis
// [x] Weather routine analysis
// [x] Environmental influence analysis
// [x] Deterministic narrative builder v2
// [x] ContextIntelligenceReport
//
// HIGH PRIORITY REMAINING WORK
//
// [ ] Real BehaviorContextAccessKit adapters
// [ ] SessionCoordinator adapters
// [ ] AnalyticsEngine adapters
// [ ] WeatherAnalysisEngine adapters
// [ ] WeatherKitService adapters
// [ ] DataStore adapters
// [ ] Book model adapters
//
// [ ] Context window presets
// [ ] Dynamic context windows
// [ ] Multi-window comparison engine
// [ ] Window weighting engine
//
// [ ] Device-state analysis
// [ ] Foreground/background influence
// [ ] Screen lock influence
// [ ] Sleep/wake influence
//
// [ ] Inactivity reconstruction
// [ ] Idle gap analysis
// [ ] Recovery-session detection
// [ ] Fatigue indicators
//
// [ ] Environment evolution tracking
// [ ] Longitudinal behavior shifts
// [ ] Behavioral lifecycle analysis
//
// [ ] Sequence recurrence database
// [ ] Sequence consistency scoring
// [ ] Sequence timing analysis
// [ ] Transition chain reconstruction
//
// [ ] ContextDistribution profile models
// [ ] Behavioral diversity profiles
// [ ] Most productive context
// [ ] Most consistent context
//
// [ ] Confidence engine v2
// [ ] Confidence breakdown model
// [ ] Evidence quality scoring
// [ ] Historical depth scoring
//
// [ ] Narrative engine v3
// [ ] Explainability narratives
// [ ] Evidence-backed narrative citations
//
// [ ] Full inline documentation pass
// [ ] Final architectural cleanup
// [ ] Duplicate model consolidation
// [ ] Compile verification pass
//
// IMPORTANT NOTES FOR NEXT AI
//
// 1. DO NOT replace existing systems.
//    Consume outputs only.
//
// 2. BehaviorContextEngine sits ABOVE analytics.
//    Never duplicate reading analytics.
//
// 3. Context comes from evidence.
//    Never generate context from absence.
//
// 4. Absence is ONLY valid for routine disruption.
//
// 5. Continue building deterministic systems.
//    No AI generation.
//    No LLM logic.
//    No probabilistic narratives.
//
// 6. Next major milestone should be:
//    Integration Layer + Device-State Reconstruction +
//    Inactivity Reconstruction.
//
// 7. After integrations exist, refactor all analyzers into:
//      ContextAnalysisPipeline
//      SignificancePipeline
//      NarrativePipeline
//      RoutinePipeline
//
// 8. Final target remains a 2k–4k+ line contextual intelligence subsystem.
//
// ==============================================

