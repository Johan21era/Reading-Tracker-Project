
//  NewYearTransitionMonitor.swift
//  Reading Tracker
//
//  Feature C: New Year Transition Celebration
//
//  SPECIFICATION
//  If an active reading session crosses midnight between December 31 and January 1:
//    1. Small notification (toast-style banner)
//    2. Expansion (brief intermediate state)
//    3. Full-screen presentation (10–15 seconds)
//  After completion: return directly to the active reading session.
//  Restore reading state, position, and active session without corruption.
//
//  VISUAL STYLE
//  Dark background. Subtle electric-blue mist. Snowflake-confetti particles.
//  Calm, reflective, elegant. Never loud, chaotic, or distracting.
//
//  INTEGRATION POINT
//  SessionCoordinator.activeBookID drives the "is reading" check.
//  The midnight monitor runs only while a session is active.
//  Attach NewYearTransitionMonitor as an @StateObject in the reading screen host.
//
//  SESSION SAFETY
//  The celebration does NOT call endSession / startSession.
//  It overlays the active reading view and removes itself automatically.
//  DataStore and SessionCoordinator state is untouched during the celebration.

import Combine
import SwiftUI

// MARK: - New Year Transition Monitor

/// Observes wall clock time during an active reading session.
/// Fires exactly once when midnight December 31 → January 1 occurs.
///
/// Usage:
///   @StateObject private var newYearMonitor = NewYearTransitionMonitor()
///
///   .onAppear { newYearMonitor.startMonitoring() }
///   .onDisappear { newYearMonitor.stopMonitoring() }
///   .overlay { if newYearMonitor.celebrationActive { NewYearCelebrationOverlay(...) } }
@MainActor
final class NewYearTransitionMonitor: ObservableObject {
    @Published private(set) var celebrationActive: Bool = false

    private var timer: Timer?
    private var hasFiredThisSession: Bool = false

    func startMonitoring() {
        stopMonitoring()
        // Check every 5 seconds — precise enough without burning CPU.
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkMidnight()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func dismissCelebration() {
        celebrationActive = false
        hasFiredThisSession = true // Don't re-trigger on same session
    }

    private func checkMidnight() {
        guard !hasFiredThisSession, !celebrationActive else { return }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.month, .day, .hour, .minute], from: now)

        // Trigger within the first 5 minutes of January 1
        guard components.month == 1,
              components.day == 1,
              components.hour == 0,
              let minute = components.minute, minute < 5 else { return }

        celebrationActive = true
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - New Year Celebration Overlay

/// Three-phase overlay that presents over the active reading session.
/// Phase 1: Toast (2 seconds)
/// Phase 2: Expansion (1.5 seconds)
/// Phase 3: Full screen (8–10 seconds)
/// After completion: auto-dismisses and returns to reading session.
struct NewYearCelebrationOverlay: View {
    let onComplete: () -> Void // Called when celebration ends; reading resumes

    @State private var phase: CelebrationPhase = .toast
    @State private var particles: [SnowParticle] = []
    @State private var phaseTimer: Timer?
    @State private var mistOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var scaleFactor: Double = 0.6
    @State private var overlayOpacity: Double = 0
    @State private var particleTimer: Timer?
    @State private var autoCompleteTimer: Timer?

    private enum CelebrationPhase {
        case toast, expanding, fullscreen, exiting
    }

