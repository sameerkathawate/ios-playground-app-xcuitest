//
//  PictureViewerView.swift
//  XCUITestPlaygroundApp
//

import SwiftUI

struct PictureViewerView: View {

@State private var zoom: CGFloat = 1.0

var body: some View {
    NavigationStack {

        ZStack {

            // MARK: Image
            Image("sample_picture")
                .resizable()
                .scaledToFit()
                .scaleEffect(zoom)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoom = value
                        }
                )
                .onTapGesture(count: 2) {
                    zoom = zoom == 1 ? 2 : 1
                }
                .accessibilityIdentifier("picture_image")

            // MARK: Floating Controls
            VStack {
                Spacer()

                HStack(spacing: 40) {

                    Button {
                        zoom = max(0.5, zoom - 0.2)
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .accessibilityIdentifier("picture_zoom_out")

                    Button {
                        zoom = 1.0
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityIdentifier("picture_reset")

                    Button {
                        zoom = min(3.0, zoom + 0.2)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .accessibilityIdentifier("picture_zoom_in")

                }
                .font(.title2)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.bottom, 20)
                .accessibilityIdentifier("picture_controls")
            }
        }
        .navigationTitle("Picture Viewer")
    }
}
}
