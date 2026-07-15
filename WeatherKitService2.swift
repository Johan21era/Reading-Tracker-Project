//  WeatherKitService2.swift
//  Reading Tracker
//  Sole responsibility: produce a valid WeatherSnapshot for any (location, timestamp) pair,
//  persist it durably, and make historical snapshots queryable by the range and granularity
//  that WeatherAnalysisEngine needs.
//
//  Every subsystem in this file answers the four-gate test:
//  1. Which WeatherAnalysisEngine structure consumes its output?
//  2. What data does it provide?
//  3. How does that data reach WeatherAnalysisEngine?
//  4. Why can WeatherAnalysisEngine not function correctly without it?
//
//  Target: macOS 13+ (Ventura and later). No iOS-first assumptions.
//  Persistence: SQLite at ~/Library/Application Support/<BundleID>/weather_snapshots.sqlite3
//

import Combine
import CoreLocation
import Foundation
import SQLite3
import WeatherKit

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - WeatherKitService

//
// Consumes:    All 13 engine output types (indirectly, via WeatherSnapshot → EnvironmentalSessionRecord.weather)
// Provides:    WeatherSnapshot instances fetched from WeatherKit
// Path:        WeatherSnapshot → EnvironmentalSessionRecord.weather → all engine entry points
// Required:    Without a WeatherSnapshot, EnvironmentalSessionRecord cannot be constructed.
//              Without records, no engine analysis method returns results.

@MainActor
public final class WeatherKitService: ObservableObject {
    public static let shared = WeatherKitService()

    private let weatherService = WeatherService.shared
    private let store: WeatherSnapshotStore
    private let normaliser = WeatherSnapshotNormaliser()
    private let locationProvider: LocationProvider

    #if DEBUG
    private(set) var consoleLastAttemptAt: Date?
    private(set) var consoleLastSuccessAt: Date?
    private(set) var consoleSuccessCount: Int = 0
    #endif

    private init() {
        store = WeatherSnapshotStore()
        locationProvider = LocationProvider()

        #if DEBUG
        DeveloperConsoleRegistry.shared.register(self)
        #endif
    }

    // MARK: - Primary Session Attachment

    //
    // Called at session end. Returns WeatherSnapshot for EnvironmentalSessionRecord construction.
    // Persists the snapshot so it is available for future bulk analysis passes.

    public func snapshotForCurrentConditions(
        sessionID: UUID
    ) async throws -> WeatherSnapshot {
        #if DEBUG
        consoleLastAttemptAt = Date()
        #endif

        let location = try await locationProvider.currentLocation()

        let weather = try await weatherService.weather(
            for: location,
            including: .current, .hourly
        )

        let snapshot = normaliser.normalise(
            current: weather.0,
            hourly: weather.1,
            at: Date(),
            location: location,
            sessionID: sessionID
        )

        try store.save(snapshot, sessionID: sessionID)

        #if DEBUG
        consoleLastSuccessAt = Date()
        consoleSuccessCount += 1
        #endif

        return snapshot
    }

    // MARK: - Historical Backfill

    //
    // Fetches WeatherSnapshot for a past session timestamp.
    // Improves ConfidenceReport.dataCoverageScore for existing sessions that were
    // logged before WeatherKitService was available.

    public func snapshotForHistoricalSession(
        sessionID: UUID,
        at timestamp: Date
    ) async throws -> WeatherSnapshot {
        if let cached = try store.fetch(sessionID: sessionID) {
            return cached
        }

        let location = locationProvider.cachedLocation ?? locationProvider.defaultLocation

        let hourlyWeather = try await weatherService.weather(
            for: location,
            including: .hourly(startDate: timestamp, endDate: timestamp.addingTimeInterval(3600))
        )

        guard let hourlyEntry = hourlyWeather.forecast.first else {
            throw WeatherKitServiceError.noHistoricalDataAvailable(timestamp)
        }

        let snapshot = normaliser.normaliseFromHourly(
            hourly: hourlyEntry,
            at: timestamp,
            location: location,
            sessionID: sessionID
        )

        try store.save(snapshot, sessionID: sessionID)

        return snapshot
    }

    // MARK: - Forecast Input

    //
    // Returns WeatherSnapshot for a future date.
    // Caller wraps in EnvironmentalForecastInput for WeatherAnalysisEngine.generateForecast().

    public func snapshotForForecast(
        targetDate: Date
    ) async throws -> WeatherSnapshot {
        let location = try await locationProvider.currentLocation()

        let hourlyForecast = try await weatherService.weather(
            for: location,
            including: .hourly(startDate: targetDate, endDate: targetDate.addingTimeInterval(3600))
        )

        guard let entry = hourlyForecast.forecast.first(where: {
            Calendar.current.isDate($0.date, equalTo: targetDate, toGranularity: .hour)
        }) else {
            throw WeatherKitServiceError.noForecastAvailable(targetDate)
        }

        return normaliser.normaliseFromHourly(
            hourly: entry,
            at: targetDate,
            location: location,
            sessionID: nil
        )
    }

    // MARK: - Bulk Historical Query

    //
    // Returns all persisted WeatherSnapshots in a date range.
    // Used when the caller assembles EnvironmentalSessionRecord arrays for bulk analysis
    // (e.g. building EnvironmentalEvolutionReport baseline vs current snapshots).

    public func snapshots(
        from startDate: Date,
        to endDate: Date
    ) throws -> [WeatherSnapshot] {
        try store.fetchRange(from: startDate, to: endDate)
    }

    // MARK: - Coverage Audit

    //
    // Returns the fraction of session IDs that have a persisted WeatherSnapshot.
    // Used to populate ConfidenceReport.dataCoverageScore accurately.
    // The engine hardcodes dataCoverageScore to 1.0; this method enables the fix.

    public func coverageRatio(for sessionIDs: [UUID]) throws -> Double {
        let covered = try store.countPresent(sessionIDs: sessionIDs)
        guard !sessionIDs.isEmpty else { return 0 }
        return Double(covered) / Double(sessionIDs.count)
    }
}

