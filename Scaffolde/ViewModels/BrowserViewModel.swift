import AppKit
import Foundation
import UniformTypeIdentifiers

/// ViewModel responsible for managing browser state and URL handling
@MainActor
class BrowserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var urlString: String = ""
    @Published var currentURL: URL? = nil
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var errorMessage: String? = nil
    
    @Published var navigationRequest: URLRequest? = nil
    @Published var navigationID = UUID()

    // MARK: - Public Methods

    /// Loads the content from the current URL string
    func loadContent() {
        let trimmedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else {
            errorMessage = "URL cannot be empty"
            return
        }

        errorMessage = nil
        
        if let url = parseURL(from: trimmedString) {
            navigate(to: url)
        } else {
            errorMessage = "Invalid URL or file path"
        }
    }
    
    /// Navigate to a specific URL
    func navigate(to url: URL) {
        navigationRequest = URLRequest(url: url)
        navigationID = UUID()
    }
    
    /// Parse URL from string, handling various formats
    private func parseURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }
        
        if trimmed.hasPrefix("file://") {
            return URL(string: trimmed)
        }
        
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        
        if let url = URL(string: "http://\(trimmed)"), url.host != nil {
            return url
        }
        
        return nil
    }

    /// Opens a file picker and loads the selected HTML file
    func selectLocalFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.html, .data]
        panel.title = "Select HTML File"
        panel.message = "Choose an HTML file to load in the browser"

        if panel.runModal() == .OK {
            if let url = panel.url {
                urlString = url.path
                navigate(to: url)
                errorMessage = nil
            }
        }
    }

    /// Refreshes the current loaded content
    func refresh() {
        guard let url = currentURL else { return }
        navigate(to: url)
    }

    /// Performs a hard reload (bypass cache)
    func hardReload() {
        guard currentURL != nil else { return }

        NotificationCenter.default.post(
            name: Notification.Name("HardReloadWebView"),
            object: nil
        )
    }

    /// Clears the current URL and loaded content
    func clearContent() {
        urlString = ""
        currentURL = nil
        navigationRequest = nil
        errorMessage = nil
        isLoading = false
    }
    
    /// Called when WebView successfully loads a URL
    func didNavigate(to url: URL) {
        currentURL = url
        urlString = url.absoluteString
    }

    // MARK: - Private Methods

    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string),
            let scheme = url.scheme
        else { return false }

        return ["http", "https", "file"].contains(scheme.lowercased())
    }

    private func isValidLocalPath(_ path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
            !isDirectory.boolValue
        else { return false }

        let url = URL(fileURLWithPath: path)
        return url.pathExtension.lowercased() == "html"
            || url.pathExtension.lowercased() == "htm"
    }
}
