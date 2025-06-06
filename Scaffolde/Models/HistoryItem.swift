import Foundation

/// Represents a single history entry in the browser
struct HistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let url: URL
    var title: String
    var lastVisit: Date
    var visitCount: Int
    var typedCount: Int  // Times URL was typed directly
    var faviconData: Data?

    /// Frecency score combining frequency and recency
    var frecencyScore: Double {
        calculateFrecency()
    }

    init(
        id: UUID = UUID(),
        url: URL,
        title: String = "",
        lastVisit: Date = Date(),
        visitCount: Int = 1,
        typedCount: Int = 0,
        faviconData: Data? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title.isEmpty ? url.absoluteString : title
        self.lastVisit = lastVisit
        self.visitCount = visitCount
        self.typedCount = typedCount
        self.faviconData = faviconData
    }

    /// Calculate frecency score based on Firefox's algorithm
    private func calculateFrecency() -> Double {
        let daysSinceVisit =
            Calendar.current.dateComponents(
                [.day],
                from: lastVisit,
                to: Date()
            ).day ?? 0

        // Time-based weight buckets
        let recencyWeight: Double
        switch daysSinceVisit {
        case 0...4:
            recencyWeight = 100.0
        case 5...14:
            recencyWeight = 70.0
        case 15...31:
            recencyWeight = 50.0
        case 32...90:
            recencyWeight = 30.0
        default:
            recencyWeight = 10.0
        }

        // Type bonus (typed URLs get priority)
        let typeBonus: Double = typedCount > 0 ? 2000.0 : 0.0

        // Visit frequency bonus
        let frequencyBonus = Double(visitCount) * 100.0

        return recencyWeight + typeBonus + frequencyBonus
    }

    /// Check if this item matches a search query
    func matches(_ query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        return url.absoluteString.lowercased().contains(lowercaseQuery)
            || title.lowercased().contains(lowercaseQuery)
    }

    /// Calculate match quality score for ranking
    func matchScore(for query: String) -> Double {
        let lowercaseQuery = query.lowercased()
        let urlString = url.absoluteString.lowercased()
        let titleLower = title.lowercased()

        // Exact match gets highest score
        if urlString == lowercaseQuery || titleLower == lowercaseQuery {
            return 1000.0
        }

        // URL starts with query
        if urlString.hasPrefix(lowercaseQuery) {
            return 800.0
        }

        // Title starts with query
        if titleLower.hasPrefix(lowercaseQuery) {
            return 700.0
        }

        // Word boundary match in URL
        if urlString.contains("://\(lowercaseQuery)")
            || urlString.contains("/\(lowercaseQuery)")
            || urlString.contains(".\(lowercaseQuery)") {
            return 600.0
        }

        // Word boundary match in title
        let titleWords = titleLower.split(separator: " ")
        if titleWords.contains(where: { $0.hasPrefix(lowercaseQuery) }) {
            return 500.0
        }

        // Contains match
        if urlString.contains(lowercaseQuery) {
            return 300.0
        }

        if titleLower.contains(lowercaseQuery) {
            return 200.0
        }

        return 0.0
    }
}

/// Visit information for detailed history tracking
struct HistoryVisit: Codable {
    let historyItemId: UUID
    let visitTime: Date
    let transitionType: TransitionType

    enum TransitionType: String, Codable {
        case typed  // User typed URL
        case link  // Clicked a link
        case reload  // Page reload
        case formSubmit  // Form submission
        case other  // Other navigation
    }
}
