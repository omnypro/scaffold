import SwiftUI
import WebKit

struct WebViewRepresentable: NSViewRepresentable {
    @Binding var urlString: String?
    let consoleViewModel: ConsoleViewModel

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
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
                    DispatchQueue.main.async {
                        self.parent.consoleViewModel.addLog(
                            message,
                            level: logLevel
                        )
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
        {
            // Inject JavaScript to capture console logs
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
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Enable local file access
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        // Add script message handler for console logs
        config.userContentController.add(
            context.coordinator,
            name: "consoleLog"
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Enable developer extras (inspector)
        if webView.configuration.preferences.responds(
            to: NSSelectorFromString("developerExtrasEnabled")
        ) {
            webView.configuration.preferences.setValue(
                true,
                forKey: "developerExtrasEnabled"
            )
        }

        // Set transparent background
        webView.setValue(false, forKey: "drawsBackground")
        webView.setValue(
            NSColor.clear,
            forKey: "backgroundColor"
        )

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let urlString = urlString else { return }
        let trimmedURL = urlString.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedURL.isEmpty else { return }

        // Check if we need to load a new URL
        let currentURL = webView.url?.absoluteString ?? ""

        if trimmedURL.hasPrefix("file://") || trimmedURL.hasPrefix("/") {
            // Handle local files
            let url: URL
            if trimmedURL.hasPrefix("file://") {
                url = URL(string: trimmedURL)!
            } else {
                url = URL(fileURLWithPath: trimmedURL)
            }

            if currentURL != url.absoluteString {
                webView.loadFileURL(
                    url,
                    allowingReadAccessTo: url.deletingLastPathComponent()
                )
            }
        } else if trimmedURL.hasPrefix("http://")
            || trimmedURL.hasPrefix("https://")
        {
            // Handle web URLs
            if let url = URL(string: trimmedURL), currentURL != trimmedURL {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        } else {
            // Assume https:// if no protocol
            let fullURL = "https://\(trimmedURL)"
            if let url = URL(string: fullURL), currentURL != fullURL {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
}
