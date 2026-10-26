// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

enum SettingsViewModelFactory {

    // MARK: - Public methods
    @MainActor
    static func build(with navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>) -> SettingsViewModel {
        @Dependency
        var preferencesProvider: PreferencesProviderProtocol
        @Dependency
        var xcodeProvider: XcodeProviderProtocol

        return SettingsViewModel(navigation: navigation, preferencesProvider: preferencesProvider, xcodeProvider: xcodeProvider)
    }

}
