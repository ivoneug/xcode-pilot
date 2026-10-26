// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

enum RepositoryLocator: ServiceLocatorProtocol {

    // MARK: - Properties
    private static let locator: Resolver = makeLocator()

    // MARK: - Public methods
    static func resolve<Service>(_ type: Service.Type) -> Service {
        locator.resolve(type)
    }

}

private extension RepositoryLocator {

    static func makeLocator() -> Resolver {
        guard NSClassFromString("Dummy") == nil else {
            return ServiceResolver()
        }
        return ServiceResolver()
            .register(AppStateRepository.self) { _ in AppStateRepository.shared }
    }

}
