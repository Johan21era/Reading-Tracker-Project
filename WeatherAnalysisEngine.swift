//
//  WeatherAnalysisEngine.swift
//  Environmental intelligence layer for long-term reading behavior analysis.
//  Designed to augment AnalyticsEngine, EstimationEngine,
//  PredictiveRecommendationEngine, IntelligentNotificationEngine,
//  and InsightEngine without duplicating their responsibilities.
//

import Foundation

// MARK: - Environmental Condition Models

public enum WeatherConditionCategory: String, Codable, CaseIterable, Hashable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case rain
    case heavyRain
    case snow
    case heavySnow
    case storm
    case wind
    case mixed
    case unknown
}

public enum SeasonalPeriod: String, Codable, CaseIterable, Hashable {
    case spring
    case summer
    case autumn
    case winter
}

public enum DayPeriod: String, Codable, CaseIterable, Hashable {
    case dawn
    case morning
    case afternoon
    case evening
    case night
}

public struct WeatherSnapshot: Codable, Hashable, Identifiable {
    public let id: UUID

    public let timestamp: Date

    public let temperatureCelsius: Double
    public let feelsLikeTemperatureCelsius: Double

    public let humidity: Double
    public let pressure: Double

    public let cloudCover: Double
    public let visibilityKilometers: Double

    public let windSpeedKPH: Double

    public let precipitationMillimeters: Double

    public let snowfallMillimeters: Double

    public let stormActivityIndex: Double

    public let condition: WeatherConditionCategory

    public let season: SeasonalPeriod

    public let month: Int

    public let weekday: Int

    public let dayPeriod: DayPeriod

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        temperatureCelsius: Double,
        feelsLikeTemperatureCelsius: Double,
        humidity: Double,
        pressure: Double,
        cloudCover: Double,
        visibilityKilometers: Double,
        windSpeedKPH: Double,
        precipitationMillimeters: Double,
        snowfallMillimeters: Double,
        stormActivityIndex: Double,
        condition: WeatherConditionCategory,
        season: SeasonalPeriod,
        month: Int,
        weekday: Int,
        dayPeriod: DayPeriod
    ) {
        self.id = id
        self.timestamp = timestamp
        self.temperatureCelsius = temperatureCelsius
        self.feelsLikeTemperatureCelsius = feelsLikeTemperatureCelsius
        self.humidity = humidity
        self.pressure = pressure
        self.cloudCover = cloudCover
        self.visibilityKilometers = visibilityKilometers
        self.windSpeedKPH = windSpeedKPH
        self.precipitationMillimeters = precipitationMillimeters
        self.snowfallMillimeters = snowfallMillimeters
        self.stormActivityIndex = stormActivityIndex
        self.condition = condition
        self.season = season
        self.month = month
        self.weekday = weekday
        self.dayPeriod = dayPeriod
    }
}

// MARK: - Environmental Classification

public enum EnvironmentalFactor: String, Codable, CaseIterable, Hashable {
    case temperature
    case feelsLikeTemperature
    case humidity
    case pressure
    case cloudCover
    case visibility
    case windSpeed
    case rain
    case snow
    case stormActivity
    case season
    case month
    case weekday
    case dayPeriod
}

public enum ReadingBehaviorMetric: String, Codable, CaseIterable, Hashable {
    case readingDuration
    case pagesRead
    case chaptersCompleted
    case booksCompleted
    case readingSpeed
    case readingConsistency
    case readingFrequency
    case genreSelection
    case genreAvoidance
    case difficulty
    case complexity
    case bookLength
    case seriesProgression
    case completionLikelihood
    case abandonmentLikelihood
    case rereadingBehavior
    case sessionQuality
    case momentum
    case engagement
}

public enum CorrelationLifecycle: String, Codable, CaseIterable, Hashable {
    case emerging
    case strengthening
    case stable
    case weakening
    case declining
    case recurring
    case seasonal
    case persistent
    case temporary
}

public enum BehaviorEvolutionState: String, Codable, CaseIterable, Hashable {
    case newBehavior
    case strengthening
    case weakening
    case stable
    case lost
    case evolving
}

