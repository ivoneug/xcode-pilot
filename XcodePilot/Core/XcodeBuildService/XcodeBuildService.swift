// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

final class XcodeBuildService {

    // MARK: - Properties
    private let processService: ProcessServiceProtocol
    private let decoder = JSONDecoder()

    // MARK: - Init/Deinit
    init(processService: ProcessServiceProtocol) {
        self.processService = processService
    }

    // MARK: - Private methods
    /// xcodebuild may print warnings in front of the JSON, the payload starts at its first bracket
    private func decode<Model: Decodable>(_ type: Model.Type, from data: Data, opening: UInt8, command: Command) throws -> Model {
        guard let start = data.firstIndex(of: opening), let model = try? decoder.decode(type, from: data[start...]) else {
            throw PilotError.unreadableOutput(command: command.title)
        }
        return model
    }

    private func configurations(ofWorkspace workspace: ProjectRef) async -> [String] {
        var configurations: [String] = []
        for project in WorkspaceParser.projects(in: workspace) {
            let command = XcodeBuildArguments.list(project)
            guard let data = try? await processService.stdout(command),
                  let info = try? decode(ProjectListResponseDTO.self, from: data, opening: Constants.openingBrace, command: command) else {
                continue
            }
            for configuration in info.convertToPlain().configurations where configurations.contains(configuration) == false {
                configurations.append(configuration)
            }
        }
        return configurations
    }

}

// MARK: - XcodeBuildServiceProtocol
extension XcodeBuildService: XcodeBuildServiceProtocol {

    func projectInfo(_ project: ProjectRef) async throws -> ProjectInfo {
        let command = XcodeBuildArguments.list(project)
        let data = try await processService.stdout(command)
        let info = try decode(ProjectListResponseDTO.self, from: data, opening: Constants.openingBrace, command: command).convertToPlain()
        guard info.configurations.isEmpty else {
            return info
        }

        var configurations: [String] = []
        if project.kind == .workspace {
            configurations = await self.configurations(ofWorkspace: project)
        }
        if configurations.isEmpty {
            configurations = Constants.defaultConfigurations
        }
        return ProjectInfo(schemes: info.schemes, configurations: configurations)
    }

    func destinations(_ project: ProjectRef, scheme: String) async throws -> [Destination] {
        let command = XcodeBuildArguments.destinations(project, scheme: scheme)
        let result = await processService.run(command)
        let destinations = DestinationParser.parse(result.output)
        guard destinations.isEmpty == false || result.succeeded else {
            throw PilotError.commandFailed(command: command.title, status: result.status, output: result.output)
        }
        return destinations
    }

    func runnableProduct(_ request: BuildRequest) async throws -> RunnableProduct {
        let command = XcodeBuildArguments.buildSettings(request)
        let data = try await processService.stdout(command)
        let entries = try decode([BuildSettingsResponseDTO].self, from: data, opening: Constants.openingBracket, command: command)
        let preferredTarget = SchemeFileParser.schemeFile(named: request.scheme, in: request.project)
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
            .flatMap(SchemeFileParser.runnableTarget(in:))
        guard let product = entries.runnableProduct(scheme: request.scheme, preferredTarget: preferredTarget) else {
            throw PilotError.noRunnableProduct(scheme: request.scheme)
        }
        return product
    }

    func start(
        _ action: BuildAction,
        request: BuildRequest,
        resultBundle: URL?,
        archivePath: URL?
    ) -> (AsyncStream<ProcessOutput>, ProcessHandle) {
        processService.stream(XcodeBuildArguments.action(action, request, resultBundle: resultBundle, archivePath: archivePath))
    }

    func exportArchive(
        _ archive: ArchiveInfo,
        method: ExportMethod,
        upload: Bool,
        exportPath: URL
    ) throws -> (AsyncStream<ProcessOutput>, ProcessHandle) {
        let options = method.exportOptions(upload: upload, teamId: archive.teamId)
        let data = try PropertyListSerialization.data(fromPropertyList: options, format: .xml, options: .zero)
        let optionsPlist = FileManager.default.temporaryDirectory.appendingPathComponent("ExportOptions-\(UUID().uuidString).plist")
        try data.write(to: optionsPlist)
        try FileManager.default.createDirectory(at: exportPath, withIntermediateDirectories: true)
        return processService.stream(XcodeBuildArguments.exportArchive(archive.path, exportPath: exportPath, optionsPlist: optionsPlist))
    }

    func buildIssues(resultBundle: URL) async -> [BuildIssue]? {
        guard FileManager.default.fileExists(atPath: resultBundle.path),
              let data = try? await processService.stdout(XcodeBuildArguments.buildResults(resultBundle)),
              let results = try? decoder.decode(BuildResultsResponseDTO.self, from: data) else {
            return nil
        }
        return results.convertToPlain()
    }

    func testSummary(resultBundle: URL) async -> TestSummary? {
        guard FileManager.default.fileExists(atPath: resultBundle.path),
              let data = try? await processService.stdout(XcodeBuildArguments.testSummary(resultBundle)),
              let summary = try? decoder.decode(TestSummaryResponseDTO.self, from: data) else {
            return nil
        }
        return summary.convertToPlain()
    }

    func archiveInfo(at url: URL) -> ArchiveInfo? {
        guard let data = try? Data(contentsOf: url.appendingPathComponent(Constants.infoPlist)),
              let info = try? PropertyListDecoder().decode(ArchiveInfoDTO.self, from: data) else {
            return nil
        }
        // macOS bundles keep their Info.plist under Contents/, the iOS family ones are flat
        let applicationPath = info.applicationProperties?.applicationPath ?? String.empty
        let macInfoPlist = url.appendingPathComponent("Products/\(applicationPath)/Contents/\(Constants.infoPlist)")
        return info.convertToPlain(path: url, isMac: FileManager.default.fileExists(atPath: macInfoPlist.path))
    }

}

private enum Constants {
    static let openingBrace = UInt8(ascii: "{")
    static let openingBracket = UInt8(ascii: "[")
    static let defaultConfigurations = ["Debug", "Release"]
    static let infoPlist = "Info.plist"
}
