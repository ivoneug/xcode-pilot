// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

enum DevicesViewModelFactory {

    // MARK: - Public methods
    @MainActor
    static func build(with navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>) -> DevicesViewModel {
        @Dependency
        var devicesProvider: DevicesProviderProtocol
        @Dependency
        var projectProvider: ProjectProviderProtocol
        @Dependency
        var xcodeProvider: XcodeProviderProtocol

        return DevicesViewModel(
            navigation: navigation,
            devicesProvider: devicesProvider,
            projectProvider: projectProvider,
            xcodeProvider: xcodeProvider
        )
    }

}