public enum EnvironmentalInsightCategory: String, Codable, CaseIterable {
    case readingSpeed
    case readingVolume
    case engagement
    case completion
    case abandonment
    case genrePreference
    case genreAvoidance
    case consistency
    case momentum
    case seasonalShift
    case environmentalSensitivity
}

// MARK: - Confidence System

public struct ConfidenceReport: Codable, Hashable {
    public let overallConfidence: Double

    public let sampleSizeScore: Double

    public let recurrenceScore: Double

    public let stabilityScore: Double

    public let consistencyScore: Double

    public let dataCoverageScore: Double

    public let supportingSamples: Int

    public init(
        overallConfidence: Double,
        sampleSizeScore: Double,
        recurrenceScore: Double,
        stabilityScore: Double,
        consistencyScore: Double,
        dataCoverageScore: Double,
        supportingSamples: Int
    ) {
        self.overallConfidence = overallConfidence
        self.sampleSizeScore = sampleSizeScore
        self.recurrenceScore = recurrenceScore
        self.stabilityScore = stabilityScore
        self.consistencyScore = consistencyScore
        self.dataCoverageScore = dataCoverageScore
        self.supportingSamples = supportingSamples
    }
}

// MARK: - Correlation Models

public struct EnvironmentalCorrelation: Codable, Identifiable, Hashable {
    public let id: UUID

    public let factor: EnvironmentalFactor

    public let metric: ReadingBehaviorMetric

    public let coefficient: Double

    public let significance: Double

    public let influenceScore: Double

    public let lifecycle: CorrelationLifecycle

    public let confidence: ConfidenceReport

    public let firstObserved: Date

    public let lastObserved: Date

    public let supportingSampleCount: Int

    public init(
        id: UUID = UUID(),
        factor: EnvironmentalFactor,
        metric: ReadingBehaviorMetric,
        coefficient: Double,
        significance: Double,
        influenceScore: Double,
        lifecycle: CorrelationLifecycle,
        confidence: ConfidenceReport,
        firstObserved: Date,
        lastObserved: Date,
        supportingSampleCount: Int
    ) {
        self.id = id
        self.factor = factor
        self.metric = metric
        self.coefficient = coefficient
        self.significance = significance
        self.influenceScore = influenceScore
        self.lifecycle = lifecycle
        self.confidence = confidence
        self.firstObserved = firstObserved
        self.lastObserved = lastObserved
        self.supportingSampleCount = supportingSampleCount
    }
}

// MARK: - Environmental Profiles

public struct TemperatureProfile: Codable, Hashable {
    public let optimalRange: ClosedRange<Double>

    public let peakReadingSpeed: Double

    public let peakEngagement: Double

    public let peakReadingVolume: Double

    public let influenceScore: Double

    public let confidence: ConfidenceReport
}

public struct SeasonalProfile: Codable, Hashable {
    public let season: SeasonalPeriod

    public let averageReadingDuration: Double

    public let averageReadingSpeed: Double

    public let averageEngagement: Double

    public let averagePagesRead: Double

    public let dominantGenres: [String]

    public let avoidedGenres: [String]

    public let confidence: ConfidenceReport
}

public struct WeatherInfluenceProfile: Codable, Hashable {
    public let strongestPositiveFactors: [EnvironmentalCorrelation]

    public let strongestNegativeFactors: [EnvironmentalCorrelation]

    public let environmentalSensitivityScore: Double

    public let dominantSeason: SeasonalPeriod?

    public let dominantCondition: WeatherConditionCategory?

    public let confidence: ConfidenceReport
}

public struct EnvironmentalReadingProfile: Codable, Hashable {
    public let temperatureProfile: TemperatureProfile?

    public let seasonalProfiles: [SeasonalProfile]

    public let influenceProfile: WeatherInfluenceProfile

    public let generatedAt: Date
}

// MARK: - Evolution Tracking

public struct EnvironmentalBehaviorSnapshot: Codable, Identifiable, Hashable {
    public let id: UUID

    public let createdAt: Date

    public let periodStart: Date

    public let periodEnd: Date

    public let influenceScore: Double

    public let dominantGenres: [String]

