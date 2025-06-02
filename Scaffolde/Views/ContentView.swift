import AppKit
import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var browserViewModel = BrowserViewModel()
    @StateObject private var windowViewModel = WindowViewModel()
    @StateObject private var consoleViewModel = ConsoleViewModel()
    @StateObject private var consoleWindowViewModel: ConsoleWindowViewModel
    @State private var selectedEngine: BrowserEngine = .webkit
    @FocusState private var isURLFieldFocused: Bool

    init() {
        let consoleVM = ConsoleViewModel()
        _consoleViewModel = StateObject(wrappedValue: consoleVM)
        _consoleWindowViewModel = StateObject(
            wrappedValue: ConsoleWindowViewModel(consoleViewModel: consoleVM)
        )
    }

    private let webViewPadding: CGFloat = 8

    var body: some View {
        ZStack {
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

            selectedEngine.createView(
                consoleViewModel: consoleViewModel,
                browserViewModel: browserViewModel
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
        .overlay(alignment: .bottom) {
            if browserViewModel.isLoading {
                GeometryReader { geometry in
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(
                            width: geometry.size.width
                                * browserViewModel.loadingProgress,
                            height: 4
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 4)
                .padding(.horizontal, webViewPadding)
                .animation(
                    .easeInOut(duration: 0.2),
                    value: browserViewModel.loadingProgress
                )
            }
        }
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
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("ToggleBackgroundImage")
            )
        ) { _ in
            windowViewModel.toggleBackgroundImage()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("HardReloadWebView")
            )
        ) { _ in
            hardReloadWebView()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("ToggleConsole")
            )
        ) { _ in
            consoleWindowViewModel.toggle()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("FocusURLBar")
            )
        ) { _ in
            isURLFieldFocused = true
            DispatchQueue.main.async {
                if let window = NSApp.keyWindow,
                   let fieldEditor = window.fieldEditor(false, for: nil) {
                    fieldEditor.selectAll(nil)
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("StopLoading")
            )
        ) { _ in
            if isURLFieldFocused {
                browserViewModel.urlString = ""
                isURLFieldFocused = false
            } else if browserViewModel.isLoading {
                stopLoading()
            }
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
                .focused($isURLFieldFocused)
                .accessibilityLabel("URL input field")
                .accessibilityHint(
                    "Enter a web URL or local file path and press Enter to load"
                )

                Button(action: {
                    refreshWebView()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
                .accessibilityHint("Reload the current page")
            }

            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    consoleWindowViewModel.toggle()
                }) {
                    Image(
                        systemName: consoleWindowViewModel.isVisible
                            ? "terminal.fill" : "terminal"
                    )
                }
                .accessibilityLabel("Toggle console")
                .accessibilityHint("Show or hide the console window")

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
                    .accessibilityHint(
                        "Choose an image to display behind the web content"
                    )

                    Button("Toggle Background Image") {
                        windowViewModel.toggleBackgroundImage()
                    }
                    .disabled(windowViewModel.backgroundImage == nil)
                    .keyboardShortcut("B", modifiers: .command)
                    .accessibilityLabel("Toggle background image")
                    .accessibilityHint(
                        "Toggle the visibility of the background image"
                    )

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
                .accessibilityHint(
                    windowViewModel.backgroundImage != nil
                        ? "Background image is set" : "No background image"
                )
            }
        }
        .focusedSceneValue(
            \.hasBackgroundImage,
            windowViewModel.backgroundImage != nil
        )
        .focusedSceneValue(\.selectedBrowserEngine, selectedEngine)
    }

    private func refreshWebView() {
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

    private func hardReloadWebView() {
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
            webView.reloadFromOrigin()
        }
    }
    
    private func stopLoading() {
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
           let webView = findWebView(in: contentView) {
            webView.stopLoading()
            browserViewModel.isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
