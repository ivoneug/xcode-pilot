// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit

/// The menu the menu bar item shows on right click: the main actions without opening the panel
@MainActor
final class StatusMenuBuilder {

    // MARK: - Properties
    private let viewModel: StatusBarViewModel

    // MARK: - Init/Deinit
    init(viewModel: StatusBarViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Internal methods
    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        if let project = viewModel.project {
            let summary = [project.name, viewModel.scheme, viewModel.destination?.displayName].compactMap { $0 }
            menu.addItem(header(summary.joined(separator: " · ")))
        }
        addActions(to: menu)
        menu.addItem(.separator())
        addSelection(to: menu)
        menu.addItem(.separator())
        addXcodeItems(to: menu)
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: Localizations.Menu.showPanel, symbolName: "macwindow") { [viewModel] in
            viewModel.showPanel()
        })
        menu.addItem(ClosureMenuItem(title: Localizations.Menu.quit, keyEquivalent: "q") { [viewModel] in
            viewModel.quit()
        })
        return menu
    }

    // MARK: - Private methods
    private func addActions(to menu: NSMenu) {
        let run = actionItem(.run, hotKey: .run)
        run.isEnabled = viewModel.canRun
        menu.addItem(run)
        for action in [BuildAction.build, .test, .clean, .archive] {
            let item = actionItem(action, hotKey: action == .build ? .build : nil)
            item.isEnabled = viewModel.canStart
            menu.addItem(item)
        }
        let stop = ClosureMenuItem(title: Localizations.Action.stop, symbolName: "stop.fill") { [viewModel] in
            viewModel.stop()
        }
        apply(.stop, to: stop)
        stop.isEnabled = viewModel.isBusy || viewModel.isAppRunning
        menu.addItem(stop)
    }

    private func addSelection(to menu: NSMenu) {
        let projects = NSMenu()
        for project in viewModel.recentProjects {
            let item = ClosureMenuItem(title: project.name, symbolName: project.symbolName) { [viewModel] in
                viewModel.select(project)
            }
            item.toolTip = project.displayPath
            item.state = project == viewModel.project ? .on : .off
            projects.addItem(item)
        }
        menu.addItem(submenu(Localizations.Menu.project, items: projects))

        let schemes = NSMenu()
        for scheme in viewModel.schemes {
            let item = ClosureMenuItem(title: scheme) { [viewModel] in
                viewModel.selectScheme(scheme)
            }
            item.state = scheme == viewModel.scheme ? .on : .off
            schemes.addItem(item)
        }
        menu.addItem(submenu(Localizations.Menu.scheme, items: schemes))

        let destinations = NSMenu()
        for (index, group) in viewModel.destinationGroups.enumerated() {
            if index > .zero {
                destinations.addItem(.separator())
            }
            destinations.addItem(header(group.title))
            for destination in group.destinations {
                let item = ClosureMenuItem(title: destination.displayName, symbolName: destination.symbolName) { [viewModel] in
                    viewModel.selectDestination(destination)
                }
                item.state = viewModel.destination?.matches(destination) == true ? .on : .off
                destinations.addItem(item)
            }
        }
        menu.addItem(submenu(Localizations.Menu.destination, items: destinations))
    }

    private func addXcodeItems(to menu: NSMenu) {
        if viewModel.lastArchive != nil {
            menu.addItem(ClosureMenuItem(title: Localizations.Archive.showInOrganizer, symbolName: "archivebox") { [viewModel] in
                viewModel.showLastArchiveInOrganizer()
            })
        }
        let openProject = ClosureMenuItem(title: Localizations.Menu.openInXcode, symbolName: "hammer") { [viewModel] in
            viewModel.openInXcode()
        }
        openProject.isEnabled = viewModel.project != nil
        menu.addItem(openProject)
        menu.addItem(ClosureMenuItem(title: Localizations.Xcode.organizer, symbolName: "square.grid.2x2") { [viewModel] in
            viewModel.show(.organizer)
        })
        menu.addItem(ClosureMenuItem(title: Localizations.Xcode.devicesAndSimulators, symbolName: "iphone.and.ipad") { [viewModel] in
            viewModel.show(.devicesAndSimulators)
        })
    }

    private func actionItem(_ action: BuildAction, hotKey: HotKey?) -> NSMenuItem {
        let item = ClosureMenuItem(title: action.title, symbolName: action.symbolName) { [viewModel] in
            viewModel.start(action)
        }
        if let hotKey {
            apply(hotKey, to: item)
        }
        return item
    }

    /// Shows the global shortcut next to the item; it also works while the menu is open
    private func apply(_ hotKey: HotKey, to item: NSMenuItem) {
        item.keyEquivalent = hotKey.key.lowercased()
        item.keyEquivalentModifierMask = [.control, .option, .command]
    }

    private func submenu(_ title: String, items: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: String.empty)
        item.submenu = items
        item.isEnabled = items.items.isEmpty == false
        return item
    }

    private func header(_ title: String) -> NSMenuItem {
        NSMenuItem.sectionHeader(title: title)
    }

}
