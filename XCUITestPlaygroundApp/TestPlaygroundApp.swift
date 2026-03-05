//
//  TestPlaygroundApp.swift
//  XCUITestPlaygroundApp
//
//
import SwiftUI

@main
struct XCUITestPlaygroundApp: App {

    @StateObject private var state = AppState()

    init() {
        if CommandLine.arguments.contains(TestHooks.uiTestModeArg) {
            // Turn off animations if you want super-stable tests (optional)
            // UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(state)
        }
    }
}
