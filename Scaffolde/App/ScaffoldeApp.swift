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
            }

            // History menu - separate top-level menu like Safari
            CommandMenu("History") {
                // TODO: Implement history window
                /*
                Button("Show All History") {
                    // This will open a dedicated history window in a future update
                }
                .keyboardShortcut("Y", modifiers: .command)
                .disabled(true)
                
                Divider()
                */

                // Back/Forward items with current page titles
                if let viewModel = browserViewModel {
                    Button("Back") {
                        viewModel.goBack()
                    }
                    .keyboardShortcut("[", modifiers: .command)
                    .disabled(!viewModel.canGoBack)

                    Button("Forward") {
                        viewModel.goForward()
                    }
                    .keyboardShortcut("]", modifiers: .command)
                    .disabled(!viewModel.canGoForward)

                    Divider()
                }

                // Recent history items
                if let historyManager = browserViewModel?.historyManager {
                    let recentItems = historyManager.items
                        .sorted { $0.lastVisit > $1.lastVisit }
                        .prefix(15)

                    if !recentItems.isEmpty {
                        ForEach(Array(recentItems)) { item in
                            Button(
                                action: {
                                    browserViewModel?.urlString =
                                        item.url.absoluteString
                                    browserViewModel?.navigate()
                                },
                                label: {
                                    HStack(spacing: 6) {
                                        // Favicon
                                        if let faviconData = item.faviconData,
                                            let nsImage = NSImage(
                                                data: faviconData
                                            ) {
                                            Image(nsImage: nsImage)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .cornerRadius(2)
                                        } else {
                                            // Default globe icon if no favicon
                                            Image(systemName: "globe")
                                                .font(.system(size: 12))
                                                .frame(width: 16, height: 16)
                                                .foregroundColor(.secondary)
                                        }

                                        // Page title
                                        Text(
                                            item.title.isEmpty
                                                ? item.url.host
                                                    ?? item.url.absoluteString
                                                : item.title
                                        )
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    }
                                }
                            )
                            .help(item.url.absoluteString)
                        }

                        Divider()
                    }
                }

                Divider()

                Button("Clear History...") {
                    if let historyManager = browserViewModel?.historyManager {
                        NSAlert.showClearHistoryAlert { shouldClear in
                            if shouldClear {
                                historyManager.clearHistory()
                            }
                        }
                    }
                }
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
