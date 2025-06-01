import AppKit
import Foundation

/// ViewModel responsible for managing window sizing and display settings
@MainActor
class WindowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSize = WindowSize(
        name: "1080p",
        width: 1920,
        height: 1080
    )
    @Published var backgroundImage: NSImage? = nil
    private var previousBackgroundImage: NSImage? = nil

    // MARK: - Constants
    private let webViewPadding: CGFloat = 8

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
        }
    }
}
