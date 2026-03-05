import XCTest

final class AsyncTests: BaseTest {

    func test_async_success_result() {
        let app = XCUIApplication()
        app.activate()
        
        // Verify "More" button exists
        let moreButton = app.buttons["More"].firstMatch
        XCTAssertTrue(moreButton.waitForExistence(timeout: 5), "More button should exist")
        moreButton.tap()
        
        // Verify "Async" option exists
        let asyncOption = app.staticTexts["Async"].firstMatch
        XCTAssertTrue(asyncOption.waitForExistence(timeout: 5), "Async option should exist")
        asyncOption.tap()
        
        // Verify switch exists
        let permissionSwitch = app.switches["0"].firstMatch
        XCTAssertTrue(permissionSwitch.waitForExistence(timeout: 5), "Permission switch should exist")
        
        // Capture initial state
        let initialValue = permissionSwitch.value as? String
        
        // Toggle switch
        permissionSwitch.tap()
        
        // Assert switch state changed
        let newValue = permissionSwitch.value as? String
        XCTAssertNotEqual(initialValue, newValue, "Switch value should change after tap")
        
        // Optional explicit assertion
        XCTAssertEqual(newValue, "1", "Switch should be ON after tapping")
    }
}
