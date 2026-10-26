// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

enum PanelViewModelFactory {

    // MARK: - Public methods
    @MainActor
    static func build(with navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>) -> PanelViewModel {
        @Dependency
        var projectProvider: ProjectProviderProtocol
        @Dependency
        var buildProvider: BuildProviderProtocol
        @Dependency
        var runProvider: RunProviderProtocol
        @Dependency
        var preferencesProvider: PreferencesProviderProtocol
        @Dependency
        var xcodeProvider: XcodeProviderProtocol

        return PanelViewModel(
            navigation: navigation,
            projectProvider: projectProvider,
            buildProvider: buildProvider,
            runProvider: runProvider,
            preferencesProvider: preferencesProvider,
            xcodeProvider: xcodeProvider
        )
    }

}