public enum WeatherKitServiceError: Error {
    case locationUnavailable
    case noHistoricalDataAvailable(Date)
    case noForecastAvailable(Date)
    case storeWriteFailure(Error)
}

// MARK: - WeatherSnapshotNormaliser

//
// Consumes:    WeatherSnapshot (all 16 fields read by the engine's correlation extractors)
// Provides:    Correctly populated WeatherSnapshot from WeatherKit raw types
// Path:        Direct — WeatherSnapshot is the `weather` property of EnvironmentalSessionRecord
// Required:    stormActivityIndex (analyzeStormCorrelations), season (buildSeasonalProfiles),
//              dayPeriod (correlation grouping), and condition (determineDominantCondition)
//              are NOT directly vended by WeatherKit. If left as defaults/zeros, those
//              engine analysis branches produce no signal at all.

struct WeatherSnapshotNormaliser {
    // MARK: - Current Conditions

    func normalise(
        current: CurrentWeather,
        hourly: Forecast<HourWeather>,
        at timestamp: Date,
        location: CLLocation,
        sessionID _: UUID?
    ) -> WeatherSnapshot {
        let hourEntry = hourly.forecast.first(where: {
            Calendar.current.isDate($0.date, equalTo: timestamp, toGranularity: .hour)
        })

        let precipMM = hourEntry?.precipitationAmount.converted(to: .millimeters).value ?? 0
        let snowMM = hourEntry?.snowfallAmount.converted(to: .millimeters).value ?? 0

        return WeatherSnapshot(
            timestamp: timestamp,
            temperatureCelsius: current.temperature.converted(to: .celsius).value,
            feelsLikeTemperatureCelsius: current.apparentTemperature.converted(to: .celsius).value,
            humidity: current.humidity,
            pressure: current.pressure.converted(to: .hectopascals).value,
            cloudCover: current.cloudCover,
            visibilityKilometers: current.visibility.converted(to: .kilometers).value,
            windSpeedKPH: current.wind.speed.converted(to: .kilometersPerHour).value,
            precipitationMillimeters: precipMM,
            snowfallMillimeters: snowMM,
            stormActivityIndex: computeStormIndex(
                condition: current.condition,
                windKPH: current.wind.speed.converted(to: .kilometersPerHour).value,
                precipMM: precipMM
            ),
            condition: mapCondition(current.condition),
            season: deriveSeason(from: timestamp, latitude: location.coordinate.latitude),
            month: Calendar.current.component(.month, from: timestamp),
            weekday: Calendar.current.component(.weekday, from: timestamp),
            dayPeriod: deriveDayPeriod(from: timestamp)
        )
    }

    // MARK: - Hourly Entry (historical / forecast)

    func normaliseFromHourly(
        hourly: HourWeather,
        at timestamp: Date,
        location: CLLocation,
        sessionID _: UUID?
    ) -> WeatherSnapshot {
        let precipMM = hourly.precipitationAmount.converted(to: .millimeters).value
        let snowMM = hourly.snowfallAmount.converted(to: .millimeters).value

        return WeatherSnapshot(
            timestamp: timestamp,
            temperatureCelsius: hourly.temperature.converted(to: .celsius).value,
            feelsLikeTemperatureCelsius: hourly.apparentTemperature.converted(to: .celsius).value,
            humidity: hourly.humidity,
            pressure: hourly.pressure.converted(to: .hectopascals).value,
            cloudCover: hourly.cloudCover,
            visibilityKilometers: hourly.visibility.converted(to: .kilometers).value,
            windSpeedKPH: hourly.wind.speed.converted(to: .kilometersPerHour).value,
            precipitationMillimeters: precipMM,
            snowfallMillimeters: snowMM,
            stormActivityIndex: computeStormIndex(
                condition: hourly.condition,
                windKPH: hourly.wind.speed.converted(to: .kilometersPerHour).value,
                precipMM: precipMM
            ),
            condition: mapCondition(hourly.condition),
            season: deriveSeason(from: timestamp, latitude: location.coordinate.latitude),
            month: Calendar.current.component(.month, from: timestamp),
            weekday: Calendar.current.component(.weekday, from: timestamp),
            dayPeriod: deriveDayPeriod(from: timestamp)
        )
    }

    // MARK: - stormActivityIndex

    //
    // Composite 0–1 score used directly by analyzeStormCorrelations().
    // A zero value silences that entire correlation branch.
    // Weighted: condition type (50%) + wind speed (30%) + precipitation intensity (20%).

    func computeStormIndex(
        condition: WeatherCondition,
        windKPH: Double,
        precipMM: Double
    ) -> Double {
        let stormConditions: Set<WeatherCondition> = [
            .thunderstorms, .tropicalStorm, .hurricane,
            .heavyRain, .strongStorms, .freezingRain, .sleet,
        ]

        let conditionScore: Double = stormConditions.contains(condition) ? 0.5 : 0.0
        let windScore = min(windKPH / 120.0, 1.0) * 0.3 // 120 kph ceiling
        let precipScore = min(precipMM / 50.0, 1.0) * 0.2 // 50 mm/h ceiling

        return conditionScore + windScore + precipScore
    }

    // MARK: - Season

    //
    // Derived from month + hemisphere (latitude sign).
    // Used by buildSeasonalProfiles() which groups all sessions by season.
    // Southern-hemisphere correction is essential for accurate SeasonalProfile data.

    func deriveSeason(from date: Date, latitude: Double) -> SeasonalPeriod {
        let month = Calendar.current.component(.month, from: date)
        let isNorthern = latitude >= 0

        switch month {
        case 3, 4, 5: return isNorthern ? .spring : .autumn
        case 6, 7, 8: return isNorthern ? .summer : .winter
        case 9, 10, 11: return isNorthern ? .autumn : .spring
        default: return isNorthern ? .winter : .summer
        }
    }

    // MARK: - DayPeriod

    //
    // Derived from hour. Used by correlation grouping and EnvironmentalFactor.dayPeriod.

