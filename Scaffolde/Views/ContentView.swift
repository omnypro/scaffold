import AppKit
import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var browserViewModel = BrowserViewModel()
    @StateObject private var windowViewModel = WindowViewModel()
    @StateObject private var consoleViewModel = ConsoleViewModel()
    @State private var selectedEngine: BrowserEngine = .webkit

    private let webViewPadding: CGFloat = 8

    var body: some View {
        ZStack {
            // Background image layer
            if let backgroundImage = windowViewModel.backgroundImage {
                Image(nsImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: windowViewModel.currentSize.width,
                        height: windowViewModel.currentSize.height
                    )
                    .clipped()
                    .cornerRadius(8)
            }

            // WebView layer
            selectedEngine.createView(
                urlString: $browserViewModel.loadedURL,
                consoleViewModel: consoleViewModel
            )
            .frame(
                width: windowViewModel.currentSize.width,
                height: windowViewModel.currentSize.height
            )
            .background(
                windowViewModel.backgroundImage == nil
                    ? Color.black : Color.clear
            )
            .cornerRadius(8)
        }
        .padding(
            EdgeInsets(
                top: 0,
                leading: webViewPadding,
                bottom: webViewPadding,
                trailing: webViewPadding
            )
        )
        .onAppear {
            windowViewModel.setupWindow()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("OpenFile")
            )
        ) { _ in
            browserViewModel.selectLocalFile()
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
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("SetBackgroundImage")
            )
        ) { _ in
            windowViewModel.selectBackgroundImage()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("ClearBackgroundImage")
            )
        ) { _ in
            windowViewModel.clearBackgroundImage()
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                TextField(
                    "Enter URL or file path",
                    text: $browserViewModel.urlString
                )
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 300)
                .onSubmit {
                    browserViewModel.loadContent()
                }

                Button(action: {
                    refreshWebView()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                Text(windowViewModel.sizeDisplayText)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)

                Menu {
                    ForEach(WindowSize.presets) { size in
                        Button(windowViewModel.menuItemText(for: size)) {
                            windowViewModel.setWindowSize(size)
                        }
                    }
                } label: {
                    Image(systemName: "aspectratio")
                }

                Menu {
                    Button("Set Background Image...") {
                        windowViewModel.selectBackgroundImage()
                    }

                    Button("Clear Background Image") {
                        windowViewModel.clearBackgroundImage()
                    }
                    .disabled(windowViewModel.backgroundImage == nil)
                } label: {
                    Image(
                        systemName: windowViewModel.backgroundImage != nil
                            ? "photo.fill" : "photo"
                    )
                }
            }
        }
        .alert(
            "Error",
            isPresented: .constant(browserViewModel.errorMessage != nil)
        ) {
            Button("OK") {
                browserViewModel.errorMessage = nil
            }
        } message: {
            Text(browserViewModel.errorMessage ?? "")
        }
    }

    private func refreshWebView() {
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
}

#Preview {
    ContentView()
}
