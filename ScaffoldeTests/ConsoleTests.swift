import XCTest

@testable import Scaffolde

/// Tests for console functionality
@MainActor
class ConsoleTests: XCTestCase {

    func testConsoleWindowToggle() async {
        let consoleViewModel = ConsoleViewModel()
        let windowViewModel = ConsoleWindowViewModel(
            consoleViewModel: consoleViewModel
        )

        // Initial state
        XCTAssertFalse(windowViewModel.isVisible, "Console should start hidden")

        // First toggle - should show
        windowViewModel.toggle()
        XCTAssertTrue(
            windowViewModel.isVisible,
            "Console should be visible after first toggle"
        )

        // Second toggle - should hide
        windowViewModel.toggle()
        XCTAssertFalse(
            windowViewModel.isVisible,
            "Console should be hidden after second toggle"
        )

        // Test show/hide directly
        windowViewModel.show()
        XCTAssertTrue(
            windowViewModel.isVisible,
            "Console should be visible after show()"
        )

        windowViewModel.hide()
        XCTAssertFalse(
            windowViewModel.isVisible,
            "Console should be hidden after hide()"
        )
    }

    func testConsoleLogging() async {
        let consoleViewModel = ConsoleViewModel()

        // Add logs
        consoleViewModel.addLog("Test log", level: .log)
        consoleViewModel.addLog("Test error", level: .error)
        consoleViewModel.addLog("Test warning", level: .warn)

        XCTAssertEqual(consoleViewModel.logs.count, 3, "Should have 3 logs")
        XCTAssertEqual(
            consoleViewModel.filteredLogs.count,
            3,
            "All logs should be visible by default"
        )

        // Test search
        consoleViewModel.searchText = "error"
        XCTAssertEqual(
            consoleViewModel.filteredLogs.count,
            1,
            "Should only show error log when searching"
        )

        consoleViewModel.searchText = ""
        XCTAssertEqual(
            consoleViewModel.filteredLogs.count,
            3,
            "All logs should be visible when search is cleared"
        )
    }

    func testConsoleClear() async {
        let consoleViewModel = ConsoleViewModel()

        // Add some logs
        consoleViewModel.addLog("Test 1", level: .log)
        consoleViewModel.addLog("Test 2", level: .log)

        XCTAssertEqual(consoleViewModel.logs.count, 2)

        // Clear logs
        consoleViewModel.clearLogs()

        XCTAssertEqual(consoleViewModel.logs.count, 0, "Logs should be cleared")
        XCTAssertEqual(
            consoleViewModel.filteredLogs.count,
            0,
            "Filtered logs should be cleared"
        )
    }
}
