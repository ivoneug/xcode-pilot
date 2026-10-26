// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

enum StatusBarViewModelFactory {

    // MARK: - Public methods
    @MainActor
    static func build() -> StatusBarViewModel {
        @Dependency
        var buildProvider: BuildProviderProtocol
        @Dependency
        var runProvider: RunProviderProtocol
        @Dependency
        var projectProvider: ProjectProviderProtocol
        @Dependency
        var preferencesProvider: PreferencesProviderProtocol
        @Dependency
        var xcodeProvider: XcodeProviderProtocol
        @Dependency
        var hotKeyService: HotKeyServiceProtocol
        @Dependency
        var timerScheduler: TimerSchedulerProtocol
        @RepositoryDependency
        var appStateRepository: AppStateRepository

        return StatusBarViewModel(
            buildProvider: buildProvider,
            runProvider: runProvider,
            projectProvider: projectProvider,
            preferencesProvider: preferencesProvider,
            xcodeProvider: xcodeProvider,
            hotKeyService: hotKeyService,
            timerScheduler: timerScheduler,
            appStateRepository: appStateRepository
        )
    }

}
