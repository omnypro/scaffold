import SwiftUI

protocol BrowserView: View {
    var urlString: Binding<String?> { get }
    var consoleLogs: Binding<[ConsoleLog]> { get }
}

enum BrowserEngine: String, CaseIterable {
    case webkit = "WebKit"
    case chromium = "Chromium"
    
    @ViewBuilder
    func createView(urlString: Binding<String?>, consoleLogs: Binding<[ConsoleLog]>) -> some View {
        switch self {
        case .webkit:
            WebViewRepresentable(urlString: urlString, consoleLogs: consoleLogs)
        case .chromium:
            // Future: ChromiumViewRepresentable(urlString: urlString, consoleLogs: consoleLogs)
            Text("Chromium support coming soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
    }
}