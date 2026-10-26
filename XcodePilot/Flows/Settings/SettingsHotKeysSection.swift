// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

struct SettingsHotKeysSection: View {

    // MARK: - Properties
    @ObservedObject var viewModel: SettingsViewModel

    // MARK: - Layout
    var body: some View {
        Section(Localizations.Settings.HotKeys.title) {
            Toggle(Localizations.Settings.HotKeys.enabled, isOn: Binding(
                get: { viewModel.preferences.usesGlobalHotKeys },
                set: { viewModel.set(\.usesGlobalHotKeys, to: $0) }
            ))
            ForEach(viewModel.hotKeys, id: \.0) { hotKey, title in
                LabeledContent(title) {
                    Text(hotKey.displayName)
                        .font(.system(size: Constants.fontSize, design: .monospaced))
                        .foregroundStyle(Colors.textSecondary.color)
                }
            }
            .disabled(viewModel.preferences.usesGlobalHotKeys == false)
        }
    }

}

private enum Constants {
    static let fontSize: CGFloat = 12
}
