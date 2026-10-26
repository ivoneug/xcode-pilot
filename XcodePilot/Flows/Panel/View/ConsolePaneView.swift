// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// stdout and stderr of the app launched by Run
struct ConsolePaneView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Layout
    var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: Margin.x4) {
                Text(viewModel.run?.stateDescription ?? Localizations.Console.notRunning)
                    .font(.system(size: Constants.fontSize))
                    .foregroundStyle(Colors.textSecondary.color)
                    .lineLimit(1)
                Spacer(minLength: .zero)
                Button(Localizations.Log.copy, action: viewModel.copyConsole)
                    .disabled(viewModel.consoleLines.isEmpty)
            }
            .controlSize(.small)
            .padding(.horizontal, Margin.x6)
            .padding(.vertical, Margin.x3)

            Divider()

            if viewModel.run == nil {
                EmptyStateView(
                    symbolName: "terminal",
                    title: Localizations.Console.empty,
                    message: Localizations.Console.emptyHint
                )
            } else {
                LogTextView(
                    lines: viewModel.consoleLines,
                    version: viewModel.consoleVersion,
                    source: viewModel.run?.id.uuidString ?? String.empty
                )
            }
        }
    }

}

private enum Constants {
    static let fontSize: CGFloat = 11
}
