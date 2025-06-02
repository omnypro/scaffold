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
                    webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
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
                self?.browserViewModel.isLoading = false
                self?.browserViewModel.loadingProgress = 0.0
            }
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            DispatchQueue.main.async { [weak self] in
                self?.browserViewModel.isLoading = false
                self?.browserViewModel.loadingProgress = 0.0
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
        
        Task { @MainActor in
            for await _ in browserViewModel.$navigationID.values {
                if let request = browserViewModel.navigationRequest {
                    context.coordinator.performNavigation(request)
                    browserViewModel.navigationRequest = nil
                }
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
