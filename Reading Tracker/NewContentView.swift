//
//  NewContentView.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/15/26.
//
//  CHANGES FROM ORIGINAL:
//
//  1. EstimationEngine is now wired up (was dead code).
//     Hovering over a book for 1.5s shows full reading time estimates
//     (time to finish, per-session breakdown, chapter-by-chapter, confidence)
//     in the detail pane — the core feature the app was designed around.
//
//  2. HoverIntent enum replaces the stringly-typed "INSPECTING"/"INTERESTED"/"IGNORE"
//     state machine. The free function hoverLevel() at the bottom of the file is removed.
//
//  3. @State var selectedBook removed — it was declared but never read or written
//     anywhere that affected the UI. Replaced with @State var inspectedBook which
//     actually drives the detail pane.
//
//  4. All print() / emoji debug logging removed (F13).
//     Import errors now surface via @State var importError + .alert() instead
//     of printing to the console and silently failing.
//
//  5. Hover now triggers while the user is still hovering (after 1.5s),
//     not only when they move the cursor away — better UX for the estimation panel.
//
//  6. Book row label extracted into BookRowView (keeps body readable).
//
//  7. BookEstimationView added — renders the EstimationEngine output in the
//     detail pane with time-to-finish, session breakdown, chapter list, confidence.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - HoverIntent
// Replaces the stringly-typed "INSPECTING" / "INTERESTED" / "IGNORE" system (F9).
// Using an enum means the compiler catches typos and exhaustive switch is enforced.

private enum HoverIntent {
    case ignore       // < 0.5 s — accidental mouse pass
    case interested   // 0.5 – 1.5 s — user paused
    case inspecting   // ≥ 1.5 s — user wants detail

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

    /// The book whose estimation is currently shown in the detail pane.
    /// Replaces the unused @State var selectedBook.
    @State private var inspectedBook: Book?
    @State private var currentEstimation: BookEstimationResult?

    /// Fires after 1.5 s of hover to show estimation while the cursor is still over the row.
    @State private var hoverWorkItem: DispatchWorkItem?

    /// Surfaces import failures to the user via an alert instead of print().
    @State private var importError: String?

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
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Book", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let book = inspectedBook, let estimation = currentEstimation {
                // EstimationEngine output — the core hover feature
                BookEstimationView(book: book, estimation: estimation)
            } else {
                // Placeholder shown before any book is hovered
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Hover over a book to see reading estimates")
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("Import Failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    // MARK: - Hover Handling

    private func handleHover(hovering: Bool, book: Book) {
        if hovering {
            // Cancel any pending work from a previous hover
            hoverWorkItem?.cancel()

            // After 1.5 s of sustained hover → run the estimation and show it
            let workItem = DispatchWorkItem { [book] in
                let result = EstimationEngine.estimate(for: book, allBooks: dataStore.books)
                inspectedBook = book
                currentEstimation = EstimationEngine.validate(result: result)
            }
            hoverWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)

        } else {
            // Cursor left the row — cancel the pending estimation if it hasn't fired yet
            hoverWorkItem?.cancel()
            hoverWorkItem = nil
        }
    }

    // MARK: - Toolbar: Add Book

    private func addItem() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories   = false
        panel.canChooseFiles         = true
        panel.allowedContentTypes    = [.pdf, .epub]

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task {
                do {
                    let book = try await BookImporter.importBook(from: url)
                    await MainActor.run {
                        dataStore.addBook(book)
                    }
                } catch {
                    await MainActor.run {
                        importError = error.localizedDescription
                    }
                }
            }
        }
    }

    // MARK: - Delete

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                dataStore.removeBook(id: dataStore.books[index].id)
            }
        }
    }
}

// MARK: - ContentBookRowView
// Extracted from ContentView.body to keep the list readable.

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

// MARK: - BookEstimationView
// Renders EstimationEngine output in the detail pane.
// Shown when the user hovers over a book for ≥ 1.5 s.

struct BookEstimationView: View {
    let book: Book
    let estimation: BookEstimationResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Header ────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // ── Time to Finish ────────────────────────────────────────
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

                // ── Per Reading Session ───────────────────────────────────
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

                // ── Chapter Breakdown ─────────────────────────────────────
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

                // ── Confidence ────────────────────────────────────────────
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

    // MARK: - Helpers

    private var completionLabel: String {
        let days = estimation.estimatedDaysRemaining
        if days == 0 {
            return "Could finish today"
        } else if days == 1 {
            return "Estimated completion tomorrow"
        } else {
            return "Estimated completion in \(days) days"
        }
    }

    @ViewBuilder
    private func statCell(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func confidenceLabel(_ level: ConfidenceLevel) -> String {
        switch level {
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .low:    return .orange
        case .medium: return .yellow
        case .high:   return .green
        }
    }
}

// MARK: - Shared Duration Formatter
// Single source of truth for "Xh Ym" / "Ym" display across ContentView and BookEstimationView.

private func formatDuration(_ time: TimeInterval) -> String {
    let hours   = Int(time) / 3600
    let minutes = (Int(time) % 3600) / 60
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(DataStore())
        .environmentObject(SessionCoordinator(dataStore: DataStore()))
}

