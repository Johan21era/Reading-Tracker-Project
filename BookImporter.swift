// BookImporter.swift
// Handles importing EPUB and PDF files, extracting metadata and chapter structure.
// PATCHED: B4 — security-scoped bookmark is now computed AND stored in Book.bookmarkData
//               for both PDF and EPUB paths so file access survives app restart.
// AUDIT:
//   Task 1  — importPDF: bookmark creation wrapped in do/catch; failure is logged,
//             not silently dropped via try?. Book is still created (import succeeded).
//   Task 2  — importEPUB: same treatment as Task 1.
//   Task 21 — importBook: scope opened before switch (confirmed correct; validated).

import Foundation
import PDFKit
#if canImport(ZIPFoundation)
    import ZIPFoundation
#endif
#if canImport(Compression)
    import Compression
#endif

// MARK: - ImportError

enum ImportError: LocalizedError {
    case unsupportedFileType(String)
    case fileNotReadable(URL)
    case epubMissingOPF
    case epubParseFailure(String)
    case epubUnzipFailure(String)
    case pdfOpenFailure

    var errorDescription: String? {
        switch self {
        case let .unsupportedFileType(ext): return "Unsupported file type: \(ext)"
        case let .fileNotReadable(url): return "Cannot read file at \(url.path)"
        case .epubMissingOPF: return "EPUB is missing OPF package document"
        case let .epubParseFailure(msg): return "EPUB parse error: \(msg)"
        case let .epubUnzipFailure(msg): return "Failed to unzip EPUB: \(msg)"
        case .pdfOpenFailure: return "Could not open PDF document"
        }
    }
}

// MARK: - BookImporter

enum BookImporter {
    /// TASK 21 (validated): Security scope is opened before the switch dispatch and
    /// released via defer when importBook returns. Since importEPUB is async, the
    /// defer fires only after `await importEPUB(url:)` completes — holding the scope
    /// for the full duration of both synchronous (PDF) and asynchronous (EPUB) imports.
    static func importBook(from url: URL) async throws -> Book {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileNotReadable(url)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        switch url.pathExtension.lowercased() {
        case "epub": return try await importEPUB(url: url)
        case "pdf": return try importPDF(url: url)
        default: throw ImportError.unsupportedFileType(url.pathExtension)
        }
    }

    // MARK: - PDF Import

    static func importPDF(url: URL) throws -> Book {
        guard let doc = PDFDocument(url: url) else { throw ImportError.pdfOpenFailure }

        let totalPages = doc.pageCount
        let title = (doc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let author = (doc.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String)
            ?? "Unknown"

        var chapters: [Chapter] = []
        if let outline = doc.outlineRoot {
            chapters = extractChapters(from: outline, totalPages: totalPages)
        }

        // TASK 1 FIX: Wrap bookmark creation in do/catch so failures are logged
        // rather than silently discarded by try?.
        //
        // Original (WRONG — silently drops bookmark errors):
        //   let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, ...)
        //
        // A nil bookmark means the book can only be opened in the same app launch
        // as the import (the sandbox URL remains valid within a session). On restart,
        // resolveURL() falls back to the raw URL, which the sandbox will reject.
        //
        // We still create the Book even if bookmark creation fails — the import
        // itself succeeded and the book is usable in the current session.
        var bookmarkData: Data?
        do {
            bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            print("[BookImporter] Warning: could not create security-scoped bookmark " +
                "for PDF '\(url.lastPathComponent)': \(error). " +
                "File will not be accessible after app restart. " +
                "Check that the app has the com.apple.security.files.bookmarks.app-scope entitlement.")
        }

        return Book(
            title: title,
            author: author,
            fileURL: url,
            fileType: .pdf,
            totalPages: totalPages,
            chapters: chapters,
            bookmarkData: bookmarkData
        )
    }

    private static func extractChapters(from outline: PDFOutline, totalPages: Int) -> [Chapter] {
        var result: [Chapter] = []
        var index = 0

        func visit(_ node: PDFOutline) {
            if let dest = node.destination,
               let page = dest.page,
               let doc = page.document,
               let label = node.label, !label.isEmpty
            {
                let pageNum = doc.index(for: page)
                result.append(Chapter(title: label, index: index, startPage: pageNum, endPage: pageNum))
                index += 1
            }
            for i in 0 ..< node.numberOfChildren {
                if let child = node.child(at: i) {
                    visit(child)
                }
            }
        }
        visit(outline)

        for i in 0 ..< result.count {
            let nextStart = i + 1 < result.count ? result[i + 1].startPage - 1 : totalPages - 1
            result[i].endPage = max(result[i].startPage, nextStart)
        }
        return result
    }

    // MARK: - EPUB Import

    private static func unzipEPUB(at source: URL, to destination: URL) throws {
        #if canImport(ZIPFoundation)
            do {
                try FileManager.default.unzipItem(at: source, to: destination)
                return
            } catch { /* fall through */ }
        #endif
        do {
            guard let archive = Archive(url: source, accessMode: .read) else {
                throw ImportError.epubUnzipFailure("Cannot open archive")
            }
            for entry in archive {
                let entryURL = destination.appendingPathComponent(entry.path)
                let entryDir = entryURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: entryDir, withIntermediateDirectories: true)
                _ = try archive.extract(entry, to: entryURL)
            }
        } catch {
            throw ImportError.epubUnzipFailure(error.localizedDescription)
        }
    }

