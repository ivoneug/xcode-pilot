// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Accumulates bytes read from a pipe and hands out complete UTF-8 lines
final class LineSplitter: @unchecked Sendable {

    // MARK: - Properties
    private let lock = NSLock()
    private var buffer = Data()

    // MARK: - Internal methods
    func append(_ data: Data) -> [String] {
        lock.withLock {
            buffer.append(data)
            guard let lastNewline = buffer.lastIndex(of: Constants.newline) else {
                return []
            }
            let complete = buffer[buffer.startIndex..<lastNewline]
            buffer = Data(buffer[buffer.index(after: lastNewline)...])
            return Self.split(complete)
        }
    }

    func flush() -> [String] {
        lock.withLock {
            defer {
                buffer.removeAll()
            }
            return buffer.isEmpty ? [] : Self.split(buffer)
        }
    }

    // MARK: - Private methods
    private static func split(_ data: Data) -> [String] {
        String(decoding: data, as: UTF8.self)
            .split(separator: "\n", omittingEmptySubsequences: false)
            // Pseudo terminals (`simctl launch --console-pty`) end lines with CRLF
            .map { $0.hasSuffix("\r") ? String($0.dropLast()) : String($0) }
    }

}

/// Tracks pipe EOF and process exit so a stream finishes exactly once
final class StreamState: @unchecked Sendable {

    // MARK: - Properties
    private let lock = NSLock()
    private var isAtEndOfFile = false
    private var status: Int32?
    private var isFinished = false

    // MARK: - Internal methods
    /// Returns the exit status if the process already exited
    func markEndOfFile() -> Int32? {
        lock.withLock {
            isAtEndOfFile = true
            return status
        }
    }

    /// Returns whether the pipe already reached EOF
    func markExited(_ status: Int32) -> Bool {
        lock.withLock {
            self.status = status
            return isAtEndOfFile
        }
    }

    func claimFinish() -> Bool {
        lock.withLock {
            defer {
                isFinished = true
            }
            return isFinished == false
        }
    }

}

/// Collects stdout and resumes a continuation once, when both the pipe and the process are done
final class DataCollector: @unchecked Sendable {

    // MARK: - Properties
    private let lock = NSLock()
    private var buffer = Data()
    private var isFinished = false
    private var isResumed = false
    private var pending: (() -> Void)?

    // MARK: - Computed properties
    var data: Data {
        lock.withLock { buffer }
    }

    // MARK: - Internal methods
    func append(_ data: Data) {
        lock.withLock {
            buffer.append(data)
        }
    }

    func claimResume() -> Bool {
        lock.withLock {
            defer {
                isResumed = true
            }
            return isResumed == false
        }
    }

    func finishReading() {
        let callback: (() -> Void)? = lock.withLock {
            isFinished = true
            defer {
                pending = nil
            }
            return pending
        }
        callback?()
    }

    /// Runs `body` once the pipe reached EOF: the process may exit before its output is drained
    func whenFinished(_ body: @escaping () -> Void) {
        let runsNow: Bool = lock.withLock {
            guard isFinished == false else {
                return true
            }
            pending = body
            return false
        }
        if runsNow {
            body()
        }
    }

}

private enum Constants {
    static let newline = UInt8(ascii: "\n")
}
