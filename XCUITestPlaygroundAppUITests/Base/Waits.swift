//
//  Waits.swift
//  XCUITestPlaygroundApp
//

import XCTest

extension XCUIElement {
    func waitExists(_ timeout: TimeInterval = 5) -> Bool {
        return self.waitForExistence(timeout: timeout)
    }
}
