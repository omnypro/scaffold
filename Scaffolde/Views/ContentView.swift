import SwiftUI

struct ContentView: View {
    @StateObject private var browserViewModel: BrowserViewModel
    @StateObject private var windowViewModel = WindowViewModel()
    @StateObject private var consoleWindowViewModel: ConsoleWindowViewModel
    @StateObject private var appState = AppState()
    @StateObject private var layerSystemViewModel = LayerSystemViewModel()
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
        .overlay(alignment: .leading) {
            // Layer panel floating overlay
            if layerSystemViewModel.isPanelVisible {
                LayerPanelView(viewModel: layerSystemViewModel)
                    .padding(.leading, 12)
                    .padding(.vertical, 12)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: layerSystemViewModel.isPanelVisible)
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
                // Layer panel toggle
                Button(action: { layerSystemViewModel.togglePanel() }) {
                    Image(
                        systemName: layerSystemViewModel.isPanelVisible
                            ? "square.stack.fill" : "square.stack"
                    )
                }
                .help("Toggle layer panel")
                
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

            // Always show main browser as base layer
            appState.selectedEngine.createView(
                browserViewModel: browserViewModel
            )
            .background(
                windowViewModel.backgroundImage == nil
                    ? Color.black : Color.clear
            )
            .cornerRadius(8)
            
            // Render additional layers on top
            ForEach(layerSystemViewModel.layers.sorted(by: { $0.zIndex < $1.zIndex })) { layer in
                LayerView(layer: layer)
                    .frame(
                        width: windowViewModel.currentSize.width,
                        height: windowViewModel.currentSize.height
                    )
                    .cornerRadius(8)
                    .allowsHitTesting(layer.id == layerSystemViewModel.selectedLayer?.id)
            }

            // Loading progress bar (only show for main browser view)
            if layerSystemViewModel.layers.isEmpty && browserViewModel.isLoading {
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
            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "l":
                    isURLFieldFocused = true
                    return nil
                case "L" where event.modifierFlags.contains(.shift):
                    // Cmd+Shift+L toggles layer panel
                    layerSystemViewModel.togglePanel()
                    return nil
                default:
                    break
                }
            }
            return event
        }
    }
}
