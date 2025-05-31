import AppKit
import Foundation

struct WindowSize: Identifiable {
    let id = UUID()
    let name: String
    let width: CGFloat
    let height: CGFloat

    static let presets: [WindowSize] = [
        WindowSize(name: "720p", width: 1280, height: 720),
        WindowSize(name: "1080p", width: 1920, height: 1080),
        WindowSize(name: "4K", width: 3840, height: 2160),
        WindowSize(name: "Square", width: 1080, height: 1080),
        WindowSize(name: "Vertical", width: 1080, height: 1920),
    ]
}

class WindowSettings: ObservableObject {
    @Published var stayOnTop: Bool = false {
        didSet {
            updateWindowLevel()
        }
    }

    private func updateWindowLevel() {
        if let window = NSApp.windows.first {
            window.level = stayOnTop ? .floating : .normal
        }
    }

    private func updateWindowStyle() {
        if let window = NSApp.windows.first {
            window.styleMask.insert(.titled)
            window.styleMask.insert(.closable)
            window.styleMask.insert(.miniaturizable)
            window.styleMask.insert(.resizable)
        }
    }
}
