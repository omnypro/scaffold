import Combine
import WebKit
import XCTest

@testable import Scaffolde

@MainActor
final class BrowserViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: BrowserViewModel!
    private var mockHistoryManager: HistoryManager!
    private var mockConsoleViewModel: ConsoleViewModel!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        cancellables = []
        mockHistoryManager = HistoryManager()
        mockConsoleViewModel = ConsoleViewModel()
        sut = BrowserViewModel(
            historyManager: mockHistoryManager,
            consoleViewModel: mockConsoleViewModel
        )

        // Clear UserDefaults for testing
        UserDefaults.standard.removeObject(forKey: "LastOpenedURL")
    }

    override func tearDown() async throws {
        cancellables = nil
        sut = nil
        mockHistoryManager = nil
        mockConsoleViewModel = nil

        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Then
        XCTAssertEqual(sut.urlString, "")
        XCTAssertNil(sut.currentURL)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.loadingProgress, 0.0)
        XCTAssertEqual(sut.pageTitle, "")
        XCTAssertFalse(sut.canGoBack)
        XCTAssertFalse(sut.canGoForward)
        XCTAssertNil(sut.navigationError)
    }

    func testURLStringUpdates() {
        // When
        sut.urlString = "https://example.com"

        // Then
        XCTAssertEqual(sut.urlString, "https://example.com")
    }

    // MARK: - Navigation Error Tests

    func testNavigationWithInvalidURL() {
        // Given
        let invalidURL = "not a valid url at all"

        // When
        sut.urlString = invalidURL
        sut.navigate()

        // Then
        XCTAssertNotNil(sut.navigationError)
        XCTAssertEqual(
            (sut.navigationError as NSError?)?.code,
            NSURLErrorBadURL
        )
    }

    func testNavigationWithEmptyURL() {
        // Given
        sut.urlString = ""

        // When
        sut.navigate()

        // Then - Should not crash, just do nothing
        XCTAssertNil(sut.navigationError)
    }

    func testNavigationWithWhitespaceURL() {
        // Given
        sut.urlString = "   "

        // When
        sut.navigate()

        // Then - Should trim and do nothing
        XCTAssertNil(sut.navigationError)
    }

    // MARK: - WebView Command Tests

    func testReloadCommand() {
        // Given
        let webView = sut.webView

        // When
        sut.reload()

        // Then - WebView should receive reload command
        // Note: We can't verify the actual reload without UI testing
        XCTAssertNotNil(webView)
    }

    func testHardReloadCommand() {
        // Given
        let webView = sut.webView

        // When
        sut.hardReload()

        // Then - WebView should receive reload from origin command
        XCTAssertNotNil(webView)
    }

    func testStopLoadingCommand() {
        // Given
        let webView = sut.webView

        // When
        sut.stopLoading()

        // Then - WebView should receive stop loading command
        XCTAssertNotNil(webView)
    }

    func testGoBackCommand() {
        // When
        sut.goBack()

        // Then - Should not crash even if can't go back
        XCTAssertFalse(sut.canGoBack)
    }

    func testGoForwardCommand() {
        // When
        sut.goForward()

        // Then - Should not crash even if can't go forward
        XCTAssertFalse(sut.canGoForward)
    }

    // MARK: - URL Validation Tests

    func testNavigateWithValidURLs() {
        let validURLs = [
            "https://example.com",
            "http://localhost:3000",
            "file:///Users/test/file.html",
            "/Users/test/file.html"
        ]

        for urlString in validURLs {
            // Reset error
            sut.navigationError = nil

            // When
            sut.urlString = urlString
            sut.navigate()

            // Then - Should not have immediate error
            XCTAssertNil(sut.navigationError, "Failed for URL: \(urlString)")
        }
    }

    // MARK: - WebView Integration Tests

    func testWebViewExists() {
        XCTAssertNotNil(sut.webView)
    }

    func testWebViewHasNavigationDelegate() {
        XCTAssertNotNil(sut.webView.navigationDelegate)
        XCTAssertTrue(sut.webView.navigationDelegate === sut)
    }

    func testWebViewHasUIDelegate() {
        XCTAssertNotNil(sut.webView.uiDelegate)
        XCTAssertTrue(sut.webView.uiDelegate === sut)
    }

    // MARK: - URL Persistence Tests

    func testURLRestorationOnInit() async throws {
        // Given - Save a URL to UserDefaults
        let testURL = "https://restored.com"
        UserDefaults.standard.set(testURL, forKey: "LastOpenedURL")

        // When - Create new view model
        let restoredViewModel = BrowserViewModel(
            historyManager: mockHistoryManager,
            consoleViewModel: mockConsoleViewModel
        )

        // Then - URL should be restored
        XCTAssertEqual(restoredViewModel.urlString, testURL)
    }

    // MARK: - History Integration Tests

    func testNavigationRecordsHistory() async throws {
        // Given
        let testURL = "https://example.com"
        let historyExpectation = XCTestExpectation(
            description: "History recorded"
        )

        mockHistoryManager.$items
            .dropFirst()
            .sink { items in
                if items.contains(where: {
                    $0.url.absoluteString.contains("example.com")
                }) {
                    historyExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        sut.urlString = testURL
        sut.navigate()

        // Then
        await fulfillment(of: [historyExpectation], timeout: 5.0)

        let history = mockHistoryManager.search("", limit: 10)
        XCTAssertFalse(history.isEmpty)
        XCTAssertTrue(
            history.contains { $0.url.absoluteString.contains("example.com") }
        )
    }
}
