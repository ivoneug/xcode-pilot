// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import UniformTypeIdentifiers

/// Picks a project, a workspace, a package manifest or a folder containing one of them
enum ProjectOpenPanel {

    // MARK: - Internal methods
    @MainActor
    static func run() -> URL? {
        let panel = NSOpenPanel()
        panel.title = Localizations.Project.OpenPanel.title
        panel.prompt = Localizations.Project.OpenPanel.prompt
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        // Bundles are picked as a whole instead of being browsed into
        panel.treatsFilePackagesAsDirectories = false
        // A menu bar app has to come forward, otherwise the panel opens behind the frontmost app
        NSApp.activate(ignoringOtherApps: true)
        return panel.runModal() == .OK ? panel.url : nil
    }

}