    public let dominantConditions: [WeatherConditionCategory]

    public let averageReadingSpeed: Double

    public let averageEngagement: Double

    public let averageReadingDuration: Double

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        periodStart: Date,
        periodEnd: Date,
        influenceScore: Double,
        dominantGenres: [String],
        dominantConditions: [WeatherConditionCategory],
        averageReadingSpeed: Double,
        averageEngagement: Double,
        averageReadingDuration: Double
    ) {
        self.id = id
        self.createdAt = createdAt
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.influenceScore = influenceScore
        self.dominantGenres = dominantGenres
        self.dominantConditions = dominantConditions
        self.averageReadingSpeed = averageReadingSpeed
        self.averageEngagement = averageEngagement
        self.averageReadingDuration = averageReadingDuration
    }
}

public struct EnvironmentalEvolutionFinding: Codable, Identifiable, Hashable {
    public let id: UUID

    public let state: BehaviorEvolutionState

    public let title: String

    public let description: String

    public let magnitude: Double

    public let confidence: ConfidenceReport

    public init(
        id: UUID = UUID(),
        state: BehaviorEvolutionState,
        title: String,
        description: String,
        magnitude: Double,
        confidence: ConfidenceReport
    ) {
        self.id = id
        self.state = state
        self.title = title
        self.description = description
        self.magnitude = magnitude
        self.confidence = confidence
    }
}

public struct EnvironmentalEvolutionReport: Codable, Hashable {
    public let generatedAt: Date

    public let findings: [EnvironmentalEvolutionFinding]

    public let baselineSnapshot: EnvironmentalBehaviorSnapshot

    public let currentSnapshot: EnvironmentalBehaviorSnapshot
}

// MARK: - Forecasting

public struct EnvironmentalForecastInput: Codable, Hashable {
    public let forecastWeather: WeatherSnapshot

    public init(forecastWeather: WeatherSnapshot) {
        self.forecastWeather = forecastWeather
    }
}

public struct EnvironmentalForecast: Codable, Hashable {
    public let expectedReadingDuration: Double

    public let expectedPagesRead: Double

    public let expectedReadingSpeed: Double

    public let expectedEngagement: Double

    public let expectedCompletionProbability: Double

    public let predictedGenres: [String]

    public let confidence: ConfidenceReport
}

// MARK: - Insight Objects

public struct EnvironmentalInsight: Codable, Identifiable, Hashable {
    public let id: UUID

    public let category: EnvironmentalInsightCategory

    public let title: String

    public let summary: String

    public let influenceScore: Double

    public let confidence: ConfidenceReport

    public let generatedAt: Date

    public init(
        id: UUID = UUID(),
        category: EnvironmentalInsightCategory,
        title: String,
        summary: String,
        influenceScore: Double,
        confidence: ConfidenceReport,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.summary = summary
        self.influenceScore = influenceScore
        self.confidence = confidence
        self.generatedAt = generatedAt
    }
}

// MARK: - Reports

public struct WeatherTrendReport: Codable, Hashable {
    public let generatedAt: Date

    public let correlations: [EnvironmentalCorrelation]

    public let strongestInfluences: [EnvironmentalCorrelation]

    public let environmentalSensitivityScore: Double

    public let confidence: ConfidenceReport
}

public struct EnvironmentalBehaviorReport: Codable, Hashable {
    public let generatedAt: Date

    public let profile: EnvironmentalReadingProfile

    public let insights: [EnvironmentalInsight]

    public let correlations: [EnvironmentalCorrelation]

    public let confidence: ConfidenceReport
}

// MARK: - Internal Analysis Helpers

struct CorrelationAccumulator {
    var factor: EnvironmentalFactor

    var metric: ReadingBehaviorMetric

    var values: [(Double, Double)] = []

    mutating func append(x: Double, y: Double) {
        values.append((x, y))
    }
}

struct SeasonalBucket {
    let season: SeasonalPeriod

    var sessionCount: Int = 0

    var totalDuration: Double = 0

    var totalPages: Double = 0

    var totalSpeed: Double = 0

    var totalEngagement: Double = 0

    var genres: [String: Int] = [:]
}

