import Foundation
import SwiftUI

/// Shared app state for cross-view communication
@MainActor
class AppState: ObservableObject {
    @Published var selectedEngine: BrowserEngine = .webkit
    @Published var engineChangeCommand = UUID()

    func setEngine(_ engine: BrowserEngine) {
        selectedEngine = engine
        engineChangeCommand = UUID()
    }
}
