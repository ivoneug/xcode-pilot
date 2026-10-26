// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// Error and warning counters, each shown only when non-zero
struct IssueCountView: View {

    // MARK: - Properties
    let errors: Int
    let warnings: Int

    // MARK: - Layout
    var body: some View {
        HStack(spacing: Margin.x4) {
            if errors > .zero {
                Label("\(errors)", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(Colors.failure.color)
            }
            if warnings > .zero {
                Label("\(warnings)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Colors.warning.color)
            }
        }
        .font(.system(size: Constants.fontSize, weight: .semibold).monospacedDigit())
        .labelStyle(CompactLabelStyle())
    }

}

private struct CompactLabelStyle: LabelStyle {

    // MARK: - Layout
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Margin.x1) {
            configuration.icon
            configuration.title
        }
    }

}

private enum Constants {
    static let fontSize: CGFloat = 11
}
