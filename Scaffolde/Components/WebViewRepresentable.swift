import SwiftUI
import WebKit

/// Simplified WebViewRepresentable that just displays the WebView
struct WebViewRepresentable: NSViewRepresentable {
    let webView: WKWebView
    
    func makeNSView(context: Context) -> WKWebView {
        // Set visual properties
        webView.setValue(false, forKey: "drawsBackground")
        webView.setValue(NSColor.clear, forKey: "backgroundColor")
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed
    }
}