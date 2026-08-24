//  OnlineBookDiscoveryViewModel.swift
//  Online Book Discovery System
//
//  Swift Concurrency only.
//  No Combine pipelines.
//  Auto-search with 500ms debounce.
//  Network monitoring via NWPathMonitor.
//

import Combine
import Foundation
import Network

@MainActor
final class BookDiscoveryViewModel: ObservableObject {
    @Published var query = "" {
        didSet {
            scheduleSearch()
        }
    }

    @Published var results: [OnlineBook] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOffline = false

    private let service = BookDiscoveryService()

    private var searchTask: Task<Void, Never>?
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(
        label: "BookDiscovery.NetworkMonitor"
    )

    init() {
        startNetworkMonitoring()
    }

    deinit {
        searchTask?.cancel()
        monitor.cancel()
    }

    func searchNow() {
        scheduleSearch(immediate: true)
    }
}

// MARK: - Search

private extension BookDiscoveryViewModel {
    func scheduleSearch(
        immediate: Bool = false
    ) {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard trimmedQuery.count >= 3 else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        guard !isOffline else {
            results = []
            errorMessage = "No internet connection available."
            isLoading = false
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }

            if !immediate {
                do {
                    try await Task.sleep(
                        for: .milliseconds(500)
                    )
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else {
                return
            }

            await self.performSearch(
                query: trimmedQuery
            )
        }
    }

    func performSearch(
        query: String
    ) async {
        isLoading = true
        errorMessage = nil

        let searchResults = await service.searchBooks(
            query: query
        )

        guard !Task.isCancelled else {
            return
        }

        results = searchResults
        isLoading = false

        if searchResults.isEmpty {
            errorMessage = nil
        }
    }
}

// MARK: - Network Monitoring

private extension BookDiscoveryViewModel {
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }

                let offline = path.status != .satisfied

                self.isOffline = offline

                if offline {
                    self.results = []
                    self.isLoading = false
                    self.errorMessage =
                        "No internet connection available."

                } else {
                    if self.errorMessage ==
                        "No internet connection available."
                    {
                        self.errorMessage = nil
                    }

                    let trimmedQuery = self.query
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )

                    if trimmedQuery.count >= 3 {
                        self.searchNow()
                    }
                }
            }
        }

        monitor.start(
            queue: monitorQueue
        )
    }
}
