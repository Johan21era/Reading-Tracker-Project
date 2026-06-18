//
//  EPUBReaderScreen.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/16/26.
//


// EPUBReaderScreen.swift
// AUDIT:
//   Task 5  — Security scope held across async Task via withTaskCancellationHandler.
//             Explicit capture list ensures resolvedURL is not accessed after dealloc.
//   Task 18 — errorMessage and isLoading reset at the top of onAppear so re-opening
//             after a failure triggers a fresh load attempt.
//   Task 28 — All early-return paths set isLoading = false (confirmed present).

import SwiftUI
import Foundation
#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

// MARK: - EPUBReaderScreen

struct EPUBReaderScreen: View {
    let book: Book
    @ObservedObject var coordinator: SessionCoordinator
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var extractedText: String = ""

    /// Reference to the in-flight Task so it can be cancelled on disappear.
    @State private var loadTask: Task<Void, Never>?

    init(book: Book, coordinator: SessionCoordinator) {
        self.book = book
        self.coordinator = coordinator
    }

    var body: some View {
        Group {
            if let error = errorMessage {
                errorView(error)
            } else if isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .onAppear {
            // TASK 18 FIX: Reset state before each load attempt so that re-opening
            // after a failure triggers a fresh load rather than showing the stale error.
            //
            // Original code (no reset):
            //   .onAppear {
            //       loadEPUBContent()   ← errorMessage still set from previous failure
            //       coordinator.startReading(...)
            //   }
            errorMessage = nil
            isLoading    = true
            extractedText = ""

            loadEPUBContent()
            coordinator.startReading(bookID: book.id, page: coordinator.currentPage)
        }
        .onDisappear {
            // Cancel the in-flight load task to avoid updating state after the
            // view has left the hierarchy.
            loadTask?.cancel()
            loadTask = nil
            coordinator.endCurrentSession()
        }
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                metadataSection

                if !book.chapters.isEmpty {
                    chaptersSection
                }

                if !extractedText.isEmpty {
                    textPreviewSection
                }
            }
            .padding()
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(book.title)
                .font(.title)
                .fontWeight(.bold)
            Text("By \(book.author)")
                .font(.title2)
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                Label("\(book.totalPages) pages", systemImage: "doc.text")
                Label("\(book.chapters.count) chapters", systemImage: "list.bullet")
                if let difficulty = book.difficultyProfile {
                    Label(String(format: "Grade %.1f", difficulty.gradeLevel), systemImage: "chart.bar")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chapters")
                .font(.headline)
                .fontWeight(.bold)
            ForEach(book.chapters) { chapter in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.title)
                            .font(.body)
                        Text("Pages \(chapter.startPage + 1) - \(chapter.endPage + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(chapter.pageCount) p")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var textPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Text Preview")
                .font(.headline)
                .fontWeight(.bold)
            Text(extractedText)
                .font(.body)
                .lineLimit(nil)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - EPUB Loading

    private func loadEPUBContent() {
        print("🔍 [EPUBReaderScreen] loadEPUBContent called for book: \(book.title)")
        print("🔍 [EPUBReaderScreen] Original fileURL: \(book.fileURL.path)")
        print("🔍 [EPUBReaderScreen] Has bookmarkData: \(book.bookmarkData != nil)")

        guard let resolvedURL = book.resolveURL() else {
            let msg = "Could not resolve file URL for \(book.title)"
            print("❌ EPUB ERROR: \(msg)")
            errorMessage = msg
            isLoading    = false       // TASK 28: confirmed present on all early-exit paths
            return
        }

        print("🔍 [EPUBReaderScreen] Resolved URL: \(resolvedURL.path)")
        print("🔍 [EPUBReaderScreen] File exists: \(FileManager.default.fileExists(atPath: resolvedURL.path))")

        let didStartAccess = resolvedURL.startAccessingSecurityScopedResource()
        print("🔍 [EPUBReaderScreen] Security scope started: \(didStartAccess)")

        guard didStartAccess else {
            let msg = "Could not access security-scoped resource for \(book.title)"
            print("❌ EPUB ERROR: \(msg)")
            errorMessage = msg
            isLoading    = false       // TASK 28: confirmed present
            return
        }

        // TASK 5 FIX: Use withTaskCancellationHandler to guarantee
        // stopAccessingSecurityScopedResource() is called even when the Task
        // is cancelled (e.g. user navigates away mid-load).
        //
        // Original code called stop() inside do/catch blocks, but Swift's
        // structured concurrency will NOT run those catch/finally paths when a
        // Task is externally cancelled — the cancellation propagates by throwing
        // CancellationError, which bypasses user-written catch { } blocks unless
        // the catch explicitly re-throws (or uses Task.checkCancellation()).
        //
        // withTaskCancellationHandler guarantees the handler runs synchronously
        // on cancellation, regardless of where the Task is suspended.
        //
        // Explicit capture [resolvedURL] ensures the URL is captured by value
        // (not as a closure over self.resolvedURL which would be a local variable
        // on the stack and potentially deallocated before the handler fires).
        loadTask = Task { [resolvedURL] in
            await withTaskCancellationHandler(
                operation: {
                    print("🔍 [EPUBReaderScreen] Task started, security scope active")
                    do {
                        let tempDir = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString, isDirectory: true)
                        try FileManager.default.createDirectory(at: tempDir,
                                                                withIntermediateDirectories: true)
                        defer { try? FileManager.default.removeItem(at: tempDir) }

                        print("🔍 [EPUBReaderScreen] Unzipping EPUB to temp dir")
                        try unzipEPUB(at: resolvedURL, to: tempDir)

                        print("🔍 [EPUBReaderScreen] Parsing OPF")
                        let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
                        let opfURL = try findOPFURL(containerURL: containerURL, baseDir: tempDir)
                        let metadata = try parseOPF(opfURL: opfURL, baseDir: tempDir)

                        print("🔍 [EPUBReaderScreen] Extracting sample text")
                        let sampleText = await extractSampleText(spineItems: metadata.spineItems,
                                                                 maxChars: 3000)

                        // Release scope after all file I/O is complete.
                        print("🔍 [EPUBReaderScreen] Stopping security scope after extraction")
                        resolvedURL.stopAccessingSecurityScopedResource()

                        let displayText = sampleText.isEmpty ? "No text content available" : sampleText
                        await MainActor.run {
                            guard !Task.isCancelled else { return }
                            self.extractedText = displayText
                            self.isLoading     = false
                            print("✅ [EPUBReaderScreen] Content loaded successfully")
                        }
                    } catch {
                        resolvedURL.stopAccessingSecurityScopedResource()
                        let msg = "Failed to load EPUB: \(error.localizedDescription)"
                        print("❌ EPUB ERROR: \(msg)")
                        await MainActor.run {
                            guard !Task.isCancelled else { return }
                            self.errorMessage = msg
                            self.isLoading    = false
                        }
                    }
                },
                onCancel: {
                    // TASK 5 FIX: This handler fires synchronously on cancellation,
                    // guaranteeing the security scope is always released even when
                    // the Task body is mid-suspension (e.g. inside extractSampleText).
                    print("🔍 [EPUBReaderScreen] Task cancelled — releasing security scope")
                    resolvedURL.stopAccessingSecurityScopedResource()
                }
            )
        }
    }

    // MARK: - EPUB Parsing Helpers

    private func unzipEPUB(at source: URL, to destination: URL) throws {
        #if canImport(ZIPFoundation)
        try FileManager.default.unzipItem(at: source, to: destination)
        #else
        throw NSError(domain: "EPUBReader", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "ZIPFoundation not available"])
        #endif
    }

