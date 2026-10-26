// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

struct BasicServiceFactory<Service> {

    // MARK: - Properties
    private let factory: (Resolver) -> Service

    // MARK: - Init/Deinit
    init(_: Service.Type, factory: @escaping (Resolver) -> Service) {
        self.factory = factory
    }

}

// MARK: - ServiceFactory
extension BasicServiceFactory: ServiceFactory {

    func resolve(from resolver: Resolver) -> Service {
        factory(resolver)
    }
}
