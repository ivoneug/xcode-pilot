// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Carbon.HIToolbox
import Foundation

/// A system wide keyboard shortcut
struct HotKey: Hashable {

    // MARK: - Nested types
    enum Modifier: Hashable {
        case command
        case option
        case control
        case shift
    }

    // MARK: - Properties
    /// Virtual key code (`kVK_*`)
    let keyCode: UInt32
    let modifiers: [Modifier]
    let key: String

    // MARK: - Computed properties
    var displayName: String {
        let symbols = modifiers.map { modifier -> String in
            switch modifier {
            case .control:
                return "⌃"
            case .option:
                return "⌥"
            case .shift:
                return "⇧"
            case .command:
                return "⌘"
            }
        }
        return symbols.joined() + key
    }

}

extension HotKey {

    // MARK: - Static properties
    static let build = HotKey(keyCode: UInt32(kVK_ANSI_B), modifiers: Constants.modifiers, key: "B")
    static let run = HotKey(keyCode: UInt32(kVK_ANSI_R), modifiers: Constants.modifiers, key: "R")
    static let stop = HotKey(keyCode: UInt32(kVK_ANSI_Period), modifiers: Constants.modifiers, key: ".")
    static let togglePanel = HotKey(keyCode: UInt32(kVK_ANSI_X), modifiers: Constants.modifiers, key: "X")

}

private enum Constants {
    static let modifiers: [HotKey.Modifier] = [.control, .option, .command]
}
