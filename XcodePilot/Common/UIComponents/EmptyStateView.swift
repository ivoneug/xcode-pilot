// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// Placeholder for an empty list
struct EmptyStateView: View {

    // MARK: - Properties
    let symbolName: String
    let title: String
    var message: String?

    // MARK: - Layout
    var body: some View {
        VStack(spacing: Margin.x3) {
            Image(systemName: symbolName)
                .font(.system(size: Constants.iconSize))
                .foregroundStyle(Colors.textTertiary.color)
            Text(title)
                .font(.system(size: Constants.titleSize, weight: .medium))
                .foregroundStyle(Colors.textSecondary.color)
            if let message {
                Text(message)
                    .font(.system(size: Constants.messageSize))
                    .foregroundStyle(Colors.textTertiary.color)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Margin.x8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

private enum Constants {
    static let iconSize: CGFloat = 26
    static let titleSize: CGFloat = 13
    static let messageSize: CGFloat = 11
}
