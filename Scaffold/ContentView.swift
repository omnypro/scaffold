//
//  ContentView.swift
//  Scaffold
//
//  Created by Bryan Veloso on 5/30/25.
//

import AppKit
import SwiftUI
import WebKit

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var loadedURL: String? = nil
    @State private var consoleLogs: [ConsoleLog] = []
    @StateObject private var windowSettings = WindowSettings()
    @State private var currentWindowSize = WindowSize(
        name: "1080p",
        width: 1920,
        height: 1080
    )
    @State private var selectedEngine: BrowserEngine = .webkit

    private let webViewPadding: CGFloat = 8

    var body: some View {
        selectedEngine.createView(
            urlString: $loadedURL,
            consoleLogs: $consoleLogs
        )
        .frame(width: currentWindowSize.width, height: currentWindowSize.height)
        .background(Color.black)
        .cornerRadius(8)
        .padding(
            EdgeInsets(
                top: 0,
                leading: webViewPadding,
                bottom: webViewPadding,
                trailing: webViewPadding
            )
        )
        .onAppear {
            if let window = NSApp.windows.first {
                window.titlebarAppearsTransparent = true
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("OpenFile")
            )
        ) { _ in
            selectLocalFile()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("RefreshWebView")
            )
        ) { _ in
            // Find WKWebView recursively
            func findWebView(in view: NSView) -> WKWebView? {
                if let webView = view as? WKWebView {
                    return webView
                }
                for subview in view.subviews {
                    if let found = findWebView(in: subview) {
                        return found
                    }
                }
                return nil
            }

            if let window = NSApp.windows.first,
                let webView = findWebView(in: window.contentView!)
            {
                webView.reload()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("SetEngine")
            )
        ) { notification in
            if let engine = notification.object as? BrowserEngine {
                selectedEngine = engine
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                TextField("Enter URL or file path", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 300)
                    .onSubmit {
                        loadContent()
                    }

                Button(action: {
                    NotificationCenter.default.post(
                        name: Notification.Name("RefreshWebView"),
                        object: nil
                    )
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                Text(
                    "\(Int(currentWindowSize.width), format: .number.grouping(.never))×\(Int(currentWindowSize.height), format: .number.grouping(.never))"
                )
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)

                Menu {
                    ForEach(WindowSize.presets) { size in
                        Button(
                            "\(size.name) (\(Int(size.width), format: .number.grouping(.never))×\(Int(size.height), format: .number.grouping(.never)))"
                        ) {
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
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
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
            // Add padding to account for border
            window.setContentSize(
                NSSize(
                    width: size.width + webViewPadding,
                    height: size.height + webViewPadding
                )
            )
            window.center()
        }
    }
}

#Preview {
    ContentView()
}
