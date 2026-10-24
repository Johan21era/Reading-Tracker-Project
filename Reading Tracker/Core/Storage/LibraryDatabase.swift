//  LibraryDatabase.swift
//  Bedrock G3A — GRDB/SQLite foundation.
//
//  This is deliberately additive: the existing JSON DataStore remains the
//  default until G3B/G3C prove parity. The database is the future normalized
//  core: books, sessions, page_times, library state, notes, collections,
//  achievements, weather, audio, and (later) behavior evidence.
//
//  G3A keeps a full Book payload in `books.payload_json` as the parity source
//  of truth, while ALSO writing normalized session/page_timing rows. G3B
//  switches reads to summaries + on-demand sessions and SQL aggregates.

import Foundation
import GRDB

nonisolated final class LibraryDatabase: @unchecked Sendable {
    let pool: DatabasePool

    init(url: URL) throws {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            try db.execute(sql: "PRAGMA synchronous = NORMAL")
        }
        pool = try DatabasePool(path: url.path, configuration: config)
        try Self.migrator.migrate(pool)
    }

    // MARK: - Schema

    static let migrator: DatabaseMigrator = {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "books") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("author", .text).notNull()
                t.column("date_added", .double).notNull()
                t.column("payload_json", .text).notNull()
                t.column("updated_at", .double).notNull()
            }

            try db.create(table: "sessions") { t in
                t.column("id", .text).primaryKey()
                t.column("book_id", .text).notNull()
                    .references("books", onDelete: .cascade)
                t.column("start_time", .double).notNull()
                t.column("end_time", .double)
                t.column("start_page", .integer).notNull()
                t.column("end_page", .integer).notNull()
                t.column("audio_profile_id", .text)
                t.column("payload_json", .text).notNull()
            }
            try db.create(index: "idx_sessions_book", on: "sessions", columns: ["book_id"])
            try db.create(index: "idx_sessions_start", on: "sessions", columns: ["start_time"])

            try db.create(table: "page_times") { t in
                t.column("id", .text).primaryKey()
                t.column("session_id", .text).notNull()
                    .references("sessions", onDelete: .cascade)
                t.column("idx", .integer).notNull()
                t.column("page_number", .integer).notNull()
                t.column("start_time", .double).notNull()
                t.column("end_time", .double)
                t.column("payload_json", .text).notNull()
            }
            try db.create(index: "idx_page_times_session", on: "page_times", columns: ["session_id"])
            try db.create(index: "idx_page_times_start", on: "page_times", columns: ["start_time"])

            try db.create(table: "library_state") { t in
                t.column("key", .text).primaryKey()
                t.column("payload_json", .text).notNull()
            }

            try db.create(table: "collections") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("date_created", .double).notNull()
            }
            try db.create(table: "book_collections") { t in
                t.column("book_id", .text).notNull()
                    .references("books", onDelete: .cascade)
                t.column("collection_id", .text).notNull()
                    .references("collections", onDelete: .cascade)
                t.primaryKey(["book_id", "collection_id"])
            }

            try db.create(table: "notes") { t in
                t.column("id", .text).primaryKey()
                t.column("book_id", .text).notNull()
                    .references("books", onDelete: .cascade)
                t.column("page_number", .integer)
                t.column("text", .text).notNull()
                t.column("tag", .text).notNull()
                t.column("created_at", .double).notNull()
                t.column("modified_at", .double).notNull()
            }
            try db.create(index: "idx_notes_book", on: "notes", columns: ["book_id"])

            try db.create(table: "achievements") { t in
                t.column("id", .text).primaryKey()
                t.column("kind", .text).notNull().unique()
                t.column("earned_at", .double).notNull()
                t.column("book_id", .text)
            }

            try db.create(table: "weather_snapshots") { t in
                t.column("id", .text).primaryKey()
                t.column("timestamp", .double).notNull()
                t.column("session_id", .text)
                t.column("temperature_celsius", .double).notNull()
                t.column("feels_like_celsius", .double).notNull()
                t.column("humidity", .double).notNull()
                t.column("pressure", .double).notNull()
                t.column("cloud_cover", .double).notNull()
                t.column("visibility_km", .double).notNull()
                t.column("wind_speed_kph", .double).notNull()
                t.column("precipitation_mm", .double).notNull()
                t.column("snowfall_mm", .double).notNull()
                t.column("condition", .text).notNull()
                t.column("season", .text).notNull()
                t.column("day_period", .text).notNull()
                t.column("payload_json", .text).notNull()
            }
            try db.create(index: "idx_weather_timestamp", on: "weather_snapshots", columns: ["timestamp"])
            try db.create(index: "idx_weather_session", on: "weather_snapshots", columns: ["session_id"])

            try db.create(table: "audio_profiles") { t in
                t.column("id", .text).primaryKey()
                t.column("session_id", .text)
                t.column("payload_json", .text).notNull()
            }

            try db.create(table: "behavior_events") { t in
                t.column("id", .text).primaryKey()
                t.column("timestamp", .double).notNull()
                t.column("type", .text).notNull()
                t.column("payload_json", .text).notNull()
            }
            try db.create(index: "idx_behavior_timestamp", on: "behavior_events", columns: ["timestamp"])

            try db.create(table: "application_sessions") { t in
                t.column("id", .text).primaryKey()
                t.column("start_time", .double).notNull()
                t.column("end_time", .double)
                t.column("payload_json", .text).notNull()
            }

            try db.create(table: "inactivity_records") { t in
                t.column("id", .text).primaryKey()
                t.column("start_time", .double).notNull()
                t.column("end_time", .double)
                t.column("payload_json", .text).notNull()
            }

            try db.create(table: "device_state_events") { t in
                t.column("id", .text).primaryKey()
                t.column("timestamp", .double).notNull()
                t.column("payload_json", .text).notNull()
            }

            try db.create(table: "meta") { t in
                t.column("key", .text).primaryKey()
                t.column("value", .text).notNull()
            }
        }
        return migrator
    }()

    // MARK: - Import / parity source

    private static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }

    private static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    /// Replace the whole library in one transaction. G3A parity path.
    func importLibrary(books: [Book], state: LibraryState) throws {
        let enc = Self.encoder()
        try pool.write { db in
            try db.execute(sql: "DELETE FROM book_collections")
            try db.execute(sql: "DELETE FROM notes")
            try db.execute(sql: "DELETE FROM achievements")
            try db.execute(sql: "DELETE FROM page_times")
            try db.execute(sql: "DELETE FROM sessions")
            try db.execute(sql: "DELETE FROM books")
            try db.execute(sql: "DELETE FROM collections")
            try db.execute(sql: "DELETE FROM library_state")

            // Collections must exist before book_collections references them.
            for collection in state.collections {
                try db.execute(
                    sql: "INSERT INTO collections (id, name, date_created) VALUES (?, ?, ?)",
                    arguments: [
                        collection.id.uuidString, collection.name,
                        collection.dateCreated.timeIntervalSince1970,
                    ])
            }

            for book in books {
                let payload = try enc.encode(book)
                let payloadString = String(decoding: payload, as: UTF8.self)
                try db.execute(
                    sql: """
                        INSERT INTO books
                        (id, title, author, date_added, payload_json, updated_at)
                        VALUES (?, ?, ?, ?, ?, ?)
                        """,
                    arguments: [
                        book.id.uuidString, book.title, book.author,
                        book.dateAdded.timeIntervalSince1970, payloadString,
                        Date().timeIntervalSince1970,
                    ])

                for session in book.sessions {
                    let sPayload = try enc.encode(session)
                    try db.execute(
                        sql: """
                            INSERT INTO sessions
                            (id, book_id, start_time, end_time, start_page, end_page,
                             audio_profile_id, payload_json)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                            """,
                        arguments: [
                            session.id.uuidString, book.id.uuidString,
                            session.startTime.timeIntervalSince1970,
                            session.endTime?.timeIntervalSince1970,
                            session.startPage, session.endPage,
                            session.audioContextProfileID?.uuidString,
                            String(decoding: sPayload, as: UTF8.self),
                        ])

                    for (idx, timing) in session.pageTimes.enumerated() {
                        let tPayload = try enc.encode(timing)
                        try db.execute(
                            sql: """
                                INSERT INTO page_times
                                (id, session_id, idx, page_number, start_time, end_time, payload_json)
                                VALUES (?, ?, ?, ?, ?, ?, ?)
                                """,
                            arguments: [
                                timing.id.uuidString, session.id.uuidString, idx,
                                timing.pageNumber,
                                timing.startTime.timeIntervalSince1970,
                                timing.endTime?.timeIntervalSince1970,
                                String(decoding: tPayload, as: UTF8.self),
                            ])
                    }
                }

                for note in book.notes {
                    try db.execute(
                        sql: """
                            INSERT INTO notes
                            (id, book_id, page_number, text, tag, created_at, modified_at)
                            VALUES (?, ?, ?, ?, ?, ?, ?)
                            """,
                        arguments: [
                            note.id.uuidString, book.id.uuidString, note.pageNumber,
                            note.text, note.tag.rawValue,
                            note.createdAt.timeIntervalSince1970,
                            note.modifiedAt.timeIntervalSince1970,
                        ])
                }

                for collectionID in book.collectionIDs {
                    try db.execute(
                        sql: "INSERT OR IGNORE INTO book_collections (book_id, collection_id) VALUES (?, ?)",
                        arguments: [book.id.uuidString, collectionID.uuidString])
                }
            }

            for achievement in state.earnedAchievements {
                try db.execute(
                    sql: """
                        INSERT OR IGNORE INTO achievements (id, kind, earned_at, book_id)
                        VALUES (?, ?, ?, ?)
                        """,
                    arguments: [
                        achievement.id.uuidString, achievement.kind.rawValue,
                        achievement.earnedAt.timeIntervalSince1970,
                        achievement.relatedBookID?.uuidString,
                    ])
            }

            let stateData = try enc.encode(state)
            try db.execute(
                sql: "INSERT INTO library_state (key, payload_json) VALUES (?, ?)",
                arguments: ["root", String(decoding: stateData, as: UTF8.self)])
        }
    }

    /// G3A parity read: full Book payloads (sessions included), no lazy loading.
    func loadBooks() throws -> [Book] {
        let dec = Self.decoder()
        return try pool.read { db in
            try Row.fetchAll(db, sql: "SELECT payload_json FROM books ORDER BY date_added")
                .compactMap { row -> Book? in
                    let text: String = row["payload_json"]
                    return try? dec.decode(Book.self, from: Data(text.utf8))
                }
        }
    }

    func loadState() throws -> LibraryState {
        let dec = Self.decoder()
        return try pool.read { db in
            guard let row = try Row.fetchOne(
                db, sql: "SELECT payload_json FROM library_state WHERE key = ?", arguments: ["root"]),
                let state = try? dec.decode(LibraryState.self, from: Data((row["payload_json"] as String).utf8))
            else {
                return LibraryState()
            }
            return state
        }
    }

    func close() throws {
        try pool.close()
    }

    func counts() throws -> (books: Int, sessions: Int, pageTimes: Int) {
        try pool.read { db in
            let books = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM books") ?? 0
            let sessions = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM sessions") ?? 0
            let pageTimes = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM page_times") ?? 0
            return (books, sessions, pageTimes)
        }
    }
}
