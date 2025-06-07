import XCTest
@testable import Scaffolde

@MainActor
class HistoryMenuTests: XCTestCase {
    var historyManager: HistoryManager!
    
    override func setUp() async throws {
        try await super.setUp()
        historyManager = HistoryManager()
        historyManager.clearHistory()
    }
    
    override func tearDown() async throws {
        historyManager.clearHistory()
        historyManager = nil
        try await super.tearDown()
    }
    
    func testHistoryMenuPopulation() async throws {
        // Add some test history items
        guard let exampleURL = URL(string: "https://example.com"),
              let appleURL = URL(string: "https://apple.com"),
              let githubURL = URL(string: "https://github.com"),
              let googleURL = URL(string: "https://google.com"),
              let stackURL = URL(string: "https://stackoverflow.com") else {
            XCTFail("Failed to create test URLs")
            return
        }
        
        let testUrls = [
            (url: exampleURL, title: "Example Domain"),
            (url: appleURL, title: "Apple"),
            (url: githubURL, title: "GitHub: Let's build from here"),
            (url: googleURL, title: "Google"),
            (url: stackURL, title: "Stack Overflow")
        ]
        
        // Add items to history
        for item in testUrls {
            historyManager.addItem(
                url: item.url,
                title: item.title,
                transitionType: .typed
            )
        }
        
        // Get recent items (simulating what the menu would show)
        let recentItems = historyManager.search("", limit: 15)
        
        // Verify we have the expected items
        XCTAssertEqual(recentItems.count, 5, "Should have 5 history items")
        
        // Verify they're sorted by most recent first
        XCTAssertEqual(recentItems[0].title, "Stack Overflow", "Most recent item should be first")
        XCTAssertEqual(recentItems[1].title, "Google", "Second most recent item should be second")
        
        // Verify all items have proper titles (not URLs)
        for item in recentItems {
            XCTAssertFalse(item.title.hasPrefix("http"), "Title should not be a URL")
            XCTAssertFalse(item.title.isEmpty, "Title should not be empty")
        }
    }
    
    func testHistoryMenuWithEmptyHistory() async throws {
        // Get recent items from empty history
        let recentItems = historyManager.search("", limit: 15)
        
        // Verify empty history returns no items
        XCTAssertEqual(recentItems.count, 0, "Should have no history items")
    }
    
    func testHistoryMenuLimitOf15Items() async throws {
        // Add 20 test history items
        for idx in 1...20 {
            guard let url = URL(string: "https://example\(idx).com") else {
                XCTFail("Failed to create URL for index \(idx)")
                continue
            }
            historyManager.addItem(
                url: url,
                title: "Example Site \(idx)",
                transitionType: .typed
            )
        }
        
        // Get recent items with limit of 15
        let recentItems = historyManager.search("", limit: 15)
        
        // Verify we get exactly 15 items
        XCTAssertEqual(recentItems.count, 15, "Should return exactly 15 items")
        
        // Verify they're the most recent 15 (20 down to 6)
        for (index, item) in recentItems.enumerated() {
            let expectedNumber = 20 - index
            XCTAssertEqual(item.title, "Example Site \(expectedNumber)")
        }
    }
}
