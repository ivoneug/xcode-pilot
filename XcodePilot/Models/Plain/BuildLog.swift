// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Append only storage of a build log or an app console. Readers compare `version` to notice new lines.
final class BuildLog {

    // MARK: - Properties
    private(set) var compactLines: [String] = []
    private(set) var fullLines: [String] = []
    private(set) var version: Int = .zero

    // MARK: - Internal methods
    func append(full: [String], compact: [String]) {
        guard full.isEmpty == false || compact.isEmpty == false else {
            return
        }
        fullLines.append(contentsOf: full)
        compactLines.append(contentsOf: compact)
        if fullLines.count > Constants.lineLimit {
            fullLines.removeFirst(fullLines.count - Constants.lineLimit)
        }
        if compactLines.count > Constants.lineLimit {
            compactLines.removeFirst(compactLines.count - Constants.lineLimit)
        }
        version += 1
    }

    func append(_ lines: [String]) {
        append(full: lines, compact: lines)
    }

    func reset() {
        fullLines.removeAll()
        compactLines.removeAll()
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

private enum Constants {
    static let lineLimit = 300_000
}
