import AppKit
import Foundation
import UniformTypeIdentifiers

/// ViewModel responsible for managing browser state and URL handling
@MainActor
class BrowserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var urlString: String = ""
    @Published var loadedURL: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Public Methods

    /// Loads the content from the current URL string
    func loadContent() {
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "URL cannot be empty"
            return
        }

        errorMessage = nil
        isLoading = true

        // Validate and process the URL
        if isValidURL(urlString) {
            loadedURL = urlString
        } else if isValidLocalPath(urlString) {
            loadedURL = urlString
        } else {
            // Try adding http:// prefix
            let urlWithScheme = "http://\(urlString)"
            if isValidURL(urlWithScheme) {
                loadedURL = urlWithScheme
                urlString = urlWithScheme
            } else {
                errorMessage = "Invalid URL or file path"
            }
        }

        isLoading = false
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
                loadedURL = url.path
                errorMessage = nil
            }
        }
    }

    /// Refreshes the current loaded content
    func refresh() {
        guard loadedURL != nil else { return }

        // Trigger a reload by setting to nil and back
        let currentURL = loadedURL
        loadedURL = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.loadedURL = currentURL
        }
    }

    /// Performs a hard reload (bypass cache)
    func hardReload() {
        guard loadedURL != nil else { return }

        // Will be handled by WebView with reloadFromOrigin
        NotificationCenter.default.post(
            name: Notification.Name("HardReloadWebView"),
            object: nil
        )
    }

    /// Clears the current URL and loaded content
    func clearContent() {
        urlString = ""
        loadedURL = nil
        errorMessage = nil
        isLoading = false
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

        // Check if it's an HTML file
        let url = URL(fileURLWithPath: path)
        return url.pathExtension.lowercased() == "html"
            || url.pathExtension.lowercased() == "htm"
    }
}
