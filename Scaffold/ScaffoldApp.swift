//
//  ScaffoldApp.swift
//  Scaffold
//
//  Created by Bryan Veloso on 5/30/25.
//

import AppKit
import SwiftUI

@main
struct ScaffoldApp: App {
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Scaffold") {
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

                Button("Clear Background Image") {
                    NotificationCenter.default.post(
                        name: Notification.Name("ClearBackgroundImage"),
                        object: nil
                    )
                }

                Divider()
            }
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        
        Window("About Scaffold", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
