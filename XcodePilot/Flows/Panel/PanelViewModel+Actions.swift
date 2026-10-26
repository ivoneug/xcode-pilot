// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import Foundation

extension PanelViewModel {

    // MARK: - Project
    func openProject() {
        guard let url = ProjectOpenPanel.run() else {
            return
        }
        guard let project = ProjectRef.resolve(url) else {
            alertMessage = Localizations.Project.notAProject(url.lastPathComponent)
            return
        }
        projectProvider.select(project)
    }

    func select(_ project: ProjectRef) {
        guard project.exists else {
            projectProvider.remove(project)
            alertMessage = Localizations.Project.missing(project.displayPath)
            return
        }
        projectProvider.select(project)
    }

    func remove(_ project: ProjectRef) {
        projectProvider.remove(project)
    }

    func selectScheme(_ scheme: String) {
        projectProvider.selectScheme(scheme)
    }

    func selectConfiguration(_ configuration: String?) {
        projectProvider.selectConfiguration(configuration)
    }

    func selectDestination(_ destination: Destination) {
        projectProvider.selectDestination(destination)
    }

    func reloadProject() {
        projectProvider.reload()
    }

    func reloadDestinations() {
        projectProvider.reloadDestinations()
    }

    func openInXcode() {
        guard let project else {
            return
        }
        xcodeProvider.open(project)
    }

    func revealProject() {
        guard let project else {
            return
        }
        xcodeProvider.reveal(project.path)
    }

    // MARK: - Build
    func start(_ action: BuildAction) {
        guard let request = projectProvider.request, isBusy == false else {
            return
        }
        buildProvider.start(action, request: request)
    }

    func stop() {
        if isBusy {
            buildProvider.cancel()
        } else {
            Task { [runProvider] in
                await runProvider.stop()
            }
        }
    }

    func dismissActivity() {
        buildProvider.dismissActivity()
    }

    // MARK: - Issues
    func copy(_ issue: BuildIssue) {
        NSPasteboard.general.copy(issue.copyText)
        showCopiedFeedback(for: issue)
    }

    func copyMessage(of issue: BuildIssue) {
        NSPasteboard.general.copy(issue.message)
        showCopiedFeedback(for: issue)
    }

    func copyLocation(of issue: BuildIssue) {
        guard let location = issue.location else {
            return
        }
        NSPasteboard.general.copy(location)
        showCopiedFeedback(for: issue)
    }

    func copyIssues() {
        NSPasteboard.general.copy(issues.copyText)
    }

    func open(_ issue: BuildIssue) {
        xcodeProvider.open(issue)
    }

    func reveal(_ issue: BuildIssue) {
        guard let file = issue.file else {
            return
        }
        xcodeProvider.reveal(file)
    }

    // MARK: - Log
    func setCompactLog(_ isCompact: Bool) {
        preferencesProvider.update { $0.showsCompactLog = isCompact }
    }

    func copyLog() {
        NSPasteboard.general.copy(logLines.joined(separator: String.lineBreak))
    }

    func openLog() {
        let name = "\(activity?.request.scheme ?? CommonConstants.appName) \(activity?.action.title ?? String.empty).log"
        guard let url = buildProvider.log.writeTemporaryFile(named: name) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Console
    /// Copies the lines the console shows, the filtered out ones stay behind
    func copyConsole() {
        NSPasteboard.general.copy(consoleLines.joined(separator: String.lineBreak))
    }

    func updateConsoleFilter(tokens: [ConsoleFilter.Token], draft: String) {
        var filter = consoleFilter
        filter.tokens = ConsoleFilter.unique(tokens)
        filter.draft = draft
        apply(filter)
    }

    func setConsoleFilterMode(_ mode: ConsoleFilter.Mode) {
        var filter = consoleFilter
        filter.mode = mode
        apply(filter)
    }

    func clearConsoleFilter() {
        updateConsoleFilter(tokens: [], draft: String.empty)
    }

    /// The field goes away with the text typed into it, which stays as a token instead of getting lost
    func commitConsoleFilterDraft() {
        let tokens = consoleFilter.tokens + (ConsoleFilter.Token(parsing: consoleFilter.draft).map { [$0] } ?? [])
        updateConsoleFilter(tokens: tokens, draft: String.empty)
    }

    // MARK: - Archive
    func showInOrganizer(_ archive: ArchiveInfo) {
        xcodeProvider.showInOrganizer(archive)
    }

    func reveal(_ archive: ArchiveInfo) {
        xcodeProvider.reveal(archive.path.path)
    }

    func export(_ archive: ArchiveInfo) {
        navigation.send(.export(archive: archive))
    }

    func revealExport() {
        guard let url = activity?.exportURL else {
            return
        }
        xcodeProvider.reveal(url.path)
    }

    // MARK: - Xcode
    func show(_ window: XcodeWindow) {
        Task { @MainActor [weak self, xcodeProvider] in
            do {
                try await xcodeProvider.show(window)
            } catch {
                self?.alertMessage = error.localizedDescription
            }
        }
    }

    func openAccessibilitySettings() {
        xcodeProvider.openAccessibilitySettings()
    }

    // MARK: - Navigation
    func openSettings() {
        navigation.send(.settings)
    }

    func detach() {
        navigation.send(.detach)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Private methods
    /// Assigned only on a change: every assignment filters the console again
    private func apply(_ filter: ConsoleFilter) {
        guard filter != consoleFilter else {
            return
        }
        consoleFilter = filter
    }

}
