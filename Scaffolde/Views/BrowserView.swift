import SwiftUI

protocol BrowserView: View {
    var urlString: Binding<String?> { get }
    var consoleViewModel: ConsoleViewModel { get }
}

enum BrowserEngine: String, CaseIterable {
    case webkit = "WebKit"
    case chromium = "Chromium"

    @ViewBuilder
    func createView(
        urlString: Binding<String?>,
        consoleViewModel: ConsoleViewModel,
        browserViewModel: BrowserViewModel
    ) -> some View {
        switch self {
        case .webkit:
            WebViewRepresentable(
                urlString: urlString,
                consoleViewModel: consoleViewModel,
                browserViewModel: browserViewModel
            )
        case .chromium:
            // Future: ChromiumViewRepresentable(urlString: urlString, consoleViewModel: consoleViewModel)
            Text("Chromium support coming soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
    }
}