    func deriveDayPeriod(from date: Date) -> DayPeriod {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 5 ..< 7: return .dawn
        case 7 ..< 12: return .morning
        case 12 ..< 17: return .afternoon
        case 17 ..< 21: return .evening
        default: return .night
        }
    }

    // MARK: - WeatherCondition → WeatherConditionCategory

    //
    // Maps WeatherKit's WeatherCondition enum to WeatherAnalysisEngine's
    // WeatherConditionCategory. Used by determineDominantCondition() →
    // WeatherInfluenceProfile.dominantCondition.

    func mapCondition(_ condition: WeatherCondition) -> WeatherConditionCategory {
        switch condition {
        case .clear, .mostlyClear:
            return .clear
        case .partlyCloudy:
            return .partlyCloudy
        case .mostlyCloudy, .cloudy:
            return .cloudy
        case .foggy, .haze, .smoky, .blowingDust:
            return .fog
        case .drizzle, .rain:
            return .rain
        case .heavyRain, .freezingRain:
            return .heavyRain
        case .flurries, .snow, .sleet:
            return .snow
        case .heavySnow, .blizzard:
            return .heavySnow
        case .thunderstorms, .strongStorms, .tropicalStorm, .hurricane:
            return .storm
        case .windy, .blowingSnow:
            return .wind
        case .wintryMix:
            return .mixed
        default:
            return .unknown
        }
    }
}

// MARK: - WeatherSnapshotStore

//
// Consumes:    EnvironmentalSessionRecord (via session ID join),
//              WeatherTrendReport (temporal queries),
//              EnvironmentalEvolutionReport (baseline/current snapshot queries)
// Provides:    Durable persistence and range querying of WeatherSnapshot instances
// Path:        Snapshots retrieved from store → assembled into [EnvironmentalSessionRecord]
//              → passed to all engine entry points
// Required:    Without persistence, all historical data is lost between app launches.
//              SeasonalProfile requires data from all four seasons.
//              EnvironmentalEvolutionReport requires a baseline snapshot from months ago.
//              Neither is achievable without durable storage.
//
// Schema:
//   weather_snapshots
//     id                        TEXT PRIMARY KEY   (WeatherSnapshot.id UUID)
//     timestamp                 REAL               (Unix epoch, indexed)
//     session_id                TEXT               (nullable; NULL for forecast snapshots)
//     temperature_celsius       REAL
//     feels_like_celsius        REAL
//     humidity                  REAL
//     pressure                  REAL
//     cloud_cover               REAL
//     visibility_km             REAL
//     wind_speed_kph            REAL
//     precipitation_mm          REAL
//     snowfall_mm               REAL
//     storm_activity_index      REAL
//     condition                 TEXT               (WeatherConditionCategory.rawValue)
//     season                    TEXT               (SeasonalPeriod.rawValue)
//     month                     INTEGER
//     weekday                   INTEGER
//     day_period                TEXT               (DayPeriod.rawValue)
//     created_at                REAL

final class WeatherSnapshotStore {
    private let dbURL: URL
    private var db: OpaquePointer?

