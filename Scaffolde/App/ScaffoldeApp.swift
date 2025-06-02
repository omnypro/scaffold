import SwiftUI

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
    @FocusedValue(\.appState) private var appState: AppState?

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
            }
            CommandGroup(after: .newItem) {
                Button("Open File...") {
                    browserViewModel?.selectLocalFile()
                }
                .keyboardShortcut("O", modifiers: .command)
            }

            CommandGroup(replacing: .toolbar) {
                Button("Reload") {
                    browserViewModel?.refresh()
                }
                .keyboardShortcut("R", modifiers: .command)

                Button("Hard Reload") {
                    browserViewModel?.hardReload()
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])

                Divider()

                Menu("Browser Engine") {
                    Button("WebKit") {
                        appState?.setEngine(.webkit)
                    }

                    Button("Chromium (Coming Soon)") {
                        appState?.setEngine(.chromium)
                    }
                    .disabled(true)
                }

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

                Button("Toggle Console") {
                    consoleWindowViewModel?.toggle()
                }
                .keyboardShortcut("J", modifiers: [.command, .option])

                Divider()

                Button("Focus URL Bar") {
                    browserViewModel?.focusURLBar()
                }
                .keyboardShortcut("L", modifiers: .command)

                Button("Stop Loading") {
                    browserViewModel?.stopLoading()
                }
                .keyboardShortcut(.escape, modifiers: [])
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
