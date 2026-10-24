//  SentinelPaneView.swift
//  AsterismaV1.0 — DEVELOPER CONSOLE PANE
//
//  P6.5: the two-faced Sentinel browser Johan asked for.
//
//    LEFT FACE (extreme technical): every journal line as raw structured
//      data — timestamps, probe, rule, severity, outcome, full debugDetail,
//      plus a live "what ran" view of recentFindings with the exact
//      validator-style detail the probe captured.
//    RIGHT FACE (high layman): plain-English sentences generated from the
//      same entries ("Closed a reading session that was left open for 2+ days
//      on 'The Gilded Hour'"), grouped by what happened.
//
//  SECURITY (S4 restated): debugDetail may contain ids/paths and is shown
//  ONLY in this Debug-only console pane. The layman face renders exclusively
//  the static userSummary literals defined by probes.

#if DEBUG

import SwiftUI

struct SentinelPaneView: View {
    @ObservedObject private var engine = SentinelEngine.shared
    @EnvironmentObject private var dataStore: DataStore

    enum Face: String, CaseIterable, Identifiable {
        case technical = "Technical"
        case layman = "Plain English"
        var id: String { rawValue }
    }

    @State private var face: Face = .layman
    @State private var ruleFilter: String = "All"
    @State private var runningNow = false

    private var rules: [String] {
        var set = Set<String>(["All"])
        for f in engine.recentFindings { set.insert(f.rule) }
        return set.sorted()
    }

    private var filtered: [SentinelFinding] {
        ruleFilter == "All"
            ? engine.recentFindings
            : engine.recentFindings.filter { $0.rule == ruleFilter }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(ConsolePalette.border)

            controls
            Divider().overlay(ConsolePalette.border)

            Picker("", selection: $face) {
                ForEach(Face.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(10)

            switch face {
            case .technical: technicalFace
            case .layman: laymanFace
            }
        }
        .background(ConsolePalette.background)
        .onDisappear { /* keep engine running; this is just a viewport */ }
    }

    // MARK: Header + status

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(ConsolePalette.statusColor(.running))
                Text("Sentinel")
                    .font(.system(.title2, design: .monospaced).weight(.semibold))
                    .foregroundStyle(ConsolePalette.textPrimary)
                Spacer()
                Button {
                    runCycle()
                } label: {
                    Label("Run Probe Now", systemImage: "bolt.radiowaves.left.and.right")
                        .font(.system(.callout, design: .monospaced))
                }
                .buttonStyle(.borderedProminent)
                .disabled(runningNow)
            }

            HStack(spacing: 16) {
                metricChip("LAST RUN", lastRunText)
                metricChip("LIFETIME FIXED", "\(engine.lifetimeAutoFixed)")
                metricChip("AWAITING YOU", "\(engine.lifetimeStalled)")
                metricChip("PROBES", "\(probeCount)")
                if engine.allowsRepair {
                    Label("AUTO-REPAIR ON", systemImage: "wrench.and.screwdriver.fill")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(.green)
                } else {
                    Label("REPORT-ONLY MODE", systemImage: "eye")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lastRunText: String {
        guard let d = engine.lastRunDate else { return "never" }
        return d.formatted(date: .omitted, time: .standard)
    }

    /// Probe count mirrors the engine's registered list (names only).
    private var probeCount: Int { 8 } // matches default battery; keep in sync

    private func metricChip(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(.callout, design: .monospaced).weight(.bold))
                .foregroundStyle(ConsolePalette.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .tracking(1)
                .foregroundStyle(ConsolePalette.textSecondary)
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 12) {
            Picker("Rule", selection: $ruleFilter) {
                ForEach(rules, id: \.self) { Text($0).tag($0) }
            }
            .frame(width: 260)

            Spacer()

            if let url = engine.journalURL {
                Button {
                    NSWorkspace.shared.open(url.deletingLastPathComponent())
                } label: {
                    Label("Open Journal Folder", systemImage: "folder")
                        .font(.system(.caption, design: .monospaced))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: Technical face

    private var technicalFace: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if filtered.isEmpty {
                    emptyState("No findings recorded this session.\nRun a probe or wait for the next scheduled cycle.")
                }
                ForEach(filtered) { finding in
                    technicalRow(finding)
                }
            }
            .padding(12)
        }
    }

    private func technicalRow(_ f: SentinelFinding) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                outcomeBadge(f.outcome)
                Text(f.date.formatted(date: .omitted, time: .standard))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(ConsolePalette.textSecondary)
                Text("[\(f.severity.rawValue.uppercased())]")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(severityColor(f.severity))
                Text("\(f.probe).\(f.rule)")
                    .font(.system(.callout, design: .monospaced).weight(.semibold))
                    .textSelection(.enabled)
                Spacer()
            }

            Text(f.debugDetail)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(ConsolePalette.textSecondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(ConsolePalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(ConsolePalette.border, lineWidth: 1))
    }

    // MARK: Layman face

    private var laymanFace: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if filtered.isEmpty {
                    emptyState("Nothing to report — your library looks healthy.")
                }
                ForEach(Array(groupedByStory(filtered).enumerated()), id: \.offset) { _, story in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: story.isFix ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(story.isFix ? Color.green : Color.orange)
                            .font(.body)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(story.headline)
                                .font(.callout.weight(.medium))
                                .textSelection(.enabled)
                            if let when = story.when {
                                Text(when.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(ConsolePalette.textSecondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(ConsolePalette.panel))
                }
            }
            .padding(12)
        }
    }

    private struct Story {
        let headline: String
        let isFix: Bool
        let when: Date?
    }

    /// Collapses duplicate findings into one human sentence each,
    /// using ONLY the probe-authored static userSummary strings.
    private func groupedByStory(_ findings: [SentinelFinding]) -> [Story] {
        var counts: [String: (n: Int, fix: Bool, date: Date?, sample: String)] = [:]
        var order: [String] = []
        for f in findings {
            let key = f.userSummary + "|" + f.outcome.rawValue
            if counts[key] == nil {
                order.append(key)
                counts[key] = (1, f.outcome == .autoFixed, f.date, f.debugDetail)
            } else {
                counts[key]!.n += 1
            }
        }
        return order.map { key in
            let v = counts[key]!
            let base = key.split(separator: "|").first.map(String.init) ?? key
            let headline = v.n > 1 ? "\(base) (\(v.n) similar items)" : base
            return Story(headline: headline, isFix: v.fix, when: v.date)
        }
    }

    private func emptyState(_ text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkerboard")
                .font(.system(size: 34))
                .foregroundStyle(ConsolePalette.textSecondary)
            Text(text)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(ConsolePalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(30)
    }

    // MARK: Helpers

    private func outcomeBadge(_ outcome: SentinelFinding.Outcome) -> some View {
        let (text, color): (String, Color) = {
            switch outcome {
            case .autoFixed: return ("FIXED", .green)
            case .stalled: return ("NEEDS YOU", .orange)
            case .detected: return ("DETECTED", .yellow)
            }
        }()
        return Text(text)
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .tracking(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.18)))
            .overlay(Capsule().strokeBorder(color.opacity(0.45), lineWidth: 1))
            .foregroundStyle(color)
    }

    private func severityColor(_ s: SentinelFinding.Severity) -> Color {
        switch s {
        case .critical: return .red
        case .warning: return .orange
        case .info: return ConsolePalette.textSecondary
        }
    }

    @MainActor
    private func runCycle() {
        runningNow = true
        engine.runCycle()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            runningNow = false
        }
    }
}
#endif
