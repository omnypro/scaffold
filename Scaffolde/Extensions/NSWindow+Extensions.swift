import AppKit

extension NSWindow {
    func focusURLTextField() {
        // Find the TextField in the toolbar
        if let toolbar = self.toolbar {
            for item in toolbar.items {
                if let view = item.view {
                    findAndFocusTextField(in: view)
                }
            }
        }
    }

    private func findAndFocusTextField(in view: NSView) {
        if let textField = view as? NSTextField {
            self.makeFirstResponder(textField)
            textField.selectText(nil)
            return
        }

        for subview in view.subviews {
            findAndFocusTextField(in: subview)
        }
    }
}
