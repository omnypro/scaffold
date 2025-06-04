import Combine
import Foundation

/// Manages browser history with persistence and search capabilities
@MainActor
class HistoryManager: ObservableObject {
    @Published private(set) var items: [HistoryItem] = []
    @Published private(set) var isLoading = false

    private let maxHistoryItems = 10000
    private let maxHistoryAge = 365  // days
    private let historyFileName = "browser_history.json"
    private var historyFileURL: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        .appendingPathComponent("Scaffolde")
        .appendingPathComponent(historyFileName)
    }

    // Debouncing for search
    private var searchCancellable: AnyCancellable?

    init() {
        createDirectoryIfNeeded()
        loadHistory()
    }

    // MARK: - Public Methods

    /// Add or update a history item
    func addItem(
        url: URL,
        title: String,
        transitionType: HistoryVisit.TransitionType
    ) {
        // Check if URL already exists
        if let existingIndex = items.firstIndex(where: { $0.url == url }) {
            // Update existing item
            items[existingIndex].title =
                title.isEmpty ? items[existingIndex].title : title
            items[existingIndex].lastVisit = Date()
            items[existingIndex].visitCount += 1

            if transitionType == .typed {
                items[existingIndex].typedCount += 1
            }
        } else {
            // Create new item
            let newItem = HistoryItem(
                url: url,
                title: title,
                typedCount: transitionType == .typed ? 1 : 0
            )
            items.append(newItem)
        }
        
        // Clean up old items
        cleanupHistory()

        // Save to disk
        saveHistory()
    }

    /// Search history with query
    func search(_ query: String, limit: Int = 10) -> [HistoryItem] {
        guard !query.isEmpty else {
            // Return recent items when no query
            return Array(
                items
                    .sorted { $0.lastVisit > $1.lastVisit }
                    .prefix(limit)
            )
        }

        // Filter matching items
        let matchingItems = items.filter { $0.matches(query) }

        // Sort by combined score (match quality + frecency)
        let scoredItems = matchingItems.map { item in
            (
                item: item,
                score: item.matchScore(for: query) + item.frecencyScore
            )
        }

        return
            scoredItems
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.item }
    }

    /// Get suggestions for autocomplete (returns best match)
    func getAutocompleteURL(for query: String) -> String? {
        guard !query.isEmpty else { return nil }

        let matches = search(query, limit: 1)
        guard let bestMatch = matches.first else { return nil }

        let urlString = bestMatch.url.absoluteString
        let lowercaseQuery = query.lowercased()
        let lowercaseURL = urlString.lowercased()

        // Only autocomplete if URL starts with query
        if lowercaseURL.hasPrefix(lowercaseQuery) {
            return urlString
        }

        // Check if host starts with query
        if let host = bestMatch.url.host,
            host.lowercased().hasPrefix(lowercaseQuery)
        {
            return urlString
        }

        return nil
    }

    /// Remove specific history item
    func removeItem(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    /// Clear all history
    func clearHistory() {
        items.removeAll()
        saveHistory()
    }

    /// Clear history older than specified days
    func clearHistoryOlderThan(days: Int) {
        let cutoffDate =
            Calendar.current.date(byAdding: .day, value: -days, to: Date())
            ?? Date()
        items.removeAll { $0.lastVisit < cutoffDate }
        saveHistory()
    }

    /// Update favicon for URL
    func updateFavicon(for url: URL, faviconData: Data) {
        if let index = items.firstIndex(where: { $0.url == url }) {
            items[index].faviconData = faviconData
            saveHistory()
        }
    }

    // MARK: - Private Methods

    private func createDirectoryIfNeeded() {
        let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let scaffoldeURL = appSupportURL.appendingPathComponent("Scaffolde")

        if !FileManager.default.fileExists(atPath: scaffoldeURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: scaffoldeURL,
                    withIntermediateDirectories: true
                )
            } catch {
                // Failed to create directory
            }
        }
    }

    private func loadHistory() {
        isLoading = true

        Task.detached { [weak self] in
            guard let self = self else { return }

            let fileURL = await self.historyFileURL

            do {
                let data = try Data(contentsOf: fileURL)
                let decodedItems = try JSONDecoder().decode(
                    [HistoryItem].self,
                    from: data
                )

                await MainActor.run {
                    self.items = decodedItems
                    self.isLoading = false
                    self.cleanupHistory()
                }
            } catch {
                // File doesn't exist or decode failed - start with empty history
                await MainActor.run {
                    self.items = []
                    self.isLoading = false
                }
            }
        }
    }

    private func saveHistory() {
        Task.detached { [weak self] in
            guard let self = self else { return }

            let fileURL = await self.historyFileURL
            let itemsToSave = await self.items

            do {
                let data = try JSONEncoder().encode(itemsToSave)
                try data.write(to: fileURL)
            } catch {
                // Failed to save history
            }
        }
    }

    private func cleanupHistory() {
        // Remove items older than maxHistoryAge
        let cutoffDate =
            Calendar.current.date(
                byAdding: .day,
                value: -maxHistoryAge,
                to: Date()
            ) ?? Date()
        items.removeAll { $0.lastVisit < cutoffDate }

        // Keep only the most recent maxHistoryItems
        if items.count > maxHistoryItems {
            items = Array(
                items
                    .sorted { $0.lastVisit > $1.lastVisit }
                    .prefix(maxHistoryItems)
            )
        }
    }
}

// MARK: - History Search Provider

/// Provides debounced search functionality for the history
class HistorySearchProvider: ObservableObject {
    @Published var searchResults: [HistoryItem] = []
    @Published var isSearching = false
    @Published var autocompleteURL: String?

    private let historyManager: HistoryManager
    private var searchCancellable: AnyCancellable?
    private let searchDebounceInterval: TimeInterval = 0.3

    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
    }

    func search(_ query: String) {
        // Cancel previous search
        searchCancellable?.cancel()

        guard !query.isEmpty else {
            searchResults = []
            autocompleteURL = nil
            isSearching = false
            return
        }

        isSearching = true

        // Debounce search
        searchCancellable = Just(query)
            .delay(
                for: .seconds(searchDebounceInterval),
                scheduler: DispatchQueue.main
            )
            .sink { [weak self] searchQuery in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    self.searchResults = self.historyManager.search(searchQuery)
                    self.autocompleteURL = self.historyManager
                        .getAutocompleteURL(for: searchQuery)
                    self.isSearching = false
                }
            }
    }

    func clearSearch() {
        searchCancellable?.cancel()
        searchResults = []
        autocompleteURL = nil
        isSearching = false
    }
    
    @MainActor
    func showRecentHistory() {
        searchResults = historyManager.search("", limit: 10)
        autocompleteURL = nil
        isSearching = false
    }
}
