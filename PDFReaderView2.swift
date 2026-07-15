// PDFReaderView2.swift
// Wraps PDFKit's PDFView in a SwiftUI-compatible component.
// PATCHED:
//   B1 — Replace unreliable PDFViewPageChanged notification with 1 Hz polling.
//   B2 — PDFReaderScreen no longer holds @State var currentPage.
//         coordinator.currentPage is the single source of truth.
// AUDIT:
//   Task 4  — Security-scoped access is held in the Coordinator and released in
//             dismantleNSView, NOT via a defer in makeNSView. This ensures PDFKit's
//             lazy page renderer can read pages after makeNSView returns.
//   Task 6  — Polling timer invalidated in dismantleNSView (correct teardown hook).
//   Task 7  — Confirmed: no @State var currentPage in PDFReaderScreen.
//   Task 19 — PDFReaderScreen surfaces a load error via @State errorMessage.
//   Task 20 — updateNSView already guards nil document; confirmed correct.
//   Task 23 — stopPolling() and stopSecurityAccess() called from dismantleNSView.
// READER POLISH (this pass):
//   Visual — backgroundColor + pageBreakMargins give the page breathing room;
//            PDFKit renders its own native page shadow against the contrast
//            (no custom drawing added).
//   Render — interpolationQuality raised for crisper scroll/zoom rendering.
//   Zoom   — min/maxScaleFactor bound the range so autoScales can't collapse
//            a page to an illegible sliver or blow it up past usefulness.
//   Zoom   — trackManualZoom() piggybacks on the existing 1 Hz polling timer:
//            if scaleFactor moves without a bounds-size change, that's a
//            manual zoom, so autoScales is turned off to preserve it across
//            later window resizes.
//   Nothing in security-scoped access, polling cadence, the onPageChange /
//   onLoadError contracts, document loading, or teardown logic was touched.

import AppKit
import PDFKit
import SwiftUI

// MARK: - PDFReaderView

struct PDFReaderView: NSViewRepresentable {
    let book: Book
    /// B2: Plain value — the coordinator is the only writer.
    let currentPage: Int
    let onPageChange: (Int) -> Void
    /// TASK 19: Sentinel value (-1) signals a load failure to PDFReaderScreen.
    /// Normal page indices are ≥ 0; -1 is used exclusively for error signalling.
    let onLoadError: ((String) -> Void)?

    init(book: Book,
         currentPage: Int,
         onPageChange: @escaping (Int) -> Void,
         onLoadError: ((String) -> Void)? = nil)
    {
        self.book = book
        self.currentPage = currentPage
        self.onPageChange = onPageChange
        self.onLoadError = onLoadError
    }