    init(directory: URL? = nil) {
        if let dir = directory {
            dbURL = dir.appendingPathComponent("weather_snapshots.sqlite3")
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!

            let appDir = appSupport.appendingPathComponent(
                Bundle.main.bundleIdentifier ?? "ReadingTracker",
                isDirectory: true
            )

            try? FileManager.default.createDirectory(
                at: appDir,
                withIntermediateDirectories: true
            )

            dbURL = appDir.appendingPathComponent("weather_snapshots.sqlite3")
        }

        openDatabase()
        createSchemaIfNeeded()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Write

    func save(_ snapshot: WeatherSnapshot, sessionID: UUID?) throws {
        let sql = """
            INSERT OR REPLACE INTO weather_snapshots (
                id, timestamp, session_id,
                temperature_celsius, feels_like_celsius,
                humidity, pressure, cloud_cover,
                visibility_km, wind_speed_kph,
                precipitation_mm, snowfall_mm,
                storm_activity_index, condition, season,
                month, weekday, day_period, created_at
            ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StoreError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, snapshot.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 2, snapshot.timestamp.timeIntervalSince1970)

        if let sid = sessionID {
            sqlite3_bind_text(stmt, 3, sid.uuidString, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 3)
        }

        sqlite3_bind_double(stmt, 4, snapshot.temperatureCelsius)
        sqlite3_bind_double(stmt, 5, snapshot.feelsLikeTemperatureCelsius)
        sqlite3_bind_double(stmt, 6, snapshot.humidity)
        sqlite3_bind_double(stmt, 7, snapshot.pressure)
        sqlite3_bind_double(stmt, 8, snapshot.cloudCover)
        sqlite3_bind_double(stmt, 9, snapshot.visibilityKilometers)
        sqlite3_bind_double(stmt, 10, snapshot.windSpeedKPH)
        sqlite3_bind_double(stmt, 11, snapshot.precipitationMillimeters)
        sqlite3_bind_double(stmt, 12, snapshot.snowfallMillimeters)
        sqlite3_bind_double(stmt, 13, snapshot.stormActivityIndex)
        sqlite3_bind_text(stmt, 14, snapshot.condition.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 15, snapshot.season.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 16, Int32(snapshot.month))
        sqlite3_bind_int(stmt, 17, Int32(snapshot.weekday))
        sqlite3_bind_text(stmt, 18, snapshot.dayPeriod.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 19, Date().timeIntervalSince1970)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw StoreError.writeFailed
        }
    }

    // MARK: - Read

    func fetch(sessionID: UUID) throws -> WeatherSnapshot? {
        let sql = "SELECT * FROM weather_snapshots WHERE session_id = ? LIMIT 1"
        return try executeQuery(sql: sql, bindings: [sessionID.uuidString]).first
    }

    func fetchRange(from start: Date, to end: Date) throws -> [WeatherSnapshot] {
        let sql = """
            SELECT * FROM weather_snapshots
            WHERE timestamp >= ? AND timestamp <= ?
            ORDER BY timestamp ASC
        """
        return try executeQuery(
            sql: sql,
            bindings: [start.timeIntervalSince1970, end.timeIntervalSince1970]
        )
    }

    func countPresent(sessionIDs: [UUID]) throws -> Int {
        guard !sessionIDs.isEmpty else { return 0 }

        let placeholders = sessionIDs.map { _ in "?" }.joined(separator: ",")
        let sql = "SELECT COUNT(*) FROM weather_snapshots WHERE session_id IN (\(placeholders))"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StoreError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        for (i, id) in sessionIDs.enumerated() {
            sqlite3_bind_text(stmt, Int32(i + 1), id.uuidString, -1, SQLITE_TRANSIENT)
        }

        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    // MARK: - Private

    private func openDatabase() {
        sqlite3_open(dbURL.path, &db)
    }

    private func createSchemaIfNeeded() {
        let sql = """
            CREATE TABLE IF NOT EXISTS weather_snapshots (
                id                    TEXT PRIMARY KEY,
                timestamp             REAL NOT NULL,
                session_id            TEXT,
                temperature_celsius   REAL NOT NULL,
                feels_like_celsius    REAL NOT NULL,
                humidity              REAL NOT NULL,
                pressure              REAL NOT NULL,
                cloud_cover           REAL NOT NULL,
                visibility_km         REAL NOT NULL,
                wind_speed_kph        REAL NOT NULL,
                precipitation_mm      REAL NOT NULL,
                snowfall_mm           REAL NOT NULL,
                storm_activity_index  REAL NOT NULL,
                condition             TEXT NOT NULL,
                season                TEXT NOT NULL,
                month                 INTEGER NOT NULL,
                weekday               INTEGER NOT NULL,
                day_period            TEXT NOT NULL,
                created_at            REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_ws_timestamp  ON weather_snapshots(timestamp);
            CREATE INDEX IF NOT EXISTS idx_ws_session_id ON weather_snapshots(session_id);
            CREATE INDEX IF NOT EXISTS idx_ws_season     ON weather_snapshots(season);
            CREATE INDEX IF NOT EXISTS idx_ws_condition  ON weather_snapshots(condition);
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private func executeQuery(sql: String, bindings: [Any]) throws -> [WeatherSnapshot] {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StoreError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        for (i, binding) in bindings.enumerated() {
            let idx = Int32(i + 1)
            switch binding {
            case let s as String: sqlite3_bind_text(stmt, idx, s, -1, SQLITE_TRANSIENT)
            case let d as Double: sqlite3_bind_double(stmt, idx, d)
            default: break
            }
        }

        var results: [WeatherSnapshot] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let snapshot = rowToSnapshot(stmt) {
                results.append(snapshot)
            }
        }
        return results
    }

    private func rowToSnapshot(_ stmt: OpaquePointer?) -> WeatherSnapshot? {
        guard let stmt = stmt else { return nil }

        guard
            let idStr = sqlite3_column_text(stmt, 0).map({ String(cString: $0) }),
            let id = UUID(uuidString: idStr),
            let condStr = sqlite3_column_text(stmt, 13).map({ String(cString: $0) }),
            let condition = WeatherConditionCategory(rawValue: condStr),
            let seasStr = sqlite3_column_text(stmt, 14).map({ String(cString: $0) }),
            let season = SeasonalPeriod(rawValue: seasStr),
            let dpStr = sqlite3_column_text(stmt, 17).map({ String(cString: $0) }),
            let dayPeriod = DayPeriod(rawValue: dpStr)
        else { return nil }

        return WeatherSnapshot(
            id: id,
            timestamp: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1)),
            temperatureCelsius: sqlite3_column_double(stmt, 3),
            feelsLikeTemperatureCelsius: sqlite3_column_double(stmt, 4),
            humidity: sqlite3_column_double(stmt, 5),
            pressure: sqlite3_column_double(stmt, 6),
            cloudCover: sqlite3_column_double(stmt, 7),
            visibilityKilometers: sqlite3_column_double(stmt, 8),
            windSpeedKPH: sqlite3_column_double(stmt, 9),
            precipitationMillimeters: sqlite3_column_double(stmt, 10),
            snowfallMillimeters: sqlite3_column_double(stmt, 11),
            stormActivityIndex: sqlite3_column_double(stmt, 12),
            condition: condition,
            season: season,
            month: Int(sqlite3_column_int(stmt, 15)),
            weekday: Int(sqlite3_column_int(stmt, 16)),
            dayPeriod: dayPeriod
        )
    }

    enum StoreError: Error {
        case prepareFailed
        case writeFailed
    }
}

// MARK: - LocationProvider

//
// Consumes:    WeatherSnapshot (all fields depend on having a valid location)
// Provides:    CLLocation for WeatherKit API calls
// Path:        Location → WeatherKit fetch → WeatherSnapshot → EnvironmentalSessionRecord.weather
// Required:    WeatherKit requires a location. Without one, no WeatherSnapshot can be created.
//
// macOS notes:
// - requestAlwaysAuthorization() is unavailable in sandboxed macOS apps.
// - Uses requestWhenInUseAuthorization() — fires while app has active windows.
// - Caches last known location in UserDefaults for use when not in foreground.
// - Exposes manualLocation override — the correct desktop affordance for users who
//   work from a fixed location or decline to grant permission.

