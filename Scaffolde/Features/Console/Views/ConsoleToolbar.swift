import SwiftUI

struct ConsoleToolbar: View {
    @ObservedObject var viewModel: ConsoleViewModel
    @State private var searchText = ""
    @State private var showingExporter = false

    private func generateExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let dateString = formatter.string(from: Date())
        return "console-logs-\(dateString).txt"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .frame(width: 200)

            Divider()
                .frame(height: 20)

            // Filter buttons
            ConsoleFilterButtons(viewModel: viewModel)

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    viewModel.clearLogs()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Clear all logs")

                Button {
                    showingExporter = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Export logs")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
        .fileExporter(
            isPresented: $showingExporter,
            document: ConsoleLogDocument(logs: viewModel.filteredLogs),
            contentType: .plainText,
            defaultFilename: generateExportFilename()
        ) { _ in
            // Handle export result if needed
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
    }
}

struct ConsoleFilterButtons: View {
    @ObservedObject var viewModel: ConsoleViewModel

    var body: some View {
        HStack(spacing: 12) {
            // All filter (with icon)
            Button {
                viewModel.setFilter(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 14))
                    if viewModel.filterLevel == nil && !viewModel.logs.isEmpty {
                        Text("\(viewModel.logs.count)")
                            .font(.caption)
                    }
                }
                .foregroundColor(
                    viewModel.filterLevel == nil ? .primary : .secondary
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .background(
                viewModel.filterLevel == nil
                    ? Color.accentColor.opacity(0.2) : Color.clear
            )
            .cornerRadius(6)
            .help("Show all logs")

            Divider()
                .frame(height: 16)

            ForEach(
                [ConsoleLog.LogLevel.error, .warn, .info, .log],
                id: \.self
            ) { level in
                FilterButton(
                    level: level,
                    isActive: viewModel.filterLevel == level,
                    count: viewModel.logs.filter { $0.level == level }.count
                ) {
                    viewModel.setFilter(
                        viewModel.filterLevel == level ? nil : level
                    )
                }
            }
        }
    }
}

struct FilterButton: View {
    let level: ConsoleLog.LogLevel
    let isActive: Bool
    let count: Int
    let action: () -> Void

    var levelColor: Color {
        switch level {
        case .error: return .red
        case .warn: return .orange
        case .info: return .blue
        case .log: return .secondary
        }
    }

    var levelIcon: String {
        switch level {
        case .error: return "xmark.circle.fill"
        case .warn: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .log: return "text.bubble.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: levelIcon)
                    .font(.system(size: 14))
                if count != 0 { // swiftlint:disable:this empty_count
                    Text("\(count)")
                        .font(.caption)
                }
            }
            .foregroundColor(isActive ? levelColor : levelColor.opacity(0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(isActive ? levelColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .help("\(level.rawValue.capitalized) (\(count))")
    }
}