struct ConditionBucket {
    let condition: WeatherConditionCategory

    var sessions: Int = 0

    var totalDuration: Double = 0

    var totalPages: Double = 0

    var totalSpeed: Double = 0
}

// MARK: - Main Engine

public final class WeatherAnalysisEngine {
    public init() {}
}

// MARK: - Core Analysis Interfaces

public extension WeatherAnalysisEngine {
    // MARK: Environmental Session Record

    struct EnvironmentalSessionRecord: Codable, Identifiable, Hashable {
        public let id: UUID

        public let sessionID: UUID

        public let bookID: UUID

        public let timestamp: Date

        public let weather: WeatherSnapshot

        // Reading metrics supplied by existing systems.
        // WeatherAnalysisEngine does NOT calculate these.
        // It consumes them.

        public let readingDurationMinutes: Double

        public let pagesRead: Double

        public let chaptersCompleted: Double

        public let booksCompleted: Double

        public let readingSpeed: Double

        public let consistencyScore: Double

        public let readingFrequencyScore: Double

        public let engagementScore: Double

        public let sessionQualityScore: Double

        public let momentumScore: Double

        public let completionProbability: Double

        public let abandonmentProbability: Double

        public let difficultyScore: Double

        public let complexityScore: Double

        public let bookLength: Double

        public let genre: String?

        public let seriesIdentifier: String?

        public let reread: Bool

        public init(
            id: UUID = UUID(),
            sessionID: UUID,
            bookID: UUID,
            timestamp: Date,
            weather: WeatherSnapshot,
            readingDurationMinutes: Double,
            pagesRead: Double,
            chaptersCompleted: Double,
            booksCompleted: Double,
            readingSpeed: Double,
            consistencyScore: Double,
            readingFrequencyScore: Double,
            engagementScore: Double,
            sessionQualityScore: Double,
            momentumScore: Double,
            completionProbability: Double,
            abandonmentProbability: Double,
            difficultyScore: Double,
            complexityScore: Double,
            bookLength: Double,
            genre: String?,
            seriesIdentifier: String?,
            reread: Bool
        ) {
            self.id = id
            self.sessionID = sessionID
            self.bookID = bookID
            self.timestamp = timestamp
            self.weather = weather
            self.readingDurationMinutes = readingDurationMinutes
            self.pagesRead = pagesRead
            self.chaptersCompleted = chaptersCompleted
            self.booksCompleted = booksCompleted
            self.readingSpeed = readingSpeed
            self.consistencyScore = consistencyScore
            self.readingFrequencyScore = readingFrequencyScore
            self.engagementScore = engagementScore
            self.sessionQualityScore = sessionQualityScore
            self.momentumScore = momentumScore
            self.completionProbability = completionProbability
            self.abandonmentProbability = abandonmentProbability
            self.difficultyScore = difficultyScore
            self.complexityScore = complexityScore
            self.bookLength = bookLength
            self.genre = genre
            self.seriesIdentifier = seriesIdentifier
            self.reread = reread
        }
    }

    // MARK: Public Entry Point

    func buildEnvironmentalProfile(
        from sessions: [EnvironmentalSessionRecord]
    ) -> EnvironmentalReadingProfile {
        let temperatureProfile = buildTemperatureProfile(
            from: sessions
        )

        let seasonalProfiles = buildSeasonalProfiles(
            from: sessions
        )

        let influenceProfile = buildInfluenceProfile(
            from: sessions
        )

        return EnvironmentalReadingProfile(
            temperatureProfile: temperatureProfile,
            seasonalProfiles: seasonalProfiles,
            influenceProfile: influenceProfile,
            generatedAt: Date()
        )
    }

    // MARK: Full Correlation Analysis

    func analyzeCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        guard sessions.count >= 5 else {
            return []
        }

        var correlations: [EnvironmentalCorrelation] = []

        correlations.append(contentsOf:
            analyzeTemperatureCorrelations(from: sessions))

        correlations.append(contentsOf:
            analyzeHumidityCorrelations(from: sessions))

        correlations.append(contentsOf:
            analyzePressureCorrelations(from: sessions))

