// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

final class XcodeBuildArgumentsTests: XCTestCase {

    // MARK: - Tests
    func testBuildForSimulatorSkipsProvisioning() {
        let resultBundle = URL(fileURLWithPath: "/tmp/r.xcresult")
        let command = XcodeBuildArguments.action(.build, TestData.request, resultBundle: resultBundle, archivePath: nil)

        XCTAssertEqual(command.tool, "xcodebuild")
        XCTAssertEqual(command.arguments, [
            "build", "-project", "/tmp/App/App.xcodeproj", "-scheme", "App",
            "-destination", "id=8E1492DC-A05C-4D48-B31A-097101291DEB",
            "-resultBundlePath", "/tmp/r.xcresult"
        ])
        XCTAssertEqual(command.workingDirectory?.path, "/tmp/App")
    }

    func testArchiveUsesGenericDestinationAndProvisioning() {
        var request = BuildRequest(project: TestData.project, scheme: "App", configuration: "Release", destination: TestData.simulator)
        request.skipMacroValidation = true
        let archivePath = URL(fileURLWithPath: "/tmp/App.xcarchive")
        let command = XcodeBuildArguments.action(.archive, request, resultBundle: nil, archivePath: archivePath)

        XCTAssertTrue(command.arguments.starts(with: ["archive"]))
        XCTAssertTrue(command.arguments.contains("generic/platform=iOS"))
        XCTAssertTrue(command.arguments.contains("Release"))
        XCTAssertTrue(command.arguments.contains("/tmp/App.xcarchive"))
        XCTAssertTrue(command.arguments.contains("-allowProvisioningUpdates"))
        XCTAssertTrue(command.arguments.contains("-skipMacroValidation"))
    }

    func testPackageRunsInItsDirectory() {
        let package = ProjectRef(path: "/tmp/Package", kind: .package)

        let command = XcodeBuildArguments.list(package)

        XCTAssertEqual(command.arguments, ["-list", "-json"])
        XCTAssertEqual(command.workingDirectory?.path, "/tmp/Package")
    }

    func testExportOptions() {
        let options = ExportMethod.appStoreConnect.exportOptions(upload: true, teamId: "TEAM")

        XCTAssertEqual(options["method"] as? String, "app-store-connect")
        XCTAssertEqual(options["destination"] as? String, "upload")
        XCTAssertEqual(options["teamID"] as? String, "TEAM")
        XCTAssertEqual(ExportMethod.debugging.exportOptions(upload: true, teamId: nil)["destination"] as? String, "export")
    }

}
