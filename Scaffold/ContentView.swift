//
//  ContentView.swift
//  Scaffold
//
//  Created by Bryan Veloso on 5/30/25.
//

import SwiftUI
import WebKit
import AppKit

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var loadedURL: String = ""
    @State private var consoleLogs: [ConsoleLog] = []
    @StateObject private var windowSettings = WindowSettings()
    @State private var currentWindowSize = WindowSize(name: "1080p", width: 1920, height: 1080)
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                TextField("Enter URL or file path", text: $urlString, onCommit: {
                    loadContent()
                })
                .textFieldStyle(.roundedBorder)
                
                Button("Load") {
                    loadContent()
                }
                
                Button("Browse...") {
                    selectLocalFile()
                }
                
                Spacer()
                
                // Window Size Menu
                Menu("Window Size") {
                    ForEach(WindowSize.presets) { size in
                        Button("\(size.name) (\(Int(size.width))×\(Int(size.height)))") {
                            currentWindowSize = size
                            setWindowSize(size)
                        }
                    }
                }
                
                // Settings Menu
                Menu("Settings") {
                    Toggle("Stay on Top", isOn: $windowSettings.stayOnTop)
                    Toggle("Frameless", isOn: $windowSettings.isFrameless)
                }
            }
            .padding()
            
            Divider()
            
            // Main content area
            WebViewRepresentable(urlString: $loadedURL, consoleLogs: $consoleLogs)
                .frame(width: currentWindowSize.width, height: currentWindowSize.height)
        }
    }
    
    private func loadContent() {
        loadedURL = urlString
    }
    
    private func selectLocalFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.html, .data]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                urlString = url.path
                loadedURL = url.path
            }
        }
    }
    
    private func setWindowSize(_ size: WindowSize) {
        // The WebView is now explicitly sized, so we just resize the window to fit
        if let window = NSApp.windows.first {
            window.setContentSize(NSSize(width: size.width, height: size.height + 60)) // +60 for toolbar
            window.center()
        }
    }
}


#Preview {
    ContentView()
}
