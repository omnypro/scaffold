//
//  ScaffoldApp.swift
//  Scaffold
//
//  Created by Bryan Veloso on 5/30/25.
//

import SwiftUI
import AppKit

@main
struct ScaffoldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open File...") {
                    NotificationCenter.default.post(name: Notification.Name("OpenFile"), object: nil)
                }
                .keyboardShortcut("O", modifiers: .command)
            }
            
            CommandGroup(replacing: .toolbar) {
                Button("Reload") {
                    NotificationCenter.default.post(name: Notification.Name("RefreshWebView"), object: nil)
                }
                .keyboardShortcut("R", modifiers: .command)
                
                Divider()
                
                Menu("Browser Engine") {
                    Button("WebKit") {
                        NotificationCenter.default.post(name: Notification.Name("SetEngine"), object: BrowserEngine.webkit)
                    }
                    Button("Chromium (Coming Soon)") {
                        NotificationCenter.default.post(name: Notification.Name("SetEngine"), object: BrowserEngine.chromium)
                    }
                    .disabled(true)
                }
            }
        }
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
