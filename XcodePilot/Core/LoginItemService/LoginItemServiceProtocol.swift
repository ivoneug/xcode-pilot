// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol LoginItemServiceProtocol {
    /**
     Whether the app starts at login
     */
    var isEnabled: Bool { get }
    /**
     Adds or removes the app from the login items
     - Parameter isEnabled: Whether the app starts at login
     */
    func setEnabled(_ isEnabled: Bool) throws
}
