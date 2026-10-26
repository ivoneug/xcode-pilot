// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// What is going on right now: the running build with its step and progress, or the last result
struct ActivityCardView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Layout
    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x3) {
            if let activity = viewModel.activity {
                activityContent(activity)
            } else {
                idleContent
            }
            if let run = viewModel.run {
                RunStatusView(run: run, onStop: viewModel.stop)
            }
            if let error = viewModel.projectError {
                Text(error)
                    .font(.system(size: Constants.detailSize))
                    .foregroundStyle(Colors.failure.color)
                    .lineLimit(Constants.errorLineLimit)
                    .textSelection(.enabled)
            }
        }
        .padding(Margin.x6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.cardBackground.color, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .padding(.horizontal, Margin.x6)
    }

    private var idleContent: some View {
        HStack(spacing: Margin.x4) {
            Image(systemName: "hammer")
                .font(.system(size: Constants.iconSize))
                .foregroundStyle(Colors.textTertiary.color)
            VStack(alignment: .leading, spacing: Margin.x1) {
                Text(Localizations.Activity.ready)
                    .font(.system(size: Constants.titleSize, weight: .semibold))
                Text(Localizations.Activity.readyHint(HotKey.run.displayName, HotKey.build.displayName))
                    .font(.system(size: Constants.detailSize))
                    .foregroundStyle(Colors.textSecondary.color)
            }
        }
    }

    // MARK: - Private methods
    private func activityContent(_ activity: BuildActivity) -> some View {
        VStack(alignment: .leading, spacing: Margin.x3) {
            HStack(spacing: Margin.x4) {
                statusIcon(activity)
                VStack(alignment: .leading, spacing: Margin.x1) {
                    HStack(spacing: Margin.x3) {
                        Text(activity.title)
                            .font(.system(size: Constants.titleSize, weight: .semibold))
                        IssueCountView(errors: activity.errorCount, warnings: activity.warningCount)
                    }
                    Text(subtitle(activity))
                        .font(.system(size: Constants.detailSize))
                        .foregroundStyle(Colors.textSecondary.color)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: .zero)
                duration(activity)
                if activity.isRunning == false {
                    SymbolButton(symbolName: "xmark", help: Localizations.Activity.dismiss, action: viewModel.dismissActivity)
                }
            }
            if activity.isRunning {
                progress(activity)
            }
            if let summary = activity.testSummary {
                Text(summary.description)
                    .font(.system(size: Constants.detailSize, weight: .medium))
            }
            if let archive = activity.archive, activity.status == .succeeded {
                ArchiveResultView(activity: activity, archive: archive, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder private func statusIcon(_ activity: BuildActivity) -> some View {
        switch activity.status {
        case .running:
            ProgressView()
                .controlSize(.small)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
        case .succeeded:
            icon("checkmark.circle.fill", color: Colors.success.color)
        case .failed:
            icon("xmark.circle.fill", color: Colors.failure.color)
        case .cancelled:
            icon("stop.circle.fill", color: Colors.textTertiary.color)
        }
    }

    private func icon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: Constants.iconSize))
            .foregroundStyle(color)
    }

    private func subtitle(_ activity: BuildActivity) -> String {
        if activity.isRunning, let step = activity.step {
            return [step, activity.stepTarget].compactMap { $0 }.joined(separator: " — ")
        }
        let request = activity.request
        // Archives are built for the platform, not for the device picked to run on
        let destination = activity.action == .archive || activity.action == .export
            ? request.destination.basePlatform
            : request.destination.displayName
        return [request.scheme, destination, request.configuration].compactMap { $0 }.joined(separator: " · ")
    }

    private func duration(_ activity: BuildActivity) -> some View {
        TimelineView(.periodic(from: activity.startedAt, by: 1)) { _ in
            Text(activity.duration.readableDuration)
                .font(.system(size: Constants.detailSize, weight: .medium).monospacedDigit())
                .foregroundStyle(Colors.textSecondary.color)
        }
    }

    @ViewBuilder private func progress(_ activity: BuildActivity) -> some View {
        if activity.expectedDuration != nil {
            TimelineView(.periodic(from: activity.startedAt, by: Constants.progressRefresh)) { _ in
                ProgressView(value: activity.estimatedProgress ?? .zero)
                    .progressViewStyle(.linear)
            }
        } else {
            ProgressView()
                .progressViewStyle(.linear)
        }
    }

}

private enum Constants {
    static let iconSize: CGFloat = 22
    static let titleSize: CGFloat = 13
    static let detailSize: CGFloat = 11
    static let cornerRadius: CGFloat = 10
    static let errorLineLimit = 4
    static let progressRefresh: TimeInterval = 0.5
}