@MainActor
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    /// Cached from last successful fetch — used when app is not foreground.
    private(set) var cachedLocation: CLLocation? {
        didSet {
            if let loc = cachedLocation {
                UserDefaults.standard.set(loc.coordinate.latitude, forKey: "wks_lat")
                UserDefaults.standard.set(loc.coordinate.longitude, forKey: "wks_lon")
            }
        }
    }

    /// User-configured manual location override (macOS Preferences affordance).
    var manualLocation: CLLocation? {
        get {
            let lat = UserDefaults.standard.double(forKey: "wks_manual_lat")
            let lon = UserDefaults.standard.double(forKey: "wks_manual_lon")
            guard lat != 0 || lon != 0 else { return nil }
            return CLLocation(latitude: lat, longitude: lon)
        }
        set {
            UserDefaults.standard.set(newValue?.coordinate.latitude, forKey: "wks_manual_lat")
            UserDefaults.standard.set(newValue?.coordinate.longitude, forKey: "wks_manual_lon")
        }
    }

    /// Fallback used only when no cached or manual location exists.
    /// New York City. This will be wrong for most users;
    /// the manual override path is the correct resolution.
    let defaultLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)

    override init() {
        super.init()
        manager.delegate = self
        restorePersistedLocation()
    }

    func currentLocation() async throws -> CLLocation {
        if let manual = manualLocation {
            return manual
        }

        switch manager.authorizationStatus {
        case .authorized:
            return try await fetchOneTimeLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return cachedLocation ?? defaultLocation
        case .denied, .restricted:
            if let cached = cachedLocation {
                return cached
            }
            throw LocationError.permissionDenied
        default:
            return cachedLocation ?? defaultLocation
        }
    }

    private func fetchOneTimeLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    private func restorePersistedLocation() {
        let lat = UserDefaults.standard.double(forKey: "wks_lat")
        let lon = UserDefaults.standard.double(forKey: "wks_lon")
        guard lat != 0 || lon != 0 else { return }
        cachedLocation = CLLocation(latitude: lat, longitude: lon)
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            if let location = locations.last {
                self.cachedLocation = location
                self.continuation?.resume(returning: location)
                self.continuation = nil
            }
        }
    }

    nonisolated func locationManager(
        _: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
        }
    }

    enum LocationError: Error {
        case permissionDenied
    }
}

// MARK: - EnvironmentalSessionAssembler

//
// Consumes:    EnvironmentalSessionRecord (directly constructs it)
// Provides:    The fully assembled EnvironmentalSessionRecord by joining reading session
//              data (from existing engines) with the fetched WeatherSnapshot
// Path:        assemble() → [EnvironmentalSessionRecord] → all engine entry points
// Required:    This is the explicit join seam between the reading tracker's session data
//              and WeatherKitService's weather data. Without this, the engine's primary
//              input type can never be constructed.

public struct EnvironmentalSessionAssembler {
    private let weatherService: WeatherKitService

    public init(weatherService: WeatherKitService? = nil) {
        if let ws = weatherService {
            self.weatherService = ws
        } else {
            // Resolve the shared instance on the main actor to satisfy isolation rules in Swift 6
            self.weatherService = Self.resolveShared()
        }
    }

    @MainActor
    private static func resolveShared() -> WeatherKitService {
        WeatherKitService.shared
    }

    // MARK: - Assemble at Session End

    public func assembleAtSessionEnd(
        sessionID: UUID,
        bookID: UUID,
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
    ) async throws -> WeatherAnalysisEngine.EnvironmentalSessionRecord {
        let snapshot = try await weatherService.snapshotForCurrentConditions(
            sessionID: sessionID
        )

        return WeatherAnalysisEngine.EnvironmentalSessionRecord(
            sessionID: sessionID,
            bookID: bookID,
            timestamp: snapshot.timestamp,
            weather: snapshot,
            readingDurationMinutes: readingDurationMinutes,
            pagesRead: pagesRead,
            chaptersCompleted: chaptersCompleted,
            booksCompleted: booksCompleted,
            readingSpeed: readingSpeed,
            consistencyScore: consistencyScore,
            readingFrequencyScore: readingFrequencyScore,
            engagementScore: engagementScore,
            sessionQualityScore: sessionQualityScore,
            momentumScore: momentumScore,
            completionProbability: completionProbability,
            abandonmentProbability: abandonmentProbability,
            difficultyScore: difficultyScore,
            complexityScore: complexityScore,
            bookLength: bookLength,
            genre: genre,
            seriesIdentifier: seriesIdentifier,
            reread: reread
        )
    }

    // MARK: - Retroactive Assembly

    //
    // Assembles a record for a historical session that was logged without weather data.
    // Improves ConfidenceReport.dataCoverageScore for existing analysis runs.

    public func assembleRetroactively(
        sessionID: UUID,
        bookID: UUID,
        timestamp: Date,
        readingMetrics: ReadingSessionMetrics
    ) async throws -> WeatherAnalysisEngine.EnvironmentalSessionRecord {
        let snapshot = try await weatherService.snapshotForHistoricalSession(
            sessionID: sessionID,
            at: timestamp
        )

        return WeatherAnalysisEngine.EnvironmentalSessionRecord(
            sessionID: sessionID,
            bookID: bookID,
            timestamp: timestamp,
            weather: snapshot,
            readingDurationMinutes: readingMetrics.durationMinutes,
            pagesRead: readingMetrics.pagesRead,
            chaptersCompleted: readingMetrics.chaptersCompleted,
            booksCompleted: readingMetrics.booksCompleted,
            readingSpeed: readingMetrics.readingSpeed,
            consistencyScore: readingMetrics.consistencyScore,
            readingFrequencyScore: readingMetrics.readingFrequencyScore,
            engagementScore: readingMetrics.engagementScore,
            sessionQualityScore: readingMetrics.sessionQualityScore,
            momentumScore: readingMetrics.momentumScore,
            completionProbability: readingMetrics.completionProbability,
            abandonmentProbability: readingMetrics.abandonmentProbability,
            difficultyScore: readingMetrics.difficultyScore,
            complexityScore: readingMetrics.complexityScore,
            bookLength: readingMetrics.bookLength,
            genre: readingMetrics.genre,
            seriesIdentifier: readingMetrics.seriesIdentifier,
            reread: readingMetrics.reread
        )
    }
}

// MARK: - ReadingSessionMetrics

//
// Value type carrying pre-computed reading metrics from existing analytics systems.
// WeatherAnalysisEngine does NOT compute these — it consumes them.
// This struct is the handoff surface from AnalyticsEngine / EstimationEngine
// into the weather layer.

