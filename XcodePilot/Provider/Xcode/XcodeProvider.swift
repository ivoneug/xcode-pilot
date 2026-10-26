// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

final class XcodeProvider {

    // MARK: - Properties
    private let xcodeAppService: XcodeAppServiceProtocol
    private let preferencesProvider: PreferencesProviderProtocol

    // MARK: - Init/Deinit
    init(xcodeAppService: XcodeAppServiceProtocol, preferencesProvider: PreferencesProviderProtocol) {
        self.xcodeAppService = xcodeAppService
        self.preferencesProvider = preferencesProvider
    }

}

// MARK: - XcodeProviderProtocol
extension XcodeProvider: XcodeProviderProtocol {

    var isAccessibilityTrusted: Bool {
        xcodeAppService.isAccessibilityTrusted
    }

    var installedXcodes: [URL] {
        xcodeAppService.installedXcodes()
    }

    func activeXcode() async -> URL? {
        await xcodeAppService.activeXcode()
    }

    func open(_ project: ProjectRef) {
        Task { [xcodeAppService] in
            await xcodeAppService.open(project)
        }
    }

    func showInOrganizer(_ archive: ArchiveInfo) {
        Task { [xcodeAppService] in
            await xcodeAppService.showInOrganizer(archive.path)
        }
    }

    func show(_ window: XcodeWindow) async throws {
        try await xcodeAppService.show(window)
    }

    func open(_ issue: BuildIssue) {
        guard let file = issue.file else {
            return
        }
        xcodeAppService.open(file: file, line: issue.line, column: issue.column, editor: preferencesProvider.preferences.editor)
    }

    func reveal(_ path: String) {
        xcodeAppService.reveal(path)
    }

    func openAccessibilitySettings() {
        xcodeAppService.openAccessibilitySettings()
    }

}
