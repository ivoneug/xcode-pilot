// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// Project picker and the panel level buttons
struct PanelHeaderView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Layout
    var body: some View {
        HStack(spacing: Margin.x2) {
            projectMenu

            Spacer(minLength: Margin.x4)

            if viewModel.isLoadingProject {
                ProgressView()
                    .controlSize(.small)
            }
            SymbolButton(symbolName: "arrow.clockwise", help: Localizations.Header.reload, isEnabled: viewModel.project != nil) {
                viewModel.reloadProject()
            }
            SymbolButton(symbolName: "hammer", help: Localizations.Menu.openInXcode, isEnabled: viewModel.project != nil) {
                viewModel.openInXcode()
            }
            SymbolButton(symbolName: "macwindow.on.rectangle", help: Localizations.Header.detach, action: viewModel.detach)
            SymbolButton(symbolName: "gearshape", help: Localizations.Header.settings, action: viewModel.openSettings)
        }
        .padding(.horizontal, Margin.x6)
        .padding(.vertical, Margin.x4)
    }

    private var projectMenu: some View {
        Menu {
            if viewModel.recentProjects.isEmpty == false {
                Section(Localizations.Project.recent) {
                    ForEach(viewModel.recentProjects) { project in
                        projectButton(project)
                    }
                }
            }
            if viewModel.xcodeRecentProjects.isEmpty == false {
                Section(Localizations.Project.recentInXcode) {
                    ForEach(viewModel.xcodeRecentProjects) { project in
                        projectButton(project)
                    }
                }
            }
            Divider()
            Button(Localizations.Project.open, action: viewModel.openProject)
                .keyboardShortcut("o")
            if let project = viewModel.project {
                Button(Localizations.Project.reveal, action: viewModel.revealProject)
                Button(Localizations.Project.removeFromRecents) {
                    viewModel.remove(project)
                }
            }
        } label: {
            HStack(spacing: Margin.x3) {
                Image(systemName: viewModel.project?.symbolName ?? "folder.badge.plus")
                    .font(.system(size: Constants.iconSize, weight: .semibold))
                    .foregroundStyle(Colors.accentColor.color)
                VStack(alignment: .leading, spacing: .zero) {
                    Text(viewModel.project?.name ?? Localizations.Project.choose)
                        .font(.system(size: Constants.titleSize, weight: .semibold))
                        .foregroundStyle(Colors.textPrimary.color)
                    if let project = viewModel.project {
                        Text(project.displayPath)
                            .font(.system(size: Constants.pathSize))
                            .foregroundStyle(Colors.textTertiary.color)
                            .truncationMode(.middle)
                    }
                }
                .lineLimit(1)
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.visible)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Private methods
    private func projectButton(_ project: ProjectRef) -> some View {
        Button {
            viewModel.select(project)
        } label: {
            if project == viewModel.project {
                Label(project.name, systemImage: "checkmark")
            } else {
                Text(project.name)
            }
        }
        .help(project.displayPath)
    }

}

private enum Constants {
    static let iconSize: CGFloat = 18
    static let titleSize: CGFloat = 14
    static let pathSize: CGFloat = 10
}
