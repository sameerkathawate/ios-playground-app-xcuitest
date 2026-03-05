//
//  AppState.swift
//  XCUITestPlaygroundApp
//

import Foundation
import Combine
import SwiftUI

@MainActor
class AppState: ObservableObject {

    @Published var isUITestMode: Bool = false
    @Published var networkDelaySeconds: Double = 2.0
    @Published var shouldFailNetwork: Bool = false

    func resetAll() {
        isUITestMode = false
        networkDelaySeconds = 2.0
        shouldFailNetwork = false
    }
}

