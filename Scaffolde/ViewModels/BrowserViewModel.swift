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
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            } else {
                webView.load(URLRequest(url: url))
            }
        } else {
            navigationError = NSError(
                domain: "Scaffolde",
                code: NSURLErrorBadURL,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL or file path"]
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
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        loadingObserver = webView.observe(\.isLoading) { [weak self] _, _ in
            Task { @MainActor in
                self?.isLoading = self?.webView.isLoading ?? false
            }
        }
        
        progressObserver = webView.observe(\.estimatedProgress) { [weak self] _, _ in
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
                    self?.urlString = url.absoluteString
                }
            }
        }
        
        canGoBackObserver = webView.observe(\.canGoBack) { [weak self] _, _ in
            Task { @MainActor in
                self?.canGoBack = self?.webView.canGoBack ?? false
            }
        }
        
        canGoForwardObserver = webView.observe(\.canGoForward) { [weak self] _, _ in
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
            })();
            """
        
        let script = WKUserScript(
            source: consoleScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(self, name: "consoleLog")
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
        
        // Try adding https:// prefix
        if let url = URL(string: "https://\(trimmed)"), url.host != nil {
            return url
        }
        
        return nil
    }
}

// MARK: - WKNavigationDelegate
extension BrowserViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
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
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        navigationError = error
        consoleViewModel.addLog(
            "Navigation failed: \(error.localizedDescription)",
            level: .error
        )
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        navigationError = error
        
        let nsError = error as NSError
        var errorMessage = "Navigation failed: \(error.localizedDescription)"
        
        // Add more context for common errors
        switch nsError.code {
        case NSURLErrorSecureConnectionFailed:
            errorMessage += " (SSL/TLS certificate issue)"
        case NSURLErrorCannotFindHost:
            errorMessage += " (Cannot find host)"
        case NSURLErrorNotConnectedToInternet:
            errorMessage += " (No internet connection)"
        default:
            break
        }
        
        consoleViewModel.addLog(errorMessage, level: .error)
    }
}

// MARK: - WKScriptMessageHandler
extension BrowserViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "consoleLog",
              let body = message.body as? [String: Any],
              let level = body["level"] as? String,
              let messageText = body["message"] as? String else { return }
        
        let logLevel: ConsoleLog.LogLevel = switch level {
        case "error": .error
        case "warning": .warn
        case "info": .info
        default: .log
        }
        
        consoleViewModel.addLog(messageText, level: logLevel)
    }
}