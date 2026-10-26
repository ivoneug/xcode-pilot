// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension BuildResultsResponseDTO {

    // MARK: - Internal methods
    func convertToPlain() -> [BuildIssue] {
        let errors = (errors ?? []).map { $0.convertToPlain(severity: .error) }
        let warnings = (warnings ?? []).map { $0.convertToPlain(severity: .warning) }
        let analyzerWarnings = (analyzerWarnings ?? []).map { $0.convertToPlain(severity: .warning) }
        return errors + warnings + analyzerWarnings
    }

}

extension BuildResultsResponseDTO.Issue {

    // MARK: - Internal methods
    func convertToPlain(severity: BuildIssue.Severity) -> BuildIssue {
        var issue = BuildIssue(severity: severity, message: message, target: targetName, category: issueType)
        if let location = sourceURL.flatMap(Self.parseLocation) {
            issue.file = location.file
            issue.line = location.line
            issue.column = location.column
        }
        return issue
    }

    // MARK: - Private methods
    /// Line and column numbers in the fragment are zero based
    private static func parseLocation(_ raw: String) -> (file: String, line: Int?, column: Int?)? {
        guard let components = URLComponents(string: raw), components.scheme == Constants.fileScheme else {
            return nil
        }
        let path = components.percentEncodedPath.removingPercentEncoding ?? components.path
        guard path.isEmpty == false else {
            return nil
        }

        var values: [String: Int] = [:]
        for pair in (components.fragment ?? String.empty).split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2, let value = Int(parts[1]) {
                values[String(parts[0])] = value
            }
        }
        return (path, values[Constants.startingLine].map { $0 + 1 }, values[Constants.startingColumn].map { $0 + 1 })
    }

}

private enum Constants {
    static let fileScheme = "file"
    static let startingLine = "StartingLineNumber"
    static let startingColumn = "StartingColumnNumber"
}
