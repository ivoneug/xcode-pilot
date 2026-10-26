// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol HotKeyServiceProtocol: AnyObject {
    /**
     Registers a system wide shortcut
     - Parameter hotKey: Key and modifiers
     - Parameter action: Called on the main thread when the shortcut is pressed
     */
    func register(_ hotKey: HotKey, action: @escaping () -> Void)
    /**
     Removes every shortcut registered so far
     */
    func unregisterAll()
}
