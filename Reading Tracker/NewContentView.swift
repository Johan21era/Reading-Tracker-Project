//  NewContentView.swift
//  Reading Tracker
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
// 11. ROADMAP 2.2 (RA-002 / O-8): duplicate imports now surface an informational
//     "Import Notes" alert instead of silently doing nothing. DataStore.addBook
//     returns whether it accepted the book; a rejected duplicate is reported here.
//
//  All original functionality (hover estimation, book import, PDFReaderScreen,
//  EPUBReaderScreen, NavigationSplitView layout) is unchanged.
//
//  SHEET DISMISS AFFORDANCE NOTE (NA-9 verification): every top-level sheet in
//  this file presents .sheetDismissAffordance() EXCEPT BookDiscoveryView — which
//  was verified during RA-002 to carry its OWN header-bar close control with
//  Escape support (BookDiscoveryView.swift headerBar), so adding the floating
//  overlay here would render two close controls on one sheet. The LT-2 invariant
//  "a dead-end sheet is structurally impossible" holds for all sheets.

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

// MARK: - Sheet dismissal affordance (LIVE-TEST LT-1/LT-2/LT-4 systemic fix)

/// LIVE TESTING LT-1/LT-2/LT-4: several analytics sheets shipped with NO way to
/// close them (Discover Books, Annual Reports, Insights…), trapping the user until
/// force-quit. This floating close affordance + Escape shortcut is applied at every
/// top-level sheet root so a sheet can never again be a dead end.
private struct SheetDismissAffordance: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.secondary)
                    .background(Circle().fill(.regularMaterial))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            .help("Close (Esc)")
            .padding(14)
        }
    }
}

extension View {
    func sheetDismissAffordance() -> some View { modifier(SheetDismissAffordance()) }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var sessionCoordinator: SessionCoordinator
    @EnvironmentObject private var goalVM: GoalProgressViewModel
    @EnvironmentObject private var contextEngine: BehaviorContextEngine

    /// AUDIT §1.1 / D5 WIRING (Phase 2): the single shared EnvironmentEngine,
    /// owned here via @StateObject exactly as EnvironmentBackgroundView2's header
    /// prescribes ("ContentView owns the single instance"; a default argument or
    /// ObservedObject-owned engine would multiply 45s recompute loops).
    @StateObject private var environmentEngine = EnvironmentEngine()

    /// LIVE-TEST LT-4: Insights opens as a real movable window, not a sheet.
    @Environment(\.openWindow) private var openWindow

    // Estimation state (unchanged)
    @State private var inspectedBook: Book?
    @State private var currentEstimation: BookEstimationResult?
    @State private var hoverWorkItem: DispatchWorkItem?
    @State private var importError: String?

    // ── Feature sheet presentation ─────────────────────────────────────────
    @State private var showRecommendations: Bool = false
    @State private var showGoals: Bool = false
    @State private var showAchievements: Bool = false
    @State private var showSessionHistory: Bool = false
    @State private var showDiscovery: Bool = false
    @State private var showAnnualReports: Bool = false
    @State private var showContextInsights: Bool = false
    @State private var showWeatherInsights: Bool = false
    @State private var showExplorer: Bool = false
    @State private var importWarnings: [String]?

    // ── Achievement toast ──────────────────────────────────────────────────
    @State private var toastAchievement: EarnedAchievement?
    @State private var toastVisible: Bool = false
    @State private var pendingToasts: [EarnedAchievement] = []

    // P5 Feature 5: onboarding + library search/sort
    @AppStorage("onboarding.completed") private var onboardingDismissed = false
    @State private var showOnboarding = false
    @State private var searchText = ""
    @State private var sortMode: LibrarySortMode = .dateAddedDesc

    // P6: Sentinel
    @StateObject private var sentinel = SentinelEngine.shared
    @State private var sentinelReport: (fixed: Int, stalled: Int, headline: String)?

    /// Filtered+sorted sidebar source.
    /// HOTFIX (stall report): this was a computed property — the Reading HUD's
    /// once-per-second elapsed-time tick re-evaluated ContentView, which
    /// re-filtered AND re-sorted the ENTIRE library every second on main.
    /// Now memoized: recompute ONLY when books/search/sort actually change.
    @State private var cachedVisibleBooks: [Book] = []
    @State private var cacheSignature: String = ""

