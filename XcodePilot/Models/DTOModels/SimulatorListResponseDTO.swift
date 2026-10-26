// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// `xcrun simctl list devices -j`
struct SimulatorListResponseDTO: Decodable {

    // MARK: - Nested types
    struct Device: Decodable {
        let udid: String
        let name: String
        let state: String
        let isAvailable: Bool?
        let deviceTypeIdentifier: String?
    }

    // MARK: - Properties
    /// Devices keyed by runtime identifier: `com.apple.CoreSimulator.SimRuntime.iOS-18-5`
    let devices: [String: [Device]]

}
