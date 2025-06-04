import SwiftUI
import WebKit
import Combine

/// Layer types that can be added to the system
enum LayerType: Identifiable, Equatable {
    case webView(url: String)
    case image(NSImage)
    case color(Color)
    
    var id: String {
        switch self {
        case .webView(let url): return "webview-\(url)"
        case .image: return "image-\(UUID().uuidString)"
        case .color: return "color-\(UUID().uuidString)"
        }
    }
}

/// Individual layer in the layer system
class Layer: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var type: LayerType
    @Published var opacity: Double = 1.0
    @Published var isVisible: Bool = true
    @Published var isLocked: Bool = false
    var zIndex: Int = 0
    
    // For WebView layers
    var webView: WKWebView?
    var webViewModel: BrowserViewModel?
    
    init(name: String, type: LayerType, zIndex: Int = 0) {
        self.name = name
        self.type = type
        self.zIndex = zIndex
        
        // Initialize WebView if needed
        if case .webView(let url) = type {
            setupWebView(url: url)
        }
    }
    
    private func setupWebView(url: String) {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        // Inject CSS to make the WebView background transparent
        let script = WKUserScript(
            source: """
            document.documentElement.style.backgroundColor = 'transparent';
            document.body.style.backgroundColor = 'transparent';
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(script)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        self.webView = webView
        
        // Parse and load the URL
        if let parsedURL = parseURL(from: url) {
            webView.load(URLRequest(url: parsedURL))
        }
    }
    
    private func parseURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Already a valid URL
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        
        // Check for localhost or IP addresses
        if trimmed.hasPrefix("localhost") || trimmed.range(of: #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"#, options: .regularExpression) != nil {
            return URL(string: "http://\(trimmed)")
        }
        
        // Try adding https://
        if let url = URL(string: "https://\(trimmed)"), url.host != nil {
            return url
        }
        
        return nil
    }
}

/// Main layer system view model
@MainActor
class LayerSystemViewModel: ObservableObject {
    @Published var layers: [Layer] = []
    @Published var selectedLayer: Layer?
    @Published var isPanelVisible = false
    
    // Limit WebView layers for performance
    private let maxWebViewLayers = 3
    
    var webViewLayerCount: Int {
        layers.filter { layer in
            if case .webView = layer.type {
                return true
            }
            return false
        }.count
    }
    
    var canAddWebViewLayer: Bool {
        webViewLayerCount < maxWebViewLayers
    }
    
    // MARK: - Layer Management
    
    func addLayer(type: LayerType, name: String? = nil) {
        // Check WebView limit
        if case .webView = type, !canAddWebViewLayer {
            return
        }
        
        let layerName = name ?? generateLayerName(for: type)
        let zIndex = layers.count // New layers go on top
        let layer = Layer(name: layerName, type: type, zIndex: zIndex)
        
        layers.append(layer)
        selectedLayer = layer
    }
    
    func removeLayer(_ layer: Layer) {
        layers.removeAll { $0.id == layer.id }
        if selectedLayer?.id == layer.id {
            selectedLayer = layers.last
        }
    }
    
    func duplicateLayer(_ layer: Layer) {
        // Don't duplicate WebView layers if at limit
        if case .webView = layer.type, !canAddWebViewLayer {
            return
        }
        
        let newLayer = Layer(
            name: "\(layer.name) Copy",
            type: layer.type
        )
        newLayer.opacity = layer.opacity
        newLayer.isVisible = layer.isVisible
        
        if let index = layers.firstIndex(where: { $0.id == layer.id }) {
            layers.insert(newLayer, at: index + 1)
            selectedLayer = newLayer
        }
    }
    
    func moveLayer(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
        // Update zIndex for all layers after move
        for (index, layer) in layers.enumerated() {
            layer.zIndex = index
        }
    }
    
    func toggleLayerVisibility(_ layer: Layer) {
        layer.isVisible.toggle()
    }
    
    func toggleLayerLock(_ layer: Layer) {
        layer.isLocked.toggle()
    }
    
    func togglePanel() {
        isPanelVisible.toggle()
    }
    
    // MARK: - Private Methods
    
    private func generateLayerName(for type: LayerType) -> String {
        switch type {
        case .webView(let url):
            if let host = URL(string: url)?.host {
                return host
            }
            return "Web Layer"
        case .image:
            return "Image Layer"
        case .color:
            return "Color Layer"
        }
    }
}