// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// stdout and stderr of the app launched by Run, filtered like Xcode's console
struct ConsolePaneView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Computed properties
    private var filter: ConsoleFilter {
        viewModel.consoleFilter
    }

    // MARK: - Layout
    var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: Margin.x3) {
                modeMenu
                ConsoleFilterField(tokens: filter.tokens, draft: filter.draft, onChange: viewModel.updateConsoleFilter)
                    .frame(maxWidth: .infinity)
                if filter.isEmpty == false {
                    SymbolButton(
                        symbolName: "xmark.circle.fill",
                        help: Localizations.Console.Filter.clear,
                        action: viewModel.clearConsoleFilter
                    )
                }
                if filter.isActive, viewModel.run != nil {
                    Text(Localizations.Console.Filter.count(viewModel.consoleLines.count, viewModel.consoleLineCount))
                        .font(.system(size: Constants.fontSize).monospacedDigit())
                        .foregroundStyle(Colors.textSecondary.color)
                        .help(Localizations.Console.Filter.countHelp)
                        .fixedSize()
                }
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
                    source: [AnyHashable(viewModel.run?.id), AnyHashable(filter)],
                    highlights: filter.highlights
                )
                .overlay {
                    if filter.isActive, viewModel.consoleLines.isEmpty, viewModel.consoleLineCount > .zero {
                        EmptyStateView(symbolName: "line.3.horizontal.decrease.circle", title: Localizations.Console.Filter.noMatches)
                    }
                }
            }
        }
        // Text typed into the field would be lost with it, so it stays as a token
        .onDisappear(perform: viewModel.commitConsoleFilterDraft)
    }

    private var modeMenu: some View {
        Menu {
            Picker(String.empty, selection: Binding(get: { filter.mode }, set: viewModel.setConsoleFilterMode)) {
                ForEach(ConsoleFilter.Mode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            Divider()
            Text(Localizations.Console.Filter.exclusionHint)
        } label: {
            Image(systemName: filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(Localizations.Console.Filter.options)
    }

}

private enum Constants {
    static let fontSize: CGFloat = 11
}
