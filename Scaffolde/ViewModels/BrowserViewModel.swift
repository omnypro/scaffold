import Combine
import Foundation
import WebKit

/// Simplified BrowserViewModel that owns WebView directly
@MainActor
class BrowserViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var urlString: String = ""
    @Published var currentURL: URL? = nil
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var pageTitle: String = ""
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var navigationError: Error? = nil

    // MARK: - WebView
    let webView: WKWebView

    // MARK: - Dependencies
    let historyManager: HistoryManager
    let consoleViewModel: ConsoleViewModel

    // MARK: - Private Properties
    private var loadingObserver: NSKeyValueObservation?
    private var progressObserver: NSKeyValueObservation?
    private var titleObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?

    // MARK: - Initialization
    init(historyManager: HistoryManager, consoleViewModel: ConsoleViewModel) {
        self.historyManager = historyManager
        self.consoleViewModel = consoleViewModel

        // Configure WebView
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        // Set delegates
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // Setup observers for WebView properties
        setupObservers()

        // Setup console logging
        setupConsoleLogging()
    }

    // MARK: - Navigation Methods

    /// Navigate to URL from the URL bar
    func navigate() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let url = parseURL(from: trimmed) {
            if url.isFileURL {
                webView.loadFileURL(
                    url,
                    allowingReadAccessTo: url.deletingLastPathComponent()
                )
            } else {
                webView.load(URLRequest(url: url))
            }
        } else {
            navigationError = NSError(
                domain: "Scaffolde",
                code: NSURLErrorBadURL,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid URL or file path"
                ]
            )
        }
    }

    /// Reload the current page
    func reload() {
        webView.reload()
    }

    /// Hard reload (reload from origin)
    func hardReload() {
        webView.reloadFromOrigin()
    }

    /// Stop loading
    func stopLoading() {
        webView.stopLoading()
    }

    /// Go back
    func goBack() {
        webView.goBack()
    }

    /// Go forward
    func goForward() {
        webView.goForward()
    }
    
    /// Open Web Inspector
    func openWebInspector() {
        // Try the modern approach first
        if webView.responds(to: Selector(("_showInspector"))) {
            webView.perform(Selector(("_showInspector")))
        } else if webView.responds(to: Selector(("showInspector"))) {
            webView.perform(Selector(("showInspector")))
        } else {
            // Fallback: Try to get the inspector and show it
            if let inspector = webView.perform(Selector(("_inspector")))?.takeUnretainedValue() as? NSObject {
                if inspector.responds(to: Selector(("show:"))) {
                    inspector.perform(Selector(("show:")), with: nil)
                } else if inspector.responds(to: Selector(("showWindow:"))) {
                    inspector.perform(Selector(("showWindow:")), with: nil)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func displayErrorPage(
        title: String,
        description: String,
        url: String
    ) {
        let errorHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        background-color: #1e1e1e;
                        color: #ffffff;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        margin: 0;
                        text-align: center;
                    }
                    .error-container {
                        max-width: 500px;
                        padding: 40px;
                    }
                    .error-icon {
                        font-size: 72px;
                        margin-bottom: 20px;
                        opacity: 0.7;
                    }
                    h1 {
                        font-size: 28px;
                        font-weight: 500;
                        margin: 0 0 16px 0;
                    }
                    p {
                        font-size: 16px;
                        line-height: 1.5;
                        opacity: 0.8;
                        margin: 0 0 24px 0;
                    }
                    .url {
                        font-family: 'SF Mono', Monaco, 'Courier New', monospace;
                        font-size: 13px;
                        background-color: rgba(255, 255, 255, 0.1);
                        padding: 8px 12px;
                        border-radius: 4px;
                        word-break: break-all;
                        margin-bottom: 24px;
                    }
                    .actions {
                        display: flex;
                        gap: 12px;
                        justify-content: center;
                    }
                    button {
                        background-color: #007AFF;
                        color: white;
                        border: none;
                        padding: 10px 20px;
                        border-radius: 6px;
                        font-size: 14px;
                        cursor: pointer;
                        transition: opacity 0.2s;
                    }
                    button:hover {
                        opacity: 0.8;
                    }
                    button.secondary {
                        background-color: rgba(255, 255, 255, 0.1);
                    }
                </style>
            </head>
            <body>
                <div class="error-container">
                    <div class="error-icon">⚠️</div>
                    <h1>\(title)</h1>
                    <p>\(description)</p>
                    <div class="url">\(url)</div>
                    <div class="actions">
                        <button onclick="window.location.reload()">Try Again</button>
                        <button class="secondary" onclick="window.history.back()">Go Back</button>
                    </div>
                </div>
            </body>
            </html>
            """

        webView.loadHTMLString(errorHTML, baseURL: nil)

        DispatchQueue.main.async { [weak self] in
            self?.urlString = url
        }
    }

    private func setupObservers() {
        loadingObserver = webView.observe(\.isLoading) { [weak self] _, _ in
            Task { @MainActor in
                self?.isLoading = self?.webView.isLoading ?? false
            }
        }

        progressObserver = webView.observe(\.estimatedProgress) {
            [weak self] _, _ in
            Task { @MainActor in
                self?.loadingProgress = self?.webView.estimatedProgress ?? 0.0
            }
        }

        titleObserver = webView.observe(\.title) { [weak self] _, _ in
            Task { @MainActor in
                self?.pageTitle = self?.webView.title ?? ""
            }
        }

        urlObserver = webView.observe(\.url) { [weak self] _, _ in
            Task { @MainActor in
                if let url = self?.webView.url {
                    self?.currentURL = url
                    if url.absoluteString != "about:blank" {
                        self?.urlString = url.absoluteString
                    }
                }
            }
        }

        canGoBackObserver = webView.observe(\.canGoBack) { [weak self] _, _ in
            Task { @MainActor in
                self?.canGoBack = self?.webView.canGoBack ?? false
            }
        }

        canGoForwardObserver = webView.observe(\.canGoForward) {
            [weak self] _, _ in
            Task { @MainActor in
                self?.canGoForward = self?.webView.canGoForward ?? false
            }
        }
    }

    private func setupConsoleLogging() {
        // Inject console capture script
        let consoleScript = """
            (function() {
                const originalLog = console.log;
                const originalError = console.error;
                const originalWarn = console.warn;
                const originalInfo = console.info;
                const originalDebug = console.debug;
                
                function sendToSwift(level, args) {
                    const message = Array.from(args).map(arg => {
                        if (typeof arg === 'object') {
                            try {
                                return JSON.stringify(arg, null, 2);
                            } catch(e) {
                                return String(arg);
                            }
                        }
                        return String(arg);
                    }).join(' ');
                    
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: level,
                        message: message
                    });
                }
                
                console.log = function() {
                    originalLog.apply(console, arguments);
                    sendToSwift('log', arguments);
                };
                
                console.error = function() {
                    originalError.apply(console, arguments);
                    sendToSwift('error', arguments);
                };
                
                console.warn = function() {
                    originalWarn.apply(console, arguments);
                    sendToSwift('warning', arguments);
                };
                
                console.info = function() {
                    originalInfo.apply(console, arguments);
                    sendToSwift('info', arguments);
                };
                
                console.debug = function() {
                    originalDebug.apply(console, arguments);
                    sendToSwift('debug', arguments);
                };
            })();
            """

        let script = WKUserScript(
            source: consoleScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(
            self,
            name: "consoleLog"
        )
    }

    func parseURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Local file path
        if trimmed.hasPrefix("/") {
            let url = URL(fileURLWithPath: trimmed)
            return FileManager.default.fileExists(atPath: trimmed) ? url : nil
        }

        // File URL
        if trimmed.hasPrefix("file://") {
            return URL(string: trimmed)
        }

        // HTTP/HTTPS URL
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }

        // Default to http:// for everything without a protocol
        if let url = URL(string: "http://\(trimmed)"), url.host != nil {
            return url
        }

        return nil
    }
}

// MARK: - WKNavigationDelegate
extension BrowserViewModel: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        navigationError = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            historyManager.addItem(
                url: url,
                title: webView.title ?? url.absoluteString,
                transitionType: .typed
            )
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        navigationError = error

        let nsError = error as NSError
        let errorTitle = "Page Load Error"
        let errorDescription = error.localizedDescription

        // Handle specific error cases
        switch nsError.code {
        case NSURLErrorCancelled:
            // User cancelled, don't show error page
            return
        default:
            break
        }

        consoleViewModel.addLog(
            "Navigation failed: \(error.localizedDescription)",
            level: .error
        )

        // Display error page
        displayErrorPage(
            title: errorTitle,
            description: errorDescription,
            url: urlString
        )
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        navigationError = error

        let nsError = error as NSError
        var errorMessage = "Navigation failed: \(error.localizedDescription)"
        var errorTitle = "Cannot Load Page"
        var errorDescription = error.localizedDescription

        // Add more context for common errors
        switch nsError.code {
        case NSURLErrorSecureConnectionFailed:
            errorMessage += " (SSL/TLS certificate issue)"
            errorTitle = "Security Error"
            errorDescription =
                "There was a problem with the security certificate for this site."
        case NSURLErrorCannotFindHost:
            errorMessage += " (Cannot find host)"
            errorTitle = "Server Not Found"
            errorDescription =
                "The server could not be found. Please check the URL and try again."
        case NSURLErrorNotConnectedToInternet:
            errorMessage += " (No internet connection)"
            errorTitle = "No Internet Connection"
            errorDescription =
                "Please check your internet connection and try again."
        case NSURLErrorTimedOut:
            errorTitle = "Connection Timed Out"
            errorDescription = "The server took too long to respond."
        case NSURLErrorFileDoesNotExist:
            errorTitle = "File Not Found"
            errorDescription = "The requested file could not be found."
        default:
            break
        }

        consoleViewModel.addLog(errorMessage, level: .error)

        // Display error page in WebView
        displayErrorPage(
            title: errorTitle,
            description: errorDescription,
            url: urlString
        )
    }
}

// MARK: - WKScriptMessageHandler
extension BrowserViewModel: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "consoleLog",
            let body = message.body as? [String: Any],
            let level = body["level"] as? String,
            let messageText = body["message"] as? String
        else { return }

        let logLevel: ConsoleLog.LogLevel =
            switch level {
            case "error": .error
            case "warning": .warn
            case "info": .info
            case "debug": .log  // Map debug to log for now
            default: .log
            }

        consoleViewModel.addLog(messageText, level: logLevel)
    }
}

// MARK: - WKUIDelegate
extension BrowserViewModel: WKUIDelegate {
    // This captures native console messages that aren't from JavaScript console.* calls
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        consoleViewModel.addLog(message, level: .log)
        completionHandler()
    }
    
    // Capture console messages from the browser itself
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        consoleViewModel.addLog("Web content process terminated", level: .error)
    }
}
