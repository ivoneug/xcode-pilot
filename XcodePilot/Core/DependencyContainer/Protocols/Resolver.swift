// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

public protocol Resolver {
    /**
     Returns the instance registered for the type
     - Parameter type: Type of the object
     - Returns: The object
     */
    func resolve<Service>(_ type: Service.Type) -> Service
}
