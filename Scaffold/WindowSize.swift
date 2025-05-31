import Foundation
import AppKit

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
        WindowSize(name: "Vertical", width: 1080, height: 1920)
    ]
}

class WindowSettings: ObservableObject {
    @Published var stayOnTop: Bool = false {
        didSet {
            updateWindowLevel()
        }
    }
    
    @Published var isFrameless: Bool = false {
        didSet {
            updateWindowStyle()
        }
    }
    
    private func updateWindowLevel() {
        if let window = NSApp.windows.first {
            window.level = stayOnTop ? .floating : .normal
        }
    }
    
    private func updateWindowStyle() {
        if let window = NSApp.windows.first {
            if isFrameless {
                window.styleMask.remove(.titled)
                window.styleMask.remove(.closable)
                window.styleMask.remove(.miniaturizable)
                window.styleMask.remove(.resizable)
            } else {
                window.styleMask.insert(.titled)
                window.styleMask.insert(.closable)
                window.styleMask.insert(.miniaturizable)
                window.styleMask.insert(.resizable)
            }
        }
    }
}