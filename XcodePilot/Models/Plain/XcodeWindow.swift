// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Xcode windows that can only be reached through its Window menu
enum XcodeWindow {
    case organizer
    case devicesAndSimulators

    // MARK: - Computed properties
    /// Title of the item in Xcode's Window menu. Xcode isn't localized, so it is always English.
    var menuItemTitle: String {
        switch self {
        case .organizer:
            return "Organizer"
        case .devicesAndSimulators:
            return "Devices and Simulators"
        }
    }

}
