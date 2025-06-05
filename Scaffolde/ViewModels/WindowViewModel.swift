import AppKit
import Foundation

/// ViewModel responsible for managing window sizing and display settings
@MainActor
class WindowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSize: WindowSize {
        didSet {
            saveWindowSize()
            // Defer window update to avoid SwiftUI update cycle conflicts
            DispatchQueue.main.async { [weak self] in
                self?.updateWindowSizeForZoom()
            }
        }
    }
    @Published var backgroundImage: NSImage? = nil
    private var previousBackgroundImage: NSImage? = nil
    @Published var zoomLevel: Double = 1.0 {
        didSet {
            saveZoomLevel()
            // Defer window update to avoid SwiftUI update cycle conflicts
            DispatchQueue.main.async { [weak self] in
                self?.updateWindowSizeForZoom()
            }
        }
    }

    // MARK: - Constants
    private let webViewPadding: CGFloat = 8
    private let windowPositionXKey = "SavedWindowPositionX"
    private let windowPositionYKey = "SavedWindowPositionY"
    private let windowSizeNameKey = "SavedWindowSizeName"
    private let windowSizeWidthKey = "SavedWindowSizeWidth"
    private let windowSizeHeightKey = "SavedWindowSizeHeight"
    private let zoomLevelKey = "SavedZoomLevel"

    // MARK: - Initialization
    init() {
        // Load saved window size or use default
        self.currentSize = Self.loadSavedWindowSize()
        // Load saved zoom level
        self.zoomLevel = UserDefaults.standard.double(forKey: zoomLevelKey)
        if zoomLevel == 0 {
            zoomLevel = 1.0
        }
    }

    // MARK: - Computed Properties
    var sizeDisplayText: String {
        if zoomLevel != 1.0 {
            return "\(Int(currentSize.width))×\(Int(currentSize.height)) @ \(Int(zoomLevel * 100))%"
        } else {
            return "\(Int(currentSize.width))×\(Int(currentSize.height))"
        }
    }
    
    var effectiveSize: CGSize {
        CGSize(
            width: currentSize.width * CGFloat(zoomLevel),
            height: currentSize.height * CGFloat(zoomLevel)
        )
    }

    func menuItemText(for size: WindowSize) -> String {
        "\(size.name) (\(Int(size.width))×\(Int(size.height)))"
    }

    // MARK: - Public Methods

    /// Sets the window size and updates the actual window
    func setWindowSize(_ size: WindowSize) {
        currentSize = size
        
        // Automatically adjust zoom if the new size would exceed screen bounds
        DispatchQueue.main.async { [weak self] in
            self?.autoZoomIfNeeded()
        }
    }

    /// Opens a file picker for selecting a background image
    func selectBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP]
        panel.title = "Select Background Image"
        panel.message =
            "Select an image to serve as the backdrop for the browser window."

        if panel.runModal() == .OK {
            if let url = panel.url,
                let image = NSImage(contentsOf: url)
            {
                backgroundImage = image
            }
        }
    }

    /// Clears the current background image
    func clearBackgroundImage() {
        previousBackgroundImage = backgroundImage
        backgroundImage = nil
    }

    /// Toggles the background image on/off
    func toggleBackgroundImage() {
        if backgroundImage != nil {
            previousBackgroundImage = backgroundImage
            backgroundImage = nil
        } else if let previous = previousBackgroundImage {
            backgroundImage = previous
        }
    }
    
    /// Sets the zoom level with intelligent bounds checking
    func setZoomLevel(_ level: Double) {
        // Calculate maximum zoom that fits on screen
        let maxZoom = calculateMaxZoomForScreen()
        
        // Ensure zoom never exceeds 100% or screen bounds
        let cappedLevel = min(level, min(1.0, maxZoom))
        
        // Round to nearest 5% increment
        let roundedLevel = roundToNearest5Percent(cappedLevel)
        
        zoomLevel = max(0.25, roundedLevel)
    }
    
    /// Zoom to fit the current window
    func zoomToFit() {
        let optimalZoom = calculateOptimalZoomForScreen()
        setZoomLevel(optimalZoom)
    }
    
    /// Automatically sets zoom when window size changes to ensure it fits on screen
    func autoZoomIfNeeded() {
        let maxZoom = calculateMaxZoomForScreen()
        if zoomLevel > maxZoom {
            setZoomLevel(maxZoom)
        }
    }
    
    /// Get current screen info
    func getCurrentScreenInfo() -> (size: NSSize, scale: CGFloat) {
        guard let screen = NSApp.windows.first?.screen ?? NSScreen.main else {
            return (NSSize(width: 1920, height: 1080), 1.0)
        }
        
        return (screen.visibleFrame.size, screen.backingScaleFactor)
    }
    
    /// Calculate the maximum zoom level that fits on the current screen
    private func calculateMaxZoomForScreen() -> Double {
        let screenInfo = getCurrentScreenInfo()
        let screenSize = screenInfo.size
        
        // Account for window chrome and safe margins
        let safeMargin: CGFloat = 100
        let maxWidth = screenSize.width - safeMargin
        let maxHeight = screenSize.height - safeMargin - 50 // Extra for title bar
        
        // Actual padding: 0 top, webViewPadding on other sides
        let widthRatio = maxWidth / (currentSize.width + webViewPadding * 2)
        let heightRatio = maxHeight / (currentSize.height + webViewPadding)  // Only bottom padding
        
        return Double(min(widthRatio, heightRatio))
    }
    
    /// Calculate optimal zoom to fit content comfortably on screen
    private func calculateOptimalZoomForScreen() -> Double {
        let maxZoom = calculateMaxZoomForScreen()
        
        // Use 90% of max zoom for comfortable viewing
        let optimalZoom = maxZoom * 0.9
        
        // Never exceed 100%
        let cappedZoom = min(optimalZoom, 1.0)
        
        // Round to nearest 5% for clean display
        return roundToNearest5Percent(cappedZoom)
    }
    
    /// Round zoom level to nearest 5% increment
    private func roundToNearest5Percent(_ value: Double) -> Double {
        // Convert to percentage, round to nearest 5, convert back
        let percentage = value * 100
        let rounded = round(percentage / 5) * 5
        return rounded / 100
    }

    /// Configures the window appearance on initialization
    func setupWindow() {
        if let window = NSApp.windows.first {
            window.titlebarAppearsTransparent = true

            // Apply saved window size with zoom
            updateWindowSizeForZoom()

            // Restore saved position or center the window
            restoreWindowPosition(window)

            // Set up position tracking
            setupPositionTracking(window)
        }
    }

    // MARK: - Private Methods

    /// Saves the current window size to UserDefaults
    private func saveWindowSize() {
        UserDefaults.standard.set(currentSize.name, forKey: windowSizeNameKey)
        UserDefaults.standard.set(currentSize.width, forKey: windowSizeWidthKey)
        UserDefaults.standard.set(
            currentSize.height,
            forKey: windowSizeHeightKey
        )
    }

    /// Loads the saved window size from UserDefaults
    private static func loadSavedWindowSize() -> WindowSize {
        let defaults = UserDefaults.standard

        // Check if we have saved values
        if let savedName = defaults.string(forKey: "SavedWindowSizeName") {
            let savedWidth = defaults.double(forKey: "SavedWindowSizeWidth")
            let savedHeight = defaults.double(forKey: "SavedWindowSizeHeight")

            // If width and height are valid, use them
            if savedWidth > 0 && savedHeight > 0 {
                // First check if it matches a preset
                if let preset = WindowSize.presets.first(where: {
                    $0.name == savedName && $0.width == CGFloat(savedWidth)
                        && $0.height == CGFloat(savedHeight)
                }) {
                    return preset
                }

                // Otherwise create a custom size
                return WindowSize(
                    name: savedName,
                    width: CGFloat(savedWidth),
                    height: CGFloat(savedHeight)
                )
            }
        }

        // Default to 1080p
        return WindowSize(name: "1080p", width: 1920, height: 1080)
    }

    /// Sets up window position tracking
    private func setupPositionTracking(_ window: NSWindow) {
        // Create a notification observer for window movement
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.saveWindowPosition(window)
            }
        }
    }

    /// Saves the current window position to UserDefaults
    private func saveWindowPosition(_ window: NSWindow) {
        let frame = window.frame
        UserDefaults.standard.set(
            Double(frame.origin.x),
            forKey: windowPositionXKey
        )
        UserDefaults.standard.set(
            Double(frame.origin.y),
            forKey: windowPositionYKey
        )
    }

    /// Restores the window position from UserDefaults
    private func restoreWindowPosition(_ window: NSWindow) {
        let defaults = UserDefaults.standard
        let savedX = defaults.double(forKey: windowPositionXKey)
        let savedY = defaults.double(forKey: windowPositionYKey)

        // Check if we have saved position values
        if savedX != 0 || savedY != 0 {
            let savedOrigin = NSPoint(x: savedX, y: savedY)
            let newFrame = NSRect(origin: savedOrigin, size: window.frame.size)

            // Verify the position is visible on current screen configuration
            if isFrameVisible(newFrame) {
                window.setFrameOrigin(savedOrigin)
            } else {
                // If not visible, center the window
                window.center()
            }
        } else {
            // No saved position, center the window
            window.center()
        }
    }

    /// Checks if a frame is visible on any screen
    private func isFrameVisible(_ frame: NSRect) -> Bool {
        for screen in NSScreen.screens {
            // Check if at least 100x100 pixels of the window is visible on this screen
            let visibleArea = screen.visibleFrame.intersection(frame)
            if visibleArea.width >= 100 && visibleArea.height >= 100 {
                return true
            }
        }
        return false
    }
    
    /// Saves the current zoom level to UserDefaults
    private func saveZoomLevel() {
        UserDefaults.standard.set(zoomLevel, forKey: zoomLevelKey)
    }
    
    /// Updates the window size based on the current zoom level
    private func updateWindowSizeForZoom() {
        guard let window = NSApp.windows.first else { return }
        
        let scaledWidth = currentSize.width * CGFloat(zoomLevel)
        let scaledHeight = currentSize.height * CGFloat(zoomLevel)
        
        // Actual padding: 0 top, webViewPadding on other sides
        window.setContentSize(
            NSSize(
                width: scaledWidth + webViewPadding * 2,  // Left and right padding
                height: scaledHeight + webViewPadding      // Only bottom padding
            )
        )
    }
}
