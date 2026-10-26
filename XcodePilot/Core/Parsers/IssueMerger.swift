// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Combines the issues parsed from the live log with the ones of the result bundle
enum IssueMerger {

    // MARK: - Internal methods
    /// Prefers the bundle (complete and de-duplicated by Xcode itself) and keeps the compiler
    /// excerpts only the live log has. Without bundle issues the live ones stay as they are.
    static func merge(live: [BuildIssue], bundle: [BuildIssue]) -> [BuildIssue] {
        guard bundle.isEmpty == false else {
            return live
        }
        return bundle.map { issue in
            guard let match = live.first(where: { isSame($0, as: issue) }) else {
                return issue
            }
            var issue = issue
            issue.context = match.context
            issue.column = issue.column ?? match.column
            issue.target = issue.target ?? match.target
            return issue
        }
    }

    // MARK: - Private methods
    private static func isSame(_ live: BuildIssue, as bundled: BuildIssue) -> Bool {
        guard live.severity == bundled.severity else {
            return false
        }
        if let file = bundled.file, let line = bundled.line {
            return live.file == file && live.line == line
        }
        return live.message.caseInsensitiveCompare(bundled.message) == .orderedSame
    }

}
