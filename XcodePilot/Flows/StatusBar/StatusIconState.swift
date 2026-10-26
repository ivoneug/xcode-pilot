// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// What the menu bar icon shows
enum StatusIconState: Equatable {

    // MARK: - Nested types
    enum Work: Equatable {
        case build
        case test
        case clean
        case archive
        case export
        case install

        // MARK: - Computed properties
        var symbolName: String {
            switch self {
            case .build:
                return "hammer.fill"
            case .test:
                return "checkmark.diamond.fill"
            case .clean:
                return "trash.fill"
            case .archive:
                return "archivebox.fill"
            case .export:
                return "square.and.arrow.up.fill"
            case .install:
                return "arrow.down.app.fill"
            }
        }
    }

    case idle
    /// `progress` is `nil` while there is nothing to estimate it from, the ring then spins
    case working(Work, progress: Double?)
    case running
    case succeeded
    case failed

    // MARK: - Computed properties
    /// Whether the icon changes on its own between state updates
    var isAnimated: Bool {
        switch self {
        case .working(_, let progress):
            return progress == nil
        case .running:
            return true
        case .idle, .succeeded, .failed:
            return false
        }
    }

}
