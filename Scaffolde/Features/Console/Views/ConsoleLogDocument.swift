import SwiftUI
import UniformTypeIdentifiers

struct ConsoleLogDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    let logs: [ConsoleLog]
    
    init(logs: [ConsoleLog]) {
        self.logs = logs
    }
    
    init(configuration: ReadConfiguration) throws {
        // We don't support reading console logs back
        self.logs = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        let content = logs.map { log in
            let timestamp = dateFormatter.string(from: log.timestamp)
            let level = log.level.rawValue.uppercased()
            return "[\(timestamp)] [\(level)] \(log.message)"
        }.joined(separator: "\n")
        
        let data = content.data(using: String.Encoding.utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}