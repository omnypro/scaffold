import Foundation

/// Represents a console log entry
struct ConsoleLog: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let level: LogLevel

    enum LogLevel: String {
        case log = "log"
        case info = "info"
        case warn = "warning"
        case error = "error"

        var symbolName: String {
            switch self {
            case .log, .info:
                return "info.circle"
            case .warn:
                return "exclamationmark.triangle"
            case .error:
                return "xmark.circle"
            }
        }
    }
}

/// ViewModel responsible for managing console logs from the WebView
@MainActor
class ConsoleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var logs: [ConsoleLog] = []
    @Published var filterLevel: ConsoleLog.LogLevel? = nil
    @Published var searchText: String = ""

    // MARK: - Computed Properties
    var filteredLogs: [ConsoleLog] {
        var filtered = logs
        
        // Filter by level if set
        if let filterLevel = filterLevel {
            filtered = filtered.filter { $0.level == filterLevel }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { log in
                log.message.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }

    var logCounts: (total: Int, errors: Int, warnings: Int) {
        let errors = logs.filter { $0.level == .error }.count
        let warnings = logs.filter { $0.level == .warn }.count
        return (logs.count, errors, warnings)
    }

    // MARK: - Public Methods

    /// Adds a new console log entry
    func addLog(_ message: String, level: ConsoleLog.LogLevel = .log) {
        let log = ConsoleLog(
            timestamp: Date(),
            message: message,
            level: level
        )
        logs.append(log)

        // Keep only the last 1000 logs to prevent memory issues
        if logs.count > 1000 {
            logs.removeFirst(logs.count - 1000)
        }
    }

    /// Clears all console logs
    func clearLogs() {
        logs.removeAll()
    }

    /// Sets the filter level for displaying logs
    func setFilter(_ level: ConsoleLog.LogLevel?) {
        filterLevel = level
    }

    /// Exports logs to a file
    func exportLogs() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        return logs.map { log in
            "[\(dateFormatter.string(from: log.timestamp))] [\(log.level.rawValue.uppercased())] \(log.message)"
        }.joined(separator: "\n")
    }
}
