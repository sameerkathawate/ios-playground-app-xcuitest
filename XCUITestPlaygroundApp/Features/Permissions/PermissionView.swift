//
//  PermissionView.swift
//  XCUITestPlaygroundApp
//

import SwiftUI

struct PermissionView: View {

    @State private var lastAction = "None"
    @State private var permissionEnabled = false

    var body: some View {
        NavigationStack {
            Form {

                Section("Permission Toggle") {

                    Toggle("Enable Permission", isOn: $permissionEnabled)
                        .accessibilityIdentifier("permission_toggle")
                        .onChange(of: permissionEnabled) { oldValue, newValue in
                            lastAction = newValue ? "Permission Enabled" : "Permission Disabled"
                        }
                }

                Section("System Alerts") {

                    Button("Simulate Permission Prompt") {
                        lastAction = "Prompt requested (stub)"
                    }
                    .accessibilityIdentifier("perm_prompt_button")

                    Text("Last: \(lastAction)")
                        .accessibilityIdentifier("perm_last_action")
                }
            }
            .navigationTitle("Permissions")
        }
    }
}
