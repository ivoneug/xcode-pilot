// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Append only storage of a build log or an app console. Readers compare `version` to notice new lines.
final class BuildLog {

    // MARK: - Properties
    static let lineLimit = 300_000
    private(set) var compactLines: [String] = []
    private(set) var fullLines: [String] = []
    private(set) var version: Int = .zero
    /// Full lines appended since the last reset, the ones dropped over the limit included
    private(set) var appendedCount: Int = .zero

    // MARK: - Internal methods
    func append(full: [String], compact: [String]) {
        guard full.isEmpty == false || compact.isEmpty == false else {
            return
        }
        fullLines.append(contentsOf: full)
        compactLines.append(contentsOf: compact)
        appendedCount += full.count
        if fullLines.count > Self.lineLimit {
            fullLines.removeFirst(fullLines.count - Self.lineLimit)
        }
        if compactLines.count > Self.lineLimit {
            compactLines.removeFirst(compactLines.count - Self.lineLimit)
        }
        version += 1
    }

    func append(_ lines: [String]) {
        append(full: lines, compact: lines)
    }

    func reset() {
        fullLines.removeAll()
        compactLines.removeAll()
        appendedCount = .zero
        version += 1
    }

    func lines(compact: Bool) -> [String] {
        compact ? compactLines : fullLines
    }

    /// Writes the full log to a temporary file, to open it in another app
    func writeTemporaryFile(named name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try fullLines.joined(separator: String.lineBreak).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

}
