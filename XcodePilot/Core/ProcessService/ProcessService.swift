// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

final class ProcessService {

    // MARK: - Properties
    @Protected var developerDirectory: String?

    // MARK: - Private methods
    /// GUI apps start with a minimal PATH: Homebrew is added so build phases find SwiftLint & co.
    /// Output is unbuffered, otherwise xcodebuild prints in large delayed chunks into a pipe.
    private func environment(for command: Command) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        var path = (environment[Constants.pathKey] ?? Constants.defaultPath).split(separator: ":").map(String.init)
        for extra in Constants.extraPaths where path.contains(extra) == false {
            path.append(extra)
        }
        environment[Constants.pathKey] = path.joined(separator: ":")
        environment[Constants.unbufferedKey] = "YES"
        if let developerDirectory, developerDirectory.isEmpty == false {
            environment[Constants.developerDirKey] = developerDirectory
        } else {
            environment.removeValue(forKey: Constants.developerDirKey)
        }
        return environment.merging(command.environment) { _, new in new }
    }

    private func makeProcess(_ command: Command) -> Process {
        let process = Process()
        if command.tool.hasPrefix("/") {
            process.executableURL = URL(fileURLWithPath: command.tool)
            process.arguments = command.arguments
        } else {
            process.executableURL = URL(fileURLWithPath: Constants.xcrun)
            process.arguments = [command.tool] + command.arguments
        }
        if let workingDirectory = command.workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }
        process.environment = environment(for: command)
        process.standardInput = FileHandle.nullDevice
        return process
    }

}

// MARK: - ProcessServiceProtocol
extension ProcessService: ProcessServiceProtocol {

    func stream(_ command: Command) -> (AsyncStream<ProcessOutput>, ProcessHandle) {
        let process = makeProcess(command)
        let handle = ProcessHandle(process: process)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let (stream, continuation) = AsyncStream<ProcessOutput>.makeStream(bufferingPolicy: .unbounded)
        let splitter = LineSplitter()
        let state = StreamState()
        let reader = pipe.fileHandleForReading

        let finish: (Int32) -> Void = { status in
            guard state.claimFinish() else {
                return
            }
            reader.readabilityHandler = nil
            let rest = splitter.flush()
            if rest.isEmpty == false {
                continuation.yield(.lines(rest))
            }
            continuation.yield(.exit(status: status))
            continuation.finish()
        }

        reader.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            guard data.isEmpty == false else {
                if let status = state.markEndOfFile() {
                    finish(status)
                }
                return
            }
            let lines = splitter.append(data)
            if lines.isEmpty == false {
                continuation.yield(.lines(lines))
            }
        }

        process.terminationHandler = { process in
            let status = process.terminationStatus
            if state.markExited(status) {
                finish(status)
            } else {
                // A grandchild (a build daemon) may keep the pipe open, the stream doesn't wait for it
                DispatchQueue.global().asyncAfter(deadline: .now() + Constants.pipeDrainTimeout) {
                    finish(status)
                }
            }
        }

        do {
            try process.run()
        } catch {
            reader.readabilityHandler = nil
            continuation.yield(.lines([Localizations.Error.launchFailed(command.tool, error.localizedDescription)]))
            continuation.yield(.exit(status: Constants.launchFailureStatus))
            continuation.finish()
            return (stream, handle)
        }
        // The child owns the write end now; closing ours lets EOF arrive once it exits
        try? pipe.fileHandleForWriting.close()

        continuation.onTermination = { reason in
            if case .cancelled = reason {
                handle.cancel()
            }
        }
        return (stream, handle)
    }

    func run(_ command: Command) async -> CommandResult {
        let (stream, _) = stream(command)
        var lines: [String] = []
        var status = Constants.launchFailureStatus
        for await output in stream {
            switch output {
            case .lines(let batch):
                lines.append(contentsOf: batch)
            case .exit(let code):
                status = code
            }
        }
        return CommandResult(status: status, output: lines.joined(separator: "\n"))
    }

    @discardableResult
    func check(_ command: Command) async throws -> String {
        let result = await run(command)
        guard result.succeeded else {
            throw PilotError.commandFailed(command: command.title, status: result.status, output: result.output)
        }
        return result.output
    }

    func stdout(_ command: Command) async throws -> Data {
        let process = makeProcess(command)
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        let collector = DataCollector()

        return try await withCheckedThrowingContinuation { continuation in
            output.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if data.isEmpty {
                    fileHandle.readabilityHandler = nil
                    collector.finishReading()
                } else {
                    collector.append(data)
                }
            }
            process.terminationHandler = { process in
                let status = process.terminationStatus
                let complete: @Sendable () -> Void = {
                    guard collector.claimResume() else {
                        return
                    }
                    guard status == .zero else {
                        let text = String(decoding: collector.data, as: UTF8.self)
                        continuation.resume(throwing: PilotError.commandFailed(command: command.title, status: status, output: text))
                        return
                    }
                    continuation.resume(returning: collector.data)
                }
                collector.whenFinished(complete)
                DispatchQueue.global().asyncAfter(deadline: .now() + Constants.pipeDrainTimeout, execute: complete)
            }
            do {
                try process.run()
                try? output.fileHandleForWriting.close()
            } catch {
                output.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }

}

private enum Constants {
    static let xcrun = "/usr/bin/xcrun"
    static let pathKey = "PATH"
    static let unbufferedKey = "NSUnbufferedIO"
    static let developerDirKey = "DEVELOPER_DIR"
    static let defaultPath = "/usr/bin:/bin:/usr/sbin:/sbin"
    static let extraPaths = ["/opt/homebrew/bin", "/usr/local/bin"]
    static let pipeDrainTimeout: TimeInterval = 2
    static let launchFailureStatus: Int32 = -1
}
