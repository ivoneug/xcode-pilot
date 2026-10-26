// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import Combine
import Foundation

@MainActor
final class SettingsViewModel: IdentifiableObject {

    // MARK: - Properties
    @Published private(set) var preferences: Preferences
    @Published private(set) var xcodes: [URL] = []
    @Published private(set) var isLoginItemEnabled = false
    @Published private(set) var isAccessibilityTrusted = false
    @Published private(set) var exportDirectory: String = String.empty
    let version = AppInfo.version
    let badgeDurations: [TimeInterval] = [10, 30, 60, .zero]
    let hotKeys: [(HotKey, String)] = [
        (.run, BuildAction.run.title),
        (.build, BuildAction.build.title),
        (.stop, Localizations.Action.stop),
        (.togglePanel, Localizations.Settings.HotKeys.togglePanel)
    ]
    private let navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>
    private let preferencesProvider: PreferencesProviderProtocol
    private let xcodeProvider: XcodeProviderProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init/Deinit
    init(
        navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>,
        preferencesProvider: PreferencesProviderProtocol,
        xcodeProvider: XcodeProviderProtocol
    ) {
        self.navigation = navigation
        self.preferencesProvider = preferencesProvider
        self.xcodeProvider = xcodeProvider
        preferences = preferencesProvider.preferences

        bindPublishers()
        refreshEnvironment()
    }

    // MARK: - Internal methods
    func close() {
        navigation.send(.main)
    }

    func set<Value>(_ keyPath: WritableKeyPath<Preferences, Value>, to value: Value) {
        preferencesProvider.update { $0[keyPath: keyPath] = value }
    }

    func setLoginItemEnabled(_ isEnabled: Bool) {
        preferencesProvider.setLoginItemEnabled(isEnabled)
    }

    func chooseExportDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.directoryURL = preferencesProvider.exportDirectory
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        set(\.exportDirectory, to: url.path)
    }

    func openAccessibilitySettings() {
        xcodeProvider.openAccessibilitySettings()
    }

    /// Permissions and installed Xcodes change outside the app, so they are re-read on appear
    func refreshEnvironment() {
        xcodes = xcodeProvider.installedXcodes
        isAccessibilityTrusted = xcodeProvider.isAccessibilityTrusted
        isLoginItemEnabled = preferencesProvider.isLoginItemEnabled
    }

    func xcodeTitle(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }

    func developerDirectory(of xcode: URL) -> String {
        xcode.appendingPathComponent(Constants.developerPath).path
    }

    func badgeDurationTitle(_ duration: TimeInterval) -> String {
        duration == .zero ? Localizations.Settings.MenuBar.untilNextAction : Localizations.Settings.MenuBar.seconds(Int(duration))
    }

    // MARK: - Private methods
    private func bindPublishers() {
        preferencesProvider.publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] preferences in
                guard let self else {
                    return
                }
                self.preferences = preferences
                exportDirectory = (preferencesProvider.exportDirectory.path as NSString).abbreviatingWithTildeInPath
                isLoginItemEnabled = preferencesProvider.isLoginItemEnabled
            })
            .store(in: &cancellables)
    }

}

private enum Constants {
    static let developerPath = "Contents/Developer"
}