        correlations.append(contentsOf:
            analyzeCloudCoverCorrelations(from: sessions))

        correlations.append(contentsOf:
            analyzeVisibilityCorrelations(from: sessions))

        correlations.append(contentsOf:
            analyzeWindSpeedCorrelations(from: sessions))

        correlations.append(contentsOf:
            analyzeRainCorrelations(from: sessions))

        correlations.append(contentsOf:
            analyzeSnowCorrelations(from: sessions))

        correlations.append(contentsOf:
            analyzeStormCorrelations(from: sessions))

        return correlations.sorted {
            abs($0.influenceScore) > abs($1.influenceScore)
        }
    }

    // MARK: Weather Trend Report

    func generateTrendReport(
        sessions: [EnvironmentalSessionRecord]
    ) -> WeatherTrendReport {
        let correlations = analyzeCorrelations(
            from: sessions
        )

        let strongest = correlations
            .sorted {
                abs($0.influenceScore) >
                    abs($1.influenceScore)
            }
            .prefix(10)

        let sensitivity = calculateEnvironmentalSensitivity(
            correlations: correlations
        )

        let confidence = calculateAggregateConfidence(
            sessions: sessions,
            correlations: correlations
        )

        return WeatherTrendReport(
            generatedAt: Date(),
            correlations: correlations,
            strongestInfluences: Array(strongest),
            environmentalSensitivityScore: sensitivity,
            confidence: confidence
        )
    }

    // MARK: Environmental Report

    func generateBehaviorReport(
        sessions: [EnvironmentalSessionRecord]
    ) -> EnvironmentalBehaviorReport {
        let profile = buildEnvironmentalProfile(
            from: sessions
        )

        let correlations = analyzeCorrelations(
            from: sessions
        )

        let insights = generateInsights(
            sessions: sessions,
            profile: profile,
            correlations: correlations
        )

        let confidence = calculateAggregateConfidence(
            sessions: sessions,
            correlations: correlations
        )

        return EnvironmentalBehaviorReport(
            generatedAt: Date(),
            profile: profile,
            insights: insights,
            correlations: correlations,
            confidence: confidence
        )
    }
}

// MARK: - Temperature Analysis

private extension WeatherAnalysisEngine {
    func buildTemperatureProfile(
        from sessions: [EnvironmentalSessionRecord]
    ) -> TemperatureProfile? {
        guard sessions.count >= 10 else {
            return nil
        }

        let sorted = sessions.sorted {
            $0.readingSpeed > $1.readingSpeed
        }

        let topSessions = Array(
            sorted.prefix(max(1, sorted.count / 5))
        )

        let temps = topSessions.map {
            $0.weather.temperatureCelsius
        }

        guard let min = temps.min(),
              let max = temps.max()
        else {
            return nil
        }

        let avgSpeed = topSessions
            .map(\.readingSpeed)
            .average

        let avgEngagement = topSessions
            .map(\.engagementScore)
            .average

        let avgVolume = topSessions
            .map(\.pagesRead)
            .average

        let confidence = calculateConfidence(
            sampleCount: topSessions.count,
            recurrence: 0.8,
            stability: 0.7,
            consistency: 0.75
        )

        return TemperatureProfile(
            optimalRange: min ... max,
            peakReadingSpeed: avgSpeed,
            peakEngagement: avgEngagement,
            peakReadingVolume: avgVolume,
            influenceScore: confidence.overallConfidence,
            confidence: confidence
        )
    }
}

// MARK: - Seasonal Analysis

