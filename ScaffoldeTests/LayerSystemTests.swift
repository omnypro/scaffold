import XCTest
@testable import Scaffolde

@MainActor
final class LayerSystemTests: XCTestCase {
    
    func testAddWebViewLayer() {
        let viewModel = LayerSystemViewModel()
        
        // Initial state
        XCTAssertEqual(viewModel.layers.count, 0)
        XCTAssertTrue(viewModel.canAddWebViewLayer)
        
        // Add a WebView layer
        viewModel.addLayer(type: .webView(url: "https://example.com"))
        
        XCTAssertEqual(viewModel.layers.count, 1)
        XCTAssertEqual(viewModel.webViewLayerCount, 1)
        XCTAssertNotNil(viewModel.selectedLayer)
        
        if case .webView(let url) = viewModel.layers.first?.type {
            XCTAssertEqual(url, "https://example.com")
        } else {
            XCTFail("Expected WebView layer")
        }
    }
    
    func testWebViewLayerLimit() {
        let viewModel = LayerSystemViewModel()
        
        // Add maximum WebView layers
        viewModel.addLayer(type: .webView(url: "https://example1.com"))
        viewModel.addLayer(type: .webView(url: "https://example2.com"))
        viewModel.addLayer(type: .webView(url: "https://example3.com"))
        
        XCTAssertEqual(viewModel.webViewLayerCount, 3)
        XCTAssertFalse(viewModel.canAddWebViewLayer)
        
        // Try to add another - should fail
        viewModel.addLayer(type: .webView(url: "https://example4.com"))
        XCTAssertEqual(viewModel.webViewLayerCount, 3) // Still 3
    }
    
    func testAddImageLayer() {
        let viewModel = LayerSystemViewModel()
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        
        viewModel.addLayer(type: .image(testImage))
        
        XCTAssertEqual(viewModel.layers.count, 1)
        if case .image = viewModel.layers.first?.type {
            // Success
        } else {
            XCTFail("Expected image layer")
        }
    }
    
    func testLayerVisibilityToggle() {
        let viewModel = LayerSystemViewModel()
        viewModel.addLayer(type: .color(.red))
        
        guard let layer = viewModel.layers.first else {
            XCTFail("No layer found")
            return
        }
        
        XCTAssertTrue(layer.isVisible)
        
        viewModel.toggleLayerVisibility(layer)
        XCTAssertFalse(layer.isVisible)
        
        viewModel.toggleLayerVisibility(layer)
        XCTAssertTrue(layer.isVisible)
    }
    
    func testLayerOpacity() {
        let viewModel = LayerSystemViewModel()
        viewModel.addLayer(type: .color(.blue))
        
        guard let layer = viewModel.layers.first else {
            XCTFail("No layer found")
            return
        }
        
        XCTAssertEqual(layer.opacity, 1.0)
        
        layer.opacity = 0.5
        XCTAssertEqual(layer.opacity, 0.5)
    }
    
    func testRemoveLayer() {
        let viewModel = LayerSystemViewModel()
        viewModel.addLayer(type: .color(.green))
        viewModel.addLayer(type: .color(.blue))
        
        XCTAssertEqual(viewModel.layers.count, 2)
        
        if let firstLayer = viewModel.layers.first {
            viewModel.removeLayer(firstLayer)
            XCTAssertEqual(viewModel.layers.count, 1)
        }
    }
    
    func testDuplicateLayer() {
        let viewModel = LayerSystemViewModel()
        viewModel.addLayer(type: .color(.purple))
        
        guard let originalLayer = viewModel.layers.first else {
            XCTFail("No layer found")
            return
        }
        
        originalLayer.opacity = 0.7
        
        viewModel.duplicateLayer(originalLayer)
        
        XCTAssertEqual(viewModel.layers.count, 2)
        XCTAssertEqual(viewModel.layers[1].opacity, 0.7)
        XCTAssertTrue(viewModel.layers[1].name.contains("Copy"))
    }
}