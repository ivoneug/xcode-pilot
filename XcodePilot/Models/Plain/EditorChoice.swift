// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// The app issues are opened in
enum EditorChoice: String, CaseIterable, Identifiable, Codable {
    case xcode
    case vscode
    case cursor
    case zed
    case defaultApp

    // MARK: - Computed properties
    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .xcode:
            return "Xcode"
        case .vscode:
            return "Visual Studio Code"
        case .cursor:
            return "Cursor"
        case .zed:
            return "Zed"
        case .defaultApp:
            return Localizations.Settings.Editor.defaultApp
        }
    }

    /// URL scheme that opens `file:line:column`, for editors that have one
    var urlScheme: String? {
        switch self {
        case .vscode:
            return "vscode"
        case .cursor:
            return "cursor"
        case .zed:
            return "zed"
        case .xcode, .defaultApp:
            return nil
        }
    }

}
