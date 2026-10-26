// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

final class ProjectRefTests: XCTestCase {

    // MARK: - Properties
    private var directory: URL?

    // MARK: - Lifecycle
    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.directory = directory
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        try super.tearDownWithError()
    }

    // MARK: - Tests
    func testFolderPrefersWorkspaceOverProject() throws {
        let directory = try XCTUnwrap(directory)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("App.xcodeproj"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("App.xcworkspace"), withIntermediateDirectories: true)

        let project = ProjectRef.resolve(directory)

        XCTAssertEqual(project?.kind, .workspace)
        XCTAssertEqual(project?.name, "App")
    }

    func testEmbeddedWorkspaceMeansTheProject() {
        let project = ProjectRef.resolve(URL(fileURLWithPath: "/tmp/App/App.xcodeproj/project.xcworkspace"))

        XCTAssertEqual(project?.kind, .project)
        XCTAssertEqual(project?.path, "/tmp/App/App.xcodeproj")
    }

    func testPackageManifest() throws {
        let directory = try XCTUnwrap(directory)
        let manifest = directory.appendingPathComponent("Package.swift")
        try Data().write(to: manifest)

        XCTAssertEqual(ProjectRef.resolve(manifest)?.kind, .package)
        XCTAssertEqual(ProjectRef.resolve(directory)?.kind, .package)
        XCTAssertEqual(ProjectRef.resolve(directory)?.xcodebuildArguments, [])
    }

    func testSchemeRunnableTarget() {
        let xml = """
        <Scheme>
           <BuildAction><BuildActionEntries><BuildableReference BlueprintName = "Core"/></BuildActionEntries></BuildAction>
           <LaunchAction buildConfiguration = "Debug">
              <BuildableProductRunnable runnableDebuggingMode = "0">
                 <BuildableReference BuildableIdentifier = "primary" BlueprintName = "App" BuildableName = "App.app"/>
              </BuildableProductRunnable>
           </LaunchAction>
        </Scheme>
        """

        XCTAssertEqual(SchemeFileParser.runnableTarget(in: xml), "App")
    }

}
