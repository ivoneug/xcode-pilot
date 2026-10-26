// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

struct IssuesListView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Layout
    var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: Margin.x4) {
                Picker(String.empty, selection: $viewModel.issueFilter) {
                    ForEach(PanelViewModel.IssueFilter.allCases) { filter in
                        Text(title(for: filter))
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()

                Spacer(minLength: .zero)

                Button(Localizations.Issues.copyAll, action: viewModel.copyIssues)
                    .controlSize(.small)
                    .disabled(viewModel.issues.isEmpty)
                    .keyboardShortcut("c", modifiers: [.command, .shift])
            }
            .padding(.horizontal, Margin.x6)
            .padding(.vertical, Margin.x3)

            Divider()

            if viewModel.issues.isEmpty {
                EmptyStateView(symbolName: emptySymbol, title: emptyTitle)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: .zero) {
                        ForEach(viewModel.issues) { issue in
                            IssueRowView(issue: issue, isCopied: viewModel.copiedIssueId == issue.id, viewModel: viewModel)
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed properties
    private var emptySymbol: String {
        viewModel.activity?.isRunning == true ? "hourglass" : "checkmark.seal"
    }

    private var emptyTitle: String {
        guard let activity = viewModel.activity else {
            return Localizations.Issues.nothingYet
        }
        return activity.isRunning ? Localizations.Issues.noneSoFar : Localizations.Issues.none
    }

    // MARK: - Private methods
    private func title(for filter: PanelViewModel.IssueFilter) -> String {
        let issues = viewModel.allIssues
        switch filter {
        case .all:
            return Localizations.Issues.Filter.all(issues.count)
        case .errors:
            return Localizations.Issues.Filter.errors(issues.errorCount)
        case .warnings:
            return Localizations.Issues.Filter.warnings(issues.warningCount)
        }
    }

}
