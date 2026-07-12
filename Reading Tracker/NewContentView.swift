//
//  NewContentView.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/29/26.
//

//
//  NewContentView.swift
//  Reading Tracker
//
//  CHANGES FROM PREVIOUS VERSION:
//
//  8. Five engine-backed feature panels are now reachable from the toolbar:
//       • "Analytics" menu  → Insights, Recommendations, Goals & Achievements,
//                             Session History
//       • "Discover Books"  → BookDiscoveryView (online search — already built)
//       • "Annual Reports"  → AnnualReportArchiveView (year-in-review — already built)
//
//  9. Achievement toast overlay: when DataStore publishes newly earned achievements,
//     a banner appears briefly at the top of the window then auto-dismisses.
//     Tapping the banner opens the full AchievementPanel.
//
// 10. GoalProgressViewModel injected via @EnvironmentObject so GoalsDashboard
//     receives live goal status updates throughout the app session.
//
//  All original functionality (hover estimation, book import, PDFReaderScreen,
//  EPUBReaderScreen, NavigationSplitView layout) is unchanged.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - HoverIntent (unchanged)

private enum HoverIntent {
    case ignore
    case interested
    case inspecting

    init(seconds: Double) {
        if seconds < 0.5 {
            self = .ignore
        } else if seconds < 1.5 {
            self = .interested
        } else {
            self = .inspecting
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var sessionCoordinator: SessionCoordinator
    @EnvironmentObject private var goalVM: GoalProgressViewModel
    @EnvironmentObject private var contextEngine: BehaviorContextEngine

    // Estimation state (unchanged)
    @State private var inspectedBook: Book?
    @State private var currentEstimation: BookEstimationResult?
    @State private var hoverWorkItem: DispatchWorkItem?
    @State private var importError: String?

    // ── Feature sheet presentation ─────────────────────────────────────────
    @State private var showInsights: Bool = false
    @State private var showRecommendations: Bool = false
    @State private var showGoals: Bool = false
    @State private var showAchievements: Bool = false
    @State private var showSessionHistory: Bool = false
    @State private var showDiscovery: Bool = false
    @State private var showAnnualReports: Bool = false
    @State private var showContextInsights: Bool = false
    @State private var showWeatherInsights: Bool = false

    // ── Achievement toast ──────────────────────────────────────────────────
    @State private var toastAchievement: EarnedAchievement?
    @State private var toastVisible: Bool = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(dataStore.books) { book in
                    NavigationLink {
                        if book.fileType == .pdf {
                            PDFReaderScreen(book: book, coordinator: sessionCoordinator)
                        } else {
                            EPUBReaderScreen(book: book, coordinator: sessionCoordinator)
                        }
                    } label: {
                        ContentBookRowView(book: book)
                            .onHover { hovering in
                                handleHover(hovering: hovering, book: book)
                            }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                // ── Existing: Add Book ─────────────────────────────────────
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addItem) {
                        Label("Add Book", systemImage: "plus")
                    }
                }

                // ── New: Analytics menu ────────────────────────────────────
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showInsights = true
                        } label: {
                            Label("Insights", systemImage: "lightbulb")
                        }

                        Button {
                            showRecommendations = true
                        } label: {
                            Label("What to Read Next", systemImage: "star.leadinghalf.filled")
                        }

                        Divider()

                        Button {
                            showGoals = true
                        } label: {
                            Label("Goals", systemImage: "target")
                        }

                        Button {
                            showAchievements = true
                        } label: {
                            Label("Achievements", systemImage: "medal")
                        }

                        Divider()

                        Button {
                            showSessionHistory = true
                        } label: {
                            Label("Session History", systemImage: "clock.arrow.circlepath")
                        }

                        Button {
                            showWeatherInsights = true
                        } label: {
                            Label("Environment", systemImage: "cloud.sun")
                        }

                        Button {
                            showContextInsights = true
                        } label: {
                            Label("Your Context", systemImage: "brain")
                        }

                    } label: {
                        Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                // ── New: Discover Books ────────────────────────────────────
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showDiscovery = true
                    } label: {
                        Label("Discover Books", systemImage: "books.vertical.fill")
                    }
                }

                // ── New: Annual Reports ────────────────────────────────────
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAnnualReports = true
                    } label: {
                        Label("Annual Reports", systemImage: "chart.bar.doc.horizontal")
                    }
                }
            }
        } detail: {
            if let book = inspectedBook, let estimation = currentEstimation {
                BookEstimationView(book: book, estimation: estimation)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Hover over a book to see reading estimates")
                        .foregroundColor(.secondary)
                }
            }
        }

        // ── Import error alert (unchanged) ─────────────────────────────────
        .alert("Import Failed", isPresented: Binding(
            get: { importError != nil },
            set: {
                if !$0 {
                    importError = nil
                }
            }
        )) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "")
        }

        // ── Feature sheets ─────────────────────────────────────────────────
        .sheet(isPresented: $showInsights) {
            ReadingInsightsDashboard()
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showRecommendations) {
            RecommendationPanel()
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showGoals) {
            GoalsDashboard()
                .environmentObject(goalVM)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementPanel()
                .environmentObject(dataStore)
                .onAppear { dataStore.clearNewAchievements() }
        }
        .sheet(isPresented: $showSessionHistory) {
            SessionHistoryView()
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showDiscovery) {
            BookDiscoveryView()
        }
        .sheet(isPresented: $showAnnualReports) {
            AnnualReportArchiveView()
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showContextInsights) {
            ContextInsightPanel()
                .environmentObject(contextEngine)
        }
        .sheet(isPresented: $showWeatherInsights) {
            WeatherInsightPanel()
                .environmentObject(dataStore)
        }

        // ── Achievement toast ──────────────────────────────────────────────
        .onReceive(dataStore.$newlyEarnedAchievements) { newly in
            guard let first = newly.first, !toastVisible else { return }
            toastAchievement = first
            withAnimation(.spring(duration: 0.4)) { toastVisible = true }
            // Auto-dismiss after 3.5 s
            Task {
                try? await Task.sleep(for: .seconds(3.5))
                withAnimation(.easeOut(duration: 0.3)) { toastVisible = false }
                try? await Task.sleep(for: .seconds(0.3))
                toastAchievement = nil
            }
        }
        .overlay(alignment: .top) {
            if toastVisible, let achievement = toastAchievement {
                AchievementToastView(achievement: achievement) {
                    // Tap opens the full achievements panel
                    withAnimation(.easeOut) { toastVisible = false }
                    showAchievements = true
                    dataStore.clearNewAchievements()
                }
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Hover Handling (unchanged)

    private func handleHover(hovering: Bool, book: Book) {
        if hovering {
            hoverWorkItem?.cancel()
            let workItem = DispatchWorkItem { [book] in
                let result = EstimationEngine.estimate(for: book, allBooks: dataStore.books)
                inspectedBook = book
                currentEstimation = EstimationEngine.validate(result: result)
            }
            hoverWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
        } else {
            hoverWorkItem?.cancel()
            hoverWorkItem = nil
        }
    }

    // MARK: - Toolbar: Add Book (unchanged)

    private func addItem() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, .epub]

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task {
                do {
                    let book = try await BookImporter.importBook(from: url)
                    await MainActor.run { dataStore.addBook(book) }
                } catch {
                    await MainActor.run { importError = error.localizedDescription }
                }
            }
        }
    }

    // MARK: - Delete (unchanged)

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                dataStore.removeBook(id: dataStore.books[index].id)
            }
        }
    }
}

