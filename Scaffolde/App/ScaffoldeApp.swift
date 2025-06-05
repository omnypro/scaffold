import Sparkle
import SwiftUI
import UniformTypeIdentifiers

@main
struct ScaffoldeApp: App {
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.hasBackgroundImage) private var hasBackgroundImage: Bool?
    @FocusedValue(\.selectedBrowserEngine) private var selectedEngine:
        BrowserEngine?
    @FocusedValue(\.browserViewModel) private var browserViewModel:
        BrowserViewModel?
    @FocusedValue(\.windowViewModel) private var windowViewModel:
        WindowViewModel?
    @FocusedValue(\.consoleWindowViewModel) private var consoleWindowViewModel:
        ConsoleWindowViewModel?

    // Sparkle updater
    @StateObject private var updaterViewModel = SparkleUpdaterViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Scaffolde") {
                    openWindow(id: "about")
                }

                CheckForUpdatesView(updaterViewModel: updaterViewModel)
            }

            CommandGroup(after: .newItem) {
                Button("Open File...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [.html, .data]
                    panel.title = "Select HTML File"
                    panel.message = "Choose an HTML file to load in the browser"

                    if panel.runModal() == .OK {
                        if let url = panel.url {
                            browserViewModel?.urlString = url.path
                            browserViewModel?.navigate()
                        }
                    }
                }
                .keyboardShortcut("O", modifiers: .command)
            }

            CommandGroup(replacing: .toolbar) {
                Button("Stop") {
                    browserViewModel?.stopLoading()
                }
                .keyboardShortcut(".", modifiers: [.command])

                Button("Reload") {
                    browserViewModel?.reload()
                }
                .keyboardShortcut("R", modifiers: .command)

                Button("Hard Reload") {
                    browserViewModel?.hardReload()
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])

                Divider()

                Button("Set Background Image...") {
                    windowViewModel?.selectBackgroundImage()
                }

                Button("Toggle Background Image") {
                    windowViewModel?.toggleBackgroundImage()
                }
                .disabled(hasBackgroundImage != true)
                .keyboardShortcut("B", modifiers: .command)

                Button("Clear Background Image") {
                    windowViewModel?.clearBackgroundImage()
                }
                .disabled(hasBackgroundImage != true)

                Divider()

                Button("Actual Size") {
                    windowViewModel?.setZoomLevel(1.0)
                }
                .disabled(windowViewModel?.zoomLevel == 1.0)
                .keyboardShortcut("0", modifiers: .command)

                Button("Zoom In") {
                    if let viewModel = windowViewModel {
                        viewModel.setZoomLevel(viewModel.zoomLevel + 0.05)
                    }
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    if let viewModel = windowViewModel {
                        viewModel.setZoomLevel(viewModel.zoomLevel - 0.05)
                    }
                }
                .keyboardShortcut("-", modifiers: .command)

                Divider()

                Button("Toggle Console") {
                    consoleWindowViewModel?.toggle()
                }
                .keyboardShortcut("J", modifiers: [.command, .option])

                Divider()

                Menu("History") {
                    Button("Clear History...") {
                        // Show confirmation dialog
                        if let historyManager = browserViewModel?.historyManager
                        {
                            NSAlert.showClearHistoryAlert { shouldClear in
                                if shouldClear {
                                    historyManager.clearHistory()
                                }
                            }
                        }
                    }

                    Button("Clear History from Today") {
                        browserViewModel?.historyManager.clearHistoryOlderThan(
                            days: 0
                        )
                    }

                    Button("Clear History Older Than 7 Days") {
                        browserViewModel?.historyManager.clearHistoryOlderThan(
                            days: 7
                        )
                    }

                    Button("Clear History Older Than 30 Days") {
                        browserViewModel?.historyManager.clearHistoryOlderThan(
                            days: 30
                        )
                    }
                }

                Divider()
            }
        }
        .windowToolbarStyle(.unified(showsTitle: false))

        Window("About Scaffolde", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .restorationBehavior(.disabled)
    }
}
