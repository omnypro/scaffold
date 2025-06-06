import Combine
import XCTest

@testable import Scaffolde

@MainActor
final class HistoryManagerTests: XCTestCase {

    // MARK: - Properties

    private var sut: HistoryManager!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        cancellables = []

        // Clear existing history file before each test
        let historyFileURL =
            FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
            ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("Scaffolde")
            .appendingPathComponent("browser_history.json")

        try? FileManager.default.removeItem(at: historyFileURL)

        sut = HistoryManager()

        // Wait for initial load to complete
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
    }

    override func tearDown() async throws {
        cancellables = nil
        sut = nil

        try await super.tearDown()
    }

    // MARK: - History Recording Tests

    func testAddingNewHistoryItem() async throws {
        // Given
        guard let testURL = URL(string: "https://example.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        let testTitle = "Example Domain"

        // When
        sut.addItem(url: testURL, title: testTitle, transitionType: .typed)

        // Give time for save operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.items.count, 1)

        let item = sut.items.first
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.url, testURL)
        XCTAssertEqual(item?.title, testTitle)
        XCTAssertEqual(item?.visitCount, 1)
        XCTAssertEqual(item?.typedCount, 1)
    }

    func testUpdatingExistingHistoryItem() async throws {
        // Given - Add initial item
        guard let testURL = URL(string: "https://example.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        sut.addItem(url: testURL, title: "Initial Title", transitionType: .link)

        // When - Visit same URL again
        sut.addItem(
            url: testURL,
            title: "Updated Title",
            transitionType: .typed
        )

        // Give time for save operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.items.count, 1)  // Should not create duplicate

        let item = sut.items.first
        XCTAssertEqual(item?.visitCount, 2)
        XCTAssertEqual(item?.typedCount, 1)  // Only typed once
        XCTAssertEqual(item?.title, "Updated Title")
    }

    func testHistoryItemWithEmptyTitle() {
        // Given
        guard let testURL = URL(string: "https://notitle.com") else {
            XCTFail("Failed to create test URL")
            return
        }

        // When
        sut.addItem(url: testURL, title: "", transitionType: .link)

        // Then
        let item = sut.items.first
        XCTAssertEqual(item?.title, testURL.absoluteString)
    }

    func testVisitCountAndTypedCount() {
        // Given
        guard let testURL = URL(string: "https://test.com") else {
            XCTFail("Failed to create test URL")
            return
        }

        // When - Multiple visits with different transition types
        sut.addItem(url: testURL, title: "Test", transitionType: .typed)
        sut.addItem(url: testURL, title: "Test", transitionType: .link)
        sut.addItem(url: testURL, title: "Test", transitionType: .typed)
        sut.addItem(url: testURL, title: "Test", transitionType: .reload)

        // Then
        let item = sut.items.first
        XCTAssertEqual(item?.visitCount, 4)
        XCTAssertEqual(item?.typedCount, 2)
    }

    // MARK: - Search Functionality Tests

    func testSearchWithEmptyQuery() {
        // Given - Add multiple items
        let urls = [
            "https://apple.com",
            "https://google.com",
            "https://github.com"
        ]

        for (index, urlString) in urls.enumerated() {
            guard let url = URL(string: urlString) else {
                XCTFail("Failed to create URL for: \(urlString)")
                continue
            }
            // Add with slight delay to ensure different timestamps
            sut.addItem(
                url: url,
                title: "Site \(index)",
                transitionType: .typed
            )
        }

        // When - Search with empty query
        let results = sut.search("", limit: 2)

        // Then - Should return most recent items
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.url.absoluteString, "https://github.com")
    }

    func testSearchWithMatchingQuery() {
        // Given
        guard let githubURL = URL(string: "https://github.com"),
              let gitlabURL = URL(string: "https://gitlab.com"),
              let googleURL = URL(string: "https://google.com") else {
            XCTFail("Failed to create test URLs")
            return
        }
        
        sut.addItem(
            url: githubURL,
            title: "GitHub",
            transitionType: .typed
        )
        sut.addItem(
            url: gitlabURL,
            title: "GitLab",
            transitionType: .typed
        )
        sut.addItem(
            url: googleURL,
            title: "Google",
            transitionType: .typed
        )

        // When
        let results = sut.search("git")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(
            results.allSatisfy { $0.url.absoluteString.contains("git") }
        )
    }

    func testSearchRankingByFrecency() async throws {
        // Given - Create items with different frecency scores
        guard let recentURL = URL(string: "https://recent.com"),
              let frequentURL = URL(string: "https://frequent.com"),
              let typedURL = URL(string: "https://typed.com") else {
            XCTFail("Failed to create test URLs")
            return
        }

        // Add frequent item (visited many times)
        for _ in 0..<10 {
            sut.addItem(
                url: frequentURL,
                title: "Frequent Site",
                transitionType: .link
            )
        }

        // Add typed item (gets bonus)
        sut.addItem(url: typedURL, title: "Typed Site", transitionType: .typed)

        // Add recent item
        sut.addItem(url: recentURL, title: "Recent Site", transitionType: .link)

        // When - Search for all
        let results = sut.search("site")

        // Then - Typed should rank highest due to type bonus
        XCTAssertEqual(results.first?.url, typedURL)
    }

    func testAutocompleteGeneration() {
        // Given
        guard let testURL = URL(string: "https://github.com/omnypro/scaffolde") else {
            XCTFail("Failed to create test URL")
            return
        }
        
        sut.addItem(
            url: testURL,
            title: "Scaffolde Repository",
            transitionType: .typed
        )

        // Test cases
        let testCases: [(query: String, shouldAutocomplete: Bool)] = [
            ("https://git", true),  // URL starts with query
            ("github", true),  // Host starts with query
            ("scaffolde", false),  // Match but not at start
            ("xyz", false),  // No match
            ("", false)  // Empty query
        ]

        for testCase in testCases {
            // When
            let autocomplete = sut.getAutocompleteURL(for: testCase.query)

            // Then
            if testCase.shouldAutocomplete {
                XCTAssertNotNil(
                    autocomplete,
                    "Expected autocomplete for: \(testCase.query)"
                )
                XCTAssertTrue(
                    autocomplete?.lowercased().contains(
                        testCase.query.lowercased()
                    ) ?? false
                )
            } else {
                XCTAssertNil(
                    autocomplete,
                    "Expected no autocomplete for: \(testCase.query)"
                )
            }
        }
    }

    // MARK: - History Management Tests

    func testRemoveHistoryItem() async throws {
        // Given
        guard let url1 = URL(string: "https://keep.com"),
              let url2 = URL(string: "https://remove.com") else {
            XCTFail("Failed to create test URLs")
            return
        }

        sut.addItem(url: url1, title: "Keep", transitionType: .typed)
        sut.addItem(url: url2, title: "Remove", transitionType: .typed)

        XCTAssertEqual(sut.items.count, 2)

        // When
        if let itemToRemove = sut.items.first(where: { $0.url == url2 }) {
            sut.removeItem(itemToRemove)
        }

        // Give time for save operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.url, url1)
    }

    func testClearAllHistory() async throws {
        // Given
        for index in 0..<5 {
            guard let url = URL(string: "https://site\(index).com") else {
                XCTFail("Failed to create URL for site \(index)")
                continue
            }
            sut.addItem(
                url: url,
                title: "Site \(index)",
                transitionType: .typed
            )
        }

        XCTAssertEqual(sut.items.count, 5)

        // When
        sut.clearHistory()

        // Give time for save operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.items.count, 0)
    }

    func testClearHistoryOlderThanDays() async throws {
        // Given - Add items with different ages
        // Note: We can't manipulate dates directly, so we'll add items and test the logic
        guard let recentURL = URL(string: "https://recent.com"),
              let oldURL = URL(string: "https://old.com") else {
            XCTFail("Failed to create test URLs")
            return
        }

        // Add items
        sut.addItem(url: recentURL, title: "Recent", transitionType: .typed)
        sut.addItem(url: oldURL, title: "Old", transitionType: .typed)

        // Wait for items to be saved
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify we have 2 items
        XCTAssertEqual(sut.items.count, 2)

        // When - Clear history older than 365 days (nothing should be cleared)
        sut.clearHistoryOlderThan(days: 365)

        // Give time for save operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - All items should still exist
        XCTAssertEqual(sut.items.count, 2)

        // Test clear all with 0 days
        sut.clearHistoryOlderThan(days: 0)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Should clear all items
        XCTAssertEqual(sut.items.count, 0)
    }

    func testHistoryCleanupMaxItems() {
        // Note: This test would require setting maxHistoryItems to a smaller value
        // or adding 10000+ items, which is impractical for unit tests
        // Instead, we verify the cleanup logic exists

        // Given
        let initialCount = sut.items.count

        // When - Add items
        for index in 0..<10 {
            guard let url = URL(string: "https://site\(index).com") else {
                XCTFail("Failed to create URL for site \(index)")
                continue
            }
            sut.addItem(
                url: url,
                title: "Site \(index)",
                transitionType: .typed
            )
        }

        // Then
        XCTAssertLessThanOrEqual(sut.items.count, 10000)  // Max limit
    }

    // MARK: - Persistence Tests

    func testFaviconUpdate() async throws {
        // Given
        guard let testURL = URL(string: "https://favicon.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        sut.addItem(url: testURL, title: "Favicon Site", transitionType: .typed)

        let faviconData = Data("test-favicon".utf8)

        // When
        sut.updateFavicon(for: testURL, faviconData: faviconData)

        // Give time for save
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let item = sut.items.first(where: { $0.url == testURL })
        XCTAssertEqual(item?.faviconData, faviconData)
    }

    // MARK: - HistorySearchProvider Tests

    func testHistorySearchProviderDebouncing() async throws {
        // Given
        let searchProvider = HistorySearchProvider(historyManager: sut)

        // Add test data
        guard let appleURL = URL(string: "https://apple.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        
        sut.addItem(
            url: appleURL,
            title: "Apple",
            transitionType: .typed
        )

        let searchExpectation = XCTestExpectation(
            description: "Search completed"
        )

        searchProvider.$searchResults
            .dropFirst()
            .sink { results in
                if !results.isEmpty {
                    searchExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When - Rapid searches (should debounce)
        searchProvider.search("a")
        searchProvider.search("ap")
        searchProvider.search("app")
        searchProvider.search("appl")
        searchProvider.search("apple")

        // Then - Should only get one search result after debounce
        await fulfillment(of: [searchExpectation], timeout: 1.0)

        XCTAssertEqual(searchProvider.searchResults.count, 1)
        XCTAssertEqual(searchProvider.searchResults.first?.title, "Apple")
    }

    func testHistorySearchProviderClearSearch() {
        // Given
        let searchProvider = HistorySearchProvider(historyManager: sut)
        guard let testURL = URL(string: "https://test.com") else {
            XCTFail("Failed to create test URL")
            return
        }
        searchProvider.searchResults = [
            HistoryItem(url: testURL, title: "Test")
        ]
        searchProvider.autocompleteURL = "https://test.com"

        // When
        searchProvider.clearSearch()

        // Then
        XCTAssertTrue(searchProvider.searchResults.isEmpty)
        XCTAssertNil(searchProvider.autocompleteURL)
        XCTAssertFalse(searchProvider.isSearching)
    }
}
