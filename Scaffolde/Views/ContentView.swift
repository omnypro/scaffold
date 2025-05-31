import AppKit
import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var browserViewModel = BrowserViewModel()
    @StateObject private var windowViewModel = WindowViewModel()
    @StateObject private var consoleViewModel = ConsoleViewModel()
    @State private var selectedEngine: BrowserEngine = .webkit
    @State private var showingErrorAlert = false

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
            refreshWebView()
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
                .accessibilityLabel("URL input field")
                .accessibilityHint("Enter a web URL or local file path and press Enter to load")

                Button(action: {
                    refreshWebView()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
                .accessibilityHint("Reload the current page")
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
                        .accessibilityLabel("Set window size to \(size.name)")
                    }
                } label: {
                    Image(systemName: "aspectratio")
                }
                .accessibilityLabel("Window size menu")
                .accessibilityHint("Choose a preset window size")

                Menu {
                    Button("Set Background Image...") {
                        windowViewModel.selectBackgroundImage()
                    }
                    .accessibilityLabel("Set background image")
                    .accessibilityHint("Choose an image to display behind the web content")

                    Button("Clear Background Image") {
                        windowViewModel.clearBackgroundImage()
                    }
                    .disabled(windowViewModel.backgroundImage == nil)
                    .accessibilityLabel("Clear background image")
                    .accessibilityHint("Remove the current background image")
                } label: {
                    Image(
                        systemName: windowViewModel.backgroundImage != nil
                            ? "photo.fill" : "photo"
                    )
                }
                .accessibilityLabel("Background image menu")
                .accessibilityHint(windowViewModel.backgroundImage != nil ? "Background image is set" : "No background image")
            }
        }
        .alert(
            "Error",
            isPresented: $showingErrorAlert
        ) {
            Button("OK") {
                browserViewModel.errorMessage = nil
            }
        } message: {
            Text(browserViewModel.errorMessage ?? "")
        }
        .onChange(of: browserViewModel.errorMessage) { _, newValue in
            showingErrorAlert = newValue != nil
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
           let contentView = window.contentView,
           let webView = findWebView(in: contentView)
        {
            webView.reload()
        }
    }
}

#Preview {
    ContentView()
}
