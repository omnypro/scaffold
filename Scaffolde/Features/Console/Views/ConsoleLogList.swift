import SwiftUI

struct ConsoleLogList: View {
    @ObservedObject var viewModel: ConsoleViewModel
    @State private var selectedLogID: UUID?
    
    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedLogID) {
                ForEach(viewModel.filteredLogs) { log in
                    ConsoleLogRow(log: log)
                        .id(log.id)
                        .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                        .listRowBackground(
                            selectedLogID == log.id
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear
                        )
                }
            }
            .listStyle(.plain)
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: viewModel.filteredLogs.count) { oldValue, newValue in
                // Auto-scroll to bottom when new logs arrive
                if let lastLog = viewModel.filteredLogs.last {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct ConsoleLogRow: View {
    let log: ConsoleLog
    @State private var isExpanded = false
    
    private var shouldShowExpander: Bool {
        log.message.count > 150 || log.message.contains("\n")
    }
    
    private var displayMessage: String {
        if !isExpanded && shouldShowExpander {
            let truncated = String(log.message.prefix(150))
            return truncated + "..."
        }
        return log.message
    }
    
    private var levelColor: Color {
        switch log.level {
        case .error: return .red
        case .warn: return .orange
        case .info: return .blue
        case .log: return .secondary
        }
    }
    
    private var levelIcon: String {
        switch log.level {
        case .error: return "xmark.circle.fill"
        case .warn: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .log: return "text.bubble"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                // Log level indicator
                Image(systemName: levelIcon)
                    .foregroundColor(levelColor)
                    .font(.system(size: 14))
                    .frame(width: 16)
                
                // Timestamp
                Text(log.timestamp, style: .time)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .leading)
                
                // Message
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayMessage)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if shouldShowExpander {
                        Button(action: { isExpanded.toggle() }) {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(log.message, forType: .string)
            }
            
            Button("Copy All Details") {
                let details = formatLogDetails(log)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(details, forType: .string)
            }
        }
    }
    
    private func formatLogDetails(_ log: ConsoleLog) -> String {
        let timestamp = ISO8601DateFormatter().string(from: log.timestamp)
        let level = log.level.rawValue.uppercased()
        return "[\(timestamp)] [\(level)]\n\(log.message)"
    }
}