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
    @Published var navigationError: Error? = nil

    @Published var navigationRequest: URLRequest? = nil
    @Published var navigationID = UUID()

    // WebView Commands
    @Published var reloadCommand = UUID()
    @Published var hardReloadCommand = UUID()
    @Published var stopLoadingCommand = UUID()

    // UI Commands
    @Published var focusURLBarCommand = UUID()

    // MARK: - Public Methods

    /// Loads the content from the current URL string
    func loadContent() {
        let trimmedString = urlString.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedString.isEmpty else {
            return
        }

        navigationError = nil

        if let url = parseURL(from: trimmedString) {
            navigate(to: url)
        } else {
            let error = NSError(
                domain: "Scaffolde",
                code: NSURLErrorBadURL,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid URL or file path"
                ]
            )
            navigationFailed(with: error)
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
            }
        }
    }

    /// Refreshes the current loaded content
    func refresh() {
        guard currentURL != nil else { return }
        reloadCommand = UUID()
    }

    /// Performs a hard reload (bypass cache)
    func hardReload() {
        guard currentURL != nil else { return }
        hardReloadCommand = UUID()
    }

    /// Stops loading the current page
    func stopLoading() {
        stopLoadingCommand = UUID()
        isLoading = false
        loadingProgress = 0.0
    }

    /// Focuses the URL bar
    func focusURLBar() {
        focusURLBarCommand = UUID()
    }

    /// Clears the current URL and loaded content
    func clearContent() {
        urlString = ""
        currentURL = nil
        navigationRequest = nil
        navigationError = nil
        isLoading = false
    }

    /// Called when WebView successfully loads a URL
    func didNavigate(to url: URL) {
        currentURL = url
        urlString = url.absoluteString
        navigationError = nil
    }

    /// Called when navigation fails
    func navigationFailed(with error: Error) {
        isLoading = false
        loadingProgress = 0.0
        navigationError = error
    }

    /// Convert NSError codes to user-friendly messages
    func errorDescription(for error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorCannotFindHost:
            return "Server not found. Check the URL and try again."
        case NSURLErrorCannotConnectToHost:
            return "Can't connect to the server."
        case NSURLErrorNotConnectedToInternet:
            return "No internet connection."
        case NSURLErrorTimedOut:
            return "The connection timed out."
        case NSURLErrorNetworkConnectionLost:
            return "Network connection was lost."
        case NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateUntrusted,
            NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid:
            return "This website's security certificate has a problem."
        case NSURLErrorUnsupportedURL:
            return "The URL format is not supported."
        case NSURLErrorFileDoesNotExist:
            return "The file could not be found."
        case NSURLErrorNoPermissionsToReadFile:
            return "Permission denied to read this file."
        default:
            return nsError.localizedDescription
        }
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
