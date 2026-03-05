//
//  AppNavigator.swift
//  XCUITestPlaygroundApp
//
import XCTest

enum AppNavigator {

    static func goToTab(_ app: XCUIApplication, id: String) {
        let tab = app.otherElements[id]
        if tab.exists {
            tab.tap()
        } else {
            // fallback: tab bar label lookup
            app.tabBars.buttons[id].tap()
        }
    }
}