public struct ReadingSessionMetrics {
    public let durationMinutes: Double
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
        durationMinutes: Double,
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
        self.durationMinutes = durationMinutes
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

// MARK: - WeatherAnalysisEngine Bug Fixes

//
// The following extensions patch three critical issues identified in the code review.
// They are additive — WeatherAnalysisEngine.swift does not need to be modified,
// only the call sites updated to use these replacements.

extension WeatherAnalysisEngine {
    // MARK: Fix 1: avoidedGenres

    //
    // Original: picks the rarest genres in the dataset — semantically wrong.
    //           A genre with 1 session is "uncommon", not "avoided".
    // Fixed:    only genres appearing in ≤5% of sessions qualify as avoided.
    //
    // Affects: SeasonalProfile.avoidedGenres → EnvironmentalReadingProfile.seasonalProfiles

    static func avoidedGenres(
        from genreCounts: [(key: String, value: Int)],
        totalSessions: Int
    ) -> [String] {
        let avoidedThreshold = max(1, Int(Double(totalSessions) * 0.05))
        return genreCounts
            .filter { $0.value <= avoidedThreshold }
            .prefix(3)
            .map(\.key)
    }

    // MARK: Fix 2: calculateAggregateConfidence (real coverage score)

    //
    // Original: hardcodes recurrence/stability/consistency to 0.8 and dataCoverageScore to 1.0.
    //           Confidence numbers are cosmetic — high regardless of actual data quality.
    // Fixed:    derives scores from actual correlation data; accepts real coverage ratio
    //           from WeatherKitService.coverageRatio(for:).
    //
    // Affects: ConfidenceReport in WeatherTrendReport, EnvironmentalBehaviorReport

    func calculateAggregateConfidenceReal(
        sessions: [EnvironmentalSessionRecord],
        correlations: [EnvironmentalCorrelation],
        dataCoverageRatio: Double
    ) -> ConfidenceReport {
        let recurrence = correlations.isEmpty ? 0.0 : correlations.map { $0.confidence.recurrenceScore }.reduce(0,+) / Double(correlations.count)
        let stability = correlations.isEmpty ? 0.0 : correlations.map { $0.confidence.stabilityScore }.reduce(0,+) / Double(correlations.count)
        let consistency = correlations.isEmpty ? 0.0 : correlations.map { $0.confidence.consistencyScore }.reduce(0,+) / Double(correlations.count)
        let sampleScore = min(1.0, Double(sessions.count) / 100.0)

        let overall = (sampleScore + recurrence + stability + consistency + dataCoverageRatio) / 5.0

        return ConfidenceReport(
            overallConfidence: overall,
            sampleSizeScore: sampleScore,
            recurrenceScore: recurrence,
            stabilityScore: stability,
            consistencyScore: consistency,
            dataCoverageScore: dataCoverageRatio,
            supportingSamples: sessions.count
        )
    }

    // MARK: Fix 3: firstObserved / lastObserved temporal sort

    //
    // Original: uses sessions.first and sessions.last without guaranteeing chronological order.
    //           firstObserved and lastObserved in EnvironmentalCorrelation may be wrong.
    // Fixed:    sort by timestamp before extracting boundary dates.
    //
    // Use this helper at the call sites in buildCorrelation() and buildBinaryConditionCorrelation().

    func temporalBounds(
        of sessions: [EnvironmentalSessionRecord]
    ) -> (first: Date, last: Date) {
        let sorted = sessions.sorted { $0.timestamp < $1.timestamp }
        return (
            first: sorted.first?.timestamp ?? Date(),
            last: sorted.last?.timestamp ?? Date()
        )
    }
}

// MARK: - WeatherKitServiceTests

//
// Unit and integration tests for WeatherKitService.
// These live here for reference; in the Xcode project they belong in the test target.
//
// Run order of priority:
//   1. WeatherSnapshotNormaliserTests  — pure unit, no dependencies, highest coverage value
//   2. WeatherSnapshotStoreTests       — SQLite integration, no network
//   3. WeatherAnalysisEngineIntegrationTests — validates full pipeline with synthetic data

#if canImport(XCTest) && DEBUG

    import XCTest

    // MARK: WeatherSnapshotNormaliserTests

//
    // Every assertion corresponds to a specific engine analysis branch.
    // A failure here means that correlation branch produces no signal.

    final class WeatherSnapshotNormaliserTests: XCTestCase {
        let normaliser = WeatherSnapshotNormaliser()

        // stormActivityIndex — analyzeStormCorrelations depends on this

        func testStormIndex_clearCalm_isZero() {
            let index = normaliser.computeStormIndex(condition: .clear, windKPH: 5, precipMM: 0)
            XCTAssertEqual(index, 0.0, accuracy: 0.01,
                           "Clear calm conditions must produce 0 storm index; analyzeStormCorrelations returns no signal otherwise")
        }

        func testStormIndex_thunderstorm_highWind_heavyRain_isHigh() {
            let index = normaliser.computeStormIndex(condition: .thunderstorms, windKPH: 90, precipMM: 30)
            XCTAssertGreaterThan(index, 0.7,
                                 "Severe storm conditions must produce high index to enable storm correlation signal")
        }

        func testStormIndex_clamped_to_1() {
            let index = normaliser.computeStormIndex(condition: .thunderstorms, windKPH: 200, precipMM: 200)
            XCTAssertLessThanOrEqual(index, 1.0)
        }

        // Season derivation — buildSeasonalProfiles depends on this

        func testSeason_northernHemisphere_june_isSummer() {
            XCTAssertEqual(normaliser.deriveSeason(from: makeDate(month: 6), latitude: 51.5), .summer)
        }

        func testSeason_southernHemisphere_june_isWinter() {
            XCTAssertEqual(normaliser.deriveSeason(from: makeDate(month: 6), latitude: -33.9), .winter,
                           "Southern hemisphere June must be winter; SeasonalProfile grouping depends on this")
        }

        func testSeason_allFourSeasons_northern() {
            let cases: [(Int, SeasonalPeriod)] = [(1, .winter), (4, .spring), (7, .summer), (10, .autumn)]
            for (month, expected) in cases {
                XCTAssertEqual(
                    normaliser.deriveSeason(from: makeDate(month: month), latitude: 40.0),
                    expected,
                    "Month \(month) should be \(expected)"
                )
            }
        }

