import XCTest
@testable import Scaffolde

/// Tests for console functionality
class ConsoleTests: XCTestCase {
    
    func testConsoleWindowToggle() {
        let consoleViewModel = ConsoleViewModel()
        let windowViewModel = ConsoleWindowViewModel(consoleViewModel: consoleViewModel)
        
        // Initial state
        XCTAssertFalse(windowViewModel.isVisible, "Console should start hidden")
        
        // First toggle - should show
        windowViewModel.toggle()
        XCTAssertTrue(windowViewModel.isVisible, "Console should be visible after first toggle")
        
        // Second toggle - should hide
        windowViewModel.toggle()
        XCTAssertFalse(windowViewModel.isVisible, "Console should be hidden after second toggle")
        
        // Test show/hide directly
        windowViewModel.show()
        XCTAssertTrue(windowViewModel.isVisible, "Console should be visible after show()")
        
        windowViewModel.hide()
        XCTAssertFalse(windowViewModel.isVisible, "Console should be hidden after hide()")
    }
    
    func testConsoleLogging() {
        let consoleViewModel = ConsoleViewModel()
        
        // Add logs
        consoleViewModel.addLog(message: "Test log", level: .log, source: "Test")
        consoleViewModel.addLog(message: "Test error", level: .error, source: "Test")
        consoleViewModel.addLog(message: "Test warning", level: .warning, source: "Test")
        
        XCTAssertEqual(consoleViewModel.logs.count, 3, "Should have 3 logs")
        XCTAssertEqual(consoleViewModel.filteredLogs.count, 3, "All logs should be visible by default")
        
        // Test filtering
        consoleViewModel.toggleFilter(.error)
        XCTAssertEqual(consoleViewModel.filteredLogs.count, 2, "Error logs should be hidden")
        
        consoleViewModel.toggleFilter(.error)
        XCTAssertEqual(consoleViewModel.filteredLogs.count, 3, "Error logs should be visible again")
    }
    
    func testConsoleClear() {
        let consoleViewModel = ConsoleViewModel()
        
        // Add some logs
        consoleViewModel.addLog(message: "Test 1", level: .log, source: "Test")
        consoleViewModel.addLog(message: "Test 2", level: .log, source: "Test")
        
        XCTAssertEqual(consoleViewModel.logs.count, 2)
        
        // Clear logs
        consoleViewModel.clearLogs()
        
        XCTAssertEqual(consoleViewModel.logs.count, 0, "Logs should be cleared")
        XCTAssertEqual(consoleViewModel.filteredLogs.count, 0, "Filtered logs should be cleared")
    }
}