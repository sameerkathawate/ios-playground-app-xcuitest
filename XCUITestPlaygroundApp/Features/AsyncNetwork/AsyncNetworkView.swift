//
//  AsyncNetworkView.swift
//  XCUITestPlaygroundApp
//


import SwiftUI

struct AsyncNetworkView: View {

    @EnvironmentObject private var state: AppState

    @State private var loading = false
    @State private var result = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Text("Delay: \(state.networkDelaySeconds, specifier: "%.1f")s")
                    Slider(value: $state.networkDelaySeconds, in: 0.5...5.0, step: 0.5)
                        .accessibilityIdentifier("async_delay_slider")
                }

                Toggle("Fail Request", isOn: $state.shouldFailNetwork)
                    .accessibilityIdentifier("async_fail_toggle")

                Button("Call API") {
                    callFakeAPI()
                }
                .accessibilityIdentifier("async_call_button")

                if loading {
                    ProgressView()
                        .accessibilityIdentifier("async_loader")
                }

                Text(result)
                    .accessibilityIdentifier("async_result")
                    .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Async")
        }
    }

    private func callFakeAPI() {
        loading = true
        result = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + state.networkDelaySeconds) {
            loading = false
            result = state.shouldFailNetwork ? "Error: 500" : "Success: 200"
        }
    }
}
