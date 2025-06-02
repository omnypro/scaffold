import SwiftUI

// Define a focused value key for background image state
struct BackgroundImageStateKey: FocusedValueKey {
    typealias Value = Bool
}

// Define a focused value key for selected browser engine
struct SelectedBrowserEngineKey: FocusedValueKey {
    typealias Value = BrowserEngine
}

// Define focused value keys for ViewModels
struct BrowserViewModelKey: FocusedValueKey {
    typealias Value = BrowserViewModel
}

struct WindowViewModelKey: FocusedValueKey {
    typealias Value = WindowViewModel
}

struct ConsoleWindowViewModelKey: FocusedValueKey {
    typealias Value = ConsoleWindowViewModel
}

struct AppStateKey: FocusedValueKey {
    typealias Value = AppState
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

    var browserViewModel: BrowserViewModel? {
        get { self[BrowserViewModelKey.self] }
        set { self[BrowserViewModelKey.self] = newValue }
    }

    var windowViewModel: WindowViewModel? {
        get { self[WindowViewModelKey.self] }
        set { self[WindowViewModelKey.self] = newValue }
    }

    var consoleWindowViewModel: ConsoleWindowViewModel? {
        get { self[ConsoleWindowViewModelKey.self] }
        set { self[ConsoleWindowViewModelKey.self] = newValue }
    }

    var appState: AppState? {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
