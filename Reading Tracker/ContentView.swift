//
//  ContentView.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/15/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var sessionCoordinator: SessionCoordinator
    @State private var selectedBook: Book?
    @State private var hoverStart: Date?
    @State private var tooltipText: String?
    @State private var tooltipPosition: CGPoint = .zero
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(dataStore.books) { book in
                    NavigationLink {
                        if book.fileType == .pdf {
                            PDFReaderScreen(book: book, coordinator: sessionCoordinator)
                        } else {
                            EPUBReaderScreen(book: book, coordinator: sessionCoordinator)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                            
                            Text(book.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(book.fileType.displayName)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(4)
                                
                                if book.totalReadingTime > 0 {
                                    Text(formatReadingTime(book.totalReadingTime))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .onHover { hovering in
                            if hovering {
                                hoverStart = Date()
                            } else if let start = hoverStart {
                                
                                let duration = Date().timeIntervalSince(start)
                                
                                let level = hoverLevel(seconds: duration)
                                
                                print("Duration: \(duration)")
                                print("Intent: \(level)")
                                
                                if level == "INSPECTING" {

                                    let prediction = AnalyticsEngine.predictions(for: book)

                                    tooltipText = """
                                    Speed: \(Int(3600 / prediction.adjustedSecondsPerPage)) pages/hr
                                    """
                                }
                                
                                hoverStart = nil
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }detail: {
                ZStack {
                    Text("Select a book")
                    if let tooltipText {
                        Text(tooltipText)
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    }
                }
            }
    }

    private func formatReadingTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func addItem() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, .epub]

        panel.begin { response in
            if response == .OK, let url = panel.url {
                print("✅ FILE SELECTED: \(url.path)")
                print("📤 CALLING BookImporter.importBook")
                Task {
                    do {
                        let book = try await BookImporter.importBook(from: url)
                        print("📥 BOOK RETURNED: \(book.title)")
                        await MainActor.run {
                            dataStore.addBook(book)
                        }
                    } catch {
                        print("❌ IMPORT FAILED: \(error)")
                    }
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                dataStore.removeBook(id: dataStore.books[index].id)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
        .environmentObject(SessionCoordinator(dataStore: DataStore()))
}
private func hoverLevel(seconds: Double) -> String {
    if seconds < 0.5 {
        return "IGNORE"
    } else if seconds < 1.5 {
        return "INTERESTED"
    } else {
        return "INSPECTING"
    }
}