    private var visibleBooks: [Book] {
        let signature = "\(dataStore.books.count)|\(dataStore.books.reduce(0) { $0 &+ $1.id.hashValue })|\(searchText)|\(sortMode.rawValue)"
        if signature != cacheSignature {
            let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
            let filtered = query.isEmpty ? dataStore.books : dataStore.books.filter {
                $0.title.lowercased().contains(query) ||
                    $0.author.lowercased().contains(query) ||
                    ($0.series ?? "").lowercased().contains(query)
            }
            cachedVisibleBooks = filtered.sorted(by: sortMode.sort)
            cacheSignature = signature
        }
        return cachedVisibleBooks
    }

    // P5 Feature 1: durability
    @State private var importNotice: String?
    @State private var pendingImportURL: URL?

    private func exportLibrary() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: LibraryArchiveManager.fileExtension) ?? .data]
        panel.nameFieldStringValue = "ReadingTracker-Backup." + LibraryArchiveManager.fileExtension
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try LibraryArchiveManager.shared.exportLibrary(from: dataStore)
                try data.write(to: url, options: .atomic)
                importNotice = "Library exported successfully."
            } catch {
                importError = error.localizedDescription
            }
        }
    }

    private func importLibrary() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            UTType(filenameExtension: LibraryArchiveManager.fileExtension) ?? .data,
            .json,
        ]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            guard let data = try? Data(contentsOf: url) else {
                importError = "Could not read that file."
                return
            }
            do {
                let s = try LibraryArchiveManager.shared.summarize(archiveData: data)
                pendingImportURL = url
                let goalsText = s.hasGoals ? "goals included" : "no goals set"
                importNotice = "REPLACE LIBRARY? Found \(s.bookCount) books, "
                    + "\(s.sessionCount) sessions, \(goalsText). "
                    + "Your current library is auto-backed-up first. Use Import again to confirm — or Cancel now."
            } catch {
                importError = error.localizedDescription
            }
        }
    }

    private func performConfirmedImportIfArmed() {
        guard let url = pendingImportURL else {
            importLibrary()
            return
        }
        pendingImportURL = nil
        guard let data = try? Data(contentsOf: url) else {
            importError = "Could not read that file."
            return
        }
        do {
            try LibraryArchiveManager.shared.importLibrary(data, into: dataStore)
            importNotice = "Library restored."
        } catch {
            importError = error.localizedDescription
        }
    }

    var body: some View {
        ZStack {
            EnvironmentBackgroundView(engine: environmentEngine)
                .ignoresSafeArea()

            NavigationSplitView {
            List {
                ForEach(visibleBooks) { book in
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
            .navigationSplitViewColumnWidth(min: DesignGrid.sidebarMinWidth, ideal: DesignGrid.sidebarIdealWidth)
            .searchable(text: $searchText, placement: .sidebar, prompt: "Search title, author, series")
            // UI REVIEW §1/§2/§8 (P7): one cohesive plane. The sidebar and
            // toolbar stop painting their own opaque surfaces; the single
            // atmospheric background behind everything becomes THE surface.
            .scrollContentBackground(.hidden)
            .toolbarBackground(.hidden, for: .windowToolbar) // Phase 2 wiring: let the ambient gradient show through
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
                            openWindow(id: "reading-insights")
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

                        Divider()

                        Button {
                            exportLibrary()
                        } label: {
                            Label("Export Library...", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            importLibrary()
                        } label: {
                            Label("Import Library...", systemImage: "square.and.arrow.down")
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

                // P5 Feature 5: sidebar sort
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort By", selection: $sortMode) {
                            ForEach(LibrarySortMode.allCases, id: \.self) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }

                // ── Phase 2: Library Explorer (progressive filtering + spatial) ──
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showExplorer = true
                    } label: {
                        Label("Explore", systemImage: "square.grid.2x2")
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
        } // ZStack — ambient environment sits behind the split view
        .environmentObject(environmentEngine) // Phase 2: downstream consumers read the same instance
        // P5 Feature 5: first-run wizard when library is empty and never dismissed.
        .onChange(of: dataStore.books.isEmpty) { _, empty in
            showOnboarding = empty && !onboardingDismissed
        }
        .onAppear {
            showOnboarding = OnboardingView.shouldShow(
                books: dataStore.books, dismissed: onboardingDismissed
            )
            // P6: Sentinel watchdog — launch cycle + periodic probes.
            sentinel.start()
            sentinel.runCycle()
            sentinelReport = sentinel.overnightReport()
        }
        .sheet(isPresented: $showOnboarding, onDismiss: { onboardingDismissed = true }) {
            OnboardingView()
                .environmentObject(dataStore)
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

        // ── AUDIT §1.1 verdict executed (Phase 2): Import Intelligence surfaces ──
        // ROADMAP 2.2: also carries the duplicate-import notice.
        .alert("Import Notes", isPresented: Binding(
            get: { importWarnings != nil },
            set: { if !$0 { importWarnings = nil } }
        )) {
            Button("OK") { importWarnings = nil }
        } message: {
            Text(importWarnings?.joined(separator: "\n") ?? "")
        }

        // P5 Feature 1: archive import confirm / result notices
        .alert("Library Archive", isPresented: Binding(
            get: { importNotice != nil },
            set: { if !$0 { importNotice = nil; pendingImportURL = nil } }
        )) {
            if pendingImportURL != nil {
                Button("Replace My Library", role: .destructive) {
                    performConfirmedImportIfArmed()
                }
                Button("Cancel", role: .cancel) {
                    pendingImportURL = nil
                }
            } else {
                Button("OK") { importNotice = nil }
            }
        } message: {
            Text(importNotice ?? "")
        }

        // ── Feature sheets ─────────────────────────────────────────────────
        .sheet(isPresented: $showRecommendations) {
            RecommendationPanel()
                .environmentObject(dataStore)
                .sheetDismissAffordance()
        }
        .sheet(isPresented: $showGoals) {
            GoalsDashboard()
                .environmentObject(goalVM)
                .environmentObject(dataStore)
                .sheetDismissAffordance()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementPanel()
                .environmentObject(dataStore)
                .onAppear { dataStore.clearNewAchievements() }
                .sheetDismissAffordance()
        }
        .sheet(isPresented: $showSessionHistory) {
            SessionHistoryView()
                .environmentObject(dataStore)
                .sheetDismissAffordance()
        }
        .sheet(isPresented: $showDiscovery) {
            // NA-9 (verified): this view ships its own header close control +
            // Escape shortcut; the floating overlay is intentionally NOT stacked.
            BookDiscoveryView()
        }
        .sheet(isPresented: $showAnnualReports) {
            AnnualReportArchiveView()
                .environmentObject(dataStore)
                .sheetDismissAffordance()
        }
        .sheet(isPresented: $showExplorer) {
            LibraryExplorerView(
                allBooks: dataStore.books,
                collections: dataStore.libraryState.collections,
                reducedMotion: environmentEngine.state.reducedMotion,
                onSelect: { book in
                    showExplorer = false
                    hoverWorkItem?.cancel()
                    let result = EstimationEngine.estimate(for: book, allBooks: dataStore.books)
                    inspectedBook = book
                    currentEstimation = EstimationEngine.validate(result: result)
                }
            )
            .frame(minWidth: 920, minHeight: 620)
            .sheetDismissAffordance()
        }
        .sheet(isPresented: $showContextInsights) {
            ContextInsightPanel()
                .environmentObject(contextEngine)
                .sheetDismissAffordance()
        }
        .sheet(isPresented: $showWeatherInsights) {
            WeatherInsightPanel()
                .environmentObject(dataStore)
                .sheetDismissAffordance()
        }

        // ── Achievement toast ──────────────────────────────────────────────
        .onReceive(dataStore.$newlyEarnedAchievements) { newly in
            // AUDIT §2.2: queue everything new instead of dropping updates while
            // a toast is visible or reading only `.first` of a batch.
            let knownIDs = Set(pendingToasts.map(\.id))
            let fresh = newly.filter { $0.id != toastAchievement?.id && !knownIDs.contains($0.id) }
            guard !fresh.isEmpty else { return }
            pendingToasts.append(contentsOf: fresh)
            showNextToastIfNeeded()
        }
        .overlay(alignment: .top) {
            if toastVisible, let achievement = toastAchievement {
                AchievementToastView(achievement: achievement) {
                    // Tap opens the full achievements panel
                    withAnimation(.easeOut) { toastVisible = false }
                    if let tapped = toastAchievement {
                        dataStore.markAchievementToastShown(id: tapped.id)
                    }
                    toastAchievement = nil
                    pendingToasts.removeAll()
                    showAchievements = true
                }
                .padding(.top, DesignGrid.hudTopInset)
                .padding(.horizontal, DesignGrid.toastHorizontalInset)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // AUDIT §1.2 / TECH_DEBT D1: persistent (dismiss-on-fix) persistence banner.
        .overlay(alignment: .bottom) {
            if case .degraded(let message) = dataStore.persistenceHealth {
                PersistenceWarningBanner(message: message)
            }
        }
        // P5 Feature 3 + UI REVIEW grid: HUD inset from shared constants.
        .overlay(alignment: .topLeading) {
            ReadingHUD()
                .padding(.leading, DesignGrid.hudLeadingInset)
                .padding(.top, DesignGrid.hudTopInset)
        }

        // P6: "While you were away" Sentinel card (top-center, above toasts).
        .overlay(alignment: .top) {
            if let report = sentinelReport {
                SentinelReportCardView(
                    fixed: report.fixed,
                    stalled: report.stalled,
                    headline: report.headline
                ) {
                    withAnimation { sentinelReport = nil }
                }
                .padding(.top, 8)
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Hover Handling (unchanged)

    private func handleHover(hovering: Bool, book: Book) {
        if hovering {
            hoverWorkItem?.cancel()
            let workItem = DispatchWorkItem { [book] in
                // AUDIT §2.3: the book may have been deleted during the 0.55 s
                // hover delay — never surface a ghost estimate.
                guard dataStore.book(id: book.id) != nil else { return }
                let result = EstimationEngine.estimate(for: book, allBooks: dataStore.books)
                inspectedBook = book
                currentEstimation = EstimationEngine.validate(result: result)
            }
            hoverWorkItem = workItem
            // LIVE-TEST LT-7: 1.5s felt sluggish; 0.55s keeps intent-filtering
            // (vs accidental sweeps) while feeling responsive.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55, execute: workItem)
        } else {
            hoverWorkItem?.cancel()
            hoverWorkItem = nil
        }
    }

    // MARK: - Toolbar: Add Book

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

                    // Phase 2 — Import Intelligence verdict EXECUTED: the previously
                    // unreachable ~250-line facade now analyzes every real import;
                    // findings surface to the user instead of vanishing (AUDIT §1.1).
                    let fileSizeBytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? nil
                    let report = ImportIntelligenceFacade.analyze(
                        book: book,
                        fileName: url.lastPathComponent,
                        fileSizeBytes: fileSizeBytes,
                        fileType: book.fileType.displayName
                    )
                    var messages = report.warnings.map { warning -> String in
                        (warning.level == .critical ? "⚠️ " : "• ") + warning.message
                    }

                    // ROADMAP 2.2 (O-8): addBook previously returned Void and silently
                    // dropped duplicates — importing the same file twice gave zero
                    // feedback. It now reports acceptance; rejection becomes a visible
                    // note through the existing Import Notes alert channel.
                    let accepted = dataStore.addBook(book)
                    if !accepted {
                        messages.append("• This book is already in your library (same file). Nothing was added.")
                    }

                    await MainActor.run {
                        if !messages.isEmpty { importWarnings = messages }
                    }
                } catch {
                    await MainActor.run { importError = error.localizedDescription }
                }
            }
        }
    }

    // MARK: - Delete

    private func deleteItems(offsets: IndexSet) {
        // AUDIT §2.1: capture identities BEFORE mutating — iterating offsets while
        // removing shifts every subsequent index, deleting the wrong books or
        // crashing on out-of-range access.
        let bookIDs = Set(offsets.map { dataStore.books[$0].id })
        withAnimation {
            bookIDs.forEach { dataStore.removeBook(id: $0) }
        }
    }

    /// AUDIT §2.2: presents queued achievements one at a time, consuming each
    /// from DataStore as its toast finishes — nothing dropped, nothing re-shown.
    private func showNextToastIfNeeded() {
        guard !toastVisible, !pendingToasts.isEmpty else { return }
        toastAchievement = pendingToasts.removeFirst()
        withAnimation(.spring(duration: 0.4)) { toastVisible = true }

        Task {
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation(.easeOut(duration: 0.3)) { toastVisible = false }
            try? await Task.sleep(for: .seconds(0.3))
            if let shown = toastAchievement {
                dataStore.markAchievementToastShown(id: shown.id)
            }
            toastAchievement = nil
            showNextToastIfNeeded()
        }
    }
}

// MARK: - ContentBookRowView (unchanged)

private struct ContentBookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 10) {
            // P5 Feature 3: real cover when captured at import.
            BookCoverThumbnail(book: book)

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
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Persistence Warning Banner

/// AUDIT §1.2 / TECH_DEBT D1: Release-visible, dismiss-on-fix banner.
/// Rendered whenever `DataStore.persistenceHealth` is degraded; disappears
/// only when a save succeeds again. Never auto-dismisses.
// MARK: - Library Sorting (P5 Feature 5)

enum LibrarySortMode: String, CaseIterable, Identifiable {
    case dateAddedDesc
    case dateAddedAsc
    case titleAsc
    case titleDesc
    case author
    case recentlyRead
    case progress

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dateAddedDesc: return "Recently Added"
        case .dateAddedAsc: return "Oldest Added"
        case .titleAsc: return "Title A-Z"
        case .titleDesc: return "Title Z-A"
        case .author: return "Author"
        case .recentlyRead: return "Recently Read"
        case .progress: return "Progress"
        }
    }

    func sort(_ a: Book, _ b: Book) -> Bool {
        switch self {
        case .dateAddedDesc: return a.dateAdded > b.dateAdded
        case .dateAddedAsc: return a.dateAdded < b.dateAdded
        case .titleAsc: return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        case .titleDesc: return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedDescending
        case .author: return a.author.localizedCaseInsensitiveCompare(b.author) == .orderedAscending
        case .recentlyRead:
            return (a.lastReadDate ?? .distantPast) > (b.lastReadDate ?? .distantPast)
        case .progress: return a.progressFraction > b.progressFraction
        }
    }
}

private struct PersistenceWarningBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Saving problems detected")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignGrid.cardCornerRadius))
        // UI REVIEW §5 (Medium #5): stroke softened — hierarchy via contrast,
        // not an extra bright boundary.
        .overlay(
            RoundedRectangle(cornerRadius: DesignGrid.cardCornerRadius)
                .stroke(Color.yellow.opacity(0.28), lineWidth: 1)
        )
        .padding(.horizontal, DesignGrid.bannerHorizontalInset)
        .padding(.bottom, DesignGrid.bannerBottomInset)
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

    /// LIVE-TEST LT-7: information arrives in three soft waves instead of one
    /// wall — wave 1 identity+headline, wave 2 per-session stats, wave 3
    /// chapters+confidence. Reduced-motion users get instant reveal.
    @State private var revealedWave = 0

    var body: some View {
        revealGroup
            .onAppear {
                Task { @MainActor in
                    for wave in 1...3 {
                        try? await Task.sleep(for: .seconds(0.14))
                        guard !Task.isCancelled else { return }
                        withAnimation(.easeOut(duration: 0.32)) { revealedWave = wave }
                    }
                }
            }
    }

    @ViewBuilder
    private var revealGroup: some View {
        let reducedMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let wave1 = revealedWave >= 1 || reducedMotion
        let wave2 = revealedWave >= 2 || reducedMotion
        let wave3 = revealedWave >= 3 || reducedMotion

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
                .opacity(wave1 ? 1 : 0)
                .offset(y: wave1 ? 0 : 14)

                Divider()
                    .opacity(wave1 ? 1 : 0)

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
                .opacity(wave2 ? 1 : 0)
                .offset(y: wave2 ? 0 : 16)

                Divider()
                    .opacity(wave2 ? 1 : 0)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Per Reading Session", systemImage: "book.pages")
                        .font(.headline)
                        .opacity(wave2 ? 1 : 0)
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
                            .opacity(wave3 ? 1 : 0)
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
