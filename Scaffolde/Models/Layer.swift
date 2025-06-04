//
//  Layer.swift
//  Scaffolde
//
//  Created by Avalonstar on 1/6/25.
//

import Foundation
import SwiftUI

struct Layer: Identifiable, Equatable {
    enum LayerType: Equatable {
        case webView(url: String)
        case image(imagePath: String?)
    }
    
    let id = UUID()
    var name: String
    var type: LayerType
    var opacity: Double = 1.0
    var isVisible: Bool = true
    var zIndex: Int
    
    static func == (lhs: Layer, rhs: Layer) -> Bool {
        lhs.id == rhs.id
    }
}

// For Phase 1, we'll support just 2 layers
struct LayerConfiguration {
    static let maxWebViewLayers = 2
    static let defaultLayers: [Layer] = [
        Layer(
            name: "Background",
            type: .image(imagePath: nil),
            opacity: 1.0,
            isVisible: true,
            zIndex: 0
        ),
        Layer(
            name: "Overlay 1",
            type: .webView(url: ""),
            opacity: 1.0,
            isVisible: true,
            zIndex: 1
        )
    ]
}