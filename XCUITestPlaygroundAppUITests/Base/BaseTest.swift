//
//  BaseTest.swift
//  XCUITestPlaygroundApp
//

import XCTest

class BaseTest: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [TestHooks.uiTestModeArg]
        app.launch()
    }
}
