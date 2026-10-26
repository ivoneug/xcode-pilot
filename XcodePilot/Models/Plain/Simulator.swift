// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

struct Simulator: Identifiable, Hashable {

    // MARK: - Properties
    let udid: String
    let name: String
    let state: String
    /// Human readable runtime: "iOS 18.5"
    let runtime: String
    let deviceType: String

    // MARK: - Computed properties
    var id: String {
        udid
    }

    var isBooted: Bool {
        state == Constants.bootedState
    }

    var symbolName: String {
        let lowered = deviceType.lowercased()
        if lowered.contains("ipad") {
            return "ipad"
        }
        if lowered.contains("watch") {
            return "applewatch"
        }
        if lowered.contains("tv") {
            return "appletv"
        }
        if lowered.contains("vision") {
            return "visionpro"
        }
        return "iphone"
    }

}

private enum Constants {
    static let bootedState = "Booted"
}
