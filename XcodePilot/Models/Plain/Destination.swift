// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// A run destination as reported by `xcodebuild -showdestinations`
struct Destination: Codable, Hashable, Identifiable {

    // MARK: - Properties
    let id: String
    let platform: String
    let name: String
    let arch: String?
    let variant: String?
    let os: String?

    // MARK: - Computed properties
    /// "Any iOS Device" style entries: buildable and archivable, not runnable
    var isPlaceholder: Bool {
        id.hasPrefix(Constants.placeholderPrefix)
    }

    var isSimulator: Bool {
        platform.hasSuffix(Constants.simulatorSuffix)
    }

    var isMac: Bool {
        platform == Constants.macOS || platform == Constants.driverKit
    }

    var isPhysicalDevice: Bool {
        isPlaceholder == false && isSimulator == false && isMac == false
    }

    var isRunnable: Bool {
        isPlaceholder == false
    }

    /// Platform without the "Simulator" suffix: "iOS", "watchOS", "macOS", ...
    var basePlatform: String {
        platform.replacingOccurrences(of: Constants.simulatorSuffix, with: String.empty)
    }

    /// Value for `xcodebuild -destination`
    var specifier: String {
        if isPlaceholder {
            return "generic/platform=\(platform)"
        }
        guard isMac else {
            return "id=\(id)"
        }
        var parts = ["platform=\(Constants.macOS)"]
        if let arch {
            parts.append("arch=\(arch)")
        }
        if let variant {
            parts.append("variant=\(variant)")
        }
        return parts.joined(separator: ",")
    }

    /// Generic destination archives for this platform are built against
    var archiveSpecifier: String {
        if isMac, let variant {
            return "generic/platform=\(Constants.macOS),variant=\(variant)"
        }
        return "generic/platform=\(basePlatform)"
    }

    var displayName: String {
        var result = name
        if isMac, let variant {
            result += " (\(variant))"
        }
        if isSimulator, let os {
            result += " · \(os)"
        }
        return result
    }

    var symbolName: String {
        switch basePlatform {
        case Constants.macOS, Constants.driverKit:
            return "laptopcomputer"
        case "watchOS":
            return "applewatch"
        case "tvOS":
            return "appletv"
        case "visionOS", "xrOS":
            return "visionpro"
        default:
            return name.lowercased().contains("ipad") ? "ipad" : "iphone"
        }
    }

    // MARK: - Internal methods
    func matches(_ other: Destination) -> Bool {
        id == other.id && variant == other.variant
    }

}

private enum Constants {
    static let placeholderPrefix = "dvtdevice-"
    static let simulatorSuffix = " Simulator"
    static let macOS = "macOS"
    static let driverKit = "DriverKit"
}
