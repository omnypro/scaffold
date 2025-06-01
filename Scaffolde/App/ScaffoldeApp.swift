import AppKit
import SwiftUI

@main
struct ScaffoldeApp: App {
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.hasBackgroundImage) private var hasBackgroundImage: Bool?
    @FocusedValue(\.selectedBrowserEngine) private var selectedEngine:
        BrowserEngine?

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
                    NotificationCenter.default.post(
                        name: Notification.Name("OpenFile"),
                        object: nil
                    )
                }
                .keyboardShortcut("O", modifiers: .command)
            }

            CommandGroup(replacing: .toolbar) {
                Button("Reload") {
                    NotificationCenter.default.post(
                        name: Notification.Name("RefreshWebView"),
                        object: nil
                    )
                }
                .keyboardShortcut("R", modifiers: .command)

                Button("Hard Reload") {
                    NotificationCenter.default.post(
                        name: Notification.Name("HardReloadWebView"),
                        object: nil
                    )
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])

                Divider()

                Menu("Browser Engine") {
                    Button("WebKit") {
                        NotificationCenter.default.post(
                            name: Notification.Name("SetEngine"),
                            object: BrowserEngine.webkit
                        )
                    }

                    Button("Chromium (Coming Soon)") {
                        NotificationCenter.default.post(
                            name: Notification.Name("SetEngine"),
                            object: BrowserEngine.chromium
                        )
                    }
                    .disabled(true)
                }

                Divider()

                Button("Set Background Image...") {
                    NotificationCenter.default.post(
                        name: Notification.Name("SetBackgroundImage"),
                        object: nil
                    )
                }

                Button("Toggle Background Image") {
                    NotificationCenter.default.post(
                        name: Notification.Name("ToggleBackgroundImage"),
                        object: nil
                    )
                }
                .disabled(hasBackgroundImage != true)
                .keyboardShortcut("B", modifiers: .command)

                Button("Clear Background Image") {
                    NotificationCenter.default.post(
                        name: Notification.Name("ClearBackgroundImage"),
                        object: nil
                    )
                }
                .disabled(hasBackgroundImage != true)

                Divider()

                Button("Toggle Console") {
                    NotificationCenter.default.post(
                        name: Notification.Name("ToggleConsole"),
                        object: nil
                    )
                }
                .keyboardShortcut("J", modifiers: [.command, .option])
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
