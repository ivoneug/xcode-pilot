// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol XcodeAppServiceProtocol {
    /**
     Whether the app may drive other apps' menus through the Accessibility API
     */
    var isAccessibilityTrusted: Bool { get }
    /**
     Asks the system to show the Accessibility permission prompt
     */
    func requestAccessibility()
    /**
     Opens Privacy & Security → Accessibility in System Settings
     */
    func openAccessibilitySettings()
    /**
     Xcode bundles found in /Applications and ~/Applications
     */
    func installedXcodes() -> [URL]
    /**
     The Xcode.app builds use: the selected developer directory, or the one of `xcode-select`
     */
    func activeXcode() async -> URL?
    /**
     Projects Xcode opened recently, most recent first, from the per-workspace DerivedData folders
     - Parameter limit: Maximal count
     */
    func recentProjects(limit: Int) -> [ProjectRef]
    /**
     Opens the project in Xcode
     */
    func open(_ project: ProjectRef) async
    /**
     Opens the archive with Xcode, which imports it and shows it in the Organizer
     */
    func showInOrganizer(_ archive: URL) async
    /**
     Opens a window that is only reachable through Xcode's Window menu, launching Xcode if needed
     */
    func show(_ window: XcodeWindow) async throws
    /**
     Opens a source file at a location in the chosen editor
     */
    func open(file: String, line: Int?, column: Int?, editor: EditorChoice)
    /**
     Selects the file in Finder
     */
    func reveal(_ path: String)
    /**
     Brings a running app to the front
     - Parameter processIdentifier: PID of the app
     */
    func activate(processIdentifier: Int32)
}
