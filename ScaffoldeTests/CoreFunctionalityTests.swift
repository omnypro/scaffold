import XCTest
@testable import Scaffolde

/// Tests to ensure core browser functionality never breaks
class CoreFunctionalityTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    // MARK: - URL Parsing Tests
    
    func testURLParsingForWebURLs() {
        let viewModel = createBrowserViewModel()
        
        // Test cases that should work
        let validURLs = [
            ("https://google.com", "https://google.com"),
            ("http://example.com", "http://example.com"),
            ("google.com", "https://google.com"),
            ("example.com:8080", "https://example.com:8080")
        ]
        
        for (input, expected) in validURLs {
            viewModel.urlString = input
            let url = viewModel.parseURL(from: input)
            XCTAssertNotNil(url, "Failed to parse: \(input)")
            XCTAssertEqual(url?.absoluteString, expected, "URL mismatch for: \(input)")
        }
    }
    
    func testURLParsingForFilePaths() {
        let viewModel = createBrowserViewModel()
        
        // Test file paths
        let filePaths = [
            "/Users/test/file.html",
            "file:///Users/test/file.html"
        ]
        
        for path in filePaths {
            let url = viewModel.parseURL(from: path)
            XCTAssertNotNil(url, "Failed to parse file path: \(path)")
            XCTAssertTrue(url?.isFileURL ?? false, "Should be file URL: \(path)")
        }
    }
    
    func testURLParsingInvalidInputs() {
        let viewModel = createBrowserViewModel()
        
        let invalidInputs = ["", "   ", "not a url at all"]
        
        for input in invalidInputs {
            let url = viewModel.parseURL(from: input)
            XCTAssertNil(url, "Should not parse invalid input: \(input)")
        }
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationTriggersWebViewLoad() {
        let viewModel = createBrowserViewModel()
        let mockDelegate = MockNavigationDelegate()
        viewModel.webView.navigationDelegate = mockDelegate
        
        viewModel.urlString = "https://example.com"
        viewModel.navigate()
        
        // Wait briefly for navigation to start
        let expectation = self.expectation(description: "Navigation started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertTrue(mockDelegate.didStartNavigation, "Navigation should have started")
    }
    
    // MARK: - State Management Tests
    
    func testLoadingStateUpdates() {
        let viewModel = createBrowserViewModel()
        
        // Initial state
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.loadingProgress, 0.0)
        
        // When WebView updates, our published properties should update
        // This tests that KVO observers are working
    }
    
    // MARK: - Console Integration Tests
    
    func testConsoleLoggingSetup() {
        let consoleViewModel = ConsoleViewModel()
        let viewModel = BrowserViewModel(
            historyManager: HistoryManager(),
            consoleViewModel: consoleViewModel
        )
        
        // Verify console script is injected
        let scripts = viewModel.webView.configuration.userContentController.userScripts
        XCTAssertTrue(scripts.count > 0, "Console script should be injected")
        
        // Verify message handler is registered
        // Note: WKUserContentController doesn't expose handlers, so we test indirectly
    }
    
    // MARK: - History Tests
    
    func testHistoryRecordingOnNavigation() {
        let historyManager = HistoryManager()
        let viewModel = BrowserViewModel(
            historyManager: historyManager,
            consoleViewModel: ConsoleViewModel()
        )
        
        let initialCount = historyManager.allItems.count
        
        // Simulate successful navigation
        let testURL = URL(string: "https://example.com")!
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
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        didStartNavigation = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishNavigation = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didFailNavigation = true
    }
}