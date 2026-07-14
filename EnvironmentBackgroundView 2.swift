//
//  EnvironmentBackgroundView 2.swift
//  Environment Engine — Phase B-D composition (Part 12 of the build spec)
//
//  Composes the environment layers Part 12 describes, in order: gradient →
//  atmospheric effects → stars → shooting stars. Depth layers, the spatial
//  library, UI components, overlays, and the interaction layer come after
//  this in Part 12's pipeline, and belong to Phase F onward.
//
//  Deliberately NOT wired into NewContentView.swift / ContentView yet.
//  Part 15's session split point falls after Phase B/C/D/E and before
//  Phase F, and Part 12's "wire into the real root view" step is Phase K
//  work — which happens together with the Spatial Library (Part 9) once
//  that exists too, so the two get integrated in one pass instead of twice.
//  This view is self-contained and ready for that wiring.
//
//  Note on `blurIntensity`: Part 5.1 defines it as part of EnvironmentState
//  but the brief doesn't specify blurring the background/star art itself —
//  doing so would blur individual stars into fuzzy blobs, which reads as a
//  bug, not an effect. This view exposes `blurIntensity` for later
//  panel/material-level consumers (frosted UI chrome, Phase K+) to read
//  from `EnvironmentState` directly; it is intentionally NOT self-applied
//  here.
//

import SwiftUI

struct EnvironmentBackgroundView: View {
    @StateObject private var engine = EnvironmentEngine()
    @StateObject private var shootingStarManager = ShootingStarManager()
    @State private var starField = StarField(stars: [])
    @State private var lastStarFieldSize: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    stops: engine.state.backgroundGradient.map {
                        Gradient.Stop(color: $0.color.swiftUIColor, location: $0.location)
                    },
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Ambient edge glow — most visible at night (see
                // EnvironmentPalette.night's saturated navy ambientLightColor
                // against a near-black background), negligible during bright
                // daytime snapshots by construction, not by special-cased logic.
                RadialGradient(
                    colors: [engine.state.ambientLightColor.swiftUIColor.opacity(0.35), .clear],
                    center: .center,
                    startRadius: min(proxy.size.width, proxy.size.height) * 0.35,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.75
                )
                .blendMode(.plusLighter)

                // Atmospheric effects layer — a soft haze whose strength
                // tracks atmosphericOpacity. Weather's cloud-cover nudge
                // (Part 8) flows into this same value, so heavier cloud
                // cover reads as slightly hazier with no separate weather-
                // specific view.
                atmosphericHaze

                StarFieldView(
                    starField: starField,
                    starVisibility: engine.state.starVisibility,
                    reducedMotion: engine.state.reducedMotion
                )

                ShootingStarView(shootingStar: shootingStarManager.active)
            }
            // Part 11: ambient/atmospheric motion belongs "on the scale of
            // many seconds to minutes" — without this, each 45s recompute
            // tick would snap to its new values instead of drifting into
            // them, which is exactly the abrupt transition Appendix A says
            // should never be observable. Ambient drift is also explicitly
            // named in Part 11 as something to minimize under reduced
            // motion, so it collapses to a near-instant fade there instead.
            .animation(ambientAnimation, value: engine.state)
            .onAppear {
                regenerateStarFieldIfNeeded(for: proxy.size)
                engine.start()
                shootingStarManager.start(
                    starVisibility: { [weak engine] in engine?.state.starVisibility ?? 0 },
                    reducedMotion: { [weak engine] in engine?.state.reducedMotion ?? false }
                )
            }
            .onChange(of: proxy.size) { _, newSize in
                regenerateStarFieldIfNeeded(for: newSize)
            }
            .onDisappear {
                engine.stop()
                shootingStarManager.stop()
            }
        }
        .ignoresSafeArea()
    }

    private var atmosphericHaze: some View {
        engine.state.ambientLightColor.swiftUIColor
            .opacity(engine.state.atmosphericOpacity * 0.25)
            .blendMode(.softLight)
            .allowsHitTesting(false)
    }

    private var ambientAnimation: Animation {
        engine.state.reducedMotion ? .easeInOut(duration: 0.4) : .easeInOut(duration: 12)
    }

    private func regenerateStarFieldIfNeeded(for size: CGSize) {
        // Regenerate only on meaningful size changes, not every layout pass
        // — star positions are resolution-independent (fractional), so a
        // small resize doesn't need a new field, only a genuinely different
        // aspect/area does. This also keeps StarField.generate off the hot
        // path during ordinary window interaction.
        let widthDelta = abs(size.width - lastStarFieldSize.width)
        let heightDelta = abs(size.height - lastStarFieldSize.height)
        guard widthDelta > 40 || heightDelta > 40 || lastStarFieldSize == .zero else { return }
        starField = StarField.generate(for: size)
        lastStarFieldSize = size
        shootingStarManager.updateFieldSize(size)
    }
}
