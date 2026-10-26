// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// The xcodebuild log, condensed to tasks and diagnostics or in full
struct LogPaneView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Layout
    var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: Margin.x4) {
                Toggle(Localizations.Log.compact, isOn: Binding(get: { viewModel.isCompactLog }, set: viewModel.setCompactLog))
                    .toggleStyle(.checkbox)
                    .help(Localizations.Log.compactHelp)
                Spacer(minLength: .zero)
                Button(Localizations.Log.copy, action: viewModel.copyLog)
                Button(Localizations.Log.openFull, action: viewModel.openLog)
            }
            .controlSize(.small)
            .disabled(viewModel.activity == nil)
            .padding(.horizontal, Margin.x6)
            .padding(.vertical, Margin.x3)

            Divider()

            if viewModel.activity == nil {
                EmptyStateView(symbolName: "text.alignleft", title: Localizations.Log.empty)
            } else {
                LogTextView(
                    lines: viewModel.logLines,
                    version: viewModel.logVersion,
                    source: [viewModel.activity?.id.uuidString ?? String.empty, "\(viewModel.isCompactLog)"]
                )
            }
        }
    }

}
