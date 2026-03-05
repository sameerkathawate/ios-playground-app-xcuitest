//
//  ToggleSheetView.swift
//  XCUITestPlaygroundApp
//
import SwiftUI

struct ToggleSheetView: View {

    @State private var showSheet = false

    var body: some View {
        VStack(spacing: 16) {
            Button("Show Sheet") { showSheet = true }
                .accessibilityIdentifier("toggle_show_sheet_button")

            Text("Sheet Visible: \(showSheet.description)")
                .accessibilityIdentifier("toggle_sheet_state")
        }
        .padding()
        .navigationTitle("Toggle Sheet")
        .sheet(isPresented: $showSheet) {
            SheetContentView()
        }
    }
}

private struct SheetContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sheetToggle = false

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Toggle in Sheet", isOn: $sheetToggle)
                    .accessibilityIdentifier("toggle_sheet_toggle")

                Button("Dismiss") { dismiss() }
                    .accessibilityIdentifier("toggle_sheet_dismiss")
            }
            .navigationTitle("Sheet")
        }
    }
}
