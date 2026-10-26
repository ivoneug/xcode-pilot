// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Incremental, line oriented parser of `xcodebuild` output.
///
/// It keeps state between lines (the issue the compiler excerpt below belongs to, the failed
/// commands section), so feed it the lines of one build in order and from a single task.
final class BuildOutputParser {

    // MARK: - Properties
    private(set) var taskCount: Int = .zero
    private var seenIssues: Set<String> = []
    private var currentIssueId: UUID?
    private var contextLineCount: Int = .zero
    /// Set while skipping the excerpt of an issue that turned out to be a duplicate
    private var isSwallowingContext = false
    private var isInFailedCommands = false
    private var isSkippingNextLine = false
    private var currentTarget: String?
    /// xcodebuild often prints the same step twice in a row (the batch and the file of a compile,
    /// repeated build system phases); one line is enough to read
    private var lastSummary: String?

    // MARK: - Internal methods
    func parse(_ line: String) -> ParsedLine {
        if isSkippingNextLine {
            isSkippingNextLine = false
            return ParsedLine()
        }

        guard line.isEmpty == false else {
            endContext()
            isInFailedCommands = false
            return ParsedLine()
        }

        if let parsed = parseSummary(line) {
            return parsed
        }

        if let parsed = parseDiagnostic(line) {
            return parsed
        }

        let isIndented = line.first == " " || line.first == "\t"

        if isIndented == false, let task = BuildTaskFormatter.task(from: line) {
            endContext()
            taskCount += 1
            currentTarget = task.target
            let suffix = task.target.map { " — \($0)" } ?? String.empty
            let summary = "▸ \(task.title)\(suffix)"
            defer {
                lastSummary = summary
            }
            let isHidden = summary == lastSummary || BuildTaskFormatter.isBookkeeping(task.kind)
            return ParsedLine(events: [.task(task)], compact: isHidden ? nil : summary)
        }

        if currentIssueId != nil || isSwallowingContext, contextLineCount < Constants.maximalContextLines {
            contextLineCount += 1
            guard isSwallowingContext == false, let id = currentIssueId else {
                return ParsedLine()
            }
            return ParsedLine(events: [.issueContext(id: id, line: line)], compact: line)
        }

        guard isIndented == false, BuildTaskFormatter.isNoise(line) == false else {
            return ParsedLine()
        }

        if let phase = BuildTaskFormatter.phaseTitle(for: line) {
            // Package fetches name what is fetched, the build system phases read better translated
            let isPackageLine = line.hasPrefix("Fetching") || line.hasPrefix("Cloning") || line.hasPrefix("Checking out")
            let summary = isPackageLine ? line : "▸ \(phase)"
            defer {
                lastSummary = summary
            }
            return ParsedLine(events: [.phase(phase)], compact: summary == lastSummary ? nil : summary)
        }
        return ParsedLine(compact: line)
    }

    // MARK: - Private methods
    /// Final status banners, the failed commands section and the command dumps around it
    private func parseSummary(_ line: String) -> ParsedLine? {
        if isInFailedCommands {
            guard line.hasPrefix("\t") else {
                isInFailedCommands = false
                return nil
            }
            let command = line.trimmingCharacters(in: .whitespaces)
            return ParsedLine(events: [.failedCommand(command)], compact: "    " + command)
        }

        if line.hasPrefix(Constants.bannerPrefix), line.hasSuffix(Constants.bannerSuffix) {
            endContext()
            let words = line.dropFirst(Constants.bannerPrefix.count).dropLast(Constants.bannerSuffix.count).split(separator: " ")
            let result = words.last.map(String.init) ?? String.empty
            let action = words.dropLast().joined(separator: String.space)
            return ParsedLine(events: [.finished(action: action, result: result)], compact: line)
        }

        if line == Constants.failedCommandsHeader {
            endContext()
            isInFailedCommands = true
            return ParsedLine(compact: line)
        }

        if Constants.commandDumpHeaders.contains(line) {
            endContext()
            isSkippingNextLine = true
            return ParsedLine()
        }
        return nil
    }

