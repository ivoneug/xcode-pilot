// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// A command line to execute. A `tool` without a leading slash is resolved through `xcrun`.
struct Command: CustomStringConvertible {

    // MARK: - Properties
    let tool: String
    let arguments: [String]
    let workingDirectory: URL?
    let environment: [String: String]

    // MARK: - Computed properties
    var description: String {
        ([tool] + arguments).map(Self.quote).joined(separator: String.space)
    }

    /// Short name for messages: `xcodebuild -list`
    var title: String {
        let name = URL(fileURLWithPath: tool).lastPathComponent
        guard let first = arguments.first else {
            return name
        }
        return "\(name) \(first)"
    }

    // MARK: - Init/Deinit
    init(_ tool: String, _ arguments: [String], in workingDirectory: URL? = nil, environment: [String: String] = [:]) {
        self.tool = tool
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.environment = environment
    }

    // MARK: - Private methods
    private static func quote(_ argument: String) -> String {
        let safe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_./=:,@+%"))
        if argument.isEmpty == false, argument.unicodeScalars.allSatisfy(safe.contains) {
            return argument
        }
        return "'" + argument.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

}

struct CommandResult {

    // MARK: - Properties
    let status: Int32
    let output: String

    // MARK: - Computed properties
    var succeeded: Bool {
        status == .zero
    }

}

enum ProcessOutput {
    /// A batch of complete lines of the merged stdout and stderr
    case lines([String])
    case exit(status: Int32)
}
