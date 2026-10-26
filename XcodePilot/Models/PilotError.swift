// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

enum PilotError: LocalizedError {
    case commandFailed(command: String, status: Int32, output: String)
    case unreadableOutput(command: String)
    case noRunnableProduct(scheme: String)
    case missingBundleIdentifier(product: String)
    case accessibilityRequired
    case xcodeNotFound
    case menuItemNotFound(String)
    case launchFailed(String)

    // MARK: - Computed properties
    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let status, let output):
            let tail = output.split(separator: "\n").suffix(Constants.outputTailLines).joined(separator: "\n")
            return Localizations.Error.commandFailed(command, Int(status)) + (tail.isEmpty ? String.empty : "\n" + tail)
        case .unreadableOutput(let command):
            return Localizations.Error.unreadableOutput(command)
        case .noRunnableProduct(let scheme):
            return Localizations.Error.noRunnableProduct(scheme)
        case .missingBundleIdentifier(let product):
            return Localizations.Error.missingBundleIdentifier(product)
        case .accessibilityRequired:
            return Localizations.Error.accessibilityRequired
        case .xcodeNotFound:
            return Localizations.Error.xcodeNotFound
        case .menuItemNotFound(let item):
            return Localizations.Error.menuItemNotFound(item)
        case .launchFailed(let message):
            return message
        }
    }

}

private enum Constants {
    static let outputTailLines = 6
}
