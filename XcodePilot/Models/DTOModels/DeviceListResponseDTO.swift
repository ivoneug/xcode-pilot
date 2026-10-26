// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// The file written by `xcrun devicectl list devices --json-output <file>`
struct DeviceListResponseDTO: Decodable {

    // MARK: - Nested types
    struct Result: Decodable {
        let devices: [Device]
    }

    struct Device: Decodable {
        let identifier: String
        let hardwareProperties: Hardware?
        let deviceProperties: Properties?
        let connectionProperties: Connection?
    }

    struct Hardware: Decodable {
        let udid: String?
        let platform: String?
        let marketingName: String?
        let productType: String?
    }

    struct Properties: Decodable {
        let name: String?
        let osVersionNumber: String?
        let developerModeStatus: String?
    }

    struct Connection: Decodable {
        let tunnelState: String?
        let pairingState: String?
        let transportType: String?
    }

    // MARK: - Properties
    let result: Result

}
