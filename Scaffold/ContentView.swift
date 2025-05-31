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
    @State private var loadedURL: String? = nil
    @State private var consoleLogs: [ConsoleLog] = []
    @StateObject private var windowSettings = WindowSettings()
    @State private var currentWindowSize = WindowSize(name: "1080p", width: 1920, height: 1080)
    
    private let webViewPadding: CGFloat = 8
    
    var body: some View {
        WebViewRepresentable(urlString: $loadedURL, consoleLogs: $consoleLogs)
            .frame(width: currentWindowSize.width, height: currentWindowSize.height)
            .background(Color.black)
            .cornerRadius(8)
            .padding(webViewPadding)
            .background(Color(NSColor.windowBackgroundColor))
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenFile"))) { _ in
                selectLocalFile()
            }
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    TextField("Enter URL or file path", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 300)
                        .onSubmit {
                            loadContent()
                        }
                }
                
                ToolbarItemGroup(placement: .automatic) {
                    Text("\(Int(currentWindowSize.width), format: .number.grouping(.never))×\(Int(currentWindowSize.height), format: .number.grouping(.never))")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(WindowSize.presets) { size in
                            Button("\(size.name) (\(Int(size.width), format: .number.grouping(.never))×\(Int(size.height), format: .number.grouping(.never)))") {
                                currentWindowSize = size
                                setWindowSize(size)
                            }
                        }
                    } label: {
                        Image(systemName: "aspectratio")
                    }
                }
            }
    }
    
    private func loadContent() {
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
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
            // Add padding to both dimensions to account for border
            window.setContentSize(NSSize(width: size.width + (webViewPadding * 2), 
                                         height: size.height + (webViewPadding * 2)))
            window.center()
        }
    }
}


#Preview {
    ContentView()
}
