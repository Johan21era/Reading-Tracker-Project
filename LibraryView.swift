//
//  LibraryView.swift
//  Reading Tracker
//
//  
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var sessionCoordinator: SessionCoordinator

    @State private var searchText: String = ""
    @State private var selectedFilter: LibraryFilter = .all
    @State private var sortOption: LibrarySortOption = .recent

    private var filteredBooks: [Book] {
        var books = dataStore.books

        if !searchText.isEmpty {
            books = books.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                    $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch selectedFilter {
        case .all:
            break
        case .pdf:
            books = books.filter { $0.fileType == .pdf }
        case .epub:
            books = books.filter { $0.fileType == .epub }
        }

        switch sortOption {
        case .title:
            books.sort { $0.title < $1.title }
        case .author:
            books.sort { $0.author < $1.author }
        case .recent:
            books.sort { $0.id.uuidString > $1.id.uuidString }
        }

        return books
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LibraryHeaderView(count: dataStore.books.count)

                LibrarySearchBarView(text: $searchText)

                LibraryFilterBarView(
                    selectedFilter: $selectedFilter,
                    sortOption: $sortOption
                )

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredBooks) { book in
                            NavigationLink {
                                destinationView(for: book)
                            } label: {
                                BookRowView(book: book)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for book: Book) -> some View {
        switch book.fileType {
        case .pdf:
            PDFReaderScreen(book: book, coordinator: sessionCoordinator)
                .environmentObject(sessionCoordinator)
        case .epub:
            EPUBReaderScreen(book: book, coordinator: sessionCoordinator)
                .environmentObject(sessionCoordinator)
        }
    }
}

// MARK: - Header

struct LibraryHeaderView: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Library")
                .font(.largeTitle.bold())

            Text("\(count) books")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Search

struct LibrarySearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search books", text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Filters

struct LibraryFilterBarView: View {
    @Binding var selectedFilter: LibraryFilter
    @Binding var sortOption: LibrarySortOption

    var body: some View {
        HStack {
            Menu {
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(LibraryFilter.all)
                    Text("PDF").tag(LibraryFilter.pdf)
                    Text("EPUB").tag(LibraryFilter.epub)
                }
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }

            Spacer()

            Menu {
                Picker("Sort", selection: $sortOption) {
                    Text("Recent").tag(LibrarySortOption.recent)
                    Text("Title").tag(LibrarySortOption.title)
                    Text("Author").tag(LibrarySortOption.author)
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Book Row

struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.15))
                .frame(width: 44, height: 60)
                .overlay(
                    Text(book.fileType == .pdf ? "PDF" : "EPUB")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(book.fileType == .pdf ? "PDF" : "EPUB")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(4)

                    Text(formatTime(book.totalReadingTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
    }
}

// MARK: - Models

enum LibraryFilter: Hashable {
    case all
    case pdf
    case epub
}

enum LibrarySortOption: Hashable {
    case recent
    case title
    case author
}
