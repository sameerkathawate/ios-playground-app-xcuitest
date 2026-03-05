//
//  RootTabView.swift
//  XCUITestPlaygroundApp
//
import SwiftUI

struct RootTabView: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        TabView {
            ControlsView()
                .tabItem { Label("Controls", systemImage: "slider.horizontal.3") }
                .accessibilityIdentifier("tab_controls")

            ToggleLabView()
                .tabItem { Label("Toggle Lab", systemImage: "switch.2") }
                .accessibilityIdentifier("tab_toggle_lab")

            GlassUIView()
                .tabItem { Label("Glass", systemImage: "square.fill") }
                .accessibilityIdentifier("tab_glass")
            
            PictureViewerView()
                .tabItem { Label("Picture", systemImage: "photo") }
                .accessibilityIdentifier("tab_picture")
                .tint(.blue)
            
            GestureView()
                .tabItem { Label("Gestures", systemImage: "hand.tap") }
                .accessibilityIdentifier("tab_gestures")

            AsyncNetworkView()
                .tabItem { Label("Async", systemImage: "network") }
                .accessibilityIdentifier("tab_async")

            PermissionView()
                .tabItem { Label("Permissions", systemImage: "lock") }
                .accessibilityIdentifier("tab_permissions")

            PerformanceView()
                .tabItem { Label("Performance", systemImage: "speedometer") }
                .accessibilityIdentifier("tab_performance")

            DebugPanelView()
                .tabItem { Label("Debug", systemImage: "gearshape") }
                .accessibilityIdentifier("tab_debug")
        }
    }
}
