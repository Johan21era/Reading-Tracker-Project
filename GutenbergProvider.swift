//
//  GutenbergProvider.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/20/26.
//


//
//  GutenbergProvider.swift
//  Online Book Discovery System
//
//  Optional enrichment provider.
//  Uses Gutendex (Project Gutenberg API).
//  Returns [] on any failure.
//  Never throws.
//

import Foundation

struct GutenbergProvider: BookProvider {

    func searchBooks(query: String) async -> [OnlineBook] {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else {
            return []
        }

        guard let encodedQuery = trimmedQuery.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) else {
            return []
        }

        guard let url = URL(
            string: "https://gutendex.com/books?search=\(encodedQuery)"
        ) else {
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode
            else {
                return []
            }

            let decoded = try JSONDecoder().decode(
                GutendexResponse.self,
                from: data
            )

            return decoded.results.compactMap { book in
                mapBook(book)
            }

        } catch {
            return []
        }
    }
}

// MARK: - Mapping

private extension GutenbergProvider {

    func mapBook(
        _ book: GutendexBook
    ) -> OnlineBook? {

        let title = book.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !title.isEmpty else {
            return nil
        }

        let author =
            book.authors.first?.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? "Unknown Author"

        let description: String? = nil

        let coverURL: URL? = {
            if let image = book.formats.imageJPEG {
                return URL(string: image)
            }
            return nil
        }()

        return OnlineBook(
            id: "gutenberg-\(book.id)",
            title: title,
            author: author,
            description: description,
            isbn: nil,
            coverURL: coverURL,
            source: .gutenberg,
            availability: .free
        )
    }
}

// MARK: - API Models

private struct GutendexResponse: Codable {
    let results: [GutendexBook]
}

private struct GutendexBook: Codable {
    let id: Int
    let title: String
    let authors: [GutendexAuthor]
    let formats: GutendexFormats
}

private struct GutendexAuthor: Codable {
    let name: String
}

private struct GutendexFormats: Codable {

    let imageJPEG: String?

    enum CodingKeys: String, CodingKey {
        case imageJPEG = "image/jpeg"
    }
}