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
        }
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
