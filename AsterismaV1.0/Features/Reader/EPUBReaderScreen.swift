//  EPUBReaderScreen.swift
//  AsterismaV1.0
//  Architectural redesign — see EPUB_READER_REDESIGN_PLAN.txt (this file's
//  single source of truth). Previous version extracted a fixed ~3,000-
//  character plain-text snippet with no navigation; this version renders
//  full chapter content via WKWebView and supports real chapter-by-chapter
//  navigation, matching the reading-position contract SessionCoordinator
//  already establishes for the PDF reader.
//
//  External contract preserved exactly: init(book: Book, coordinator:
//  SessionCoordinator) — unchanged, so both call sites (NewContentView,
//  and the live Explorer) keep compiling untouched.
//

import os
import SwiftUI
import WebKit

// MARK: - EPUBReaderScreen

struct EPUBReaderScreen: View {
    let book: Book
    @ObservedObject var coordinator: SessionCoordinator
    @EnvironmentObject private var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var package: EPUBPackage?
    @State private var currentChapterIndex: Int = 0
    @State private var pageInChapter: Int = 0
    @State private var pagesInChapter: Int = 1
    @State private var readableChapterIndices: [Int] = []
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var showingChapterList = false
    @State private var showingInfo = false

    /// Reference to the in-flight open Task so it can be cancelled on
    /// disappear, exactly like the previous implementation's loadTask.
    @State private var openTask: Task<Void, Never>?

