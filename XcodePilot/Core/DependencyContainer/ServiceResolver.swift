// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

public struct ServiceResolver {

    // MARK: - Properties
    private let factories: [AnyServiceFactory]

    // MARK: - Init/Deinit
    public init() {
        factories = []
    }

    private init(factories: [AnyServiceFactory]) {
        self.factories = factories
    }

    // MARK: Register
    public func register<T>(_ interface: T.Type, instance: T) -> Self {
        registerFactory(interface) { _ in instance }
    }

    public func register<T>(_ interface: T.Type, instanceBuilder: (Resolver) -> T) -> Self {
        register(interface, instance: instanceBuilder(self))
    }

    public func registerFactory<Service>(_ type: Service.Type, _ factory: @escaping (Resolver) -> Service) -> Self {
        assert(!factories.contains { $0.supports(type) })
        let newFactory = BasicServiceFactory<Service>(type, factory: factory)
        return ServiceResolver(factories: factories + [AnyServiceFactory(newFactory)])
    }

}

// MARK: Resolver
extension ServiceResolver: Resolver {

    public func resolve<Service>(_ type: Service.Type) -> Service {
        guard let factory = factories.first(where: { $0.supports(type) }) else {
            fatalError("No suitable factory found (\(type.self)")
        }
        return factory.resolve(from: self)
    }
}
