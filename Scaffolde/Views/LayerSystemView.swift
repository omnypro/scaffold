//
//  LayerSystemView.swift
//  Scaffolde
//
//  Created by Avalonstar on 1/6/25.
//

import SwiftUI

struct LayerSystemView: View {
    @StateObject private var layerSystem = LayerSystemViewModel()
    @ObservedObject var windowViewModel: WindowViewModel
    
    var body: some View {
        HSplitView {
            // Layer panel on the left
            LayerPanelView(viewModel: layerSystem)
                .frame(minWidth: 250, maxWidth: 300)
            
            // Canvas in the center
            LayerCanvasView(
                viewModel: layerSystem,
                windowViewModel: windowViewModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Add Alert Overlay") {
                    // Example: Add a StreamLabs alert box
                    layerSystem.updateLayerURL(
                        layerSystem.layers[1].id,
                        url: "https://streamlabs.com/alert-box/v3/7B5C6F4D8A9E"
                    )
                }
                
                Button("Add Chat") {
                    // This would add a new layer in Phase 2
                }
                .disabled(true)
                
                Spacer()
                
                Menu {
                    ForEach(WindowSize.presets) { size in
                        Button(size.name) {
                            windowViewModel.setWindowSize(size)
                        }
                    }
                } label: {
                    Label("Window Size", systemImage: "aspectratio")
                }
            }
        }
    }
}