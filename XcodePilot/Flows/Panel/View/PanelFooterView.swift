// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// Less frequent actions and the way to Xcode's own windows
struct PanelFooterView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Layout
    var body: some View {
        HStack(spacing: Margin.x6) {
            Group {
                Button {
                    viewModel.start(.test)
                } label: {
                    Label(BuildAction.test.title, systemImage: "checkmark.diamond")
                }
                .keyboardShortcut("u")
                Button {
                    viewModel.start(.clean)
                } label: {
                    Label(BuildAction.clean.title, systemImage: "trash")
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                Button {
                    viewModel.start(.archive)
                } label: {
                    Label(BuildAction.archive.title, systemImage: "archivebox")
                }
            }
            .disabled(viewModel.canStart == false)

            Spacer(minLength: Margin.x4)

            SymbolButton(symbolName: "square.grid.2x2", help: Localizations.Xcode.organizer) {
                viewModel.show(.organizer)
            }
            SymbolButton(symbolName: "iphone.and.ipad", help: Localizations.Xcode.devicesAndSimulators) {
                viewModel.show(.devicesAndSimulators)
            }
            SymbolButton(symbolName: "power", help: Localizations.Menu.quit, action: viewModel.quit)
        }
        .buttonStyle(.borderless)
        .labelStyle(.titleAndIcon)
        .font(.system(size: Constants.fontSize))
        .padding(.horizontal, Margin.x6)
        .padding(.vertical, Margin.x4)
    }

}

private enum Constants {
    static let fontSize: CGFloat = 11
}
