import SwiftUI

protocol BrowserView: View {
    var urlString: Binding<String?> { get }
    var consoleViewModel: ConsoleViewModel { get }
}

enum BrowserEngine: String, CaseIterable {
    case webkit = "WebKit"
    case chromium = "Chromium"

    @ViewBuilder
    func createView(browserViewModel: BrowserViewModel) -> some View {
        switch self {
        case .webkit:
            WebViewRepresentable(webView: browserViewModel.webView)
        case .chromium:
            Text("Chromium support coming soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
    }
}