    private func parseDiagnostic(_ line: String) -> ParsedLine? {
        guard line.contains("error") || line.contains("warning") || line.contains("note:")
            || line.hasPrefix(Constants.linkerPrefix) || line.hasPrefix(Constants.undefinedSymbols) else {
            return nil
        }

        if let match = line.wholeMatch(of: Constants.locatedDiagnostic) {
            let file = String(match.1)
            // "warning: something: 12: foo" style text is not a location
            if file.hasPrefix("/") || file.hasPrefix("~") || file.contains(String.dot) {
                let kind = String(match.4)
                guard kind != "note", kind != "remark" else {
                    return note(line)
                }
                return makeIssue(
                    severity: kind == "warning" ? .warning : .error,
                    message: String(match.5),
                    file: file,
                    line: Int(match.2),
                    column: match.3.flatMap { Int($0) },
                    compact: line
                )
            }
        }

        if let match = line.wholeMatch(of: Constants.fileDiagnostic) {
            return makeIssue(
                severity: match.2 == "warning" ? .warning : .error,
                message: String(match.3),
                file: String(match.1),
                compact: line
            )
        }

        if let match = line.wholeMatch(of: Constants.toolDiagnostic) {
            let kind = String(match.2)
            guard kind != "note" else {
                return note(line)
            }
            var message = String(match.3)
            if let tool = match.1.map(String.init), Constants.silentTools.contains(tool) == false {
                message = "\(tool): \(message)"
            }
            return makeIssue(severity: kind == "warning" ? .warning : .error, message: message, compact: line)
        }

        let isLinkerError = line.hasPrefix(Constants.linkerPrefix) && line.hasPrefix(Constants.linkerWarningPrefix) == false
        if isLinkerError || line.hasPrefix(Constants.undefinedSymbols) {
            return makeIssue(severity: .error, message: line, compact: line)
        }
        return nil
    }

    private func note(_ line: String) -> ParsedLine {
        guard let id = currentIssueId else {
            // Free standing notes ("note: Building targets in dependency order") are noise
            return ParsedLine()
        }
        return ParsedLine(events: [.issueContext(id: id, line: line)], compact: line)
    }

    private func makeIssue(
        severity: BuildIssue.Severity,
        message: String,
        file: String? = nil,
        line: Int? = nil,
        column: Int? = nil,
        compact: String
    ) -> ParsedLine {
        var message = message
        var target = currentTarget
        // Build system errors end with "(in target 'App' from project 'App')"
        if let match = message.firstMatch(of: Constants.targetSuffix) {
            target = String(match.1)
            message = String(message[..<match.range.lowerBound])
        }

        let issue = BuildIssue(severity: severity, message: message, file: file, line: line, column: column, target: target)
        contextLineCount = .zero
        guard seenIssues.insert(issue.dedupeKey).inserted else {
            currentIssueId = nil
            isSwallowingContext = true
            return ParsedLine()
        }

        isSwallowingContext = false
        currentIssueId = issue.id
        return ParsedLine(events: [.issue(issue)], compact: compact)
    }

    private func endContext() {
        currentIssueId = nil
        isSwallowingContext = false
        contextLineCount = .zero
    }

}

private enum Constants {
    static let maximalContextLines = 20
    static let bannerPrefix = "** "
    static let bannerSuffix = " **"
    static let failedCommandsHeader = "The following build commands failed:"
    static let commandDumpHeaders: Set<String> = ["Failed frontend command:", "Failed command:"]
    static let linkerPrefix = "ld: "
    static let linkerWarningPrefix = "ld: warning"
    static let undefinedSymbols = "Undefined symbols"
    /// Tools whose name adds nothing to the message
    static let silentTools: Set<String> = ["xcodebuild", "error", "warning"]
    static let locatedDiagnostic = #/(.+?):(\d+):(?:(\d+):)? (fatal error|error|warning|note|remark): (.*)/#
    static let fileDiagnostic = #/(/[^:]+): (?:fatal )?(error|warning): (.*)/#
    static let toolDiagnostic = #/(?:([A-Za-z][\w.\-]*): )?(fatal error|error|warning|note): (.*)/#
    static let targetSuffix = #/ \(in target '(.*)' from project '.*'\)$/#
}
