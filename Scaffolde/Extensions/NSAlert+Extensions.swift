import AppKit

extension NSAlert {
    /// Shows a confirmation dialog for clearing browser history
    static func showClearHistoryAlert(completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Clear Browsing History?"
        alert.informativeText =
            "This will permanently delete all browsing history. This action cannot be undone."
        alert.alertStyle = .warning

        alert.addButton(withTitle: "Clear History")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
}
