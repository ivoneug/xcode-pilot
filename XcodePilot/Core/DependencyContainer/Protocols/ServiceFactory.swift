// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

public protocol ServiceFactory {
    associatedtype Service
    /**
     Builds the service using the resolver for its own dependencies
     - Parameter resolver: Resolver of the dependencies
     - Returns: The service
     */
    func resolve(from resolver: Resolver) -> Service
}
