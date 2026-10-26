// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Handle to a running child process
final class ProcessHandle {

    // MARK: - Properties
    private let process: Process
    @Protected private(set) var isCancelled = false

    // MARK: - Computed properties
    var isRunning: Bool {
        process.isRunning
    }

    var processIdentifier: Int32 {
        process.processIdentifier
    }

    // MARK: - Init/Deinit
    init(process: Process) {
        self.process = process
    }

    // MARK: - Internal methods
    /// SIGINT lets xcodebuild finish gracefully with "** BUILD INTERRUPTED **", and simctl or
    /// devicectl forward it to the app they launched. A process that lingers is terminated, then killed.
    func cancel(gracePeriod: TimeInterval = Constants.gracePeriod) {
        isCancelled = true
        guard process.isRunning else {
            return
        }
        process.interrupt()
        DispatchQueue.global().asyncAfter(deadline: .now() + gracePeriod) { [process] in
            if process.isRunning {
                process.terminate()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + gracePeriod * 2) { [process] in
            if process.isRunning {
                kill(process.processIdentifier, SIGKILL)
            }
        }
    }

}

private enum Constants {
    static let gracePeriod: TimeInterval = 5
}
