//  DeveloperConsoleRootView.swift
//  Reading Tracker
//
//  DEVELOPER CONSOLE — Phase 1 (Foundation)
//
//  The console's own separate navigation shell. This is intentionally NOT
//  content pushed into the existing ContentView (NewContentView.swift) — it
//  is the root view of its own separate SwiftUI `Window` scene, wired in
//  ReadingTrackerApp.swift. That is what makes "opened and closed without
//  any change to existing view hierarchies or navigation state" true by
//  construction rather than by care: there is no shared state to accidentally
//  disturb, because there is no shared view tree at all.
//
//  Visual language is deliberately distinct from the app's consumer-facing
//  design (see NewContentView.swift's .regularMaterial / SF Symbols style):
//  dark background, monospaced numerics, dense layout — so it is always
//  obvious which "mode" is on screen, per the contract's requirement.
//

#if DEBUG

import SwiftUI

// MARK: - Window identity

/// Stable id for the console's Window scene. Kept as a single constant so
/// ReadingTrackerApp.swift's Window(id:) declaration and the openWindow(id:)
/// call site can never drift apart from each other.
enum DeveloperConsoleWindowID {
    static let id = "developer-console"
}

// MARK: - DeveloperConsoleSection

/// Every section the console will eventually have, per the contract's 15
/// phases. Only `.dashboard` is live this session (Phase 2). The rest are
/// listed now, disabled, so the sidebar honestly previews the console's full
/// planned shape instead of hiding it — and so later phases only ever need
/// to flip `isAvailable`, never restructure this list or the views that
/// read it.
enum DeveloperConsoleSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case subsystemExplorer
    case eventTimeline
    case stateInspector
    case dependencyGraph
    case architectureExplorer
    case performanceCenter
    case errorCenter
    case featureUsage
    case deadCode
    case internalSearch
    case learningMode
    case exportSnapshot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .subsystemExplorer: return "Subsystem Explorer"
        case .eventTimeline: return "Live Event Timeline"
        case .stateInspector: return "Current State Inspector"
        case .dependencyGraph: return "Dependency Graph"
        case .architectureExplorer: return "Architecture Explorer"
        case .performanceCenter: return "Performance Center"
        case .errorCenter: return "Error Center"
        case .featureUsage: return "Feature Usage Explorer"
        case .deadCode: return "Dead Code Analysis"
        case .internalSearch: return "Internal Search"
        case .learningMode: return "Learning Mode"
        case .exportSnapshot: return "Export & Continuity"
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: return "gauge.medium"
        case .subsystemExplorer: return "square.stack.3d.up"
        case .eventTimeline: return "clock.arrow.circlepath"
        case .stateInspector: return "eye"
        case .dependencyGraph: return "point.3.connected.trianglepath.dotted"
        case .architectureExplorer: return "building.columns"
        case .performanceCenter: return "speedometer"
        case .errorCenter: return "exclamationmark.triangle"
        case .featureUsage: return "chart.bar"
        case .deadCode: return "trash"
        case .internalSearch: return "magnifyingglass"
        case .learningMode: return "book"
        case .exportSnapshot: return "square.and.arrow.up"
        }
    }

    /// Phase 2 only, this session. Every other section is a real, named
    /// destination on the roadmap — shown, not hidden — but disabled until
    /// its own phase is built, so the console never claims to show live
    /// data it does not actually have yet.
    var isAvailable: Bool {
        self == .dashboard
    }

    var plannedPhaseLabel: String {
        switch self {
        case .dashboard: return "Phase 2"
        case .subsystemExplorer: return "Phase 3"
        case .eventTimeline: return "Phase 5"
        case .stateInspector: return "Phase 6"
        case .dependencyGraph: return "Phase 7"
        case .architectureExplorer: return "Phase 8"
        case .performanceCenter: return "Phase 9"
        case .errorCenter: return "Phase 10"
        case .featureUsage: return "Phase 11"
        case .deadCode: return "Phase 12"
        case .internalSearch: return "Phase 13"
        case .learningMode: return "Phase 14"
        case .exportSnapshot: return "Phase 15"
        }
    }
}

