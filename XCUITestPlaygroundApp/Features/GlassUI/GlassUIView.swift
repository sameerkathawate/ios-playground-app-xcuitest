//
//  GlassUIView.swift
//  XCUITestPlaygroundApp
//

import SwiftUI

struct GlassUIView: View {

    @State private var glassToggle = false
    @State private var showOverlay = false

    var body: some View {
        ZStack {
            // Background that makes material/glass obvious
            LinearGradient(colors: [.purple, .blue, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Liquid Glass / Material")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("glass_title")

                Button("Glass Button") { showOverlay.toggle() }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("glass_button")

                Toggle("Glass Toggle", isOn: $glassToggle)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("glass_toggle")

                Text("Overlay: \(showOverlay.description)")
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("glass_overlay_state")
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding()

            if showOverlay {
                VStack(spacing: 12) {
                    Text("Overlay Layer")
                        .font(.headline)

                    Button("Close Overlay") { showOverlay = false }
                        .accessibilityIdentifier("glass_overlay_close")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityIdentifier("glass_overlay")
            }
        }
    }
}
