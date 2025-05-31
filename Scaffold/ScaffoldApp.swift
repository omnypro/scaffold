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
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
