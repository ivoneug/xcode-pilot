// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

enum BuildAction: String, Codable, CaseIterable {
    case build
    case run
    case test
    case clean
    case archive
    case export

    // MARK: - Computed properties
    /// Button title: "Build", "Run", ...
    var title: String {
        switch self {
        case .build:
            return Localizations.Action.build
        case .run:
            return Localizations.Action.run
        case .test:
            return Localizations.Action.test
        case .clean:
            return Localizations.Action.clean
        case .archive:
            return Localizations.Action.archive
        case .export:
            return Localizations.Action.export
        }
    }

    /// Activity in progress: "Building", "Archiving", ...
    var progressTitle: String {
        switch self {
        case .build, .run:
            return Localizations.Activity.Progress.build
        case .test:
            return Localizations.Activity.Progress.test
        case .clean:
            return Localizations.Activity.Progress.clean
        case .archive:
            return Localizations.Activity.Progress.archive
        case .export:
            return Localizations.Activity.Progress.export
        }
    }

    /// Noun the result titles are built from: "Build" in "Build Succeeded"
    var noun: String {
        switch self {
        case .build, .run:
            return Localizations.Activity.Noun.build
        case .test:
            return Localizations.Activity.Noun.test
        case .clean:
            return Localizations.Activity.Noun.clean
        case .archive:
            return Localizations.Activity.Noun.archive
        case .export:
            return Localizations.Activity.Noun.export
        }
    }

    var symbolName: String {
        switch self {
        case .build:
            return "hammer.fill"
        case .run:
            return "play.fill"
        case .test:
            return "checkmark.diamond.fill"
        case .clean:
            return "trash.fill"
        case .archive:
            return "archivebox.fill"
        case .export:
            return "square.and.arrow.up.fill"
        }
    }

    /// Whether the action leaves an `.xcresult` bundle with issues worth reading
    var producesResultBundle: Bool {
        switch self {
        case .build, .run, .test, .archive:
            return true
        case .clean, .export:
            return false
        }
    }

}
