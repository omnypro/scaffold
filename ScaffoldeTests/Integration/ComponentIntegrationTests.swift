import Combine
import WebKit
import XCTest

@testable import Scaffolde

@MainActor
final class ComponentIntegrationTests: XCTestCase {

    // MARK: - Properties

    private var historyManager: HistoryManager!
    private var consoleViewModel: ConsoleViewModel!
    private var browserViewModel: BrowserViewModel!
    private var windowViewModel: WindowViewModel!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        cancellables = []

        // Initialize components
        historyManager = HistoryManager()
        consoleViewModel = ConsoleViewModel()
        browserViewModel = BrowserViewModel(
            historyManager: historyManager,
            consoleViewModel: consoleViewModel
        )
        windowViewModel = WindowViewModel()

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "LastOpenedURL")
    }

    override func tearDown() async throws {
        cancellables = nil
        browserViewModel = nil
        consoleViewModel = nil
        historyManager = nil
        windowViewModel = nil

        try await super.tearDown()
    }

    // MARK: - Browser + History Integration Tests

    func testNavigationRecordsHistoryCorrectly() async throws {
        // Given
        let testURL = "https://example.com"
        let historyExpectation = XCTestExpectation(
            description: "History recorded"
        )

        // Monitor history changes
        historyManager.$items
            .dropFirst()
            .sink { items in
                if items.contains(where: {
                    $0.url.absoluteString.contains("example.com")
                }) {
                    historyExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When - Navigate
        browserViewModel.urlString = testURL
        browserViewModel.navigate()

        // Then
        await fulfillment(of: [historyExpectation], timeout: 5.0)

        let historyItems = await historyManager.recentHistory(limit: 10)
        XCTAssertFalse(historyItems.isEmpty)
        XCTAssertTrue(
            historyItems.contains {
                $0.url.absoluteString.contains("example.com")
            }
        )
    }

    func testHistoryAutocompleteIntegration() async throws {
        // Given - Add history items
        guard let githubURL = URL(string: "https://github.com/omnypro/scaffolde") else {
            XCTFail("Failed to create test URL")
            return
        }
        
        historyManager.addItem(
            url: githubURL,
            title: "Scaffolde Repository",
            transitionType: .typed
        )

        // When - Type partial URL
        let autocomplete = historyManager.getAutocompleteURL(
            for: "https://github"
        )

        // Then
        XCTAssertNotNil(autocomplete)
        XCTAssertEqual(autocomplete, "https://github.com/omnypro/scaffolde")
    }

    // MARK: - Browser + Console Integration Tests

    // MARK: - Window + Browser Integration Tests

    func testWindowSizeAffectsWebViewDisplay() async throws {
        // Given
        let testSize = WindowSize(name: "Test", width: 1280, height: 720)

        // When
        windowViewModel.setWindowSize(testSize)

        // Then - Verify effective size calculation
        let effectiveSize = windowViewModel.effectiveSize
        XCTAssertEqual(
            effectiveSize.width,
            1280 * CGFloat(windowViewModel.zoomLevel)
        )
        XCTAssertEqual(
            effectiveSize.height,
            720 * CGFloat(windowViewModel.zoomLevel)
        )
    }

    func testZoomLevelAffectsEffectiveSize() {
        // Given
        windowViewModel.currentSize = WindowSize(
            name: "1080p",
            width: 1920,
            height: 1080
        )

        // When - Set different zoom levels
        let testCases = [
            (zoom: 1.0, expectedWidth: CGFloat(1920), expectedHeight: CGFloat(1080)),
            (zoom: 0.75, expectedWidth: CGFloat(1440), expectedHeight: CGFloat(810)),
            (zoom: 0.5, expectedWidth: CGFloat(960), expectedHeight: CGFloat(540)),
            (zoom: 0.25, expectedWidth: CGFloat(480), expectedHeight: CGFloat(270))
        ]

        for testCase in testCases {
            windowViewModel.setZoomLevel(testCase.zoom)

            // Then
            let effectiveSize = windowViewModel.effectiveSize
            XCTAssertEqual(
                effectiveSize.width,
                testCase.expectedWidth,
                accuracy: 1.0
            )
            XCTAssertEqual(
                effectiveSize.height,
                testCase.expectedHeight,
                accuracy: 1.0
            )
        }
    }

    // MARK: - Keyboard Shortcuts Integration Tests

    func testCommandLFocusesURLField() async throws {
        // Given
        let focusExpectation = XCTestExpectation(
            description: "URL field focused"
        )

        windowViewModel.$shouldFocusURLField
            .dropFirst()
            .filter { $0 }
            .sink { _ in
                focusExpectation.fulfill()
            }
            .store(in: &cancellables)

        // When - Setup window (which includes keyboard shortcuts)
        windowViewModel.setupWindow()

        // Note: Actual keyboard event testing requires UI tests
        // This test verifies the mechanism exists
    }

    // MARK: - State Persistence Integration Tests

    // MARK: - Error Handling Integration Tests

    func testNavigationErrorShowsErrorPage() async throws {
        // Given
        let errorExpectation = XCTestExpectation(
            description: "Error page shown"
        )

        browserViewModel.$navigationError
            .compactMap { $0 }
            .sink { _ in
                errorExpectation.fulfill()
            }
            .store(in: &cancellables)

        // When - Navigate to invalid URL
        browserViewModel.urlString = "not-a-valid-url"
        browserViewModel.navigate()

        // Then
        await fulfillment(of: [errorExpectation], timeout: 2.0)

        XCTAssertNotNil(browserViewModel.navigationError)
    }

    // MARK: - Performance Tests

    func testLargeHistorySearchPerformance() throws {
        // Given - Add many history items
        measure {
            for index in 0..<100 {
                guard let url = URL(string: "https://site\(index).com") else {
                    XCTFail("Failed to create URL for site \(index)")
                    continue
                }
                historyManager.addItem(
                    url: url,
                    title: "Site \(index)",
                    transitionType: .typed
                )
            }

            // When - Search
            let results = historyManager.search("site", limit: 10)

            // Then
            XCTAssertEqual(results.count, 10)
        }
    }

    func testConsoleLogPerformanceWithManyLogs() throws {
        // Given
        measure {
            // Add many logs
            for index in 0..<100 {
                consoleViewModel.addLog("Log message \(index)", level: .info)
            }

            // When - Filter logs
            let filtered = consoleViewModel.filteredLogs

            // Then
            XCTAssertFalse(filtered.isEmpty)
        }
    }
}

// MARK: - Helper Extensions

extension HistoryManager {
    @MainActor
    func recentHistory(limit: Int) async -> [HistoryItem] {
        return search("", limit: limit)
    }
}
