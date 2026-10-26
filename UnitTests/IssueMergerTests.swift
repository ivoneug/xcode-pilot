// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

final class IssueMergerTests: XCTestCase {

    // MARK: - Tests
    func testBundleIssuesKeepTheLiveExcerpt() {
        let live = [
            BuildIssue(severity: .error, message: "cannot find 'x' in scope", file: "/tmp/A.swift", line: 3, column: 5, context: ["x = 1"])
        ]
        let bundle = [BuildIssue(severity: .error, message: "Cannot find 'x' in scope", file: "/tmp/A.swift", line: 3, column: nil)]

        let merged = IssueMerger.merge(live: live, bundle: bundle)

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].message, "Cannot find 'x' in scope")
        XCTAssertEqual(merged[0].context, ["x = 1"])
        XCTAssertEqual(merged[0].column, 5)
    }

    func testLiveIssuesStayWithoutBundleIssues() {
        let live = [BuildIssue(severity: .error, message: "ld: library not found")]

        XCTAssertEqual(IssueMerger.merge(live: live, bundle: []).map(\.message), ["ld: library not found"])
    }

    func testCopyTextIsClangStyle() {
        let issue = BuildIssue(severity: .warning, message: "unused", file: "/tmp/A.swift", line: 3, column: 5, context: ["  var a = 1"])

        XCTAssertEqual(issue.copyText, "/tmp/A.swift:3:5: warning: unused\n  var a = 1")
    }

}