    static func importEPUB(url: URL) async throws -> Book {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try unzipEPUB(at: url, to: tempDir)

        let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
        let opfURL = try findOPFURL(containerURL: containerURL, baseDir: tempDir)
        let metadata = try parseOPF(opfURL: opfURL, baseDir: tempDir)

        let wordCount = await estimateTotalWords(spineItems: metadata.spineItems)
        let estimatedPages = max(1, wordCount / 250)
        let chapters = buildChapters(from: metadata, estimatedTotalPages: estimatedPages)

        let sampleText = await extractSampleText(spineItems: metadata.spineItems, maxChars: 5000)
        let difficulty = DifficultyAnalyzer.analyze(text: sampleText)

        // TASK 2 FIX: Same treatment as Task 1 — do/catch instead of try?.
        //
        // Original (WRONG — silently drops bookmark errors):
        //   let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, ...)
        var bookmarkData: Data?
        do {
            bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            print("[BookImporter] Warning: could not create security-scoped bookmark " +
                "for EPUB '\(url.lastPathComponent)': \(error). " +
                "File will not be accessible after app restart. " +
                "Check that the app has the com.apple.security.files.bookmarks.app-scope entitlement.")
        }

        return Book(
            title: metadata.title,
            author: metadata.author,
            fileURL: url,
            fileType: .epub,
            totalPages: estimatedPages,
            chapters: chapters,
            difficultyProfile: difficulty,
            bookmarkData: bookmarkData
        )
    }

    // MARK: - EPUB Parsing Helpers

    private struct OPFMetadata {
        var title: String
        var author: String
        var spineItems: [(id: String, href: URL)]
        var tocEntries: [(title: String, href: String)]
    }

    private static func findOPFURL(containerURL: URL, baseDir: URL) throws -> URL {
        guard let data = try? Data(contentsOf: containerURL) else { throw ImportError.epubMissingOPF }
        let xml = try XMLDocument(data: data, options: [])
        guard let opfPath = try xml.nodes(forXPath: "//@full-path").first?.stringValue else {
            throw ImportError.epubMissingOPF
        }
        return baseDir.appendingPathComponent(opfPath)
    }

