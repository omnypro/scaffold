import AppKit
import Foundation

/// ViewModel responsible for managing window sizing and display settings
@MainActor
class WindowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSize: WindowSize {
        didSet {
            saveWindowSize()
        }
    }
    @Published var backgroundImage: NSImage? = nil
    private var previousBackgroundImage: NSImage? = nil

    // MARK: - Constants
    private let webViewPadding: CGFloat = 8
    private let windowSizeNameKey = "SavedWindowSizeName"
    private let windowSizeWidthKey = "SavedWindowSizeWidth"
    private let windowSizeHeightKey = "SavedWindowSizeHeight"
    
    // MARK: - Initialization
    init() {
        // Load saved window size or use default
        self.currentSize = Self.loadSavedWindowSize()
    }

    // MARK: - Computed Properties
    var sizeDisplayText: String {
        "\(Int(currentSize.width))×\(Int(currentSize.height))"
    }

    func menuItemText(for size: WindowSize) -> String {
        "\(size.name) (\(Int(size.width))×\(Int(size.height)))"
    }

    // MARK: - Public Methods

    /// Sets the window size and updates the actual window
    func setWindowSize(_ size: WindowSize) {
        currentSize = size

        // Update the actual window size
        if let window = NSApp.windows.first {
            window.setContentSize(
                NSSize(
                    width: size.width + webViewPadding,
                    height: size.height + webViewPadding
                )
            )
            window.center()
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

    /// Configures the window appearance on initialization
    func setupWindow() {
        if let window = NSApp.windows.first {
            window.titlebarAppearsTransparent = true
            
            // Apply saved window size
            window.setContentSize(
                NSSize(
                    width: currentSize.width + webViewPadding,
                    height: currentSize.height + webViewPadding
                )
            )
            window.center()
        }
    }
    
    // MARK: - Private Methods
    
    /// Saves the current window size to UserDefaults
    private func saveWindowSize() {
        UserDefaults.standard.set(currentSize.name, forKey: windowSizeNameKey)
        UserDefaults.standard.set(currentSize.width, forKey: windowSizeWidthKey)
        UserDefaults.standard.set(currentSize.height, forKey: windowSizeHeightKey)
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
                    $0.name == savedName && 
                    $0.width == CGFloat(savedWidth) && 
                    $0.height == CGFloat(savedHeight) 
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
}
