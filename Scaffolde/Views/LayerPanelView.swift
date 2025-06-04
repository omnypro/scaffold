//
//  LayerPanelView.swift
//  Scaffolde
//
//  Created by Avalonstar on 1/6/25.
//

import SwiftUI

struct LayerPanelView: View {
    @ObservedObject var viewModel: LayerSystemViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Layers")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.layers.reversed()) { layer in
                        LayerRowView(
                            layer: layer,
                            isSelected: viewModel.selectedLayerId == layer.id,
                            viewModel: viewModel
                        )
                        .onTapGesture {
                            viewModel.selectedLayerId = layer.id
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 250)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct LayerRowView: View {
    let layer: Layer
    let isSelected: Bool
    @ObservedObject var viewModel: LayerSystemViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: {
                    viewModel.toggleLayerVisibility(layer.id)
                }) {
                    Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                        .foregroundColor(layer.isVisible ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                
                Image(systemName: iconForLayerType(layer.type))
                    .foregroundColor(.secondary)
                
                Text(layer.name)
                    .lineLimit(1)
                
                Spacer()
            }
            
            // Opacity slider
            HStack {
                Text("Opacity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { layer.opacity },
                        set: { viewModel.updateLayerOpacity(layer.id, opacity: $0) }
                    ),
                    in: 0...1
                )
                
                Text("\(Int(layer.opacity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
            
            // URL/Image input for the layer
            if case .webView(let url) = layer.type {
                TextField("Enter URL", text: Binding(
                    get: { url },
                    set: { viewModel.updateLayerURL(layer.id, url: $0) }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.caption)
            }
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
    
    func iconForLayerType(_ type: Layer.LayerType) -> String {
        switch type {
        case .webView:
            return "globe"
        case .image:
            return "photo"
        }
    }
}