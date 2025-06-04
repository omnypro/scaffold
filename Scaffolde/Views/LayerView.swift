import SwiftUI
import WebKit

struct LayerView: View {
    @ObservedObject var layer: Layer
    
    var body: some View {
        Group {
            switch layer.type {
            case .webView:
                if let webView = layer.webView {
                    WebViewLayerRepresentable(webView: webView)
                        .allowsHitTesting(!layer.isLocked)
                }
                
            case .image(let image):
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
                
            case .color(let color):
                color
                    .allowsHitTesting(false)
            }
        }
        .opacity(layer.isVisible ? layer.opacity : 0)
    }
}

// MARK: - WebView Layer Representable

struct WebViewLayerRepresentable: NSViewRepresentable {
    let webView: WKWebView
    
    func makeNSView(context: Context) -> WKWebView {
        // Make WebView transparent
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed
    }
}