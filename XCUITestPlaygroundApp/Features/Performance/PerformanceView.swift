//
//  PerformanceView.swift
//  XCUITestPlaygroundApp
//

import SwiftUI

struct PerformanceView: View {

    var body: some View {
        NavigationStack {
            List(0..<1500, id: \.self) { i in
                HStack {
                    Text("Row \(i)")
                    Spacer()
                    Image(systemName: "sparkles")
                }
                .accessibilityIdentifier("perf_row_\(i)")
            }
            .navigationTitle("Performance")
        }
    }
}
