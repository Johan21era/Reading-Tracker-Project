//
//  EPUBReaderScreen.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 7/6/26.
//


//
//  EPUBReaderScreen.swift
//  Reading Tracker
//
//  Architectural redesign — see EPUB_READER_REDESIGN_PLAN.txt (this file's
//  single source of truth). Previous version extracted a fixed ~3,000-
//  character plain-text snippet with no navigation; this version renders
//  full chapter content via WKWebView and supports real chapter-by-chapter
//  navigation, matching the reading-position contract SessionCoordinator
//  already establishes for the PDF reader.
//
//  External contract preserved exactly: init(book: Book, coordinator:
//  SessionCoordinator) — unchanged, so both call sites (NewContentView,
//  and the dead-in-practice LibraryView) keep compiling untouched.
//

import SwiftUI
import WebKit
import os

// MARK: - EPUBReaderScreen

struct EPUBReaderScreen: View {
    let book: Book
    @ObservedObject var coordinator: SessionCoordinator

    @State private var package: EPUBPackage?
    @State private var currentChapterIndex: Int = 0
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var showingChapterList = false
    @State private var showingInfo = false

    /// Reference to the in-flight open Task so it can be cancelled on
    /// disappear, exactly like the previous implementation's loadTask.
    @State private var openTask: Task<Void, Never>?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ReadingTracker",
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
            }
            coordinator.startReading(bookID: book.id, page: coordinator.currentPage)
        }
        .onDisappear {
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

            let startIndex = startingChapterIndex(in: opened, resumingFrom: coordinator.currentPage)

            await MainActor.run {
                guard !Task.isCancelled else {
                    opened.close()
                    return
                }
                self.package = opened
                self.currentChapterIndex = startIndex
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

    private var canGoToPreviousChapter: Bool { currentChapterIndex > 0 }

    private var canGoToNextChapter: Bool {
        guard let package else { return false }
        return currentChapterIndex < package.chapterCount - 1
    }

    private func goToChapter(_ index: Int) {
        guard let package, package.chapterCount > 0 else { return }
        let clamped = max(0, min(index, package.chapterCount - 1))
        currentChapterIndex = clamped

        // book.chapters may not have an entry for every spine index (see
        // startingChapterIndex above) — only update the tracked reading
        // position when there's a real page number to report.
        if book.chapters.indices.contains(clamped) {
            coordinator.turnToPage(book.chapters[clamped].startPage)
        }
    }

    private func chapterTitle(at index: Int) -> String {
        book.chapters.indices.contains(index) ? book.chapters[index].title : "Chapter \(index + 1)"
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

    private var contentView: some View {
        Group {
            if let package, let url = package.fileURL(forChapterAt: currentChapterIndex) {
                EPUBChapterWebView(
                    fileURL: url,
                    allowedReadRoot: package.allowedReadRoot,
                    onExternalLink: { url in
                        NSWorkspace.shared.open(url)
                    },
                    onLoadError: { message in
                        logger.error("Chapter failed to render: \(message)")
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
    }

    private var chapterListPopover: some View {
        List(book.chapters) { chapter in
            Button {
                goToChapter(chapter.index)
                showingChapterList = false
            } label: {
                HStack {
                    Text(chapter.title)
                    Spacer()
                    if chapter.index == currentChapterIndex {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(minWidth: 280, minHeight: 320)
    }

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
                Label("\(book.chapters.count) chapters", systemImage: "list.bullet")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            if let difficulty = book.difficultyProfile {
                Label(String(format: "Grade %.1f", difficulty.gradeLevel), systemImage: "chart.bar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
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
    let onExternalLink: (URL) -> Void
    let onLoadError: (String) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Chapter content is untrusted-ish book content, not app UI — it
        // never needs to execute script.
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        webView.loadFileURL(fileURL, allowingReadAccessTo: allowedReadRoot)
        context.coordinator.currentlyLoadedURL = fileURL
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.currentlyLoadedURL != fileURL else { return }
        context.coordinator.currentlyLoadedURL = fileURL
        webView.loadFileURL(fileURL, allowingReadAccessTo: allowedReadRoot)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onExternalLink: onExternalLink, onLoadError: onLoadError)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var currentlyLoadedURL: URL?
        let onExternalLink: (URL) -> Void
        let onLoadError: (String) -> Void

        init(onExternalLink: @escaping (URL) -> Void, onLoadError: @escaping (String) -> Void) {
            self.onExternalLink = onExternalLink
            self.onLoadError = onLoadError
        }

        /// Local file loads (the chapter itself, and its relative
        /// resources) are always allowed. A user clicking an actual link
        /// inside the chapter (e.g. a footnote pointing at a web URL) is
        /// handed to the system browser instead of navigating the reader
        /// away from the book.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                onExternalLink(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onLoadError(error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadError(error.localizedDescription)
        }
    }
}