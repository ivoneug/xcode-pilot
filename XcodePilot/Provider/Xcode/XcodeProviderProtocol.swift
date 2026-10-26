// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol XcodeProviderProtocol {

    // MARK: - Properties
    var isAccessibilityTrusted: Bool { get }
    var installedXcodes: [URL] { get }

    // MARK: - Methods
    func activeXcode() async -> URL?
    func open(_ project: ProjectRef)
    func showInOrganizer(_ archive: ArchiveInfo)
    func show(_ window: XcodeWindow) async throws
    /// Opens the issue's file in the editor chosen in the settings
    func open(_ issue: BuildIssue)
    func reveal(_ path: String)
    func openAccessibilitySettings()

}
