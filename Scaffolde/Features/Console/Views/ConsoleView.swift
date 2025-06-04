import SwiftUI

struct ConsoleView: View {
    @ObservedObject var viewModel: ConsoleViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ConsoleToolbar(viewModel: viewModel)
            
            Divider()
            
            if viewModel.filteredLogs.isEmpty {
                EmptyConsoleView()
            } else {
                ConsoleLogList(viewModel: viewModel)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct EmptyConsoleView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No console logs")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Console messages will appear here when pages log to the console")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}