// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// One diagnostic: message, location and the compiler excerpt, with everything copyable
struct IssueRowView: View {

    // MARK: - Properties
    let issue: BuildIssue
    let isCopied: Bool
    @ObservedObject var viewModel: PanelViewModel
    @State private var isExpanded = false
    @State private var isHovered = false

    // MARK: - Layout
    var body: some View {
        HStack(alignment: .top, spacing: Margin.x4) {
            Image(systemName: issue.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(issue.severity == .error ? Colors.failure.color : Colors.warning.color)
                .font(.system(size: Constants.iconSize))
                .padding(.top, Margin.x1)

            VStack(alignment: .leading, spacing: Margin.x2) {
                Text(issue.message)
                    .font(.system(size: Constants.messageSize))
                    .foregroundStyle(Colors.textPrimary.color)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                location

                if isExpanded, issue.context.isEmpty == false {
                    Text(issue.context.joined(separator: String.lineBreak))
                        .font(.system(size: Constants.codeSize, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(Margin.x3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.codeBackground.color, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
                }
            }

            Spacer(minLength: .zero)

            SymbolButton(symbolName: isCopied ? "checkmark" : "doc.on.doc", help: Localizations.Issues.copy) {
                viewModel.copy(issue)
            }
            .opacity(isHovered || isCopied ? 1 : Constants.idleButtonOpacity)
        }
        .padding(.horizontal, Margin.x6)
        .padding(.vertical, Margin.x4)
        .contentShape(Rectangle())
        .background(isHovered ? Colors.cardBackground.color : .clear)
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) {
            viewModel.open(issue)
        }
        .contextMenu {
            Button(Localizations.Issues.copy) {
                viewModel.copy(issue)
            }
            Button(Localizations.Issues.copyMessage) {
                viewModel.copyMessage(of: issue)
            }
            if issue.location != nil {
                Button(Localizations.Issues.copyLocation) {
                    viewModel.copyLocation(of: issue)
                }
                Divider()
                Button(Localizations.Issues.open) {
                    viewModel.open(issue)
                }
                Button(Localizations.Issues.reveal) {
                    viewModel.reveal(issue)
                }
            }
        }
    }

    private var location: some View {
        HStack(spacing: Margin.x3) {
            if let shortLocation = issue.shortLocation {
                Button(shortLocation) {
                    viewModel.open(issue)
                }
                .buttonStyle(.link)
                .help(issue.location ?? shortLocation)
            }
            if let target = issue.target {
                Text(target)
                    .foregroundStyle(Colors.textTertiary.color)
            }
            if issue.context.isEmpty == false {
                Button {
                    withAnimation(Constants.animation) {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(
                        isExpanded ? Localizations.Issues.hideDetails : Localizations.Issues.showDetails,
                        systemImage: isExpanded ? "chevron.down" : "chevron.right"
                    )
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Colors.textSecondary.color)
            }
        }
        .font(.system(size: Constants.locationSize))
        .lineLimit(1)
    }

}

private enum Constants {
    static let iconSize: CGFloat = 12
    static let messageSize: CGFloat = 12
    static let locationSize: CGFloat = 10.5
    static let codeSize: CGFloat = 10.5
    static let cornerRadius: CGFloat = 6
    static let idleButtonOpacity = 0.35
    static let animation: Animation = .easeInOut(duration: 0.15)
}