private extension WeatherAnalysisEngine {
    func buildSeasonalProfiles(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [SeasonalProfile] {
        var buckets: [SeasonalPeriod: SeasonalBucket] = [:]

        for season in SeasonalPeriod.allCases {
            buckets[season] = SeasonalBucket(
                season: season
            )
        }

        for session in sessions {
            var bucket = buckets[
                session.weather.season
            ] ?? SeasonalBucket(
                season: session.weather.season
            )

            bucket.sessionCount += 1
            bucket.totalDuration += session.readingDurationMinutes
            bucket.totalPages += session.pagesRead
            bucket.totalSpeed += session.readingSpeed
            bucket.totalEngagement += session.engagementScore

            if let genre = session.genre {
                bucket.genres[genre, default: 0] += 1
            }

            buckets[session.weather.season] = bucket
        }

        return buckets.values.compactMap { bucket in
            guard bucket.sessionCount > 0 else {
                return nil
            }

            let sortedGenres = bucket.genres
                .sorted {
                    $0.value > $1.value
                }

            let dominantGenres = sortedGenres
                .prefix(5)
                .map(\.key)

            let avoidedGenres = sortedGenres
                .suffix(3)
                .map(\.key)

            let confidence = calculateConfidence(
                sampleCount: bucket.sessionCount,
                recurrence: 0.8,
                stability: 0.8,
                consistency: 0.8
            )

            return SeasonalProfile(
                season: bucket.season,
                averageReadingDuration:
                bucket.totalDuration /
                    Double(bucket.sessionCount),
                averageReadingSpeed:
                bucket.totalSpeed /
                    Double(bucket.sessionCount),
                averageEngagement:
                bucket.totalEngagement /
                    Double(bucket.sessionCount),
                averagePagesRead:
                bucket.totalPages /
                    Double(bucket.sessionCount),
                dominantGenres: dominantGenres,
                avoidedGenres: avoidedGenres,
                confidence: confidence
            )
        }
        .sorted {
            $0.season.rawValue <
                $1.season.rawValue
        }
    }
}

// MARK: - Influence Profile

private extension WeatherAnalysisEngine {
    func buildInfluenceProfile(
        from sessions: [EnvironmentalSessionRecord]
    ) -> WeatherInfluenceProfile {
        let correlations = analyzeCorrelations(
            from: sessions
        )

        let strongestPositive = correlations
            .filter { $0.coefficient > 0 }
            .sorted {
                abs($0.coefficient) >
                    abs($1.coefficient)
            }
            .prefix(10)

        let strongestNegative = correlations
            .filter { $0.coefficient < 0 }
            .sorted {
                abs($0.coefficient) >
                    abs($1.coefficient)
            }
            .prefix(10)

        let confidence = calculateAggregateConfidence(
            sessions: sessions,
            correlations: correlations
        )

        let dominantSeason = determineDominantSeason(
            sessions: sessions
        )

        let dominantCondition = determineDominantCondition(
            sessions: sessions
        )

        return WeatherInfluenceProfile(
            strongestPositiveFactors:
            Array(strongestPositive),
            strongestNegativeFactors:
            Array(strongestNegative),
            environmentalSensitivityScore:
            calculateEnvironmentalSensitivity(
                correlations: correlations
            ),
            dominantSeason: dominantSeason,
            dominantCondition: dominantCondition,
            confidence: confidence
        )
    }
}

// MARK: - Correlation Analysis Core

private extension WeatherAnalysisEngine {
    // MARK: Temperature Correlations

    func analyzeTemperatureCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildCorrelation(
            sessions: sessions,
            factorExtractor: { $0.weather.temperatureCelsius },
            metricExtractor: { $0.readingSpeed },
            factor: .temperature,
            metric: .readingSpeed
        )
    }