    func makeNSView(context: Context) -> PDFView {
        print("🔍 [PDFReaderView] makeNSView called for book: \(book.title)")
        print("🔍 [PDFReaderView] Original fileURL: \(book.fileURL.path)")
        print("🔍 [PDFReaderView] Has bookmarkData: \(book.bookmarkData != nil)")

        let view = PDFView()
        view.displayMode = .singlePageContinuous
        view.autoScales = true
        view.displayDirection = .vertical
        view.delegate = context.coordinator

        // READER POLISH: visual presentation.
        // Stock PDFView has no page insets and no contrast against its own
        // background, so the page reads as a flat rectangle wallpapered onto
        // the window. A comfortable inset plus a contrasting system backdrop
        // reproduces the "page floating on a mat" look of Preview.app/Books —
        // PDFKit renders the page's drop shadow natively against that
        // background; nothing here draws anything by hand. Side margins are
        // slightly larger than the page-to-page gap, echoing the proportions
        // of a printed page's own margins.
        view.backgroundColor = .underPageBackgroundColor
        view.displaysPageBreaks = true
        view.pageBreakMargins = NSEdgeInsets(top: 36, left: 44, bottom: 36, right: 44)

        // READER POLISH: rendering quality.
        // Keeps glyph edges and images crisp while scrolling or zoomed past
        // 100%, instead of the coarser default sampling.
        view.interpolationQuality = .high

        // READER POLISH: zoom range.
        // Unconfigured min/maxScaleFactor leave very little headroom to zoom
        // in for detail or out for an overview, and don't stop autoScales
        // from blowing a small page up into a blurry, oversized fit. These
        // bounds are generous but finite in both directions.
        view.minScaleFactor = 0.25
        view.maxScaleFactor = 6.0

        // Security-scoped access: resolve URL and start accessing before reading.
        guard let resolvedURL = book.resolveURL() else {
            let msg = "Could not resolve file URL for \(book.title)"
            print("❌ PDF ERROR: \(msg)")
            DispatchQueue.main.async { self.onLoadError?(msg) }
            return view
        }

        print("🔍 [PDFReaderView] Resolved URL: \(resolvedURL.path)")
        print("🔍 [PDFReaderView] File exists: \(FileManager.default.fileExists(atPath: resolvedURL.path))")

        let didStartAccess = resolvedURL.startAccessingSecurityScopedResource()
        print("🔍 [PDFReaderView] Security scope started: \(didStartAccess)")

        guard didStartAccess else {
            let msg = "Could not access security-scoped resource for \(book.title)"
            print("❌ PDF ERROR: \(msg)")
            DispatchQueue.main.async { self.onLoadError?(msg) }
            return view
        }

        // TASK 4 FIX: DO NOT use `defer` here to stop security access.
        //
        // Rationale: PDFKit with .singlePageContinuous renders pages lazily.
        // The actual file read for individual pages happens AFTER makeNSView
        // returns (on PDFKit's internal render queue), which is AFTER any defer
        // block fires. Stopping access inside makeNSView causes blank pages,
        // rendering gaps, or crashes on large PDFs.
        //
        // Solution: Store resolvedURL in the Coordinator. Call stopSecurityAccess()
        // from dismantleNSView (the correct NSViewRepresentable teardown hook),
        // which is called by SwiftUI when the view is permanently removed from
        // the hierarchy — guaranteeing the scope is held for the full PDF lifetime.
        //
        // Original (WRONG):
        //   defer { resolvedURL.stopAccessingSecurityScopedResource() }
        //
        // Fixed: see dismantleNSView below and Coordinator.stopSecurityAccess().
        context.coordinator.startSecurityAccess(url: resolvedURL)

        print("🔍 [PDFReaderView] Creating PDFDocument from resolved URL")
        guard let doc = PDFDocument(url: resolvedURL) else {
            let msg = "Could not open PDF document for \(book.title)"
            print("❌ PDF ERROR: \(msg)")
            // Release scope immediately — no document was created
            context.coordinator.stopSecurityAccess()
            DispatchQueue.main.async { self.onLoadError?(msg) }
            return view
        }

        print("✅ [PDFReaderView] PDFDocument created successfully, pageCount: \(doc.pageCount)")

        view.document = doc
        if currentPage > 0, let page = doc.page(at: currentPage) {
            print("🔍 [PDFReaderView] Navigating to page: \(currentPage)")
            view.go(to: page)
        }

        // B1 FIX: start deterministic 1 Hz polling instead of relying on
        // PDFViewPageChanged (which only fires on "topmost page" changes in
        // continuous scroll mode, not on every page the user passes through).
        context.coordinator.startPolling(view: view)

        print("✅ [PDFReaderView] makeNSView completed successfully")
        return view
    }

    func updateNSView(_ nsView: PDFView, context _: Context) {
        // TASK 20 (confirmed): guard nil document — no security access started here.
        guard let doc = nsView.document else { return }
        // Only jump if the external currentPage differs from what's displayed.
        // This is purely a playback path (e.g. restoring a saved position).
        if let displayed = nsView.currentPage,
           doc.index(for: displayed) != currentPage,
           let target = doc.page(at: currentPage)
        {
            nsView.go(to: target)
        }
    }

