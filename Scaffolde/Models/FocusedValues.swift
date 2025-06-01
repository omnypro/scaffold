import SwiftUI

// Define a focused value key for background image state
struct BackgroundImageStateKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var hasBackgroundImage: Bool? {
        get { self[BackgroundImageStateKey.self] }
        set { self[BackgroundImageStateKey.self] = newValue }
    }
}