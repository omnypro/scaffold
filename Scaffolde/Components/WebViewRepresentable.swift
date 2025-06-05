import SwiftUI
import WebKit

/// Simplified WebViewRepresentable that just displays the WebView
struct WebViewRepresentable: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        webView.setValue(false, forKey: "drawsBackground")
        webView.setValue(NSColor.clear, forKey: "backgroundColor")

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.setNeedsDisplay(nsView.bounds)
    }
}
