//  OnlineBookSearchDrawer.swift
//  Online Book Discovery System
//
//  Left-side expandable discovery drawer.
//  Controlled only by local state.
//  No external dependencies beyond ViewModel + OnlineBook.
//

import SwiftUI

struct BookSearchDrawer: View {
    @ObservedObject var viewModel: BookDiscoveryViewModel

    @State private var isDrawerOpen = false

    var body: some View {
        ZStack(alignment: .leading) {
            // MARK: - Main Content Placeholder

            Color.clear

            // MARK: - Overlay

            if isDrawerOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isDrawerOpen = false
                        }
                    }
                    .zIndex(1)
            }

            // MARK: - Drawer

            HStack(spacing: 0) {
                if isDrawerOpen {
                    drawer
                        .frame(
                            width: calculatedWidth
                        )
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                }

                Spacer()
            }

            // MARK: - Tab

            tab
        }
        .animation(.easeInOut, value: isDrawerOpen)
    }
}

// MARK: - Drawer UI

private extension BookSearchDrawer {
    var drawer: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchField

            if viewModel.isOffline {
                Text("No internet connection available.")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding(.horizontal)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.results) { book in
                        OnlineBookRow(book: book)
                            .onTapGesture {
                                selectedBook = book
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
        .background(Color(NSColor.windowBackgroundColor))
    }

    var searchField: some View {
        TextField("Search books...", text: $viewModel.query)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
    }
}

// MARK: - Tab

private extension BookSearchDrawer {
    var tab: some View {
        VStack {
            Spacer()

            Button(action: {
                withAnimation {
                    isDrawerOpen.toggle()
                }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                        .font(.caption2)
                }
                .padding(10)
            }
            .buttonStyle(.plain)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.leading, 6)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Layout

private extension BookSearchDrawer {
    var calculatedWidth: CGFloat {
        let screenWidth = NSScreen.main?.visibleFrame.width ?? 1000
        return min(max(screenWidth * 0.35, 320), 450)
    }
}

// MARK: - Selection State (temporary internal bridge)

private extension BookSearchDrawer {
    @State var selectedBook: OnlineBook? = nil
}
