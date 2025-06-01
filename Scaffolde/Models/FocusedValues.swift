import SwiftUI

// Define a focused value key for background image state
struct BackgroundImageStateKey: FocusedValueKey {
    typealias Value = Bool
}

// Define a focused value key for selected browser engine
struct SelectedBrowserEngineKey: FocusedValueKey {
    typealias Value = BrowserEngine
}

extension FocusedValues {
    var hasBackgroundImage: Bool? {
        get { self[BackgroundImageStateKey.self] }
        set { self[BackgroundImageStateKey.self] = newValue }
    }
    
    var selectedBrowserEngine: BrowserEngine? {
        get { self[SelectedBrowserEngineKey.self] }
        set { self[SelectedBrowserEngineKey.self] = newValue }
    }
}