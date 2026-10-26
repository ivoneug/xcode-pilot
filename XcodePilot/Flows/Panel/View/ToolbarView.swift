// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// Run / Stop, Build and the scheme, destination and configuration pickers, like Xcode's toolbar
struct ToolbarView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Computed properties
    private var isStoppable: Bool {
        viewModel.isBusy || viewModel.isAppRunning
    }

    // MARK: - Layout
    var body: some View {
        HStack(spacing: Margin.x2) {
            Button {
                viewModel.start(.run)
            } label: {
                Image(systemName: "play.fill")
                    .frame(width: Constants.buttonWidth)
            }
            .keyboardShortcut("r")
            .help(Localizations.Toolbar.runHelp(HotKey.run.displayName))
            .disabled(viewModel.canRun == false)

            Button(action: viewModel.stop) {
                Image(systemName: "stop.fill")
                    .frame(width: Constants.buttonWidth)
            }
            .keyboardShortcut(".")
            .help(Localizations.Toolbar.stopHelp(HotKey.stop.displayName))
            .disabled(isStoppable == false)

            Button {
                viewModel.start(.build)
            } label: {
                Image(systemName: "hammer.fill")
                    .frame(width: Constants.buttonWidth)
            }
            .keyboardShortcut("b")
            .help(Localizations.Toolbar.buildHelp(HotKey.build.displayName))
            .disabled(viewModel.canStart == false)

            schemeMenu
            destinationMenu
            configurationMenu
        }
        .controlSize(.regular)
        .padding(.horizontal, Margin.x6)
        .padding(.bottom, Margin.x4)
    }

    private var schemeMenu: some View {
        Menu {
            ForEach(viewModel.schemes, id: \.self) { scheme in
                Button {
                    viewModel.selectScheme(scheme)
                } label: {
                    checked(scheme, isSelected: scheme == viewModel.scheme)
                }
            }
        } label: {
            Label(viewModel.scheme ?? Localizations.Toolbar.noScheme, systemImage: "square.stack.3d.up")
        }
        .frame(minWidth: Constants.schemeMinWidth, maxWidth: Constants.schemeMaxWidth)
        .disabled(viewModel.schemes.isEmpty)
        .help(Localizations.Toolbar.scheme)
    }

    private var destinationMenu: some View {
        Menu {
            ForEach(viewModel.destinationGroups) { group in
                Section(group.title) {
                    ForEach(group.destinations) { destination in
                        Button {
                            viewModel.selectDestination(destination)
                        } label: {
                            checked(destination.displayName, isSelected: viewModel.destination?.matches(destination) == true)
                        }
                    }
                }
            }
            Divider()
            Button(Localizations.Toolbar.reloadDestinations, action: viewModel.reloadDestinations)
        } label: {
            HStack(spacing: Margin.x2) {
                if viewModel.isLoadingDestinations {
                    ProgressView()
                        .controlSize(.mini)
                }
                Label(
                    viewModel.destination?.displayName ?? Localizations.Toolbar.noDestination,
                    systemImage: viewModel.destination?.symbolName ?? "iphone"
                )
            }
        }
        .frame(minWidth: Constants.destinationMinWidth, maxWidth: .infinity)
        .disabled(viewModel.scheme == nil)
        .help(Localizations.Toolbar.destination)
    }

    /// Rarely changed, so it only takes an icon; the tooltip names the configuration in use
    private var configurationMenu: some View {
        Menu {
            Button {
                viewModel.selectConfiguration(nil)
            } label: {
                checked(Localizations.Toolbar.schemeConfiguration, isSelected: viewModel.configuration == nil)
            }
            Divider()
            ForEach(viewModel.configurations, id: \.self) { configuration in
                Button {
                    viewModel.selectConfiguration(configuration)
                } label: {
                    checked(configuration, isSelected: configuration == viewModel.configuration)
                }
            }
        } label: {
            Image(systemName: viewModel.configuration == nil ? "slider.horizontal.3" : "slider.horizontal.below.square.filled.and.square")
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(viewModel.configurations.isEmpty)
        .help("\(Localizations.Toolbar.configuration): \(viewModel.configurationTitle)")
    }

    // MARK: - Private methods
    @ViewBuilder private func checked(_ title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

}

private enum Constants {
    static let buttonWidth: CGFloat = 14
    static let schemeMinWidth: CGFloat = 70
    static let schemeMaxWidth: CGFloat = 150
    static let destinationMinWidth: CGFloat = 140
}
