// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol ProcessServiceProtocol: AnyObject {
    /**
     `Contents/Developer` of the Xcode child processes use, `nil` follows `xcode-select`
     */
    var developerDirectory: String? { get set }
    /**
     Starts the command and streams its merged stdout and stderr
     - Parameter command: Command to run
     - Returns: Batches of complete lines followed by the exit status, and a handle to cancel the process
     */
    func stream(_ command: Command) -> (AsyncStream<ProcessOutput>, ProcessHandle)
    /**
     Runs the command to completion
     - Parameter command: Command to run
     - Returns: Exit status and merged output
     */
    func run(_ command: Command) async -> CommandResult
    /**
     Runs the command to completion and fails on a non-zero exit status
     - Parameter command: Command to run
     - Returns: Merged output
     */
    @discardableResult
    func check(_ command: Command) async throws -> String
    /**
     Runs the command to completion and returns its stdout only, for commands printing JSON
     - Parameter command: Command to run
     - Returns: Raw stdout
     */
    func stdout(_ command: Command) async throws -> Data
}