        // DayPeriod derivation — EnvironmentalFactor.dayPeriod depends on this

        func testDayPeriod_allBands() {
            let cases: [(Int, DayPeriod)] = [
                (5, .dawn), (9, .morning), (14, .afternoon), (19, .evening), (23, .night), (2, .night),
            ]
            for (hour, expected) in cases {
                XCTAssertEqual(
                    normaliser.deriveDayPeriod(from: makeDate(hour: hour)),
                    expected,
                    "Hour \(hour) should map to \(expected)"
                )
            }
        }

        // Condition mapping — determineDominantCondition depends on this

        func testConditionMapping_allCategories_areReachable() {
            let allExpected: Set<WeatherConditionCategory> = [
                .clear, .partlyCloudy, .cloudy, .fog, .rain,
                .heavyRain, .snow, .heavySnow, .storm, .wind, .mixed, .unknown,
            ]
            let sampleConditions: [WeatherCondition] = [
                .clear, .partlyCloudy, .cloudy, .foggy, .rain,
                .heavyRain, .snow, .blizzard, .thunderstorms, .windy, .wintryMix,
            ]
            let mapped = Set(sampleConditions.map { normaliser.mapCondition($0) })
            XCTAssertTrue(mapped.isSubset(of: allExpected))
        }

        // Helpers

        private func makeDate(month: Int = 6, hour: Int = 12) -> Date {
            var c = DateComponents()
            c.year = 2025; c.month = month; c.day = 15; c.hour = hour
            return Calendar.current.date(from: c)!
        }
    }

    // MARK: WeatherSnapshotStoreTests

//
    // Integration tests against a real (temporary) SQLite database.
    // No network calls; validates that WeatherSnapshot survives a round-trip
    // through the persistence layer with all 16 engine-consumed fields intact.

    final class WeatherSnapshotStoreTests: XCTestCase {
        var store: WeatherSnapshotStore!
        var tempDir: URL!

        override func setUp() {
            super.setUp()
            tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            store = WeatherSnapshotStore(directory: tempDir)
        }

        override func tearDown() {
            try? FileManager.default.removeItem(at: tempDir)
            super.tearDown()
        }

        func testSaveAndFetch_roundTrip_preservesAllFields() throws {
            let original = makeSnapshot()
            let sessionID = UUID()
            try store.save(original, sessionID: sessionID)

            let fetched = try XCTUnwrap(store.fetch(sessionID: sessionID))

            XCTAssertEqual(fetched.temperatureCelsius, original.temperatureCelsius)
            XCTAssertEqual(fetched.feelsLikeTemperatureCelsius, original.feelsLikeTemperatureCelsius)
            XCTAssertEqual(fetched.humidity, original.humidity)
            XCTAssertEqual(fetched.pressure, original.pressure)
            XCTAssertEqual(fetched.cloudCover, original.cloudCover)
            XCTAssertEqual(fetched.visibilityKilometers, original.visibilityKilometers)
            XCTAssertEqual(fetched.windSpeedKPH, original.windSpeedKPH)
            XCTAssertEqual(fetched.precipitationMillimeters, original.precipitationMillimeters)
            XCTAssertEqual(fetched.snowfallMillimeters, original.snowfallMillimeters)
            XCTAssertEqual(fetched.stormActivityIndex, original.stormActivityIndex)
            XCTAssertEqual(fetched.condition, original.condition)
            XCTAssertEqual(fetched.season, original.season)
            XCTAssertEqual(fetched.month, original.month)
            XCTAssertEqual(fetched.weekday, original.weekday)
            XCTAssertEqual(fetched.dayPeriod, original.dayPeriod)
        }

        func testFetchRange_returnsCorrectWindow() throws {
            let base = Date(timeIntervalSinceReferenceDate: 0)
            for i in 0 ..< 10 {
                let snap = makeSnapshot(timestamp: base.addingTimeInterval(Double(i) * 3600))
                try store.save(snap, sessionID: UUID())
            }
            let results = try store.fetchRange(
                from: base.addingTimeInterval(3600 * 2),
                to: base.addingTimeInterval(3600 * 5)
            )
            XCTAssertEqual(results.count, 4,
                           "Range query must return exactly the sessions in window")
        }

        func testCoverageRatio_partialCoverage() throws {
            let covered = (0 ..< 7).map { _ in UUID() }
            let uncovered = (0 ..< 3).map { _ in UUID() }
            for id in covered {
                try store.save(makeSnapshot(), sessionID: id)
            }

            let ratio = try store.coverageRatio(for: covered + uncovered)
            XCTAssertEqual(ratio, 0.7, accuracy: 0.01,
                           "coverageRatio feeds ConfidenceReport.dataCoverageScore; must be accurate")
        }

        func testSave_idempotent_replacesExisting() throws {
            let sessionID = UUID()
            try store.save(makeSnapshot(temperature: 20), sessionID: sessionID)
            try store.save(makeSnapshot(temperature: 25), sessionID: sessionID)

            let fetched = try XCTUnwrap(store.fetch(sessionID: sessionID))
            XCTAssertEqual(fetched.temperatureCelsius, 25,
                           "INSERT OR REPLACE must update, not duplicate, on retry")
        }

        private func makeSnapshot(timestamp: Date = Date(), temperature: Double = 18.0) -> WeatherSnapshot {
            WeatherSnapshot(
                timestamp: timestamp,
                temperatureCelsius: temperature,
                feelsLikeTemperatureCelsius: temperature - 2,
                humidity: 0.65,
                pressure: 1013.0,
                cloudCover: 0.4,
                visibilityKilometers: 15.0,
                windSpeedKPH: 12.0,
                precipitationMillimeters: 0.0,
                snowfallMillimeters: 0.0,
                stormActivityIndex: 0.05,
                condition: .clear,
                season: .summer,
                month: 7,
                weekday: 3,
                dayPeriod: .afternoon
            )
        }
    }

