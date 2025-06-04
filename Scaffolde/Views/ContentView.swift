import SwiftUI

struct ContentView: View {
    @StateObject private var browserViewModel: BrowserViewModel
    @StateObject private var windowViewModel = WindowViewModel()
    @StateObject private var consoleWindowViewModel: ConsoleWindowViewModel
    @StateObject private var appState = AppState()
    @FocusState private var isURLFieldFocused: Bool

    private let webViewPadding: CGFloat = 8

    init() {
        let historyManager = HistoryManager()
        let consoleViewModel = ConsoleViewModel()
        let browserVM = BrowserViewModel(
            historyManager: historyManager,
            consoleViewModel: consoleViewModel
        )

        _browserViewModel = StateObject(wrappedValue: browserVM)
        _consoleWindowViewModel = StateObject(
            wrappedValue: ConsoleWindowViewModel(
                consoleViewModel: consoleViewModel
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Web content
            webContent
                .frame(
                    width: windowViewModel.currentSize.width,
                    height: windowViewModel.currentSize.height
                )
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: webViewPadding,
                        bottom: webViewPadding,
                        trailing: webViewPadding
                    )
                )
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                // Back/Forward buttons
                Button(action: { browserViewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!browserViewModel.canGoBack)

                Button(action: { browserViewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!browserViewModel.canGoForward)

                // URL field
                TextField(
                    "Enter URL or search",
                    text: $browserViewModel.urlString
                )
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 300)
                .focused($isURLFieldFocused)
                .onSubmit {
                    browserViewModel.navigate()
                }

                // Reload button
                Button(action: {
                    if browserViewModel.isLoading {
                        browserViewModel.stopLoading()
                    } else {
                        browserViewModel.reload()
                    }
                }) {
                    Image(
                        systemName: browserViewModel.isLoading
                            ? "xmark" : "arrow.clockwise"
                    )
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                // Console toggle
                Button(action: { consoleWindowViewModel.toggle() }) {
                    Image(
                        systemName: consoleWindowViewModel.isVisible
                            ? "terminal.fill" : "terminal"
                    )
                }

                // Window size display
                Text(windowViewModel.sizeDisplayText)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)

                // Window size menu
                Menu {
                    ForEach(WindowSize.presets) { size in
                        Button(windowViewModel.menuItemText(for: size)) {
                            windowViewModel.setWindowSize(size)
                        }
                    }
                } label: {
                    Image(systemName: "aspectratio")
                }

                // Background image menu
                Menu {
                    Button("Set Background Image...") {
                        windowViewModel.selectBackgroundImage()
                    }

                    Button("Toggle Background Image") {
                        windowViewModel.toggleBackgroundImage()
                    }
                    .disabled(windowViewModel.backgroundImage == nil)
                    .keyboardShortcut("B", modifiers: .command)

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
        .onAppear {
            windowViewModel.setupWindow()
            setupKeyboardShortcuts()
        }
        .focusedSceneValue(
            \.hasBackgroundImage,
            windowViewModel.backgroundImage != nil
        )
        .focusedSceneValue(\.selectedBrowserEngine, appState.selectedEngine)
        .focusedSceneValue(\.browserViewModel, browserViewModel)
        .focusedSceneValue(\.windowViewModel, windowViewModel)
        .focusedSceneValue(\.consoleWindowViewModel, consoleWindowViewModel)
    }

    @ViewBuilder
    private var webContent: some View {
        ZStack {
            // Background image if set
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

            // WebView
            appState.selectedEngine.createView(
                browserViewModel: browserViewModel
            )
            .background(
                windowViewModel.backgroundImage == nil
                    ? Color.black : Color.clear
            )
            .cornerRadius(8)

            // Loading progress bar
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
                .frame(maxHeight: .infinity, alignment: .bottom)
                .animation(
                    .easeInOut(duration: 0.2),
                    value: browserViewModel.loadingProgress
                )
            }
        }
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command)
                && event.charactersIgnoringModifiers == "l"
            {
                isURLFieldFocused = true
                return nil
            }
            return event
        }
    }
}