// MARK: - ConsolePalette

/// Deliberately separate from the app's own color system (EnvironmentColor,
/// EnvironmentPalette, etc.) — the console must never depend on, or be
/// affected by, anything in the consumer-facing app's visual state (e.g.
/// the current time-of-day Environment Engine theme). A diagnostic tool
/// that itself depends on the thing it diagnoses is a design smell.
enum ConsolePalette {
    static let background = Color(red: 0.07, green: 0.08, blue: 0.09)
    static let panel = Color(red: 0.11, green: 0.12, blue: 0.135)
    static let border = Color(red: 0.22, green: 0.24, blue: 0.26)
    static let textPrimary = Color(red: 0.90, green: 0.92, blue: 0.93)
    static let textSecondary = Color(red: 0.58, green: 0.62, blue: 0.65)

    static func statusColor(_ status: ConsoleSubsystemStatus) -> Color {
        switch status {
        case .healthy: return Color(red: 0.30, green: 0.78, blue: 0.45)
        case .running: return Color(red: 0.35, green: 0.60, blue: 0.95)
        case .idle: return Color(red: 0.55, green: 0.58, blue: 0.62)
        case .initializing: return Color(red: 0.65, green: 0.55, blue: 0.95)
        case .warning: return Color(red: 0.95, green: 0.70, blue: 0.20)
        case .error: return Color(red: 0.92, green: 0.35, blue: 0.35)
        case .unavailable: return Color(red: 0.40, green: 0.42, blue: 0.45)
        }
    }

    /// For the "not yet instrumented" empty-slot state, which is distinct
    /// from all seven real statuses (see DeveloperConsoleTypes.swift) —
    /// deliberately a flat, muted dot so it never reads as "fine".
    static let notInstrumented = Color(red: 0.35, green: 0.36, blue: 0.38)
}

// MARK: - DeveloperConsoleRootView

struct DeveloperConsoleRootView: View {
    @State private var selectedSection: DeveloperConsoleSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .background(ConsolePalette.background)
        .preferredColorScheme(.dark)
        .navigationTitle("Developer Console")
    }

    private var sidebar: some View {
        List(selection: $selectedSection) {
            Section {
                ForEach(DeveloperConsoleSection.allCases) { section in
                    sidebarRow(section)
                        .tag(section)
                }
            } header: {
                Text("READING TRACKER — INTERNAL")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(ConsolePalette.textSecondary)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(ConsolePalette.panel)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240)
    }

    private func sidebarRow(_ section: DeveloperConsoleSection) -> some View {
        HStack {
            Image(systemName: section.symbolName)
                .frame(width: 18)
            Text(section.displayName)
                .font(.system(.body, design: .monospaced))
            Spacer()
            if !section.isAvailable {
                Text(section.plannedPhaseLabel)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(ConsolePalette.textSecondary)
            }
        }
        .foregroundStyle(
            section.isAvailable
                ? ConsolePalette.textPrimary
                : ConsolePalette.textSecondary.opacity(0.7)
        )
    }

    @ViewBuilder
    private var detail: some View {
        if let section = selectedSection, section != .dashboard {
            comingSoon(section)
        } else {
            DeveloperConsoleDashboardView()
        }
    }

    private func comingSoon(_ section: DeveloperConsoleSection) -> some View {
        VStack(spacing: 12) {
            Image(systemName: section.symbolName)
                .font(.system(size: 40))
                .foregroundStyle(ConsolePalette.textSecondary)
            Text(section.displayName)
                .font(.system(.title2, design: .monospaced))
                .foregroundStyle(ConsolePalette.textPrimary)
            Text("Not built yet — planned for \(section.plannedPhaseLabel) of the Developer Console contract.")
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(ConsolePalette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ConsolePalette.background)
    }
}

#endif
