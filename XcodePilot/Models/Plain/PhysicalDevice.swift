// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// A device CoreDevice knows about, from `devicectl list devices`
struct PhysicalDevice: Identifiable, Hashable {

    // MARK: - Properties
    let identifier: String
    let udid: String?
    let name: String
    let platform: String
    let model: String
    let osVersion: String?
    let tunnelState: String?
    let pairingState: String?
    let transport: String?
    let isDeveloperModeEnabled: Bool?

    // MARK: - Computed properties
    var id: String {
        identifier
    }

    var isConnected: Bool {
        tunnelState == Constants.connected
    }

    var stateDescription: String {
        if isConnected {
            return transport == Constants.wired ? Localizations.Devices.State.connectedUsb : Localizations.Devices.State.connected
        }
        if pairingState == Constants.paired, tunnelState == Constants.disconnected {
            return Localizations.Devices.State.available
        }
        return Localizations.Devices.State.unavailable
    }

    var symbolName: String {
        switch platform {
        case "watchOS":
            return "applewatch"
        case "tvOS":
            return "appletv"
        case "visionOS", "xrOS":
            return "visionpro"
        default:
            return model.lowercased().contains("ipad") ? "ipad" : "iphone"
        }
    }

}

private enum Constants {
    static let connected = "connected"
    static let disconnected = "disconnected"
    static let paired = "paired"
    static let wired = "wired"
}
