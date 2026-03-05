//
//  DebugPanelView.swift
//  XCUITestPlaygroundApp
//
//

import SwiftUI

struct DebugPanelView: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Test Mode") {
                    Toggle("UI Test Mode", isOn: $state.isUITestMode)
                        .accessibilityIdentifier("debug_ui_test_mode_toggle")

                    Button("Reset App State") {
                        state.resetAll()
                    }
                    .accessibilityIdentifier("debug_reset_button")
                }

                Section("State") {
                    Text("isUITestMode: \(state.isUITestMode.description)")
                        .accessibilityIdentifier("debug_state_is_test_mode")
                }
            }
            .navigationTitle("Debug")
        }
    }
}
