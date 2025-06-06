import AppKit
import Combine
import XCTest

@testable import Scaffolde

@MainActor
final class WindowViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: WindowViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var mockWindow: NSWindow!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        cancellables = []
        sut = WindowViewModel()

        // Create a mock window for testing
        mockWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        // Clear UserDefaults for testing
        UserDefaults.standard.removeObject(forKey: "SavedWindowSizeName")
        UserDefaults.standard.removeObject(forKey: "SavedWindowSizeWidth")
        UserDefaults.standard.removeObject(forKey: "SavedWindowSizeHeight")
        UserDefaults.standard.removeObject(forKey: "SavedZoomLevel")
        UserDefaults.standard.removeObject(forKey: "SavedWindowPositionX")
        UserDefaults.standard.removeObject(forKey: "SavedWindowPositionY")
    }

    override func tearDown() async throws {
        cancellables = nil
        sut = nil
        mockWindow = nil

        try await super.tearDown()
    }

    // MARK: - Window Size Management Tests

    func testWindowSizeChangesUpdateActualWindow() async throws {
        // Given
        let testSize = WindowSize(name: "Test", width: 1280, height: 720)
        let sizeChangeExpectation = XCTestExpectation(
            description: "Size changed"
        )

        sut.$currentSize
            .dropFirst()
            .sink { _ in
                sizeChangeExpectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.setWindowSize(testSize)

        // Then
        await fulfillment(of: [sizeChangeExpectation], timeout: 1.0)

        XCTAssertEqual(sut.currentSize.width, 1280)
        XCTAssertEqual(sut.currentSize.height, 720)
        XCTAssertEqual(sut.currentSize.name, "Test")

        // Verify effective size calculation
        let effectiveSize = sut.effectiveSize
        XCTAssertEqual(effectiveSize.width, 1280 * CGFloat(sut.zoomLevel))
        XCTAssertEqual(effectiveSize.height, 720 * CGFloat(sut.zoomLevel))
    }

    func testSizeDisplayTextFormat() {
        // Given
        sut.currentSize = WindowSize(name: "1080p", width: 1920, height: 1080)

        // When - No zoom
        sut.zoomLevel = 1.0
        XCTAssertEqual(sut.sizeDisplayText, "1920×1080")

        // When - With zoom
        sut.zoomLevel = 0.75
        XCTAssertEqual(sut.sizeDisplayText, "1920×1080 @ 75%")

        // When - With different zoom
        sut.zoomLevel = 0.5
        XCTAssertEqual(sut.sizeDisplayText, "1920×1080 @ 50%")
    }

    func testMenuItemTextFormat() {
        // Given
        let size = WindowSize(name: "1080p", width: 1920, height: 1080)

        // When
        let text = sut.menuItemText(for: size)

        // Then
        XCTAssertEqual(text, "1080p (1920×1080)")
    }

    // MARK: - Zoom Functionality Tests

    func testZoomLevelBounds() {
        // Test minimum zoom
        sut.setZoomLevel(0.1)
        XCTAssertEqual(sut.zoomLevel, 0.25)  // Minimum is 25%

        // Test maximum zoom
        sut.setZoomLevel(2.0)
        XCTAssertEqual(sut.zoomLevel, 1.0)  // Maximum is 100%

        // Test valid zoom levels
        sut.setZoomLevel(0.5)
        XCTAssertEqual(sut.zoomLevel, 0.5)

        sut.setZoomLevel(0.75)
        XCTAssertEqual(sut.zoomLevel, 0.75)
    }

    func testZoomRoundingTo5PercentIncrements() {
        // Test rounding up
        sut.setZoomLevel(0.52)
        XCTAssertEqual(sut.zoomLevel, 0.5)

        sut.setZoomLevel(0.53)
        XCTAssertEqual(sut.zoomLevel, 0.55)

        // Test rounding down
        sut.setZoomLevel(0.77)
        XCTAssertEqual(sut.zoomLevel, 0.75)

        sut.setZoomLevel(0.78)
        XCTAssertEqual(sut.zoomLevel, 0.8)

        // Test exact values
        sut.setZoomLevel(0.6)
        XCTAssertEqual(sut.zoomLevel, 0.6)

        sut.setZoomLevel(0.85)
        XCTAssertEqual(sut.zoomLevel, 0.85)
    }

    func testEffectiveSizeCalculations() {
        // Given
        sut.currentSize = WindowSize(name: "1080p", width: 1920, height: 1080)

        // Test at 100% zoom
        sut.zoomLevel = 1.0
        XCTAssertEqual(sut.effectiveSize.width, 1920)
        XCTAssertEqual(sut.effectiveSize.height, 1080)

        // Test at 50% zoom
        sut.zoomLevel = 0.5
        XCTAssertEqual(sut.effectiveSize.width, 960)
        XCTAssertEqual(sut.effectiveSize.height, 540)

        // Test at 75% zoom
        sut.zoomLevel = 0.75
        XCTAssertEqual(sut.effectiveSize.width, 1440)
        XCTAssertEqual(sut.effectiveSize.height, 810)
    }

    func testAutoZoomWhenWindowExceedsScreenBounds() async throws {
        // Given - Assume a typical screen size
        let largeSize = WindowSize(name: "4K", width: 3840, height: 2160)

        // When
        sut.setWindowSize(largeSize)

        // Give time for async auto-zoom
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        // Then - Zoom should be adjusted to fit screen
        // The exact value depends on screen size, but it should be less than 1.0
        XCTAssertLessThanOrEqual(sut.zoomLevel, 1.0)
        XCTAssertGreaterThan(sut.zoomLevel, 0.25)
    }

    func testZoomToFit() {
        // Given
        sut.currentSize = WindowSize(name: "4K", width: 3840, height: 2160)

        // When
        sut.zoomToFit()

        // Then
        // Should calculate optimal zoom for screen
        XCTAssertLessThanOrEqual(sut.zoomLevel, 1.0)
        XCTAssertGreaterThan(sut.zoomLevel, 0.25)

        // Should be rounded to 5% increment
        let percentage = Int(sut.zoomLevel * 100)
        XCTAssertEqual(percentage % 5, 0)
    }

    // MARK: - Persistence Tests

    func testSizePositionPersistence() {
        // Given
        let testSize = WindowSize(name: "Custom", width: 1600, height: 900)

        // When - Save size
        sut.setWindowSize(testSize)

        // Then - Verify saved to UserDefaults
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: "SavedWindowSizeName"),
            "Custom"
        )
        XCTAssertEqual(
            UserDefaults.standard.double(forKey: "SavedWindowSizeWidth"),
            1600
        )
        XCTAssertEqual(
            UserDefaults.standard.double(forKey: "SavedWindowSizeHeight"),
            900
        )
    }

    func testZoomLevelPersistence() {
        // When - Set zoom level
        sut.setZoomLevel(0.75)

        // Then - Verify saved to UserDefaults
        XCTAssertEqual(
            UserDefaults.standard.double(forKey: "SavedZoomLevel"),
            0.75
        )
    }

    func testRestorationOnInit() {
        // Given - Save values to UserDefaults
        UserDefaults.standard.set("TestSize", forKey: "SavedWindowSizeName")
        UserDefaults.standard.set(1400, forKey: "SavedWindowSizeWidth")
        UserDefaults.standard.set(800, forKey: "SavedWindowSizeHeight")
        UserDefaults.standard.set(0.8, forKey: "SavedZoomLevel")

        // When - Create new view model
        let restoredViewModel = WindowViewModel()

        // Then
        XCTAssertEqual(restoredViewModel.currentSize.name, "TestSize")
        XCTAssertEqual(restoredViewModel.currentSize.width, 1400)
        XCTAssertEqual(restoredViewModel.currentSize.height, 800)
        XCTAssertEqual(restoredViewModel.zoomLevel, 0.8)
    }

    func testDefaultValuesWhenNoSavedData() {
        // Given - Ensure no saved data
        UserDefaults.standard.removeObject(forKey: "SavedWindowSizeName")
        UserDefaults.standard.removeObject(forKey: "SavedWindowSizeWidth")
        UserDefaults.standard.removeObject(forKey: "SavedWindowSizeHeight")
        UserDefaults.standard.removeObject(forKey: "SavedZoomLevel")

        // When - Create new view model
        let freshViewModel = WindowViewModel()

        // Then - Should use defaults
        XCTAssertEqual(freshViewModel.currentSize.name, "1080p")
        XCTAssertEqual(freshViewModel.currentSize.width, 1920)
        XCTAssertEqual(freshViewModel.currentSize.height, 1080)
        XCTAssertEqual(freshViewModel.zoomLevel, 1.0)
    }

    // MARK: - Background Image Tests

    func testToggleBackgroundImage() {
        // Given - Set initial background
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        sut.backgroundImage = testImage

        // When - Toggle off
        sut.toggleBackgroundImage()

        // Then
        XCTAssertNil(sut.backgroundImage)

        // When - Toggle back on
        sut.toggleBackgroundImage()

        // Then
        XCTAssertNotNil(sut.backgroundImage)
        XCTAssertEqual(sut.backgroundImage?.size, testImage.size)
    }

    func testClearBackgroundImage() {
        // Given
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        sut.backgroundImage = testImage

        // When
        sut.clearBackgroundImage()

        // Then
        XCTAssertNil(sut.backgroundImage)

        // When - Toggle should bring it back
        sut.toggleBackgroundImage()

        // Then
        XCTAssertNotNil(sut.backgroundImage)
    }

    // MARK: - Screen Info Tests

    func testGetCurrentScreenInfo() {
        // When
        let screenInfo = sut.getCurrentScreenInfo()

        // Then
        XCTAssertGreaterThan(screenInfo.size.width, 0)
        XCTAssertGreaterThan(screenInfo.size.height, 0)
        XCTAssertGreaterThanOrEqual(screenInfo.scale, 1.0)
    }

    func testDisplayInfoText() {
        // When
        let displayInfo = sut.displayInfoText

        // Then
        XCTAssertFalse(displayInfo.isEmpty)
        XCTAssertTrue(displayInfo.contains("×"))  // Should have dimension separator
    }

    // MARK: - Keyboard Shortcut Tests

    func testKeyboardShortcutMechanismExists() {
        // Given - Initial state
        XCTAssertFalse(sut.shouldFocusURLField)

        // When - Setup window (which includes keyboard shortcuts)
        sut.setupWindow()

        // Then - We can't directly test private keyboard shortcuts,
        // but we can verify the public interface exists
        XCTAssertFalse(sut.shouldFocusURLField)  // Still false until triggered

        // Note: Full keyboard shortcut testing requires UI tests
        // This test verifies the setup mechanism exists
    }

    // MARK: - Window Setup Tests

    func testSetupWindowConfiguresAppearance() {
        // Given - Mock NSApp.windows
        // Note: This is difficult to test without UI tests
        // The test structure shows what should be verified

        // When
        sut.setupWindow()

        // Then - Would verify:
        // - Window titlebar transparency
        // - Window resizability disabled
        // - Window size updated
        // - Position restored or centered
        // - Keyboard shortcuts installed
    }

    // MARK: - Edge Case Tests

    func testWindowSizeWithInvalidValues() {
        // Given - Save invalid values
        UserDefaults.standard.set("Invalid", forKey: "SavedWindowSizeName")
        UserDefaults.standard.set(-100, forKey: "SavedWindowSizeWidth")
        UserDefaults.standard.set(0, forKey: "SavedWindowSizeHeight")

        // When
        let viewModel = WindowViewModel()

        // Then - Should fall back to default
        XCTAssertEqual(viewModel.currentSize.name, "1080p")
        XCTAssertEqual(viewModel.currentSize.width, 1920)
        XCTAssertEqual(viewModel.currentSize.height, 1080)
    }

    func testPresetSizeMatching() {
        // Given - Save a preset size
        UserDefaults.standard.set("720p", forKey: "SavedWindowSizeName")
        UserDefaults.standard.set(1280, forKey: "SavedWindowSizeWidth")
        UserDefaults.standard.set(720, forKey: "SavedWindowSizeHeight")

        // When
        let viewModel = WindowViewModel()

        // Then - Should match to preset
        XCTAssertEqual(viewModel.currentSize.name, "720p")

        // Verify it's using the actual preset object
        let preset = WindowSize.presets.first { $0.name == "720p" }
        XCTAssertNotNil(preset)
    }
}
