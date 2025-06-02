import SwiftUI
import WebKit

struct WebViewRepresentable: NSViewRepresentable {
    let consoleViewModel: ConsoleViewModel
    let browserViewModel: BrowserViewModel

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let consoleViewModel: ConsoleViewModel
        let browserViewModel: BrowserViewModel
        private var progressObserver: NSKeyValueObservation?
        private var webView: WKWebView?

        init(
            consoleViewModel: ConsoleViewModel,
            browserViewModel: BrowserViewModel
        ) {
            self.consoleViewModel = consoleViewModel
            self.browserViewModel = browserViewModel
        }

        func setupProgressObserver(for webView: WKWebView) {
            self.webView = webView
            progressObserver = webView.observe(
                \.estimatedProgress,
                options: [.new]
            ) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.browserViewModel.loadingProgress =
                        webView.estimatedProgress
                }
            }
        }

        func performNavigation(_ request: URLRequest) {
            guard let webView = webView else { return }

            if let url = request.url {
                if url.isFileURL {
                    webView.loadFileURL(
                        url,
                        allowingReadAccessTo: url.deletingLastPathComponent()
                    )
                } else {
                    webView.load(request)
                }
            }
        }

        deinit {
            progressObserver?.invalidate()
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "consoleLog" {
                if let dict = message.body as? [String: Any],
                    let level = dict["level"] as? String,
                    let message = dict["message"] as? String
                {
                    let logLevel = ConsoleLog.LogLevel(rawValue: level) ?? .log
                    DispatchQueue.main.async { [weak self] in
                        self?.consoleViewModel.addLog(
                            message,
                            level: logLevel
                        )
                    }
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation!
        ) {
            DispatchQueue.main.async { [weak self] in
                self?.browserViewModel.isLoading = true
                self?.browserViewModel.loadingProgress = 0.0
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
        {
            DispatchQueue.main.async { [weak self] in
                self?.browserViewModel.loadingProgress = 1.0

                if let url = webView.url {
                    self?.browserViewModel.didNavigate(to: url)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.browserViewModel.isLoading = false
                    self?.browserViewModel.loadingProgress = 0.0
                }
            }
            let js = """
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
                        sendToSwift('warn', arguments);
                    };
                    
                    console.info = function() {
                        originalInfo.apply(console, arguments);
                        sendToSwift('info', arguments);
                    };
                })();
                """

            webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("Error injecting console capture: \(error)")
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            DispatchQueue.main.async { [weak self] in
                self?.browserViewModel.navigationFailed(with: error)
                self?.loadErrorPage(in: webView, error: error)
            }
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            DispatchQueue.main.async { [weak self] in
                self?.browserViewModel.navigationFailed(with: error)
                self?.loadErrorPage(in: webView, error: error)
            }
        }

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (
                URLSession.AuthChallengeDisposition, URLCredential?
            ) -> Void
        ) {
            completionHandler(.performDefaultHandling, nil)
        }

        private func loadErrorPage(in webView: WKWebView, error: Error) {
            let nsError = error as NSError
            let errorTitle = errorTitle(for: nsError)
            let errorMessage = browserViewModel.errorDescription(for: error)

            let html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <title>\(errorTitle)</title>
                    <style>
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                            background: #1e1e1e;
                            color: #e0e0e0;
                            margin: 0;
                            padding: 40px;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            min-height: 100vh;
                            box-sizing: border-box;
                        }
                        .error-container {
                            max-width: 600px;
                            text-align: center;
                        }
                        h1 {
                            font-size: 48px;
                            margin: 0 0 20px 0;
                            font-weight: 300;
                        }
                        p {
                            font-size: 18px;
                            line-height: 1.6;
                            margin: 0 0 30px 0;
                            color: #b0b0b0;
                        }
                        .details {
                            font-size: 14px;
                            color: #808080;
                            margin-top: 40px;
                            padding-top: 20px;
                            border-top: 1px solid #333;
                        }
                        button {
                            background: #0066cc;
                            color: white;
                            border: none;
                            padding: 12px 24px;
                            font-size: 16px;
                            border-radius: 6px;
                            cursor: pointer;
                            margin: 10px;
                        }
                        button:hover {
                            background: #0052a3;
                        }
                        code {
                            background: #2a2a2a;
                            padding: 2px 6px;
                            border-radius: 3px;
                            font-family: monospace;
                        }
                    </style>
                </head>
                <body>
                    <div class="error-container">
                        <h1>\(errorTitle)</h1>
                        <p>\(errorMessage)</p>
                        <button onclick="location.reload()">Try Again</button>
                        <div class="details">
                            <p>Error Code: <code>\(nsError.code)</code></p>
                        </div>
                    </div>
                </body>
                </html>
                """

            webView.loadHTMLString(html, baseURL: nil)
        }

        private func errorTitle(for error: NSError) -> String {
            switch error.code {
            case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
                return "Server Not Found"
            case NSURLErrorCannotConnectToHost:
                return "Cannot Connect"
            case NSURLErrorNotConnectedToInternet:
                return "No Internet Connection"
            case NSURLErrorTimedOut:
                return "Connection Timed Out"
            case NSURLErrorNetworkConnectionLost:
                return "Connection Lost"
            case NSURLErrorServerCertificateHasBadDate,
                NSURLErrorServerCertificateUntrusted,
                NSURLErrorServerCertificateHasUnknownRoot,
                NSURLErrorServerCertificateNotYetValid:
                return "Security Error"
            case NSURLErrorFileDoesNotExist:
                return "File Not Found"
            case NSURLErrorNoPermissionsToReadFile:
                return "Access Denied"
            default:
                return "Cannot Load Page"
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            consoleViewModel: consoleViewModel,
            browserViewModel: browserViewModel
        )
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        config.userContentController.add(
            context.coordinator,
            name: "consoleLog"
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        context.coordinator.setupProgressObserver(for: webView)

        // Setup command observers
        Task { @MainActor in
            // Navigation command
            for await _ in browserViewModel.$navigationID.values {
                if let request = browserViewModel.navigationRequest {
                    context.coordinator.performNavigation(request)
                    browserViewModel.navigationRequest = nil
                }
            }
        }

        Task { @MainActor in
            // Reload command
            for await _ in browserViewModel.$reloadCommand.values {
                webView.reload()
            }
        }

        Task { @MainActor in
            // Hard reload command
            for await _ in browserViewModel.$hardReloadCommand.values {
                webView.reloadFromOrigin()
            }
        }

        Task { @MainActor in
            // Stop loading command
            for await _ in browserViewModel.$stopLoadingCommand.values {
                webView.stopLoading()
            }
        }

        if webView.configuration.preferences.responds(
            to: NSSelectorFromString("developerExtrasEnabled")
        ) {
            webView.configuration.preferences.setValue(
                true,
                forKey: "developerExtrasEnabled"
            )
        }

        webView.setValue(false, forKey: "drawsBackground")
        webView.setValue(
            NSColor.clear,
            forKey: "backgroundColor"
        )

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
    }
}