    func analyzeHumidityCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildCorrelation(
            sessions: sessions,
            factorExtractor: { $0.weather.humidity },
            metricExtractor: { $0.engagementScore },
            factor: .humidity,
            metric: .engagement
        )
    }

    func analyzePressureCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildCorrelation(
            sessions: sessions,
            factorExtractor: { $0.weather.pressure },
            metricExtractor: { $0.consistencyScore },
            factor: .pressure,
            metric: .readingConsistency
        )
    }

    func analyzeCloudCoverCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildCorrelation(
            sessions: sessions,
            factorExtractor: { $0.weather.cloudCover },
            metricExtractor: { $0.engagementScore },
            factor: .cloudCover,
            metric: .engagement
        )
    }

    func analyzeVisibilityCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildCorrelation(
            sessions: sessions,
            factorExtractor: { $0.weather.visibilityKilometers },
            metricExtractor: { $0.readingDurationMinutes },
            factor: .visibility,
            metric: .readingDuration
        )
    }

    func analyzeWindSpeedCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildCorrelation(
            sessions: sessions,
            factorExtractor: { $0.weather.windSpeedKPH },
            metricExtractor: { $0.momentumScore },
            factor: .windSpeed,
            metric: .momentum
        )
    }

    func analyzeRainCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildBinaryConditionCorrelation(
            sessions: sessions,
            conditionExtractor: { $0.weather.precipitationMillimeters > 0 },
            metricExtractor: { $0.readingDurationMinutes },
            factor: .rain,
            metric: .readingDuration
        )
    }

    func analyzeSnowCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildBinaryConditionCorrelation(
            sessions: sessions,
            conditionExtractor: { $0.weather.snowfallMillimeters > 0 },
            metricExtractor: { $0.readingDurationMinutes },
            factor: .snow,
            metric: .readingDuration
        )
    }

    func analyzeStormCorrelations(
        from sessions: [EnvironmentalSessionRecord]
    ) -> [EnvironmentalCorrelation] {
        return buildCorrelation(
            sessions: sessions,
            factorExtractor: { $0.weather.stormActivityIndex },
            metricExtractor: { $0.engagementScore },
            factor: .stormActivity,
            metric: .engagement
        )
    }
}

// MARK: - Generic Correlation Engine

private extension WeatherAnalysisEngine {
    func buildCorrelation(
        sessions: [EnvironmentalSessionRecord],
        factorExtractor: (EnvironmentalSessionRecord) -> Double,
        metricExtractor: (EnvironmentalSessionRecord) -> Double,
        factor: EnvironmentalFactor,
        metric: ReadingBehaviorMetric
    ) -> [EnvironmentalCorrelation] {
        guard sessions.count >= 5 else { return [] }

        let pairs = sessions.map {
            (factorExtractor($0), metricExtractor($0), $0.timestamp)
        }

        let coefficient = pearsonCorrelation(pairs.map { $0.0 }, pairs.map { $0.1 })

        let significance = calculateSignificance(
            sampleSize: sessions.count,
            coefficient: coefficient
        )

        let influenceScore = abs(coefficient) * significance

        let lifecycle = determineLifecycle(
            coefficient: coefficient,
            significance: significance
        )

        let confidence = calculateConfidence(
            sampleCount: sessions.count,
            recurrence: significance,
            stability: abs(coefficient),
            consistency: averageConsistency(pairs)
        )

        return [
            EnvironmentalCorrelation(
                factor: factor,
                metric: metric,
                coefficient: coefficient,
                significance: significance,
                influenceScore: influenceScore,
                lifecycle: lifecycle,
                confidence: confidence,
                firstObserved: sessions.first?.timestamp ?? Date(),
                lastObserved: sessions.last?.timestamp ?? Date(),
                supportingSampleCount: sessions.count
            ),
        ]
    }

    func buildBinaryConditionCorrelation(
        sessions: [EnvironmentalSessionRecord],
        conditionExtractor: (EnvironmentalSessionRecord) -> Bool,
        metricExtractor: (EnvironmentalSessionRecord) -> Double,
        factor: EnvironmentalFactor,
        metric: ReadingBehaviorMetric
    ) -> [EnvironmentalCorrelation] {
        guard sessions.count >= 5 else { return [] }

        let trueGroup = sessions.filter(conditionExtractor)
        let falseGroup = sessions.filter { !conditionExtractor($0) }

        guard !trueGroup.isEmpty, !falseGroup.isEmpty else {
            return []
        }

        let trueAvg = trueGroup.map(metricExtractor).average
        let falseAvg = falseGroup.map(metricExtractor).average

        let coefficient = (trueAvg - falseAvg) / max(trueAvg + falseAvg, 0.0001)

        let significance = calculateSignificance(
            sampleSize: sessions.count,
            coefficient: coefficient
        )

        let influenceScore = abs(coefficient) * significance

        let confidence = calculateConfidence(
            sampleCount: sessions.count,
            recurrence: significance,
            stability: abs(coefficient),
            consistency: 0.7
        )

        return [
            EnvironmentalCorrelation(
                factor: factor,
                metric: metric,
                coefficient: coefficient,
                significance: significance,
                influenceScore: influenceScore,
                lifecycle: determineLifecycle(
                    coefficient: coefficient,
                    significance: significance
                ),
                confidence: confidence,
                firstObserved: sessions.first?.timestamp ?? Date(),
                lastObserved: sessions.last?.timestamp ?? Date(),
                supportingSampleCount: sessions.count
            ),
        ]
    }
}

