import AppKit
import Foundation
import SwiftUI

/// ViewModel responsible for managing the console window
@MainActor
class ConsoleWindowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isVisible: Bool = false

    // MARK: - Private Properties
    private var consoleWindow: NSWindow?
    private var windowDelegate: WindowDelegate?
    private let consoleViewModel: ConsoleViewModel

    // MARK: - Initialization
    init(consoleViewModel: ConsoleViewModel) {
        self.consoleViewModel = consoleViewModel
    }

    // MARK: - Public Methods

    /// Shows the console window
    func show() {
        if consoleWindow == nil {
            createWindow()
        }

        consoleWindow?.makeKeyAndOrderFront(nil)
        isVisible = true
    }

    /// Hides the console window
    func hide() {
        consoleWindow?.orderOut(nil)
        isVisible = false
    }

    /// Toggles the console window visibility
    func toggle() {
        if consoleWindow?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    // MARK: - Private Methods

    private func createWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 400),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Console"
        window.setFrameAutosaveName("ScaffoldeConsoleWindow")
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 400, height: 200)

        // Position window next to main window if possible
        if let mainWindow = NSApp.windows.first {
            var newFrame = window.frame
            newFrame.origin.x = mainWindow.frame.maxX + 20
            newFrame.origin.y = mainWindow.frame.origin.y
            window.setFrame(newFrame, display: true)
        }

        // Set up content view
        let contentView = ConsoleView(viewModel: consoleViewModel)
        window.contentView = NSHostingView(rootView: contentView)

        // Set up window delegate to track visibility
        windowDelegate = WindowDelegate { [weak self] in
            self?.isVisible = false
        }
        window.delegate = windowDelegate

        consoleWindow = window
    }
}

// MARK: - Window Delegate

private class WindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
