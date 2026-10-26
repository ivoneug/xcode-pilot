// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

final class BuildTaskFormatterTests: XCTestCase {

    // MARK: - Tests
    func testTokenizeHonoursEscapedSpaces() {
        XCTAssertEqual(
            BuildTaskFormatter.tokenize("PhaseScriptExecution Run\\ Script /tmp/My\\ App/Script.sh"),
            ["PhaseScriptExecution", "Run Script", "/tmp/My App/Script.sh"]
        )
    }

    func testTitles() {
        XCTAssertEqual(
            BuildTaskFormatter.title(kind: "CompileC", arguments: ["/tmp/obj/File.o", "/tmp/src/File.m", "normal", "arm64"]),
            Localizations.Task.compiling("File.m")
        )
        XCTAssertEqual(
            BuildTaskFormatter.title(kind: "Ld", arguments: ["/tmp/Build/App.app/App", "normal"]),
            Localizations.Task.linking("App")
        )
        XCTAssertEqual(
            BuildTaskFormatter.title(kind: "PhaseScriptExecution", arguments: ["SwiftLint", "/tmp/Script.sh"]),
            Localizations.Task.runningScript("SwiftLint")
        )
        XCTAssertEqual(
            BuildTaskFormatter.title(kind: "SwiftCompile", arguments: ["normal", "arm64", "Compiling A.swift, B.swift", "/tmp/A.swift"]),
            Localizations.Task.compiling("A.swift")
        )
        XCTAssertEqual(BuildTaskFormatter.title(kind: "WriteAuxiliaryFile", arguments: ["/tmp/file"]), "Write auxiliary file")
        XCTAssertEqual(BuildTaskFormatter.title(kind: "MakeSSUIndex", arguments: []), "Make SSU index")
        XCTAssertEqual(
            BuildTaskFormatter.title(kind: "SwiftCompile", arguments: ["normal", "arm64", "Compiling App.swift", "/tmp/App.swift"]),
            Localizations.Task.compiling("App.swift")
        )
    }

    func testTaskWithoutTargetIsNotATask() {
        XCTAssertNil(BuildTaskFormatter.task(from: "CreateBuildDirectory /tmp/Build/Products"))
    }

}
