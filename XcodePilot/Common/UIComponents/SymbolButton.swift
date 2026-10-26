// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// Borderless icon button with a tooltip
struct SymbolButton: View {

    // MARK: - Properties
    let symbolName: String
    let help: String
    var isEnabled = true
    let action: () -> Void

    // MARK: - Layout
    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: Constants.iconSize, weight: .medium))
                .frame(width: Constants.side, height: Constants.side)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(help)
        .disabled(isEnabled == false)
    }

}

private enum Constants {
    static let iconSize: CGFloat = 13
    static let side: CGFloat = 24
}
