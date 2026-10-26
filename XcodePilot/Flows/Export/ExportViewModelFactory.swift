// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

enum ExportViewModelFactory {

    // MARK: - Public methods
    @MainActor
    static func build(
        archive: ArchiveInfo,
        navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>
    ) -> ExportViewModel {
        @Dependency
        var buildProvider: BuildProviderProtocol
        @Dependency
        var preferencesProvider: PreferencesProviderProtocol

        return ExportViewModel(
            archive: archive,
            navigation: navigation,
            buildProvider: buildProvider,
            preferencesProvider: preferencesProvider
        )
    }

}
