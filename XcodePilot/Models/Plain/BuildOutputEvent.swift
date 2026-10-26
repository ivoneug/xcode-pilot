// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// One build system task line, e.g. `SwiftCompile normal arm64 /path/File.swift (in target 'App' from project 'App')`
struct BuildTask: Hashable {

    // MARK: - Properties
    let kind: String
    let title: String
    let target: String?
    let project: String?

}

/// What a line of xcodebuild output means for the build state
enum BuildOutputEvent {
    case task(BuildTask)
    case issue(BuildIssue)
    case issueContext(id: UUID, line: String)
    /// A top level phase such as "Resolve Package Graph"
    case phase(String)
    /// `** BUILD SUCCEEDED **` and friends: the action ("BUILD", "ARCHIVE") and its result ("SUCCEEDED")
    case finished(action: String, result: String)
    /// An entry of "The following build commands failed:"
    case failedCommand(String)
}

/// The events of one line and how it reads in the condensed log
struct ParsedLine {

    // MARK: - Properties
    var events: [BuildOutputEvent] = []
    /// What the condensed log shows for this line, `nil` hides it
    var compact: String?

}
