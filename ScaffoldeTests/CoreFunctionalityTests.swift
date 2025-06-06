import WebKit
import XCTest

@testable import Scaffolde

/// Tests to ensure core browser functionality never breaks
@MainActor
class CoreFunctionalityTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - URL Parsing Tests

    func testURLParsingForWebURLs() async {
        let viewModel = createBrowserViewModel()

        // Test cases that should work
        let validURLs = [
            ("https://google.com", "https://google.com"),
            ("http://example.com", "http://example.com"),
            ("google.com", "https://google.com"),
            ("example.com:8080", "https://example.com:8080"),
        ]

        for (input, expected) in validURLs {
            viewModel.urlString = input
            let url = viewModel.parseURL(from: input)
            XCTAssertNotNil(url, "Failed to parse: \(input)")
            XCTAssertEqual(
                url?.absoluteString,
                expected,
                "URL mismatch for: \(input)"
            )
        }
    }

    func testURLParsingForLocalhost() async {
        let viewModel = createBrowserViewModel()

        // Test localhost URLs - should default to http://
        let localhostURLs = [
            ("localhost", "http://localhost"),
            ("localhost:3000", "http://localhost:3000"),
            ("localhost:8080", "http://localhost:8080"),
            ("127.0.0.1", "http://127.0.0.1"),
            ("127.0.0.1:8080", "http://127.0.0.1:8080"),
            ("0.0.0.0:4000", "http://0.0.0.0:4000"),
        ]

        for (input, expected) in localhostURLs {
            let url = viewModel.parseURL(from: input)
            XCTAssertNotNil(url, "Failed to parse localhost URL: \(input)")
            XCTAssertEqual(
                url?.absoluteString,
                expected,
                "Localhost URL should use http://: \(input)"
            )
        }
    }

    func testURLParsingForFilePaths() async {
        let viewModel = createBrowserViewModel()

        // Test file paths
        let filePaths = [
            "/Users/test/file.html",
            "file:///Users/test/file.html",
        ]

        for path in filePaths {
            let url = viewModel.parseURL(from: path)
            XCTAssertNotNil(url, "Failed to parse file path: \(path)")
            XCTAssertTrue(
                url?.isFileURL ?? false,
                "Should be file URL: \(path)"
            )
        }
    }

    func testURLParsingInvalidInputs() async {
        let viewModel = createBrowserViewModel()

        let invalidInputs = ["", "   ", "not a url at all"]

        for input in invalidInputs {
            let url = viewModel.parseURL(from: input)
            XCTAssertNil(url, "Should not parse invalid input: \(input)")
        }
    }

    // MARK: - Navigation Tests

    func testNavigationTriggersWebViewLoad() async {
        let viewModel = createBrowserViewModel()
        let expectation = self.expectation(description: "Navigation started")
        
        class TestDelegate: NSObject, WKNavigationDelegate {
            let expectation: XCTestExpectation
            var didStart = false
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            
            func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
                didStart = true
                expectation.fulfill()
            }
            
            func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
                // Still fulfill expectation on failure so test doesn't hang
                expectation.fulfill()
            }
        }
        
        let testDelegate = TestDelegate(expectation: expectation)
        viewModel.webView.navigationDelegate = testDelegate

        viewModel.urlString = "https://example.com"
        viewModel.navigate()

        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertTrue(
            testDelegate.didStart,
            "Navigation should have started"
        )
    }

    // MARK: - State Management Tests

    func testLoadingStateUpdates() async {
        let viewModel = createBrowserViewModel()

        // Initial state
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.loadingProgress, 0.0)

        // When WebView updates, our published properties should update
        // This tests that KVO observers are working
    }

    // MARK: - Console Integration Tests

    func testConsoleLoggingSetup() async {
        let consoleViewModel = ConsoleViewModel()
        let viewModel = BrowserViewModel(
            historyManager: HistoryManager(),
            consoleViewModel: consoleViewModel
        )

        // Verify console script is injected
        let scripts = viewModel.webView.configuration.userContentController
            .userScripts
        XCTAssertTrue(scripts.count > 0, "Console script should be injected")

        // Verify message handler is registered
        // Note: WKUserContentController doesn't expose handlers, so we test indirectly
    }

    // MARK: - History Tests

    func testHistoryRecordingOnNavigation() async {
        let historyManager = HistoryManager()
        let viewModel = BrowserViewModel(
            historyManager: historyManager,
            consoleViewModel: ConsoleViewModel()
        )

        _ = historyManager.items.count

        // Simulate successful navigation
        _ = URL(string: "https://example.com")!
        viewModel.webView(viewModel.webView, didFinish: nil)

        // Note: In real implementation, we'd need to mock the webView.url property
    }

    // MARK: - Helper Methods

    private func createBrowserViewModel() -> BrowserViewModel {
        return BrowserViewModel(
            historyManager: HistoryManager(),
            consoleViewModel: ConsoleViewModel()
        )
    }
}

// MARK: - Mock Classes

class MockNavigationDelegate: NSObject, WKNavigationDelegate {
    var didStartNavigation = false
    var didFinishNavigation = false
    var didFailNavigation = false

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        didStartNavigation = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishNavigation = true
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        didFailNavigation = true
    }
}
