import XCTest
@testable import Scaffolde

@MainActor
final class HistoryItemTests: XCTestCase {

    func testFrecencyCalculation() {
        // Given - Items with different characteristics
        let now = Date()
        let calendar = Calendar.current

        // Recent + typed + frequent
        guard let bestURL = URL(string: "https://best.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        
        let bestItem = HistoryItem(
            url: bestURL,
            title: "Best",
            lastVisit: now,
            visitCount: 10,
            typedCount: 5
        )

        // Old + never typed + infrequent
        guard let worstURL = URL(string: "https://worst.com"),
              let oldDate = calendar.date(byAdding: .day, value: -100, to: now) else {
            XCTFail("Failed to create test data")
            return
        }
        
        let worstItem = HistoryItem(
            url: worstURL,
            title: "Worst",
            lastVisit: oldDate,
            visitCount: 1,
            typedCount: 0
        )

        // Then
        XCTAssertGreaterThan(bestItem.frecencyScore, worstItem.frecencyScore)
    }

    func testMatchScoring() {
        // Given
        guard let itemURL = URL(string: "https://github.com/omnypro/scaffolde") else {
            XCTFail("Failed to create test URL")
            return
        }
        
        let item = HistoryItem(
            url: itemURL,
            title: "Scaffolde - Browser for Overlay Development"
        )

        // Test different match types
        let testCases: [(query: String, expectedMinScore: Double)] = [
            ("https://github.com/omnypro/scaffolde", 1000),  // Exact match
            ("https://github", 800),  // URL prefix
            ("Scaffolde", 700),  // Title prefix
            ("github.com", 600),  // Word boundary in URL
            ("Browser", 500),  // Word boundary in title
            ("overlay", 200)  // Contains in title
        ]

        for testCase in testCases {
            let score = item.matchScore(for: testCase.query)
            XCTAssertGreaterThanOrEqual(
                score,
                testCase.expectedMinScore,
                "Query '\(testCase.query)' should score at least \(testCase.expectedMinScore)"
            )
        }
    }

    func testMatchesQuery() {
        // Given
        guard let itemURL = URL(string: "https://example.com/test") else {
            XCTFail("Failed to create test URL")
            return
        }
        
        let item = HistoryItem(
            url: itemURL,
            title: "Example Test Page"
        )

        // Test various queries
        XCTAssertTrue(item.matches("example"))
        XCTAssertTrue(item.matches("EXAMPLE"))  // Case insensitive
        XCTAssertTrue(item.matches("test"))
        XCTAssertTrue(item.matches("page"))
        XCTAssertTrue(item.matches(".com"))
        XCTAssertFalse(item.matches("notfound"))
        XCTAssertFalse(item.matches(""))
    }
}