    /// P5 Feature 3: RSVP speed-reading over the CURRENT chapter.
    @AppStorage("rsvp.enabled") private var rsvpEnabled = true
    @AppStorage("reader.fontScale") private var fontScale: Double = 1.0
    @AppStorage("reader.lineHeight") private var lineHeight: Double = 1.55
    @AppStorage("reader.alignment") private var alignment: String = "left"
    @AppStorage("reader.theme") private var readerTheme: String = "light"
    @State private var showingTypography = false
    @State private var rsvpText: String?
    @State private var readerControlsVisible = true
    @State private var readerControlsHovered = false
    @State private var readerControlsHideTask: Task<Void, Never>?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Asterisma",
        category: "EPUBReaderScreen"
    )

    init(book: Book, coordinator: SessionCoordinator) {
        self.book = book
        self.coordinator = coordinator
    }

    var body: some View {
        Group {
            if let errorMessage {
                errorView(errorMessage)
            } else if isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .onAppear {
            errorMessage = nil
            isLoading = true
            openTask = Task {
                await openPackage()

                // LIVE-TEST LT-3b: timing begins ONLY when content actually
                // opened. Previously startReading() ran unconditionally here,
                // so staring at the load-error screen accrued phantom reading
                // time on books that never opened.
                guard !Task.isCancelled else { return }
                if errorMessage == nil, package != nil {
                    coordinator.startReading(bookID: book.id, page: book.currentPage)
                    updatePositionLabel()
                    showReaderControls()
                }
            }
        }
        .onDisappear {
            readerControlsHideTask?.cancel()
            persistPosition()
            dataStore.saveImmediately()
            openTask?.cancel()
            openTask = nil
            package?.close()
            package = nil
            coordinator.endCurrentSession()
        }
    }

    // MARK: - Opening

    private func openPackage() async {
        logger.debug("Opening EPUB package")
        do {
            let opened = try await EPUBPackage.open(book: book)

            guard !Task.isCancelled else {
                // Nobody will ever hold a reference to `opened` if we bail
                // out here — release it ourselves rather than leaking it.
                opened.close()
                return
            }

            let readable = opened.readableChapterIndices()
            let fallbackIndex = startingChapterIndex(in: opened, resumingFrom: book.currentPage)
            var startIndex = min(
                max(0, book.epubChapterIndex ?? fallbackIndex),
                max(0, opened.chapterCount - 1)
            )
            if !readable.contains(startIndex) {
                startIndex = readable.first(where: { $0 >= startIndex })
                    ?? readable.first
                    ?? 0
            }
            let startPage = max(0, book.epubPageInChapter ?? 0)

            await MainActor.run {
                guard !Task.isCancelled else {
                    opened.close()
                    return
                }
                self.package = opened
                self.readableChapterIndices = readable
                self.currentChapterIndex = startIndex
                self.pageInChapter = startPage
                self.isLoading = false
            }
            logger.info("EPUB package opened with \(opened.chapterCount, privacy: .public) chapters, resuming at chapter \(startIndex, privacy: .public)")
        } catch {
            logger.error("Failed to open EPUB package: \(error.localizedDescription)")
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    /// Maps the coordinator's persisted page back to a chapter index, so
    /// reopening a book resumes where the reader left off instead of always
    /// restarting at chapter 1. Falls back to chapter 0 if nothing matches.
    ///
    /// Defensive by design: book.chapters (persisted at import time) and the
    /// freshly-parsed spine (package.chapterCount) are not guaranteed to be
    /// the same length — see EPUB_READER_REDESIGN_PLAN.txt Section 1 — so
    /// the result is always clamped to a real spine index.
    private func startingChapterIndex(in package: EPUBPackage, resumingFrom page: Int) -> Int {
        guard package.chapterCount > 0 else { return 0 }
        let match = book.chapters.first { page >= $0.startPage && page <= $0.endPage }
        let index = match?.index ?? 0
        return min(max(0, index), package.chapterCount - 1)
    }

    // MARK: - Chapter navigation

    private var readablePosition: Int? {
        readableChapterIndices.firstIndex(of: currentChapterIndex)
    }

    private var canGoToPreviousChapter: Bool {
        (readablePosition ?? 0) > 0
    }

    private var canGoToNextChapter: Bool {
        guard let position = readablePosition else { return false }
        return position + 1 < readableChapterIndices.count
    }

    private func goToChapter(_ index: Int) {
        guard let package, package.chapterCount > 0 else { return }
        let target = readableChapterIndices.contains(index)
            ? index
            : (readableChapterIndices.first(where: { $0 > index })
                ?? readableChapterIndices.last
                ?? 0)
        let clamped = max(0, min(target, package.chapterCount - 1))
        currentChapterIndex = clamped
        pageInChapter = 0
        pagesInChapter = 1
        persistPosition()
        coordinator.turnToPage(globalPage)
        updatePositionLabel()
        showReaderControls()
    }

    private func goToPreviousReadableChapter() {
        guard let position = readablePosition, position > 0 else { return }
        goToChapter(readableChapterIndices[position - 1])
    }

    private func goToNextReadableChapter() {
        guard let position = readablePosition,
              position + 1 < readableChapterIndices.count else { return }
        goToChapter(readableChapterIndices[position + 1])
    }

    private func chapterTitle(at index: Int) -> String {
        // `book.chapters` comes from TOC entries at import time; the EPUB
        // spine can have a different count. Never show a TOC title against a
        // mismatched spine index — that produced the Chapter 25/12 conflict.
        guard let package,
              package.chapterCount == book.chapters.count,
              book.chapters.indices.contains(index)
        else {
            return "Chapter \(index + 1)"
        }
        return book.chapters[index].title
    }

    private var bookProgress: Double {
        let chapters = max(package?.chapterCount ?? book.chapters.count, 1)
        let withinChapter = Double(pageInChapter + 1) / Double(max(pagesInChapter, 1))
        let value = (Double(currentChapterIndex) + withinChapter) / Double(chapters)
        return min(1.0, max(0.0, value))
    }

    private var globalPage: Int {
        guard book.chapters.indices.contains(currentChapterIndex) else {
            return max(0, pageInChapter)
        }
        let chapter = book.chapters[currentChapterIndex]
        return min(max(chapter.startPage + pageInChapter, chapter.startPage), chapter.endPage)
    }

    private func updatePositionLabel() {
        let chapters = max(book.chapters.count, 1)
        coordinator.updatePositionLabel(
            "Ch \(currentChapterIndex + 1)/\(chapters) · \(pageInChapter + 1)/\(max(pagesInChapter, 1)) · \(Int(bookProgress * 100))%"
        )
    }

    private func persistPosition() {
        guard var current = dataStore.book(id: book.id) else { return }
        current.epubChapterIndex = currentChapterIndex
        current.epubPageInChapter = pageInChapter
        current.currentPage = globalPage
        dataStore.updateBook(current)
    }

    private func handleReaderKey(_ command: KeyNavigationCommand) -> Bool {
        switch command {
        case .left, .up:
            turnPage(-1)
            return true
        case .right, .down:
            turnPage(1)
            return true
        case .escape:
            dismiss()
            return true
        case .returnKey:
            return false
        }
    }

    private func turnPage(_ delta: Int) {
        if delta < 0 {
            if pageInChapter > 0 {
                pageInChapter -= 1
            } else if canGoToPreviousChapter {
                goToPreviousReadableChapter()
                return
            } else {
                return
            }
        } else {
            if pageInChapter + 1 < pagesInChapter {
                pageInChapter += 1
            } else if canGoToNextChapter {
                goToNextReadableChapter()
                return
            } else {
                return
            }
        }

        persistPosition()
        coordinator.turnToPage(globalPage)
        updatePositionLabel()
    }

    // MARK: - Content Views

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading EPUB...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func showReaderControls() {
        readerControlsHideTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            readerControlsVisible = true
        }
        scheduleReaderControlsHide()
    }

    private func cancelReaderControlsHide() {
        readerControlsHideTask?.cancel()
        readerControlsHideTask = nil
    }

    private func scheduleReaderControlsHide() {
        readerControlsHideTask?.cancel()
        readerControlsHideTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                if readerControlsHovered
                    || showingChapterList
                    || showingInfo
                    || showingTypography
                    || showingMirageAnalysis {
                    continue
                }
                guard readerControlsVisible else { return }
                withAnimation(.easeOut(duration: 0.4)) {
                    readerControlsVisible = false
                }
                return
            }
        }
    }

    /// Compact floating controls replace the native reader toolbar, so there
    /// is no full-width gray strip in fullscreen.
    private var readerTopControls: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
            }
            .help("Back to Library")
            .accessibilityLabel("Back to Library")

            Button {
                showingChapterList = true
            } label: {
                Text(chapterTitle(at: currentChapterIndex))
                    .lineLimit(1)
                    .frame(maxWidth: 260, alignment: .leading)
            }
            .popover(isPresented: $showingChapterList) {
                chapterListPopover
            }
            .accessibilityLabel("Table of contents")

            if rsvpEnabled {
                Button {
                    loadRSVPText()
                } label: {
                    Image(systemName: "hare")
                }
                .help("Speed-read this chapter (RSVP)")
                .accessibilityLabel("Speed read this chapter")
                .disabled(package == nil)
            }

            Button {
                showingTypography = true
            } label: {
                Image(systemName: "textformat")
            }
            .popover(isPresented: $showingTypography) {
                readerTypographyControls
            }
            .help("Reading settings")
            .accessibilityLabel("Reading settings")

            Button {
                showingInfo = true
            } label: {
                Image(systemName: "info.circle")
            }
            .popover(isPresented: $showingInfo) {
                metadataSection
                    .padding()
                    .frame(minWidth: 260)
            }
            .help("Book information")
            .accessibilityLabel("Book information")
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white.opacity(0.92))
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.55), in: Capsule())
        .padding(14)
    }

    private var readerTypographyControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reading")
                .font(.headline)

            Picker("Theme", selection: $readerTheme) {
                Text("Light").tag("light")
                Text("Sepia").tag("sepia")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Text size")
                Slider(value: $fontScale, in: 0.8 ... 1.6, step: 0.05)
                Text("\(Int(fontScale * 100))%")
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
            }
            .font(.callout)

            HStack {
                Text("Line spacing")
                Slider(value: $lineHeight, in: 1.2 ... 2.0, step: 0.05)
                Text(String(format: "%.2f", lineHeight))
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
            }
            .font(.callout)

            Picker("Alignment", selection: $alignment) {
                Text("Left").tag("left")
                Text("Justified").tag("justify")
            }
            .pickerStyle(.segmented)

            Button("Reset Reading Settings") {
                fontScale = 1.0
                lineHeight = 1.55
                alignment = "left"
                readerTheme = "light"
            }
            .buttonStyle(.link)
        }
        .padding()
        .frame(width: 300)
    }

    private var readerPageControls: some View {
        HStack(spacing: 14) {
            Button {
                turnPage(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Previous page")
            .disabled(pageInChapter == 0 && !canGoToPreviousChapter)

            Text("\(pageInChapter + 1) / \(max(pagesInChapter, 1))")
                .monospacedDigit()
                .frame(minWidth: 62)

            ProgressView(value: bookProgress)
                .progressViewStyle(.linear)
                .tint(.white.opacity(0.7))
                .frame(width: 70)

            Button {
                turnPage(1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Next page")
            .disabled(pageInChapter + 1 >= pagesInChapter && !canGoToNextChapter)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white.opacity(0.92))
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.55), in: Capsule())
        .padding(.bottom, 16)
    }

    private var readerSettingsJSON: String {
        let background: String
        let foreground: String
        switch readerTheme {
        case "sepia":
            background = "#f4ecd8"
            foreground = "#3b2f2f"
        case "dark":
            background = "#151515"
            foreground = "#e8e8e8"
        default:
            background = "#ffffff"
            foreground = "#111111"
        }
        let settings: [String: Any] = [
            "scale": fontScale,
            "lineHeight": lineHeight,
            "align": alignment,
            "bg": background,
            "fg": foreground,
        ]
        let data = (try? JSONSerialization.data(withJSONObject: settings)) ?? Data("{}".utf8)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private var contentView: some View {
        Group {
            if let package, let url = package.fileURL(forChapterAt: currentChapterIndex) {
                EPUBChapterWebView(
                    fileURL: url,
                    allowedReadRoot: package.allowedReadRoot,
                    startPage: pageInChapter,
                    targetPage: pageInChapter,
                    settingsJSON: readerSettingsJSON,
                    onExternalLink: { url in
                        NSWorkspace.shared.open(url)
                    },
                    onLoadError: { message in
                        logger.error("Chapter failed to render: \(message)")
                    },
                    onPageCount: { pages in
                        pagesInChapter = max(1, pages)
                        if pageInChapter >= pagesInChapter {
                            pageInChapter = pagesInChapter - 1
                        }
                        if book.chapters.indices.contains(currentChapterIndex) {
                            coordinator.turnToPage(globalPage)
                        }
                        updatePositionLabel()
                    },
                    onPageChanged: { page in
                        pageInChapter = max(0, page)
                        persistPosition()
                        coordinator.turnToPage(globalPage)
                        updatePositionLabel()
                    }
                )
            } else {
                Text("This chapter is unavailable.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(book.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    goToChapter(currentChapterIndex - 1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoToPreviousChapter)
                .help("Previous Chapter")

                Button {
                    showingChapterList = true
                } label: {
                    Text(chapterTitle(at: currentChapterIndex))
                        .lineLimit(1)
                }
                .popover(isPresented: $showingChapterList) {
                    chapterListPopover
                }

                Button {
                    goToChapter(currentChapterIndex + 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoToNextChapter)
                .help("Next Chapter")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if rsvpEnabled {
                    Button {
                        loadRSVPText()
                    } label: {
                        Image(systemName: "hare")
                    }
                    .help("Speed-read this chapter (RSVP)")
                    .disabled(package == nil)
                }
                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .popover(isPresented: $showingInfo) {
                    metadataSection
                        .padding()
                        .frame(minWidth: 260)
                }
            }
        }
        // P5 Feature 3: RSVP overlay (sheet — fullScreenCover is not a
        // native macOS SwiftUI presentation).
        .sheet(isPresented: Binding(
            get: { rsvpText != nil },
            set: { if !$0 { rsvpText = nil } }
        )) {
            if let text = rsvpText {
                RSVPReaderView(text: text) { rsvpText = nil }
                    .frame(minWidth: 720, minHeight: 520)
            }
        }
        // PR-5: the Mirage analyze sheet (book detail entry per owner choice).
        .sheet(isPresented: $showingMirageAnalysis) {
            MirageAnalysisSheet(book: book)
        }
        .background(KeyNavigationConfigurator(isEnabled: true, onCommand: handleReaderKey))
        .overlay(alignment: .topLeading) {
            if readerControlsVisible {
                readerTopControls
                    .transition(.opacity)
                    .onHover { hovering in
                        readerControlsHovered = hovering
                        if hovering {
                            cancelReaderControlsHide()
                        } else {
                            scheduleReaderControlsHide()
                        }
                    }
            } else {
                Button {
                    showReaderControls()
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(10)
                        .background(Color.black.opacity(0.35), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Show reading controls")
                .accessibilityLabel("Show reading controls")
                .padding(14)
                .onHover { hovering in
                    if hovering { showReaderControls() }
                }
            }
        }
        .overlay(alignment: .bottom) { readerPageControls }
    }

    /// Extracts plain text from the current chapter for RSVP streaming.
    private func loadRSVPText() {
        guard let package,
              let url = package.fileURL(forChapterAt: currentChapterIndex),
              let data = try? Data(contentsOf: url),
              let html = String(data: data, encoding: .utf8) else { return }
        let plain = stripHTML(html)
        guard !plain.isEmpty else { return }
        rsvpText = plain
    }

    private var chapterListPopover: some View {
        let indices = readableChapterIndices.isEmpty
            ? Array(0..<max(package?.chapterCount ?? book.chapters.count, 1))
            : readableChapterIndices
        return List(indices, id: \.self) { index in
            Button {
                goToChapter(index)
                showingChapterList = false
            } label: {
                HStack {
                    Text(chapterTitle(at: index))
                    Spacer()
                    if index == currentChapterIndex {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(minWidth: 280, minHeight: 320)
    }

    @State private var showingMirageAnalysis = false

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(book.title)
                .font(.title2)
                .fontWeight(.bold)
            Text("By \(book.author)")
                .font(.headline)
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                Label("\(book.totalPages) pages", systemImage: "doc.text")
                Label("\(package?.chapterCount ?? book.chapters.count) chapters", systemImage: "list.bullet")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            if let difficulty = book.difficultyProfile {
                Label(String(format: "Grade %.1f", difficulty.gradeLevel), systemImage: "chart.bar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            // PR-5 mount (owner-approved): "Analyze with Mirage" lives on this
            // book's detail popover. EPUB-only (PDF books are not Mirage-input),
            // never auto-run, and the sheet carries all typed outcomes (ADR-5,
            // S10-ES-1; the app writes no RT state — ADR-6 coherence note).
            Divider()
            Button("Analyze with Mirage…") {
                showingMirageAnalysis = true
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - EPUBChapterWebView

/// Renders one already-unzipped chapter file. Holds no resource lifecycle
/// of its own — EPUBPackage (owned by the parent view's @State) is what
/// keeps the underlying files and security scope alive; this view only
/// ever needs to be handed a currently-valid local file URL.
private struct EPUBChapterWebView: NSViewRepresentable {
    let fileURL: URL
    let allowedReadRoot: URL
    let startPage: Int
    let targetPage: Int
    let settingsJSON: String
    let onExternalLink: (URL) -> Void
    let onLoadError: (String) -> Void
    let onPageCount: (Int) -> Void
    let onPageChanged: (Int) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Pagination requires a tiny amount of injected JavaScript. Book
        // content itself still cannot be trusted with app privileges.
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(context.coordinator, name: "epubPage")
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: "window.__epubInitialPage = \(startPage);",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: "window.__epubReaderSettings = \(settingsJSON);",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: Self.paginationScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.underPageBackgroundColor = .clear

        context.coordinator.webView = webView
        context.coordinator.targetPage = startPage
        context.coordinator.settingsJSON = settingsJSON
        context.coordinator.currentlyLoadedURL = fileURL
        webView.loadFileURL(fileURL, allowingReadAccessTo: allowedReadRoot)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.webView = webView
        context.coordinator.onExternalLink = onExternalLink
        context.coordinator.onLoadError = onLoadError
        context.coordinator.onPageCount = onPageCount
        context.coordinator.onPageChanged = onPageChanged

        if context.coordinator.currentlyLoadedURL != fileURL {
            context.coordinator.currentlyLoadedURL = fileURL
            context.coordinator.targetPage = startPage
            context.coordinator.ready = false
            webView.loadFileURL(fileURL, allowingReadAccessTo: allowedReadRoot)
            return
        }

        if context.coordinator.settingsJSON != settingsJSON {
            context.coordinator.settingsJSON = settingsJSON
            webView.evaluateJavaScript(
                "window.__epubApplySettings && window.__epubApplySettings(\(settingsJSON))"
            )
        }

        if context.coordinator.targetPage != targetPage {
            context.coordinator.go(to: targetPage)
        }
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        nsView.configuration.userContentController.removeScriptMessageHandler(
            forName: "epubPage")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            startPage: startPage,
            settingsJSON: settingsJSON,
            onExternalLink: onExternalLink,
            onLoadError: onLoadError,
            onPageCount: onPageCount,
            onPageChanged: onPageChanged
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var targetPage: Int
        var settingsJSON: String
        var currentlyLoadedURL: URL?
        weak var webView: WKWebView?
        var ready = false
        var onExternalLink: (URL) -> Void
        var onLoadError: (String) -> Void
        var onPageCount: (Int) -> Void
        var onPageChanged: (Int) -> Void

        init(
            startPage: Int,
            settingsJSON: String,
            onExternalLink: @escaping (URL) -> Void,
            onLoadError: @escaping (String) -> Void,
            onPageCount: @escaping (Int) -> Void,
            onPageChanged: @escaping (Int) -> Void
        ) {
            targetPage = startPage
            self.settingsJSON = settingsJSON
            self.onExternalLink = onExternalLink
            self.onLoadError = onLoadError
            self.onPageCount = onPageCount
            self.onPageChanged = onPageChanged
        }

        func go(to page: Int) {
            targetPage = page
            guard ready, let webView else { return }
            // The script clamps to the real page count after layout.
            webView.evaluateJavaScript(
                "window.__epubGoToPage && window.__epubGoToPage(\(page))"
            )
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "epubPage",
                  let body = message.body as? [String: Any],
                  let pages = body["pages"] as? Int,
                  let page = body["page"] as? Int
            else { return }
            DispatchQueue.main.async {
                self.onPageCount(max(1, pages))
                self.onPageChanged(max(0, page))
            }
        }

        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url
            {
                onExternalLink(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            ready = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                webView.evaluateJavaScript(
                    "window.__epubGoToPage && window.__epubGoToPage(\(self.targetPage))"
                )
            }
        }

        func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            onLoadError(error.localizedDescription)
        }

        func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            onLoadError(error.localizedDescription)
        }
    }

    private static let paginationScript = """
    (function() {
      function post(pages, page) {
        if (window.webkit && window.webkit.messageHandlers.epubPage) {
          window.webkit.messageHandlers.epubPage.postMessage({pages: pages, page: page});
        }
      }
      function build() {
        if (window.__epubPaginationReady) return;
        window.__epubPaginationReady = true;

        var body = document.body;
        if (!body) return;
        var wrapper = document.createElement('div');
        wrapper.id = '__epub_paginator';
        while (body.firstChild) wrapper.appendChild(body.firstChild);
        body.appendChild(wrapper);

        var style = document.createElement('style');
        style.id = '__epubReaderStyle';
        document.head.appendChild(style);

        var gap = 44;
        var pad = 46;
        var currentPage = (window.__epubInitialPage || 0) | 0;
        var settings = {scale: 1, lineHeight: 1.55, align: 'left', bg: '#ffffff', fg: '#111111'};

        function metrics() {
          var w = window.innerWidth;
          var h = window.innerHeight;
          var spread = w >= 1000 ? 2 : 1;
          var col = Math.max(180, Math.min(620, (w - pad * 2 - gap * (spread - 1)) / spread));
          wrapper.style.columnWidth = col + 'px';
          wrapper.style.columnGap = gap + 'px';
          wrapper.style.height = h + 'px';
          var cols = Math.max(1, Math.round((wrapper.scrollWidth - pad * 2 + gap) / (col + gap)));
          var pages = Math.max(1, Math.ceil(cols / spread));
          return {pages: pages, spread: spread};
        }
        function go(page) {
          var m = metrics();
          page = Math.max(0, Math.min(page | 0, m.pages - 1));
          currentPage = page;
          wrapper.scrollLeft = page * window.innerWidth;
          post(m.pages, page);
        }
        function apply(s) {
          settings = Object.assign(settings, s || {});
          var scale = Number(settings.scale) || 1;
          var lh = Number(settings.lineHeight) || 1.55;
          var align = settings.align === 'justify' ? 'justify' : 'left';
          var bg = settings.bg || '#ffffff';
          var fg = settings.fg || '#111111';
          style.textContent = [
            'html, body { margin:0 !important; padding:0 !important; height:100% !important; overflow:hidden !important; background:' + bg + ' !important; color:' + fg + ' !important; }',
            '#__epub_paginator { height:100vh; box-sizing:border-box; padding:34px 46px; overflow-x:auto; overflow-y:hidden; column-fill:auto; background:' + bg + ' !important; color:' + fg + ' !important; font-size:' + (16 * scale) + 'px !important; line-height:' + lh + ' !important; }',
            '#__epub_paginator p, #__epub_paginator li, #__epub_paginator div { text-align:' + align + ' !important; }',
            '#__epub_paginator a { color:' + fg + ' !important; }',
            '#__epub_paginator::-webkit-scrollbar { display:none; }',
            'img, svg { max-width:100%; height:auto; }'
          ].join('\n');
          var m = metrics();
          currentPage = Math.max(0, Math.min(currentPage, m.pages - 1));
          go(currentPage);
        }

        window.__epubApplySettings = apply;
        apply(window.__epubReaderSettings || {});

        wrapper.addEventListener('scroll', function() {
          var m = metrics();
          var p = Math.round(wrapper.scrollLeft / window.innerWidth);
          if (p !== currentPage) {
            currentPage = p;
            post(m.pages, p);
          }
        });
        window.addEventListener('resize', function() {
          setTimeout(function() {
            var m = metrics();
            currentPage = Math.min(currentPage, m.pages - 1);
            go(currentPage);
          }, 60);
        });
        window.__epubGoToPage = go;
        setTimeout(function() {
          var m = metrics();
          currentPage = Math.min(currentPage, m.pages - 1);
          go(currentPage);
        }, 120);
        setTimeout(function() { go(currentPage); }, 600);
      }
      if (document.readyState === 'complete') build();
      else window.addEventListener('load', build);
    })();
    """
}
