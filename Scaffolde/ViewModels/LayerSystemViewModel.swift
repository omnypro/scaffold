//
//  LayerSystemViewModel.swift
//  Scaffolde
//
//  Created by Avalonstar on 1/6/25.
//

import Foundation
import SwiftUI
import WebKit

@MainActor
class LayerSystemViewModel: ObservableObject {
    @Published var layers: [Layer] = LayerConfiguration.defaultLayers
    @Published var selectedLayerId: UUID?
    
    // WebView instances for each layer
    private var webViews: [UUID: WKWebView] = [:]
    
    init() {
        // Initialize WebViews for webView type layers
        for layer in layers {
            if case .webView = layer.type {
                let webView = createWebView()
                webViews[layer.id] = webView
            }
        }
    }
    
    private func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.setValue(NSColor.clear, forKey: "backgroundColor")
        
        return webView
    }
    
    func webView(for layerId: UUID) -> WKWebView? {
        return webViews[layerId]
    }
    
    func updateLayerOpacity(_ layerId: UUID, opacity: Double) {
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].opacity = opacity
        }
    }
    
    func toggleLayerVisibility(_ layerId: UUID) {
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].isVisible.toggle()
        }
    }
    
    func updateLayerURL(_ layerId: UUID, url: String) {
        if let index = layers.firstIndex(where: { $0.id == layerId }),
           case .webView = layers[index].type {
            layers[index].type = .webView(url: url)
            
            // Load the URL in the WebView
            if let webView = webViews[layerId],
               let url = URL(string: url) {
                webView.load(URLRequest(url: url))
            }
        }
    }
    
    func updateLayerImage(_ layerId: UUID, imagePath: String?) {
        if let index = layers.firstIndex(where: { $0.id == layerId }),
           case .image = layers[index].type {
            layers[index].type = .image(imagePath: imagePath)
        }
    }
    
    var selectedLayer: Layer? {
        layers.first { $0.id == selectedLayerId }
    }
}