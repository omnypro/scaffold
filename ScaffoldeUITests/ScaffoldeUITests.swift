import XCTest

final class ScaffoldeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    @MainActor
    func testURLNavigation() throws {
        // Find URL field in toolbar
        let urlField = app.textFields.firstMatch
        XCTAssertTrue(urlField.exists, "URL field should exist")

        // Clear and type URL
        urlField.click()
        urlField.typeText("example.com")
        urlField.typeText("\n")  // Press Enter

        // Wait for navigation
        Thread.sleep(forTimeInterval: 2)

        // Verify URL was updated with protocol
        XCTAssertTrue(
            urlField.value as? String ?? "" == "http://example.com"
                || urlField.value as? String ?? "" == "https://example.com",
            "URL should have protocol added"
        )
    }

    @MainActor
    func testBackForwardButtons() throws {
        let backButton = app.buttons["chevron.left"]
        let forwardButton = app.buttons["chevron.right"]

        // Initially, back/forward should be disabled
        XCTAssertFalse(
            backButton.isEnabled,
            "Back button should be disabled initially"
        )
        XCTAssertFalse(
            forwardButton.isEnabled,
            "Forward button should be disabled initially"
        )

        // Navigate to enable back button
        let urlField = app.textFields.firstMatch
        urlField.click()
        urlField.typeText("example.com\n")
        Thread.sleep(forTimeInterval: 2)

        // Navigate again
        urlField.click()
        urlField.clearAndType("apple.com\n")
        Thread.sleep(forTimeInterval: 2)

        // Now back should be enabled
        XCTAssertTrue(
            backButton.isEnabled,
            "Back button should be enabled after navigation"
        )
    }

    // MARK: - Console Tests

    @MainActor
    func testConsoleToggle() throws {
        // Find console toggle button
        let consoleButton = app.buttons["terminal"]
        XCTAssertTrue(
            consoleButton.exists || app.buttons["terminal.fill"].exists,
            "Console button should exist"
        )

        // Click to open console
        if consoleButton.exists {
            consoleButton.click()
        } else {
            app.buttons["terminal.fill"].click()
        }

        // Verify console window appears
        Thread.sleep(forTimeInterval: 1)

        // Should now show filled terminal icon
        XCTAssertTrue(
            app.buttons["terminal.fill"].exists,
            "Console button should show filled icon when open"
        )
    }

    // MARK: - Window Size Tests

    @MainActor
    func testWindowSizeMenu() throws {
        // Find window size menu
        let sizeMenu = app.buttons["aspectratio"]
        XCTAssertTrue(sizeMenu.exists, "Window size menu should exist")

        // Click to open menu
        sizeMenu.click()

        // Check for preset options
        XCTAssertTrue(
            app.menuItems["1080p (1920×1080)"].exists,
            "1080p preset should exist"
        )
        XCTAssertTrue(
            app.menuItems["720p (1280×720)"].exists,
            "720p preset should exist"
        )

        // Select a size
        app.menuItems["720p (1280×720)"].click()

        // Verify size label updated
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(
            app.staticTexts["1280×720"].exists,
            "Window size should update"
        )
    }

    // MARK: - Zoom Tests

    @MainActor
    func testZoomControls() throws {
        // Find zoom menu
        let zoomMenu = app.buttons["plus.magnifyingglass"]
        XCTAssertTrue(zoomMenu.exists, "Zoom menu should exist")

        // Test keyboard shortcuts
        app.typeKey("+", modifierFlags: .command)  // Zoom in
        Thread.sleep(forTimeInterval: 0.5)

        app.typeKey("-", modifierFlags: .command)  // Zoom out
        Thread.sleep(forTimeInterval: 0.5)

        app.typeKey("0", modifierFlags: .command)  // Reset zoom
        Thread.sleep(forTimeInterval: 0.5)

        // Open zoom menu
        zoomMenu.click()

        // Check menu items
        XCTAssertTrue(
            app.menuItems["Zoom In"].exists,
            "Zoom In menu item should exist"
        )
        XCTAssertTrue(
            app.menuItems["Zoom Out"].exists,
            "Zoom Out menu item should exist"
        )
        XCTAssertTrue(
            app.menuItems["Actual Size (100%)"].exists,
            "Reset zoom menu item should exist"
        )
    }

    // MARK: - Keyboard Shortcuts

    @MainActor
    func testKeyboardShortcuts() throws {
        // Test Cmd+L (focus URL bar)
        app.typeKey("l", modifierFlags: .command)

        let urlField = app.textFields.firstMatch
        XCTAssertTrue(
            urlField.hasFocus,
            "URL field should be focused after Cmd+L"
        )

        // Test Cmd+R (reload)
        app.typeKey("r", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.5)

        // Test Cmd+Option+J (console toggle)
        app.typeKey("j", modifierFlags: [.command, .option])
        Thread.sleep(forTimeInterval: 1)
    }

    // MARK: - Menu Tests

    @MainActor
    func testApplicationMenu() throws {
        // Open Scaffolde menu
        app.menuBars.buttons["Scaffolde"].click()

        // Check for essential menu items
        XCTAssertTrue(
            app.menuItems["About Scaffolde"].exists,
            "About menu item should exist"
        )
        XCTAssertTrue(
            app.menuItems["Check for Updates..."].exists,
            "Check for Updates should exist"
        )
        XCTAssertTrue(
            app.menuItems["Quit Scaffolde"].exists,
            "Quit menu item should exist"
        )
    }

    // MARK: - Launch Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearAndType(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and type text into a non string value")
            return
        }

        self.click()

        let deleteString = String(
            repeating: XCUIKeyboardKey.delete.rawValue,
            count: stringValue.count
        )
        self.typeText(deleteString)
        self.typeText(text)
    }

    var hasFocus: Bool {
        return (value(forKey: "hasKeyboardFocus") as? Bool) ?? false
    }
}
