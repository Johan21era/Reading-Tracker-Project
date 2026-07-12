//  OnlineBookDiscoveryService.swift
//  Online Book Discovery System
//
//  Responsibilities:
//  1. Query Open Library
//  2. Query Gutenberg if needed
//  3. Merge results
//  4. Deduplicate
//  5. Rank results
//

import Foundation

struct BookDiscoveryService {
    private let openLibraryProvider = OpenLibraryProvider()
    private let gutenbergProvider = GutenbergProvider()

    func searchBooks(query: String) async -> [OnlineBook] {
        let normalizedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !normalizedQuery.isEmpty else {
            return []
        }

        var results = await openLibraryProvider.searchBooks(
            query: normalizedQuery
        )

        if results.count < 10 {
            let gutenbergResults = await gutenbergProvider.searchBooks(
                query: normalizedQuery
            )

            results.append(contentsOf: gutenbergResults)
        }

        let deduplicated = deduplicate(results)

        return rank(
            deduplicated,
            query: normalizedQuery
        )
    }
}

// MARK: - Deduplication

private extension BookDiscoveryService {
    func deduplicate(
        _ books: [OnlineBook]
    ) -> [OnlineBook] {
        var seenISBNs = Set<String>()
        var seenTitleAuthor = Set<String>()

        var uniqueBooks: [OnlineBook] = []

        for book in books {
            if let isbn = book.isbn?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !isbn.isEmpty
            {
                if seenISBNs.contains(isbn) {
                    continue
                }

                seenISBNs.insert(isbn)
                uniqueBooks.append(book)
                continue
            }

            let normalizedKey = normalizedTitleAuthorKey(
                title: book.title,
                author: book.author
            )

            if seenTitleAuthor.contains(normalizedKey) {
                continue
            }

            seenTitleAuthor.insert(normalizedKey)
            uniqueBooks.append(book)
        }

        return uniqueBooks
    }
}

// MARK: - Ranking

private extension BookDiscoveryService {
    func rank(
        _ books: [OnlineBook],
        query: String
    ) -> [OnlineBook] {
        let normalizedQuery = normalize(query)

        return books.sorted { lhs, rhs in
            let lhsScore = score(
                lhs,
                query: normalizedQuery
            )

            let rhsScore = score(
                rhs,
                query: normalizedQuery
            )

            if lhsScore == rhsScore {
                return lhs.title.localizedCaseInsensitiveCompare(
                    rhs.title
                ) == .orderedAscending
            }

            return lhsScore > rhsScore
        }
    }

    func score(
        _ book: OnlineBook,
        query: String
    ) -> Int {
        var score = 0

        let normalizedTitle = normalize(book.title)

        if normalizedTitle.contains(query) {
            score += 50
        } else if partialMatch(
            title: normalizedTitle,
            query: query
        ) {
            score += 20
        }

        if !book.author.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {
            score += 15
        }

        if let description = book.description,
           !description.trimmingCharacters(
               in: .whitespacesAndNewlines
           ).isEmpty
        {
            score += 15
        }

        if book.coverURL != nil {
            score += 10
        }

        if book.availability == .free {
            score += 10
        }

        return score
    }
}

// MARK: - Helpers

private extension BookDiscoveryService {
    func normalizedTitleAuthorKey(
        title: String,
        author: String
    ) -> String {
        "\(normalize(title))|\(normalize(author))"
    }

    func normalize(
        _ value: String
    ) -> String {
        value
            .lowercased()
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of: #"\s+"#,
                with: " ",
                options: .regularExpression
            )
    }

    func partialMatch(
        title: String,
        query: String
    ) -> Bool {
        let queryTokens = query
            .split(separator: " ")
            .map(String.init)

        guard !queryTokens.isEmpty else {
            return false
        }

        return queryTokens.contains {
            token in
            title.contains(token)
        }
    }
}
