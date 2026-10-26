// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// State of one xcodebuild invocation: build, test, clean, archive or export
struct BuildActivity: Identifiable {

    // MARK: - Nested types
    enum Status: Equatable {
        case running
        case succeeded
        case failed
        case cancelled
    }

    // MARK: - Properties
    let id = UUID()
    let action: BuildAction
    let request: BuildRequest
    let startedAt = Date()
    var finishedAt: Date?
    var status: Status = .running
    var step: String?
    var stepTarget: String?
    var taskCount: Int = .zero
    var issues: [BuildIssue] = []
    var failedCommands: [String] = []
    /// Duration of the last successful run of the same kind, the progress is estimated against it
    var expectedDuration: TimeInterval?
    var testSummary: TestSummary?
    var archive: ArchiveInfo?
    var exportURL: URL?
    var isUpload = false

    // MARK: - Computed properties
    var isRunning: Bool {
        status == .running
    }

    var duration: TimeInterval {
        (finishedAt ?? Date()).timeIntervalSince(startedAt)
    }

    var errorCount: Int {
        issues.errorCount
    }

    var warningCount: Int {
        issues.warningCount
    }

    /// Time based estimate, `nil` when there is no previous run to compare with. It never reaches
    /// the end on its own: a build that runs longer than the last one stays just short of done.
    var estimatedProgress: Double? {
        guard isRunning, let expectedDuration, expectedDuration > Constants.minimalExpectedDuration else {
            return nil
        }
        return min(duration / expectedDuration, Constants.maximalEstimatedProgress)
    }

    var title: String {
        switch status {
        case .running:
            return action.progressTitle
        case .succeeded:
            return Localizations.Activity.succeeded(action.noun)
        case .failed:
            return Localizations.Activity.failed(action.noun)
        case .cancelled:
            return Localizations.Activity.cancelled(action.noun)
        }
    }

    // MARK: - Internal methods
    mutating func apply(_ events: [BuildOutputEvent]) {
        for event in events {
            switch event {
            case .task(let task):
                taskCount += 1
                step = task.title
                stepTarget = task.target
            case .phase(let phase):
                step = phase
            case .issue(let issue):
                issues.append(issue)
            case .issueContext(let id, let line):
                if let index = issues.lastIndex(where: { $0.id == id }) {
                    issues[index].context.append(line)
                }
            case .failedCommand(let command):
                failedCommands.append(command)
            case .finished:
                break
            }
        }
    }

}

private enum Constants {
    static let minimalExpectedDuration: TimeInterval = 1
    static let maximalEstimatedProgress = 0.97
}
