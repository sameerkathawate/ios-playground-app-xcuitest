//
//  GestureView.swift
//  XCUITestPlaygroundApp
//

import SwiftUI

struct GestureView: View {

    @State private var offset: CGSize = .zero
    @State private var didLongPress = false

    var body: some View {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 140, height: 140)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in offset = value.translation }
                )
                .accessibilityIdentifier("gesture_drag_box")

            Text(didLongPress ? "Long Pressed" : "Long Press Me")
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onLongPressGesture(minimumDuration: 1.0) { didLongPress = true }
                .accessibilityIdentifier("gesture_long_press_text")

            Button("Reset") {
                offset = .zero
                didLongPress = false
            }
            .accessibilityIdentifier("gesture_reset")
        }
        .padding()
        .navigationTitle("Gestures")
    }
}
