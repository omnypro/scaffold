import Foundation

struct WindowSize: Identifiable {
    let id = UUID()
    let name: String
    let width: CGFloat
    let height: CGFloat

    static let presets: [WindowSize] = [
        WindowSize(name: "720p", width: 1280, height: 720),
        WindowSize(name: "1080p", width: 1920, height: 1080),
        WindowSize(name: "1440p", width: 2560, height: 1440),
        WindowSize(name: "4K", width: 3840, height: 2160),
        WindowSize(name: "Square", width: 1080, height: 1080),
        WindowSize(name: "Vertical", width: 1080, height: 1920)
    ]
}
