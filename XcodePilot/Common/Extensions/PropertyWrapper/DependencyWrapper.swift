// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

@propertyWrapper
struct Dependency<T> {

    // MARK: - Properties
    var wrappedValue: T {
        ProviderLocator.resolve(T.self)
    }

    // MARK: - Init/Deinit
    init() {}

}

@propertyWrapper
struct RepositoryDependency<T> {

    // MARK: - Properties
    var wrappedValue: T {
        RepositoryLocator.resolve(T.self)
    }

    // MARK: - Init/Deinit
    init() {}

}
