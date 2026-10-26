// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

struct SettingsView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: SettingsViewModel

    // MARK: - Layout
    var body: some View {
        VStack(spacing: .zero) {
            header
            Divider()
            Form {
                general
                menuBar
                build
                SettingsHotKeysSection(viewModel: viewModel)
                permissions
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .toolbar(.hidden)
        .onAppear(perform: viewModel.refreshEnvironment)
    }

    private var header: some View {
        HStack(spacing: Margin.x4) {
            Button(action: viewModel.close) {
                Label(Localizations.Common.back, systemImage: "chevron.left")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.cancelAction)
            Spacer(minLength: .zero)
            Text(Localizations.Settings.title)
                .font(.system(size: Constants.titleSize, weight: .semibold))
            Spacer(minLength: .zero)
            Text(viewModel.version)
                .font(.system(size: Constants.detailSize))
                .foregroundStyle(Colors.textTertiary.color)
        }
        .padding(.horizontal, Margin.x6)
        .padding(.vertical, Margin.x5)
    }

    private var general: some View {
        Section(Localizations.Settings.General.title) {
            Toggle(Localizations.Settings.General.launchAtLogin, isOn: Binding(
                get: { viewModel.isLoginItemEnabled },
                set: viewModel.setLoginItemEnabled
            ))
            toggle(Localizations.Settings.General.notifications, \.notifiesOnFinish)
            toggle(Localizations.Settings.General.sounds, \.playsSounds)
            Picker(Localizations.Settings.General.editor, selection: binding(\.editor)) {
                ForEach(EditorChoice.allCases) { editor in
                    Text(editor.title)
                        .tag(editor)
                }
            }
            LabeledContent(Localizations.Settings.General.exportFolder) {
                HStack(spacing: Margin.x3) {
                    Text(viewModel.exportDirectory)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(Colors.textSecondary.color)
                    Button(Localizations.Settings.General.choose, action: viewModel.chooseExportDirectory)
                }
            }
        }
    }

    private var menuBar: some View {
        Section(Localizations.Settings.MenuBar.title) {
            toggle(Localizations.Settings.MenuBar.elapsedTime, \.showsElapsedTime)
            toggle(Localizations.Settings.MenuBar.errorCount, \.showsIssueCount)
            Picker(Localizations.Settings.MenuBar.successBadge, selection: binding(\.successBadgeDuration)) {
                ForEach(viewModel.badgeDurations, id: \.self) { duration in
                    Text(viewModel.badgeDurationTitle(duration))
                        .tag(duration)
                }
            }
        }
    }

    private var build: some View {
        Section(Localizations.Settings.Build.title) {
            Picker(Localizations.Settings.Build.xcode, selection: binding(\.developerDirectory)) {
                Text(Localizations.Settings.Build.xcodeSelect)
                    .tag(String?.none)
                ForEach(viewModel.xcodes, id: \.self) { xcode in
                    Text(viewModel.xcodeTitle(xcode))
                        .tag(Optional(viewModel.developerDirectory(of: xcode)))
                }
            }
            toggle(Localizations.Settings.Build.bringSimulatorToFront, \.bringsSimulatorToFront)
            toggle(Localizations.Settings.Build.allowProvisioningUpdates, \.allowsProvisioningUpdates)
            toggle(Localizations.Settings.Build.skipMacroValidation, \.skipsMacroValidation)
                .help(Localizations.Settings.Build.skipMacroValidationHelp)
        }
    }

    private var permissions: some View {
        Section(Localizations.Settings.Permissions.title) {
            LabeledContent(Localizations.Settings.Permissions.accessibility) {
                if viewModel.isAccessibilityTrusted {
                    Label(Localizations.Settings.Permissions.granted, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Colors.success.color)
                } else {
                    Button(Localizations.Common.openSettings, action: viewModel.openAccessibilitySettings)
                }
            }
            Text(Localizations.Settings.Permissions.accessibilityHint)
                .font(.system(size: Constants.detailSize))
                .foregroundStyle(Colors.textSecondary.color)
        }
    }

    // MARK: - Private methods
    private func binding<Value>(_ keyPath: WritableKeyPath<Preferences, Value>) -> Binding<Value> {
        Binding(
            get: { viewModel.preferences[keyPath: keyPath] },
            set: { viewModel.set(keyPath, to: $0) }
        )
    }

    private func toggle(_ title: String, _ keyPath: WritableKeyPath<Preferences, Bool>) -> some View {
        Toggle(title, isOn: binding(keyPath))
    }

}

private enum Constants {
    static let titleSize: CGFloat = 13
    static let detailSize: CGFloat = 11
}
