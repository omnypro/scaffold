import SwiftUI

struct ConsoleView: View {
    @ObservedObject var consoleViewModel: ConsoleViewModel
    @State private var searchText = ""
    @State private var selectedLogID: UUID?

    private var filteredLogs: [ConsoleLog] {
        let logs = consoleViewModel.filteredLogs
        if searchText.isEmpty {
            return logs
        }
        return logs.filter { log in
            log.message.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Console")
                    .font(.headline)

                Spacer()

                // Log counts
                if consoleViewModel.logCounts.total > 0 {
                    HStack(spacing: 12) {
                        if consoleViewModel.logCounts.errors > 0 {
                            Label(
                                "\(consoleViewModel.logCounts.errors)",
                                systemImage: "xmark.circle.fill"
                            )
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                        if consoleViewModel.logCounts.warnings > 0 {
                            Label(
                                "\(consoleViewModel.logCounts.warnings)",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundColor(.orange)
                            .font(.caption)
                        }
                        Text("\(consoleViewModel.logCounts.total) logs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Clear button
                Button(action: {
                    consoleViewModel.clearLogs()
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .disabled(consoleViewModel.logs.isEmpty)
                .help("Clear console")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Filter and search bar
            HStack {
                // Filter buttons
                FilterButton(
                    title: "All",
                    isSelected: consoleViewModel.filterLevel == nil,
                    action: { consoleViewModel.setFilter(nil) }
                )

                FilterButton(
                    title: "Errors",
                    isSelected: consoleViewModel.filterLevel == .error,
                    systemImage: "xmark.circle",
                    color: .red,
                    action: { consoleViewModel.setFilter(.error) }
                )

                FilterButton(
                    title: "Warnings",
                    isSelected: consoleViewModel.filterLevel == .warn,
                    systemImage: "exclamationmark.triangle",
                    color: .orange,
                    action: { consoleViewModel.setFilter(.warn) }
                )

                FilterButton(
                    title: "Info",
                    isSelected: consoleViewModel.filterLevel == .info,
                    systemImage: "info.circle",
                    color: .blue,
                    action: { consoleViewModel.setFilter(.info) }
                )

                Spacer()

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .frame(width: 200)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Console output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredLogs) { log in
                            ConsoleLogRow(
                                log: log,
                                isSelected: selectedLogID == log.id,
                                onSelect: {
                                    selectedLogID = log.id
                                }
                            )
                            .id(log.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: consoleViewModel.logs.count) { _, _ in
                    // Auto-scroll to bottom when new logs arrive
                    if let lastLog = consoleViewModel.logs.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Status bar
            HStack {
                Button(action: {
                    exportLogs()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .disabled(consoleViewModel.logs.isEmpty)
                .help("Export logs")

                Spacer()

                if let selectedLog = consoleViewModel.logs.first(where: {
                    $0.id == selectedLogID
                }) {
                    Text(formatTimestamp(selectedLog.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minHeight: 200)
    }

    private func exportLogs() {
        let content = consoleViewModel.exportLogs()

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue =
            "console-logs-\(Date().timeIntervalSince1970).txt"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to save logs: \(error)")
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    var systemImage: String? = nil
    var color: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .foregroundColor(isSelected ? color : .secondary)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.clear
            )
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ConsoleLogRow: View {
    let log: ConsoleLog
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(formatTimestamp(log.timestamp))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            // Level indicator
            Image(systemName: log.level.symbolName)
                .foregroundColor(levelColor)
                .font(.caption)
                .frame(width: 16)

            // Message
            Text(log.message)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(log.message, forType: .string)
            }

            Button("Copy with Timestamp") {
                let fullMessage =
                    "[\(formatTimestamp(log.timestamp))] [\(log.level.rawValue.uppercased())] \(log.message)"
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(fullMessage, forType: .string)
            }
        }
    }

    private var levelColor: Color {
        switch log.level {
        case .error:
            return .red
        case .warn:
            return .orange
        case .info:
            return .blue
        case .log:
            return .secondary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.2)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

#Preview {
    ConsoleView(consoleViewModel: ConsoleViewModel())
        .frame(width: 600, height: 400)
}