    private static func parseOPF(opfURL: URL, baseDir _: URL) throws -> OPFMetadata {
        guard let data = try? Data(contentsOf: opfURL) else {
            throw ImportError.epubParseFailure("Cannot read OPF at \(opfURL.path)")
        }

        let xml: XMLDocument
        do { xml = try XMLDocument(data: data, options: []) } catch {
            throw ImportError.epubParseFailure(error.localizedDescription)
        }

        let opfDir = opfURL.deletingLastPathComponent()
        let title = (try? xml.nodes(forXPath: "//*[local-name()='title']").first?.stringValue) ?? "Unknown Title"
        let creator = (try? xml.nodes(forXPath: "//*[local-name()='creator']").first?.stringValue) ?? "Unknown Author"

        var manifest: [String: URL] = [:]
        if let items = try? xml.nodes(forXPath: "//*[local-name()='item']") {
            for item in items {
                guard let el = item as? XMLElement,
                      let id = el.attribute(forName: "id")?.stringValue,
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

        var tocEntries: [(title: String, href: String)] = []
        if let ncxID = (try? xml.nodes(forXPath: "//*[local-name()='spine']/@toc").first?.stringValue),
           let ncxURL = manifest[ncxID]
        {
            tocEntries = parseTOCncx(ncxURL: ncxURL)
        }

        return OPFMetadata(title: title, author: creator,
                           spineItems: spineItems, tocEntries: tocEntries)
    }

    private static func parseTOCncx(ncxURL: URL) -> [(title: String, href: String)] {
        guard let data = try? Data(contentsOf: ncxURL),
              let xml = try? XMLDocument(data: data, options: []) else { return [] }

        var entries: [(title: String, href: String)] = []
        if let points = try? xml.nodes(forXPath: "//*[local-name()='navPoint']") {
            for point in points {
                guard let el = point as? XMLElement else { continue }
                let label = (try? el.nodes(forXPath: ".//*[local-name()='text']").first?.stringValue) ?? "Chapter"
                let href = (try? el.nodes(forXPath: ".//*[local-name()='content']/@src").first?.stringValue) ?? ""
                entries.append((title: label, href: href))
            }
        }
        return entries
    }

    private static func buildChapters(from meta: OPFMetadata, estimatedTotalPages: Int) -> [Chapter] {
        let spineCount = max(1, meta.spineItems.count)
        let pagesPerSpineItem = max(1, estimatedTotalPages / spineCount)

        if !meta.tocEntries.isEmpty {
            return meta.tocEntries.enumerated().map { idx, entry in
                let startPage = idx * pagesPerSpineItem
                let endPage = idx + 1 < meta.tocEntries.count
                    ? (idx + 1) * pagesPerSpineItem - 1
                    : estimatedTotalPages - 1
                return Chapter(title: entry.title, index: idx, startPage: startPage, endPage: endPage)
            }
        } else {
            return meta.spineItems.enumerated().map { idx, _ in
                let startPage = idx * pagesPerSpineItem
                let endPage = idx + 1 < meta.spineItems.count
                    ? (idx + 1) * pagesPerSpineItem - 1
                    : estimatedTotalPages - 1
                return Chapter(title: "Chapter \(idx + 1)", index: idx, startPage: startPage, endPage: endPage)
            }
        }
    }

    // MARK: - Text Analysis Helpers

    private static func estimateTotalWords(spineItems: [(id: String, href: URL)]) async -> Int {
        await Task.detached(priority: .utility) {
            var total = 0
            for item in spineItems {
                guard let data = try? Data(contentsOf: item.href),
                      let html = String(data: data, encoding: .utf8) else { continue }
                total += Self.wordCount(fromHTML: html)
            }
            return total
        }.value
    }

    private static func extractSampleText(spineItems: [(id: String, href: URL)], maxChars: Int) async -> String {
        await Task.detached(priority: .utility) {
            var collected = ""
            for item in spineItems {
                guard collected.count < maxChars else { break }
                guard let data = try? Data(contentsOf: item.href),
                      let html = String(data: data, encoding: .utf8) else { continue }
                collected += Self.stripHTML(html)
            }
            return String(collected.prefix(maxChars))
        }.value
    }

    static func wordCount(fromHTML html: String) -> Int {
        stripHTML(html).split { $0.isWhitespace }.count
    }

    static func stripHTML(_ html: String) -> String {
        var result = html
        result = result.replacingOccurrences(
            of: "<(script|style)[^>]*>[\\s\\S]*?</(script|style)>",
            with: " ", options: .regularExpression
        )
        result = result.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        return result
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
    }
}

// MARK: - DifficultyAnalyzer

enum DifficultyAnalyzer {
    static func analyze(text: String) -> ReadingDifficultyProfile {
        guard !text.isEmpty else { return .baseline }

        let words = text.split { $0.isWhitespace }.map(String.init)
        let sentences = text.components(separatedBy: .init(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let wordCount = max(1, words.count)
        let sentenceCount = max(1, sentences.count)

        let avgWordLen = Double(words.reduce(0) { $0 + $1.count }) / Double(wordCount)
        let avgSentenceLen = Double(wordCount) / Double(sentenceCount)

        let rareCount = words.filter { $0.count > 8 }.count
        let rareLexiconRatio = Double(rareCount) / Double(wordCount)

        let syllables = words.reduce(0) { $0 + approximateSyllables($1) }
        let avgSyllables = Double(syllables) / Double(wordCount)
        let gradeLevel = 0.39 * avgSentenceLen + 11.8 * avgSyllables - 15.59

        return ReadingDifficultyProfile(
            gradeLevel: max(0, gradeLevel),
            averageWordLength: avgWordLen,
            averageSentenceLength: avgSentenceLen,
            rareLexiconRatio: rareLexiconRatio
        )
    }

    private static func approximateSyllables(_ word: String) -> Int {
        let lower = word.lowercased().filter { $0.isLetter }
        guard !lower.isEmpty else { return 1 }
        let vowels = CharacterSet(charactersIn: "aeiouy")
        var count = 0
        var prevWasVowel = false
        for char in lower.unicodeScalars {
            let isVowel = vowels.contains(char)
            if isVowel && !prevWasVowel {
                count += 1
            }
            prevWasVowel = isVowel
        }
        if lower.hasSuffix("e") && count > 1 {
            count -= 1
        }
        return max(1, count)
    }
}

// MARK: - APPENDED IMPORT INTELLIGENCE LAYER (v2 FULL MODULE)

import Foundation

// MARK: - Import Analytics

struct ImportAnalyticsReport {
    let fileName: String
    let fileSizeBytes: Int?
    let fileType: String
    let complexityScore: Double
    let contentRichnessScore: Double
    let chapterQualityScore: Double
    let failureProbability: Double
}

enum ImportAnalyticsEngine {
    static func analyze(book: Book, fileName: String, fileSizeBytes: Int?, fileType: String) -> ImportAnalyticsReport {
        let chapterCount = max(book.chapters.count, 1)
        let spineFactor = min(Double(chapterCount) / 25.0, 1.0)

        let avgChapterSize = Double(book.totalPages) / Double(chapterCount)
        let chapterQuality = max(0, 1.0 - abs(avgChapterSize - 20.0) / 80.0)

        let richness = min(1.0, Double(book.totalPages) / 500.0 + Double(chapterCount) / 50.0)

        let complexity = min(1.0,
                             (Double(fileSizeBytes ?? 0) / 5_000_000.0) * 0.5 +
                                 spineFactor * 0.5)

        let failure = min(1.0,
                          (fileSizeBytes == nil ? 0.2 : 0.0) +
                              (book.chapters.isEmpty ? 0.6 : 0.0) +
                              (complexity > 0.8 ? 0.2 : 0.0))

        return ImportAnalyticsReport(
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
            fileType: fileType,
            complexityScore: complexity,
            contentRichnessScore: richness,
            chapterQualityScore: chapterQuality,
            failureProbability: failure
        )
    }
}

// MARK: - Smart Import Enhancer

struct ImportSuggestion {
    let field: String
    let issue: String
    let suggestion: String
}

enum SmartImportEnhancer {
    static func analyze(book: Book) -> [ImportSuggestion] {
        var suggestions: [ImportSuggestion] = []

        if book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            book.title.lowercased().contains("unknown")
        {
            suggestions.append(.init(
                field: "title",
                issue: "Low-quality or missing title",
                suggestion: "Extract metadata from OPF or sanitize filename"
            ))
        }

        if book.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            book.author.lowercased().contains("unknown")
        {
            suggestions.append(.init(
                field: "author",
                issue: "Missing or unknown author",
                suggestion: "Check EPUB creator tags or PDF metadata"
            ))
        }

        if book.title == book.fileURL.deletingPathExtension().lastPathComponent {
            suggestions.append(.init(
                field: "title",
                issue: "Filename-derived title",
                suggestion: "Replace with structured metadata if available"
            ))
        }

        return suggestions
    }
}

// MARK: - Chapter Refinement Engine

enum ChapterRefinementEngine {
    struct ChapterIssue {
        let chapterIndex: Int
        let issue: String
    }

    static func analyze(chapters: [Chapter]) -> [ChapterIssue] {
        var issues: [ChapterIssue] = []

        for (index, chapter) in chapters.enumerated() {
            let span = chapter.endPage - chapter.startPage

            if span < 2 {
                issues.append(.init(chapterIndex: index, issue: "Tiny chapter (<2 pages)"))
            }

            if span > 80 {
                issues.append(.init(chapterIndex: index, issue: "Oversized chapter (>80 pages)"))
            }

            if chapter.endPage < chapter.startPage {
                issues.append(.init(chapterIndex: index, issue: "Invalid chapter range"))
            }
        }

        return issues
    }
}

// MARK: - Import Warning System

enum ImportWarningLevel {
    case info
    case warning
    case critical
}

struct ImportWarning {
    let message: String
    let level: ImportWarningLevel
}

enum ImportWarningEngine {
    static func evaluate(book: Book) -> [ImportWarning] {
        var warnings: [ImportWarning] = []

        if book.chapters.isEmpty {
            warnings.append(.init(message: "No chapters extracted", level: .critical))
        }

        if book.totalPages <= 1 {
            warnings.append(.init(message: "Suspicious page count", level: .warning))
        }

        if book.title.lowercased().contains("unknown") {
            warnings.append(.init(message: "Missing title metadata", level: .info))
        }

        return warnings
    }
}

// MARK: - Page Estimation Model

enum PageEstimationModel {
    static func estimatePages(from text: String, difficultyMultiplier: Double = 1.0) -> (pages: Int, confidence: Double) {
        let words = text.split { $0.isWhitespace }.count
        let sentences = text.components(separatedBy: ".").count

        let densityFactor = Double(sentences) / max(Double(words), 1)
        let adjustedWords = Double(words) * (1.0 + densityFactor)

        let pages = max(1, Int((adjustedWords / 250.0) * difficultyMultiplier))
        let confidence = min(1.0, Double(words) / 2000.0)

        return (pages, confidence)
    }
}

// MARK: - Debug Snapshot System

struct ImportDebugSnapshot {
    let fileName: String
    let fileType: String
    let chapterCount: Int
    let spineCount: Int
    let estimatedPages: Int
    let analyticsScore: Double
    let warnings: [ImportWarning]

    func printSnapshot() {
        print("""
        ===== IMPORT SNAPSHOT =====
        File: \(fileName)
        Type: \(fileType)
        Chapters: \(chapterCount)
        Spine: \(spineCount)
        Pages: \(estimatedPages)
        Score: \(analyticsScore)
        Warnings: \(warnings.count)
        ============================
        """)
    }
}

// MARK: - Plugin Architecture

protocol ImportPlugin {
    var name: String { get }
    func execute(book: Book)
}

enum ImportPluginManager {
    static var plugins: [ImportPlugin] = []

    static func register(plugin: ImportPlugin) {
        plugins.append(plugin)
    }

    static func run(book: Book) {
        for plugin in plugins {
            plugin.execute(book: book)
        }
    }
}

// MARK: - Import Intelligence Facade (ENTRY POINT)

enum ImportIntelligenceFacade {
    static func analyze(
        book: Book,
        fileName: String,
        fileSizeBytes: Int?,
        fileType: String
    ) -> (
        analytics: ImportAnalyticsReport,
        suggestions: [ImportSuggestion],
        warnings: [ImportWarning],
        chapterIssues: [ChapterRefinementEngine.ChapterIssue]
    ) {
        return (
            analytics: ImportAnalyticsEngine.analyze(
                book: book,
                fileName: fileName,
                fileSizeBytes: fileSizeBytes,
                fileType: fileType
            ),
            suggestions: SmartImportEnhancer.analyze(book: book),
            warnings: ImportWarningEngine.evaluate(book: book),
            chapterIssues: ChapterRefinementEngine.analyze(chapters: book.chapters)
        )
    }
}
