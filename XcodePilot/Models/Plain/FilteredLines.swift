// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// The lines of a log that pass a console filter. Kept in step with the log as it grows:
/// only new lines are filtered, the whole log again only when the filter or the log changes.
struct FilteredLines {

    // MARK: - Properties
    private(set) var lines: [String] = []
    private var filter: ConsoleFilter?
    private var source: AnyHashable?
    /// `BuildLog.appendedCount` the lines are filtered up to
    private var filteredCount: Int = .zero

    // MARK: - Internal methods
    /// - Parameter source: identity of the log, a new one filters it from the start
    mutating func update(from log: BuildLog, source: AnyHashable?, filter: ConsoleFilter) {
        let appendedCount = log.appendedCount
        if filter != self.filter || source != self.source || appendedCount < filteredCount {
            lines = filter.apply(to: log.fullLines)
        } else if appendedCount > filteredCount {
            // Lines dropped over the log's limit before they were filtered are gone either way
            let newLines = log.fullLines.suffix(min(appendedCount - filteredCount, log.fullLines.count))
            lines.append(contentsOf: filter.apply(to: newLines))
            if lines.count > BuildLog.lineLimit {
                lines.removeFirst(lines.count - BuildLog.lineLimit)
            }
        }
        self.filter = filter
        self.source = source
        filteredCount = appendedCount
    }

    mutating func reset() {
        self = FilteredLines()
    }

}