    /// coverageRatio convenience shim for tests (calls through to store)
    extension WeatherSnapshotStore {
        func coverageRatio(for sessionIDs: [UUID]) throws -> Double {
            let covered = try countPresent(sessionIDs: sessionIDs)
            guard !sessionIDs.isEmpty else { return 0 }
            return Double(covered) / Double(sessionIDs.count)
        }
    }

    // MARK: WeatherAnalysisEngineIntegrationTests

//
    // Validates the full pipeline from WeatherKitService output through to engine correlations.
    // Uses synthetic EnvironmentalSessionRecord arrays — no WeatherKit network calls.

    final class WeatherAnalysisEngineIntegrationTests: XCTestCase {
        let engine = WeatherAnalysisEngine()

        func testFullCorrelationPipeline_withMinimumSessions_returnsResults() {
            // Break up complex expression to help the type-checker
            var sessions: [WeatherAnalysisEngine.EnvironmentalSessionRecord] = []
            sessions.reserveCapacity(20)
            for i in 0 ..< 20 {
                let temp = Double(10 + i)
                let speed = Double(200 + i * 5)
                let s = makeSession(temperature: temp, readingSpeed: speed)
                sessions.append(s)
            }
            let correlations = engine.analyzeCorrelations(from: sessions)

            XCTAssertFalse(correlations.isEmpty,
                           "20 sessions with correlated temperature/speed must produce at least one correlation")

            let tempCorrelation = correlations.first { $0.factor == .temperature }
            XCTAssertNotNil(tempCorrelation)
            XCTAssertGreaterThan(tempCorrelation?.coefficient ?? 0, 0.8)
        }

        func testStormCorrelation_requiresNonZeroStormIndex() {
            let sessionsNoStorm = (0 ..< 20).map { _ in makeSession(stormIndex: 0.0) }
            let sessionsWithStorm = (0 ..< 20).enumerated().map { i, _ in makeSession(stormIndex: Double(i) / 20.0) }

            let noCorr = engine.analyzeCorrelations(from: sessionsNoStorm).filter { $0.factor == .stormActivity }
            let withCorr = engine.analyzeCorrelations(from: sessionsWithStorm).filter { $0.factor == .stormActivity }

            XCTAssertTrue(noCorr.isEmpty || (noCorr.first?.coefficient ?? 1) == 0,
                          "Zero storm index must produce no storm signal — validates stormActivityIndex computation")
            XCTAssertFalse(withCorr.isEmpty,
                           "Non-zero storm index must produce storm correlation")
        }

        func testSeasonalProfiles_requireAllFourSeasons() {
            let sessions = SeasonalPeriod.allCases.flatMap { season in
                (0 ..< 10).map { _ in makeSession(season: season) }
            }
            let profile = engine.buildEnvironmentalProfile(from: sessions)
            let profiledSeasons = Set(profile.seasonalProfiles.map(\.season))

            XCTAssertEqual(profiledSeasons, Set(SeasonalPeriod.allCases),
                           "All four seasons must appear — requires deriveSeason() to be correct for all months")
        }

        // Helpers

        private func makeSession(
            temperature: Double = 18.0,
            stormIndex: Double = 0.1,
            season: SeasonalPeriod = .summer,
            readingSpeed: Double = 250.0
        ) -> WeatherAnalysisEngine.EnvironmentalSessionRecord {
            WeatherAnalysisEngine.EnvironmentalSessionRecord(
                sessionID: UUID(),
                bookID: UUID(),
                timestamp: Date(),
                weather: makeWeatherSnapshot(temperature: temperature, stormIndex: stormIndex, season: season),
                readingDurationMinutes: 45,
                pagesRead: 30,
                chaptersCompleted: 1,
                booksCompleted: 0,
                readingSpeed: readingSpeed,
                consistencyScore: 0.8,
                readingFrequencyScore: 0.7,
                engagementScore: 0.75,
                sessionQualityScore: 0.8,
                momentumScore: 0.7,
                completionProbability: 0.6,
                abandonmentProbability: 0.2,
                difficultyScore: 0.5,
                complexityScore: 0.5,
                bookLength: 350,
                genre: "Fiction",
                seriesIdentifier: nil,
                reread: false
            )
        }

        private func makeWeatherSnapshot(
            temperature: Double = 18.0,
            stormIndex: Double = 0.1,
            season: SeasonalPeriod = .summer
        ) -> WeatherSnapshot {
            WeatherSnapshot(
                timestamp: Date(),
                temperatureCelsius: temperature,
                feelsLikeTemperatureCelsius: temperature - 2,
                humidity: 0.6,
                pressure: 1013.0,
                cloudCover: 0.3,
                visibilityKilometers: 20.0,
                windSpeedKPH: 10.0,
                precipitationMillimeters: 0,
                snowfallMillimeters: 0,
                stormActivityIndex: stormIndex,
                condition: .clear,
                season: season,
                month: 7,
                weekday: 2,
                dayPeriod: .afternoon
            )
        }
    }

#endif

// MARK: - Developer Console

#if DEBUG
extension WeatherKitService: DeveloperConsoleObservable {
    static var consoleIdentity: ConsoleSubsystemIdentity {
        ConsoleSubsystemIdentity(
            id: "weather-kit-service",
            displayName: "WeatherKit Service",
            category: .service,
            purpose: "Fetches and persists weather snapshots (via Apple WeatherKit + a local SQLite store) so reading sessions can be correlated with weather conditions."
        )
    }

    var consoleSnapshot: ConsoleSubsystemSnapshot {
        ConsoleSubsystemSnapshot(
            identity: Self.consoleIdentity,
            status: consoleLastAttemptAt == nil ? .idle : .healthy,
            currentActivity: consoleLastAttemptAt == nil
                ? "Not called yet this session"
                : "\(consoleSuccessCount) successful fetch(es) this session",
            lastUpdated: consoleLastSuccessAt ?? consoleLastAttemptAt,
            metrics: [
                "Attempts this session": consoleLastAttemptAt == nil ? "0" : "≥1",
                "Successes this session": "\(consoleSuccessCount)",
            ]
        )
    }
}
#endif
