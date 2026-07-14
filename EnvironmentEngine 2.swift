//
//  EnvironmentEngine 2.swift
//  Environment Engine — Phase B (Parts 5.1, 5.3 of the build spec)
//
//  Computes and periodically republishes EnvironmentState.
//
//  Architecture note: Phase A confirmed every long-lived state object in
//  this codebase (DataStore, SessionCoordinator, GoalProgressViewModel,
//  SessionEventRouter, BehaviorContextAccessKit, BehaviorContextEngine in
//  ReadingTrackerApp.swift, and WeatherKitService itself) uses the classic
//  `ObservableObject` + `@Published` + `@MainActor` pattern, not the newer
//  `@Observable` macro. EnvironmentEngine follows that same convention
//  deliberately, for consistency with the rest of the app — this also
//  matches Part 5.1's own parenthetical ("EnvironmentEngine as an
//  ObservableObject that publishes it").
//
//  Per Part 5.1/5.3: no view anywhere in this feature reads Date() or
//  accessibility settings directly (AnchorClock.swift's comment documents
//  the one exception: this file's own `now` closure), and interpolation is
//  keyframe-based, recomputed on a slow (30-60s) cadence fully decoupled
//  from per-frame animation (stars/shooting stars tick on their own
//  TimelineView-driven cadence — see the Stars/ShootingStars folders).
//

import Combine
import AppKit
import SwiftUI

@MainActor
final class EnvironmentEngine: ObservableObject {

    @Published private(set) var state: EnvironmentState = .fallback

    private var recomputeTask: Task<Void, Never>?
    private let recomputeInterval: Duration
    private let calendar: Calendar
    private let now: () -> Date

    init(
        recomputeInterval: Duration = .seconds(45),
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.recomputeInterval = recomputeInterval
        self.calendar = calendar
        self.now = now
        recompute() // synchronous first value so the very first frame is already correct, not .fallback
    }

    /// Begins the periodic recomputation loop. Idempotent — safe to call
    /// from `.onAppear` even if a previous appearance already started it.
    func start() {
        guard recomputeTask == nil else { return }
        recomputeTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: self.recomputeInterval)
                guard !Task.isCancelled else { return }
                self.recompute()
            }
        }
    }

    func stop() {
        recomputeTask?.cancel()
        recomputeTask = nil
    }

    // Deliberately no deinit-based cancellation here: cancelling
    // actor-isolated state from `deinit` is not guaranteed to run on the
    // MainActor in Swift's concurrency model, and isn't needed for
    // correctness — the `[weak self]` capture above already lets the loop
    // exit gracefully (via `guard let self else { return }`) once this
    // object is deallocated; it just may take up to one more sleep interval
    // to notice, which is harmless for a 45s-cadence background loop.

    // MARK: - Core computation

    private func recompute() {
        let minute = AnchorClock.fractionalMinutesSinceMidnight(for: now(), calendar: calendar)
        let (paletteSnapshot, blend) = Self.interpolatedSnapshot(atMinute: minute)

        let weather = WeatherEnvironmentModifier.currentBestEffort(referenceDate: now())
        let weatherModified = weather.apply(to: paletteSnapshot)

        // Part 11: "When reducedTransparency is true, reduce blurIntensity
        // and atmosphericOpacity accordingly." Re-read every tick (same 45s
        // cadence as everything else in this function), never cached.
        let reducedTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        let modified = Self.applyingReducedTransparency(reducedTransparency, to: weatherModified)

        state = EnvironmentState(
            currentAnchorBlend: blend,
            backgroundGradient: modified.gradientStops,
            ambientLightColor: modified.ambientLightColor,
            shadowIntensity: modified.shadowIntensity,
            blurIntensity: modified.blurIntensity,
            atmosphericOpacity: modified.atmosphericOpacity,
            starVisibility: modified.starVisibility,
            nightIntensity: modified.nightIntensity,
            weatherModifier: weather,
            reducedMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            reducedTransparency: reducedTransparency
        )

    }

    /// Part 11's reduced-transparency reduction. Scales blurIntensity and
    /// atmosphericOpacity down to a quarter of their computed value rather
    /// than zeroing them — a small amount of atmosphere still reads as
    /// "this environment is alive," which is the point; reduced
    /// transparency asks for less translucency, not a flat, opaque scene.
    private static func applyingReducedTransparency(
        _ reducedTransparency: Bool,
        to snapshot: EnvironmentPaletteSnapshot
    ) -> EnvironmentPaletteSnapshot {
        guard reducedTransparency else { return snapshot }
        var result = snapshot
        result.blurIntensity = snapshot.blurIntensity * 0.25
        result.atmosphericOpacity = snapshot.atmosphericOpacity * 0.25
        return result
    }

    /// Walks EnvironmentPalette.keyframeTrack to find the two keyframes
    /// bracketing `minute`, eases the raw fraction between them, and blends
    /// every property using that eased fraction. This is the entire
    /// "which time-of-day state are we in" decision — no if/else time-range
    /// branching anywhere, per Part 5.3's explicit requirement.
    private static func interpolatedSnapshot(
        atMinute minute: Double
    ) -> (EnvironmentPaletteSnapshot, [EnvironmentAnchorPeriod: Double]) {
        let track = EnvironmentPalette.keyframeTrack

        var lowerIndex = 0
        for i in 0..<(track.count - 1) {
            if minute >= track[i].minute && minute <= track[i + 1].minute {
                lowerIndex = i
                break
            }
        }
        let lower = track[lowerIndex]
        let upper = track[lowerIndex + 1]

        let span = upper.minute - lower.minute
        let rawFraction = span > 0 ? (minute - lower.minute) / span : 0
        let eased = EnvironmentMath.smoothstep(rawFraction)

        let snapshot = EnvironmentPaletteSnapshot.blend(lower.snapshot, upper.snapshot, fraction: eased)
        let blend = anchorBlend(forSegmentStartingAt: lowerIndex, easedFraction: eased)
        return (snapshot, blend)
    }

    /// Maps a keyframe-track segment + eased fraction to named-period
    /// weights. The Midday crossing point (segment index 3, 12:00-13:00)
    /// gets a genuine brief peak — Morning fades to Midday across the first
    /// half of that hour, then Midday fades to Afternoon across the second
    /// half — rather than Midday never appearing with nonzero weight at all.
    private static func anchorBlend(
        forSegmentStartingAt lowerIndex: Int,
        easedFraction: Double
    ) -> [EnvironmentAnchorPeriod: Double] {
        switch lowerIndex {
        case 0, 6: // 00:00-05:45 and 19:45-24:00 — flat night
            return [.night: 1.0]
        case 1: // 05:45-06:00 — blend zone 1: night -> morning
            return [.night: 1 - easedFraction, .morning: easedFraction]
        case 2: // 06:00-12:00 — Morning's own window
            return [.morning: 1.0]
        case 3: // 12:00-13:00 — blend zone 2: the Midday crossing point
            if easedFraction < 0.5 {
                let local = EnvironmentMath.smoothstep(easedFraction * 2)
                return [.morning: 1 - local, .midday: local]
            } else {
                let local = EnvironmentMath.smoothstep((easedFraction - 0.5) * 2)
                return [.midday: 1 - local, .afternoon: local]
            }
        case 4: // 13:00-19:30 — Afternoon's own window
            return [.afternoon: 1.0]
        case 5: // 19:30-19:45 — blend zone 3: afternoon -> night
            return [.afternoon: 1 - easedFraction, .night: easedFraction]
        default:
            return [.night: 1.0]
        }
    }
}
