//
//  LayerCanvasView.swift
//  Scaffolde
//
//  Created by Avalonstar on 1/6/25.
//

import SwiftUI

struct LayerCanvasView: View {
    @ObservedObject var viewModel: LayerSystemViewModel
    @ObservedObject var windowViewModel: WindowViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color
                Color.black
                
                // Render layers in order
                ForEach(viewModel.layers.sorted(by: { $0.zIndex < $1.zIndex })) { layer in
                    if layer.isVisible {
                        LayerView(
                            layer: layer,
                            viewModel: viewModel,
                            windowViewModel: windowViewModel
                        )
                        .opacity(layer.opacity)
                        .allowsHitTesting(layer.id == viewModel.selectedLayerId)
                    }
                }
            }
        }
    }
}

struct LayerView: View {
    let layer: Layer
    @ObservedObject var viewModel: LayerSystemViewModel
    @ObservedObject var windowViewModel: WindowViewModel
    
    var body: some View {
        switch layer.type {
        case .webView:
            if let webView = viewModel.webView(for: layer.id) {
                WebViewRepresentable(webView: webView)
            }
        case .image(let imagePath):
            if let imagePath = imagePath,
               let image = NSImage(contentsOfFile: imagePath) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if windowViewModel.backgroundImage != nil {
                // Use window background image for backward compatibility
                Image(nsImage: windowViewModel.backgroundImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}