    /// TASK 6 / TASK 23: dismantleNSView is the correct NSViewRepresentable teardown
    /// hook. It is called when SwiftUI permanently removes the view from the hierarchy
    /// (not on every re-render). This is where we:
    ///   1. Stop the 1 Hz polling timer (prevents run-loop retain cycles).
    ///   2. Release the security-scoped resource (balances startAccessingSecurityScopedResource
    ///      from makeNSView, allowing PDFKit to finish any in-flight page renders first).
    static func dismantleNSView(_ nsView: PDFView, coordinator: Coordinator) {
        coordinator.stopPolling() // TASK 6 / TASK 23
        coordinator.stopSecurityAccess() // TASK 4 / TASK 23
        nsView.document = nil // Release PDFDocument before scope ends
        print("🔍 [PDFReaderView] dismantleNSView: timer stopped, security scope released")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPageChange: onPageChange)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PDFViewDelegate {
        let onPageChange: (Int) -> Void

        // B1: polling state
        private var pollingTimer: Timer?
        private var lastReportedPage: Int = -1

        /// TASK 4: Security-scoped URL held for the lifetime of the PDFView.
        /// Nil when no scope is active (before makeNSView or after dismantleNSView).
        private var securityScopedURL: URL?

        // READER POLISH: zoom-preservation state — see trackManualZoom(on:).
        private var userHasCustomZoom = false
        private var lastKnownBoundsSize: CGSize?
        private var lastKnownScaleFactor: CGFloat?

        init(onPageChange: @escaping (Int) -> Void) {
            self.onPageChange = onPageChange
        }

        deinit {
            // Defensive cleanup — dismantleNSView should have fired first.
            pollingTimer?.invalidate()
            securityScopedURL?.stopAccessingSecurityScopedResource()
        }

        /// TASK 4: Called from makeNSView after successfully starting access.
        func startSecurityAccess(url: URL) {
            // If a previous URL is still held, release it first (shouldn't happen
            // in normal usage, but guards against view reuse edge cases).
            stopSecurityAccess()
            securityScopedURL = url
        }

        /// TASK 4 / TASK 23: Called from dismantleNSView to release the scope.
        func stopSecurityAccess() {
            securityScopedURL?.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
        }

        /// B1 FIX: 1 Hz timer; fires onPageChange only when page actually changes.
        func startPolling(view: PDFView) {
            pollingTimer?.invalidate()

            // READER POLISH: fresh zoom-tracking baseline for this PDFView.
            userHasCustomZoom = false
            lastKnownBoundsSize = nil
            lastKnownScaleFactor = nil

            pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak view] _ in
                guard let self, let view else { return }

                // READER POLISH: independent of page detection below — never
                // changes lastReportedPage and never touches onPageChange.
                self.trackManualZoom(on: view)

                guard let page = view.currentPage,
                      let doc = view.document else { return }
                let idx = doc.index(for: page)
                guard idx != self.lastReportedPage else { return }
                self.lastReportedPage = idx
                self.onPageChange(idx)
            }
        }

        /// TASK 6 / TASK 23: Called from dismantleNSView.
        func stopPolling() {
            pollingTimer?.invalidate()
            pollingTimer = nil
        }

        /// READER POLISH: detects a user-driven zoom (trackpad pinch, ⌘+/⌘-, or
        /// any other path that changes scaleFactor) so it survives window
        /// resizing instead of snapping back to fit-to-page on the next layout
        /// pass.
        ///
        /// autoScales recomputes scaleFactor to match the view's bounds on
        /// every bounds change, so a genuine window resize always moves
        /// scaleFactor and bounds.size together within the same tick. If
        /// scaleFactor moves while bounds.size does not, the only remaining
        /// explanation is a manual zoom — at that point autoScales is turned
        /// off so the chosen zoom level is preserved through future resizes.
        /// A newly opened book gets a fresh Coordinator (see makeCoordinator
        /// and the NavigationLink call sites in NewContentView/LibraryView),
        /// so this state never leaks from one book to the next.
        private func trackManualZoom(on view: PDFView) {
            let boundsSize = view.bounds.size
            let scale = view.scaleFactor

            defer {
                lastKnownBoundsSize = boundsSize
                lastKnownScaleFactor = scale
            }

            guard !userHasCustomZoom,
                  let lastBounds = lastKnownBoundsSize,
                  let lastScale = lastKnownScaleFactor,
                  lastBounds == boundsSize,
                  abs(lastScale - scale) > 0.001
            else { return }

            userHasCustomZoom = true
            view.autoScales = false
        }
    }
}

// MARK: - PDFReaderScreen

/// B2 FIX: @State var currentPage removed entirely.
/// coordinator.currentPage is the single authoritative source; this view
/// observes it via @ObservedObject and passes it read-only to PDFReaderView.
///
/// TASK 19: errorMessage state added so PDF load failures surface to the user.
struct PDFReaderScreen: View {
    let book: Book
    @ObservedObject var coordinator: SessionCoordinator

    /// TASK 19: Populated when PDFReaderView signals a load failure.
    @State private var errorMessage: String?

    init(book: Book, coordinator: SessionCoordinator) {
        self.book = book
        self.coordinator = coordinator
    }

    var body: some View {
        Group {
            if let error = errorMessage {
                // TASK 19: Show an error overlay instead of a blank screen.
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("Could Not Open PDF")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PDFReaderView(
                    book: book,
                    currentPage: coordinator.currentPage, // read-only; coordinator is the writer
                    onPageChange: { newPage in
                        // onPageChange callback → coordinator is the only entity that
                        // writes currentPage, which in turn updates DataStore.
                        coordinator.turnToPage(newPage)
                    },
                    onLoadError: { message in
                        // TASK 19: Surface the error to the user.
                        errorMessage = message
                    }
                )
            }
        }
        .onAppear {
            coordinator.startReading(bookID: book.id, page: coordinator.currentPage)
        }
        .onDisappear {
            coordinator.endCurrentSession()
        }
    }
}
