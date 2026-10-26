// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

final class BuildOutputParserTests: XCTestCase {

    // MARK: - Tests
    func testTaskLineBecomesStep() {
        let parser = BuildOutputParser()
        let parsed = parser.parse("SwiftCompile normal arm64 Compiling\\ App.swift /tmp/App/App.swift (in target 'App' from project 'App')")

        guard case .task(let task) = parsed.events.first else {
            return XCTFail("Expected a task event")
        }
        XCTAssertEqual(task.kind, "SwiftCompile")
        XCTAssertEqual(task.title, Localizations.Task.compiling("App.swift"))
        XCTAssertEqual(task.target, "App")
        XCTAssertEqual(parser.taskCount, 1)
        XCTAssertEqual(parsed.compact, "▸ \(Localizations.Task.compiling("App.swift")) — App")
    }

    func testRepeatedTaskIsShownOnce() {
        let parser = BuildOutputParser()
        let first = parser.parse("SwiftCompile normal arm64 /tmp/App/App.swift (in target 'App' from project 'App')")
        let second = parser.parse("SwiftCompile normal arm64 /tmp/App/App.swift (in target 'App' from project 'App')")

        XCTAssertNotNil(first.compact)
        XCTAssertNil(second.compact)
        XCTAssertEqual(parser.taskCount, 2)
    }

    func testReadableDuration() {
        XCTAssertEqual(TimeInterval(5.7).readableDuration, "0:05")
        XCTAssertEqual(TimeInterval(155).readableDuration, "2:35")
        XCTAssertEqual(TimeInterval(3849).readableDuration, "1:04:09")
    }

    func testCompilerErrorWithExcerpt() {
        let issues = parseIssues([
            "/tmp/App/Broken.swift:5:22: error: cannot convert value of type 'String' to specified type 'Int'",
            "        let x: Int = \"string\"",
            "                     ^~~~~~~~",
            "/tmp/App/Broken.swift:6:9: error: cannot find 'undefinedFunction' in scope",
            "        undefinedFunction()",
            "        ^~~~~~~~~~~~~~~~~",
            String.empty,
            "Failed frontend command:",
            "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -c"
        ])

        XCTAssertEqual(issues.count, 2)
        XCTAssertEqual(issues[0].severity, .error)
        XCTAssertEqual(issues[0].file, "/tmp/App/Broken.swift")
        XCTAssertEqual(issues[0].line, 5)
        XCTAssertEqual(issues[0].column, 22)
        XCTAssertEqual(issues[0].message, "cannot convert value of type 'String' to specified type 'Int'")
        XCTAssertEqual(issues[0].context, ["        let x: Int = \"string\"", "                     ^~~~~~~~"])
        XCTAssertEqual(issues[1].line, 6)
        XCTAssertEqual(issues[1].context.count, 2)
    }

    func testDuplicateIssueIsDroppedWithItsExcerpt() {
        let line = "/tmp/App/View.swift:10:5: warning: variable 'x' was never used"
        let issues = parseIssues([line, "    var x = 1", String.empty, line, "    var x = 1", String.empty])

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0].severity, .warning)
        XCTAssertEqual(issues[0].context, ["    var x = 1"])
    }

    func testNoteIsAttachedToThePreviousIssue() {
        let issues = parseIssues([
            "/tmp/App/A.swift:3:1: error: invalid redeclaration of 'foo()'",
            "/tmp/App/A.swift:1:6: note: 'foo()' previously declared here"
        ])

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0].context, ["/tmp/App/A.swift:1:6: note: 'foo()' previously declared here"])
    }

    func testBuildSystemErrorTakesTargetFromSuffix() {
        let issues = parseIssues([
            "/tmp/App/App.xcodeproj: error: Signing for \"App\" requires a development team. (in target 'App' from project 'App')"
        ])

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0].file, "/tmp/App/App.xcodeproj")
        XCTAssertNil(issues[0].line)
        XCTAssertEqual(issues[0].target, "App")
        XCTAssertEqual(issues[0].message, "Signing for \"App\" requires a development team.")
    }

    func testToolErrors() {
        let issues = parseIssues([
            "xcodebuild: error: The project named \"Foo\" does not contain a scheme named \"Bar\".",
            "ld: symbol(s) not found for architecture arm64",
            "clang: error: linker command failed with exit code 1 (use -v to see invocation)"
        ])

        XCTAssertEqual(issues.map(\.message), [
            "The project named \"Foo\" does not contain a scheme named \"Bar\".",
            "ld: symbol(s) not found for architecture arm64",
            "clang: linker command failed with exit code 1 (use -v to see invocation)"
        ])
    }

    func testFreeStandingNotesAndSourceTextAreNotIssues() {
        let issues = parseIssues([
            "note: Building targets in dependency order",
            "    print(\"error: this is source code\")",
            "SwiftCompile normal arm64 /tmp/App/ErrorView.swift (in target 'App' from project 'App')"
        ])

        XCTAssertTrue(issues.isEmpty)
    }

    func testSummaryAndFailedCommands() {
        let parser = BuildOutputParser()
        var events: [BuildOutputEvent] = []
        for line in [
            "** BUILD FAILED **",
            String.empty,
            "The following build commands failed:",
            "\tSwiftCompile normal arm64 /tmp/App/Broken.swift (in target 'App' from project 'App')",
            "\tBuilding project App with scheme App",
            "(2 failures)"
        ] {
            events += parser.parse(line).events
        }

        var finished: (String, String)?
        var failed: [String] = []
        for event in events {
            switch event {
            case .finished(let action, let result):
                finished = (action, result)
            case .failedCommand(let command):
                failed.append(command)
            default:
                break
            }
        }
        XCTAssertEqual(finished?.0, "BUILD")
        XCTAssertEqual(finished?.1, "FAILED")
        XCTAssertEqual(failed.count, 2)
    }

    func testCondensedLogHidesCommandDumps() {
        let parser = BuildOutputParser()
        let hidden = [
            "    cd /tmp/App",
            "    builtin-swiftTaskExecution -- /usr/bin/swift-frontend -c",
            "Command line invocation:",
            "2026-10-26 13:01:25.073 xcodebuild[33991:1892634] [MT] IDERunDestination: Supported platforms"
        ]
        for line in hidden {
            XCTAssertNil(parser.parse(line).compact, line)
        }
        XCTAssertNotNil(parser.parse("** BUILD SUCCEEDED **").compact)
    }

    // MARK: - Private methods
    private func parseIssues(_ lines: [String]) -> [BuildIssue] {
        let parser = BuildOutputParser()
        var activity = BuildActivity(action: .build, request: TestData.request)
        for line in lines {
            activity.apply(parser.parse(line).events)
        }
        return activity.issues
    }

}