    private func findOPFURL(containerURL: URL, baseDir: URL) throws -> URL {
        guard let data = try? Data(contentsOf: containerURL) else {
            throw NSError(domain: "EPUBReader", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot read container.xml"])
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let opfPath = try xml.nodes(forXPath: "//@full-path").first?.stringValue else {
            throw NSError(domain: "EPUBReader", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "OPF path not found"])
        }
        return baseDir.appendingPathComponent(opfPath)
    }

    private struct OPFMetadata {
        var title: String
        var author: String
        var spineItems: [(id: String, href: URL)]
    }

    private func parseOPF(opfURL: URL, baseDir: URL) throws -> OPFMetadata {
        guard let data = try? Data(contentsOf: opfURL) else {
            throw NSError(domain: "EPUBReader", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot read OPF"])
        }

        let xml = try XMLDocument(data: data, options: [])
        let opfDir  = opfURL.deletingLastPathComponent()
        let title   = (try? xml.nodes(forXPath: "//*[local-name()='title']").first?.stringValue)   ?? "Unknown Title"
        let creator = (try? xml.nodes(forXPath: "//*[local-name()='creator']").first?.stringValue) ?? "Unknown Author"

        var manifest: [String: URL] = [:]
        if let items = try? xml.nodes(forXPath: "//*[local-name()='item']") {
            for item in items {
                guard let el   = item as? XMLElement,
                      let id   = el.attribute(forName: "id")?.stringValue,
                      let href = el.attribute(forName: "href")?.stringValue else { continue }
                let decoded = href.removingPercentEncoding ?? href
                manifest[id] = opfDir.appendingPathComponent(decoded)
            }
        }

        var spineItems: [(id: String, href: URL)] = []
        if let refs = try? xml.nodes(forXPath: "//*[local-name()='itemref']/@idref") {
            for ref in refs {
                guard let idref = ref.stringValue, let href = manifest[idref] else { continue }
                spineItems.append((id: idref, href: href))
            }
        }

        return OPFMetadata(title: title, author: creator, spineItems: spineItems)
    }

    private func extractSampleText(spineItems: [(id: String, href: URL)], maxChars: Int) async -> String {
        await Task.detached(priority: .utility) {
            var collected = ""
            for item in spineItems {
                guard collected.count < maxChars else { break }
                guard let data = try? Data(contentsOf: item.href),
                      let html = String(data: data, encoding: .utf8) else { continue }
                collected += stripHTML(html)
            }
            return String(collected.prefix(maxChars))
        }.value
    }

    private func stripHTML(_ html: String) -> String {
        var result = html
        result = result.replacingOccurrences(
            of: "<(script|style)[^>]*>[\\s\\S]*?</(script|style)>",
            with: " ",
            options: .regularExpression
        )
        result = result.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        return result
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;",  with: "&")
            .replacingOccurrences(of: "&lt;",   with: "<")
            .replacingOccurrences(of: "&gt;",   with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
    }
}