// MARK: - ContentBookRowView (unchanged)

private struct ContentBookRowView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text(book.fileType.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
                if book.totalReadingTime > 0 {
                    Text(formatDuration(book.totalReadingTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Achievement Toast

private struct AchievementToastView: View {
    let achievement: EarnedAchievement
    let onTap: () -> Void

    private var definition: AchievementDefinition? {
        AchievementDefinition.definition(for: achievement.kind)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: definition?.symbolName ?? "medal.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievement Unlocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(definition?.title ?? achievement.kind.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

// MARK: - BookEstimationView (unchanged)

struct BookEstimationView: View {
    let book: Book
    let estimation: BookEstimationResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label("Time to Finish", systemImage: "clock")
                        .font(.headline)
                    Text(estimation.formattedRemaining)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(completionLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Per Reading Session", systemImage: "book.pages")
                        .font(.headline)
                    HStack(spacing: 32) {
                        statCell(
                            value: formatDuration(estimation.expectedSessionDuration),
                            label: "Expected duration"
                        )
                        statCell(
                            value: "\(Int(estimation.expectedPagesPerSession)) pages",
                            label: "Per session"
                        )
                    }
                }

                if !estimation.chapterEstimates.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Chapter Estimates", systemImage: "list.number")
                            .font(.headline)
                        ForEach(
                            Array(estimation.chapterEstimates.prefix(10).enumerated()),
                            id: \.element.chapterID
                        ) { index, chapter in
                            HStack {
                                Text("Chapter \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(chapter.pages) pg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(chapter.estimatedFormatted)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(minWidth: 50, alignment: .trailing)
                            }
                        }
                        if estimation.chapterEstimates.count > 10 {
                            Text("+ \(estimation.chapterEstimates.count - 10) more chapters")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("Prediction confidence", systemImage: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(confidenceLabel(estimation.confidence.level))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(confidenceColor(estimation.confidence.level))
                    }
                    if estimation.confidence.level == .low {
                        Text("Read more of this book to improve estimate accuracy.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }

    private var completionLabel: String {
        let days = estimation.estimatedDaysRemaining
        if days == 0 {
            return "Could finish today"
        }
        if days == 1 {
            return "Estimated completion tomorrow"
        }
        return "Estimated completion in \(days) days"
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3).fontWeight(.semibold)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }

    private func confidenceLabel(_ level: ConfidenceLevel) -> String {
        switch level {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(DataStore())
        .environmentObject(SessionCoordinator(dataStore: DataStore()))
        .environmentObject(GoalProgressViewModel())
        .environmentObject(BehaviorContextEngine())
}