    var body: some View {
        ZStack {
            switch phase {
            case .toast:
                toastView
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))

            case .expanding:
                expandingView
                    .transition(.opacity)

            case .fullscreen, .exiting:
                fullscreenView
                    .opacity(overlayOpacity)
            }
        }
        .onAppear(perform: startCelebration)
        .onDisappear(perform: cleanup)
    }

    // MARK: - Phase Views

    /// Phase 1: Toast — a gentle notification in the corner
    private var toastView: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Happy New Year")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("A new year of reading begins.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            Spacer()
        }
    }

    /// Phase 2: Expanding — intermediate fade toward fullscreen
    private var expandingView: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.9))
                Text("Happy New Year")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white)
            }
        }
    }

    /// Phase 3: Full screen — calm, elegant, immersive
    private var fullscreenView: some View {
        ZStack {
            // Background: deep navy-black
            Color(red: 0.04, green: 0.05, blue: 0.10)
                .ignoresSafeArea()

            // Electric-blue mist
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.18, green: 0.35, blue: 0.85).opacity(0.22 * mistOpacity),
                    Color.clear,
                ]),
                center: .center,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeIn(duration: 1.5)) { mistOpacity = 1 }
            }

            // Snowflake particles
            ForEach(particles) { particle in
                SnowflakeParticleView(particle: particle)
            }

            // Central content
            VStack(spacing: 32) {
                Spacer()

                Text(String(Calendar.current.component(.year, from: Date())))
                    .font(.system(size: 88, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(contentOpacity)
                    .scaleEffect(scaleFactor)

                VStack(spacing: 10) {
                    Text("A new year of reading begins.")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(contentOpacity)

                    Text("Keep reading — your session is still active.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.45))
                        .opacity(contentOpacity)
                }

                Spacer()

                // Subtle tap-to-continue
                Text("Tap to return to your book")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 32)
                    .opacity(contentOpacity)
            }
            .onTapGesture { beginExit() }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                contentOpacity = 1
                scaleFactor = 1.0
            }
        }
    }

    // MARK: - Celebration Sequence

    private func startCelebration() {
        // Phase 1: Toast — 2 seconds
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.6)) { self.phase = .expanding }

                // Phase 2: Expansion — 1.5 seconds
                self.phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    Task { @MainActor in
                        self.phase = .fullscreen
                        withAnimation(.easeIn(duration: 0.8)) {
                            self.overlayOpacity = 1
                        }
                        self.spawnParticles()

                        // Phase 3: Full screen — 10 seconds, then auto-exit
                        self.autoCompleteTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                            Task { @MainActor in self.beginExit() }
                        }
                    }
                }
            }
        }
    }

    private func beginExit() {
        autoCompleteTimer?.invalidate()
        phase = .exiting
        withAnimation(.easeOut(duration: 1.2)) {
            overlayOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            onComplete()
        }
    }

    private func cleanup() {
        phaseTimer?.invalidate()
        particleTimer?.invalidate()
        autoCompleteTimer?.invalidate()
    }

    // MARK: - Particle System

    private func spawnParticles() {
        // Initial burst
        particles = (0 ..< 40).map { _ in SnowParticle.random() }

        // Continuous trickle
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            Task { @MainActor in
                guard self.particles.count < 80 else { return }
                self.particles.append(SnowParticle.random())
                // Remove particles that have aged out
                self.particles = self.particles.filter { $0.birthTime.timeIntervalSinceNow > -12 }
            }
        }
    }
}

// MARK: - Snowflake Particle Model

struct SnowParticle: Identifiable {
    let id: UUID = .init()
    let x: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: Double // seconds to fall across screen
    let birthTime: Date = .init()
    let wobble: CGFloat // horizontal drift amplitude

    static func random() -> SnowParticle {
        SnowParticle(
            x: CGFloat.random(in: 0 ... 1),
            size: CGFloat.random(in: 6 ... 20),
            opacity: Double.random(in: 0.3 ... 0.85),
            speed: Double.random(in: 8 ... 18),
            wobble: CGFloat.random(in: -30 ... 30)
        )
    }
}

// MARK: - Snowflake Particle View

private struct SnowflakeParticleView: View {
    let particle: SnowParticle

    @State private var yOffset: CGFloat = -50
    @State private var xDrift: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        GeometryReader { geo in
            Image(systemName: ["snowflake", "star.fill", "asterisk"].randomElement()!)
                .font(.system(size: particle.size))
                .foregroundColor(Color(red: 0.65, green: 0.82, blue: 1.0).opacity(particle.opacity))
                .position(
                    x: geo.size.width * particle.x + xDrift,
                    y: yOffset
                )
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(
                        .linear(duration: particle.speed)
                            .repeatForever(autoreverses: false)
                    ) {
                        yOffset = geo.size.height + 60
                    }
                    withAnimation(
                        .easeInOut(duration: particle.speed * 0.4)
                            .repeatForever(autoreverses: true)
                    ) {
                        xDrift = particle.wobble
                    }
                    withAnimation(
                        .linear(duration: particle.speed * 0.6)
                            .repeatForever(autoreverses: false)
                    ) {
                        rotation = 360
                    }
                }
        }
    }
}

// MARK: - Reading Screen Integration

/// Modifier to attach the New Year transition monitor to any reading screen.
/// Apply to PDFReaderScreen or EPUBReaderScreen host view.
///
/// Usage:
///   SomeReaderView(...)
///       .newYearTransitionAware()
struct NewYearTransitionAwareModifier: ViewModifier {
    @StateObject private var monitor = NewYearTransitionMonitor()

    func body(content: Content) -> some View {
        content
            .onAppear { monitor.startMonitoring() }
            .onDisappear { monitor.stopMonitoring() }
            .overlay {
                if monitor.celebrationActive {
                    NewYearCelebrationOverlay {
                        monitor.dismissCelebration()
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: monitor.celebrationActive)
    }
}

extension View {
    /// Attaches the New Year midnight celebration to any reading screen.
    /// The overlay fires at most once per active session when the clock crosses midnight Dec 31 → Jan 1.
    func newYearTransitionAware() -> some View {
        modifier(NewYearTransitionAwareModifier())
    }
}
