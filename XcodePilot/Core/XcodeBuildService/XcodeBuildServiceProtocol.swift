// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol XcodeBuildServiceProtocol {
    /**
     Schemes and build configurations of a project. A workspace reports no configurations, so they
     are collected from the projects it references.
     - Parameter project: Project, workspace or package
     */
    func projectInfo(_ project: ProjectRef) async throws -> ProjectInfo
    /**
     Run destinations the scheme can be built for
     - Parameter project: Project, workspace or package
     - Parameter scheme: Scheme name
     */
    func destinations(_ project: ProjectRef, scheme: String) async throws -> [Destination]
    /**
     The product Run launches for the request, read from the build settings
     - Parameter request: What is going to be built
     */
    func runnableProduct(_ request: BuildRequest) async throws -> RunnableProduct
    /**
     Starts an xcodebuild action
     - Parameter action: Build, test, clean or archive
     - Parameter request: What to build
     - Parameter resultBundle: Where xcodebuild writes the `.xcresult` bundle
     - Parameter archivePath: Where the archive goes, for `.archive`
     - Returns: Output stream and process handle
     */
    func start(
        _ action: BuildAction,
        request: BuildRequest,
        resultBundle: URL?,
        archivePath: URL?
    ) -> (AsyncStream<ProcessOutput>, ProcessHandle)
    /**
     Starts exporting or uploading an archive
     - Parameter archive: The archive
     - Parameter method: Distribution method
     - Parameter upload: Upload to App Store Connect instead of exporting a file
     - Parameter exportPath: Folder the exported product is written to
     */
    func exportArchive(
        _ archive: ArchiveInfo,
        method: ExportMethod,
        upload: Bool,
        exportPath: URL
    ) throws -> (AsyncStream<ProcessOutput>, ProcessHandle)
    /**
     Errors and warnings stored in a result bundle, `nil` if it can't be read
     */
    func buildIssues(resultBundle: URL) async -> [BuildIssue]?
    /**
     Test results stored in a result bundle, `nil` if it can't be read
     */
    func testSummary(resultBundle: URL) async -> TestSummary?
    /**
     Reads an archive's metadata
     */
    func archiveInfo(at url: URL) -> ArchiveInfo?
}