// MARK: - Statistical Core

private extension WeatherAnalysisEngine {
    func pearsonCorrelation(
        _ x: [Double],
        _ y: [Double]
    ) -> Double {
        guard x.count == y.count,
              x.count > 1
        else { return 0 }

        let n = Double(x.count)

        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)

        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt(
            (n * sumX2 - sumX * sumX) *
                (n * sumY2 - sumY * sumY)
        )

        guard denominator != 0 else { return 0 }

        return numerator / denominator
    }

    func calculateSignificance(
        sampleSize: Int,
        coefficient: Double
    ) -> Double {
        let base = min(1.0, Double(sampleSize) / 50.0)
        let strength = abs(coefficient)

        return (base * 0.6) + (strength * 0.4)
    }

    func averageConsistency(
        _ values: [(Double, Double, Date)]
    ) -> Double {
        guard values.count > 2 else { return 0.5 }

        let diffs = zip(values, values.dropFirst()).map { a, b in
            abs(a.0 - b.0) + abs(a.1 - b.1)
        }

        let avg = diffs.average

        return 1.0 / (1.0 + avg)
    }

    func determineLifecycle(
        coefficient: Double,
        significance: Double
    ) -> CorrelationLifecycle {
        let strength = abs(coefficient)

        if significance < 0.2 {
            return .temporary
        }
        if strength > 0.8 && significance > 0.7 {
            return .persistent
        }
        if strength > 0.6 {
            return .strengthening
        }
        if strength > 0.4 {
            return .stable
        }
        if strength > 0.2 {
            return .weakening
        }

        return .emerging
    }
}

// MARK: - Utilities

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

private extension WeatherAnalysisEngine {
    func calculateConfidence(
        sampleCount: Int,
        recurrence: Double,
        stability: Double,
        consistency: Double
    ) -> ConfidenceReport {
        let sampleSizeScore = min(1.0, Double(sampleCount) / 100.0)

        let overall =
            (sampleSizeScore +
                recurrence +
                stability +
                consistency) / 4.0

        return ConfidenceReport(
            overallConfidence: overall,
            sampleSizeScore: sampleSizeScore,
            recurrenceScore: recurrence,
            stabilityScore: stability,
            consistencyScore: consistency,
            dataCoverageScore: 1.0,
            supportingSamples: sampleCount
        )
    }

    func calculateAggregateConfidence(
        sessions: [EnvironmentalSessionRecord],
        correlations _: [EnvironmentalCorrelation]
    ) -> ConfidenceReport {
        calculateConfidence(
            sampleCount: sessions.count,
            recurrence: 0.8,
            stability: 0.8,
            consistency: 0.8
        )
    }

    func calculateEnvironmentalSensitivity(
        correlations: [EnvironmentalCorrelation]
    ) -> Double {
        guard !correlations.isEmpty else { return 0 }

        return correlations
            .map { abs($0.coefficient) }
            .average
    }

    func determineDominantSeason(
        sessions: [EnvironmentalSessionRecord]
    ) -> SeasonalPeriod? {
        Dictionary(
            grouping: sessions,
            by: { $0.weather.season }
        )
        .max { $0.value.count < $1.value.count }?
        .key
    }

    func determineDominantCondition(
        sessions: [EnvironmentalSessionRecord]
    ) -> WeatherConditionCategory? {
        Dictionary(
            grouping: sessions,
            by: { $0.weather.condition }
        )
        .max { $0.value.count < $1.value.count }?
        .key
    }

    func generateInsights(
        sessions _: [EnvironmentalSessionRecord],
        profile _: EnvironmentalReadingProfile,
        correlations _: [EnvironmentalCorrelation]
    ) -> [EnvironmentalInsight] {
        return []
    }
}
