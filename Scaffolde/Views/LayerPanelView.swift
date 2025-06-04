import SwiftUI

struct LayerPanelView: View {
    @ObservedObject var viewModel: LayerSystemViewModel
    @State private var showingAddMenu = false
    @State private var newWebViewURL = ""
    
    private let panelWidth: CGFloat = 280
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Layer list
            layerList
            
            // Properties section
            if let selectedLayer = viewModel.selectedLayer {
                propertiesSection(for: selectedLayer)
            }
            
            // Add layer button
            addLayerSection
        }
        .frame(width: panelWidth)
        .frame(maxHeight: .infinity)
        .background(backgroundMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 5, y: 0)
    }
    
    private var header: some View {
        HStack {
            Text("Layers")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { viewModel.togglePanel() }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Hide layer panel")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
    
    private var layerList: some View {
        Group {
            if viewModel.layers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No layers")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Add a layer to get started")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                List {
                    ForEach(viewModel.layers.reversed()) { layer in
                        LayerRow(
                            layer: layer,
                            isSelected: viewModel.selectedLayer?.id == layer.id,
                            onSelect: { viewModel.selectedLayer = layer },
                            onVisibilityToggle: { viewModel.toggleLayerVisibility(layer) },
                            onLockToggle: { viewModel.toggleLayerLock(layer) },
                            onDelete: { viewModel.removeLayer(layer) },
                            onDuplicate: { viewModel.duplicateLayer(layer) }
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                    }
                    .onMove { source, destination in
                        // Reverse the indices since we're showing reversed
                        let reversedSource = IndexSet(source.map { viewModel.layers.count - 1 - $0 })
                        let reversedDestination = viewModel.layers.count - destination
                        viewModel.moveLayer(from: reversedSource, to: reversedDestination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var addLayerSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Add menu
                Menu {
                    Button(action: { showingAddMenu = true }) {
                        Label("Web Page", systemImage: "globe")
                    }
                    .disabled(!viewModel.canAddWebViewLayer)
                    
                    Button(action: addImageLayer) {
                        Label("Image", systemImage: "photo")
                    }
                    
                    Button(action: addColorLayer) {
                        Label("Color Fill", systemImage: "rectangle.fill")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Layer")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
                
                // Layer count
                if !viewModel.layers.isEmpty {
                    Text("\(viewModel.layers.count) layer\(viewModel.layers.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
        }
        .sheet(isPresented: $showingAddMenu) {
            AddWebViewSheet(
                urlString: $newWebViewURL,
                onAdd: { url in
                    viewModel.addLayer(type: .webView(url: url))
                    newWebViewURL = ""
                }
            )
        }
    }
    
    private var backgroundMaterial: some View {
        VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
            .overlay(Color.black.opacity(0.4))
    }
    
    private func propertiesSection(for layer: Layer) -> some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Properties")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                // Opacity slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Opacity")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("\(Int(layer.opacity * 100))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Slider(value: Binding(
                        get: { layer.opacity },
                        set: { layer.opacity = $0 }
                    ), in: 0...1)
                        .controlSize(.small)
                }
                
                // Layer type specific properties
                switch layer.type {
                case .webView(let url):
                    VStack(alignment: .leading, spacing: 4) {
                        Text("URL")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        WebViewURLField(layer: layer, initialURL: url)
                    }
                    
                case .image:
                    Text("Image Layer")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    
                case .color(let color):
                    HStack {
                        Text("Color")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.2))
        }
    }
    
    private func addImageLayer() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                viewModel.addLayer(type: .image(image))
            }
        }
    }
    
    private func addColorLayer() {
        viewModel.addLayer(type: .color(.black))
    }
}

// MARK: - Layer Row

struct LayerRow: View {
    let layer: Layer
    let isSelected: Bool
    let onSelect: () -> Void
    let onVisibilityToggle: () -> Void
    let onLockToggle: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    
    @State private var isHovering = false
    @State private var showingContextMenu = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Layer type icon
            layerIcon
                .frame(width: 16, height: 16)
                .foregroundColor(.white.opacity(0.8))
            
            // Layer name
            Text(layer.name)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            // Layer controls
            if isHovering || isSelected {
                HStack(spacing: 4) {
                    // Visibility toggle
                    Button(action: onVisibilityToggle) {
                        Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    
                    // Lock toggle
                    Button(action: onLockToggle) {
                        Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Opacity
            Text("\(Int(layer.opacity * 100))%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
        )
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button("Duplicate", action: onDuplicate)
            Button("Delete", action: onDelete)
        }
        .opacity(layer.isVisible ? 1.0 : 0.5)
    }
    
    private var layerIcon: some View {
        Group {
            switch layer.type {
            case .webView:
                Image(systemName: "globe")
            case .image:
                Image(systemName: "photo")
            case .color:
                Image(systemName: "rectangle.fill")
            }
        }
    }
}

// MARK: - Add WebView Sheet

struct AddWebViewSheet: View {
    @Binding var urlString: String
    let onAdd: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Web Layer")
                .font(.headline)
            
            TextField("Enter URL", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    if !urlString.isEmpty {
                        onAdd(urlString)
                        dismiss()
                    }
                }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Add") {
                    if !urlString.isEmpty {
                        onAdd(urlString)
                        dismiss()
                    }
                }
                .keyboardShortcut(.return)
                .disabled(urlString.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - WebView URL Field

struct WebViewURLField: View {
    @ObservedObject var layer: Layer
    let initialURL: String
    @State private var editedURL: String = ""
    @State private var isEditing = false
    
    init(layer: Layer, initialURL: String) {
        self.layer = layer
        self.initialURL = initialURL
        self._editedURL = State(initialValue: initialURL)
    }
    
    var body: some View {
        TextField("URL", text: $editedURL)
            .textFieldStyle(.plain)
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(4)
            .onSubmit {
                updateLayerURL()
            }
            .onChange(of: isEditing) { editing in
                if !editing {
                    updateLayerURL()
                }
            }
    }
    
    private func updateLayerURL() {
        if !editedURL.isEmpty && editedURL != initialURL {
            // Update the layer's URL
            if let webView = layer.webView {
                if let url = parseURL(from: editedURL) {
                    webView.load(URLRequest(url: url))
                    // Update the layer type with new URL
                    layer.type = .webView(url: editedURL)
                }
            }
        }
    }
    
    private func parseURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Already a valid URL
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        
        // Check for localhost or IP addresses
        if trimmed.hasPrefix("localhost") || trimmed.range(of: #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"#, options: .regularExpression) != nil {
            return URL(string: "http://\(trimmed)")
        }
        
        // Try adding https://
        if let url = URL(string: "https://\(trimmed)"), url.host != nil {
            return url
        }
        
        return nil
    }
}

// MARK: - Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}