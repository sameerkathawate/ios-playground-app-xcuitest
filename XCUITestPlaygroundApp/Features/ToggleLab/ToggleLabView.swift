//
//  ToggleLabView.swift
//  XCUITestPlaygroundApp
//

import SwiftUI

struct ToggleLabView: View {

    @State private var simpleToggle = false
    @State private var asyncToggle = false
    @State private var animatedToggle = false
    @State private var listToggles = Array(repeating: false, count: 25)

    @State private var asyncStatus = "Idle"
    @State private var isBusy = false

    var body: some View {
        NavigationStack {
            List {
                Section("Basic") {
                    Toggle("Simple Toggle", isOn: $simpleToggle)
                        .accessibilityIdentifier("toggle_simple")
                        .animation(.bouncy, value: simpleToggle)
                }

                Section("Animated") {
                    Toggle("Animated Toggle", isOn: $animatedToggle)
                        .accessibilityIdentifier("toggle_animated")
                        .animation(.easeInOut, value: animatedToggle)
                }

                Section("Async") {
                    Toggle("Toggle triggers async", isOn: $asyncToggle)
                        .accessibilityIdentifier("toggle_async")
                        .onChange(of: asyncToggle) { oldValue, newValue in
                            runAsyncSimulation(newValue)
                        }

                    if isBusy {
                        ProgressView()
                            .accessibilityIdentifier("toggle_async_loader")
                    }

                    Text("Status: \(asyncStatus)")
                        .accessibilityIdentifier("toggle_async_status")
                }

                Section("List Stress") {
                    ForEach(0..<listToggles.count, id: \.self) { i in
                        Toggle("Row \(i)", isOn: $listToggles[i])
                            .accessibilityIdentifier("toggle_list_\(i)")
                    }
                }

                Section("Presentation") {
                    NavigationLink("Open Toggle Sheet") {
                        ToggleSheetView()
                    }
                    .accessibilityIdentifier("toggle_sheet_nav")
                }
            }
            .navigationTitle("Toggle Lab")
        }
    }

    private func runAsyncSimulation(_ value: Bool) {
        isBusy = true
        asyncStatus = "Working..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isBusy = false
            asyncStatus = "Done (value=\(value))"
        }
    }
}
