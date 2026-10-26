// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

protocol PreferencesProviderProtocol: AnyObject {

    // MARK: - Properties
    var preferences: Preferences { get }
    /// Emits the current settings and every change
    var publisher: AnyPublisher<Preferences, Never> { get }
    var isLoginItemEnabled: Bool { get }
    /// Folder exported archives go to
    var exportDirectory: URL { get }

    // MARK: - Methods
    func update(_ change: (inout Preferences) -> Void)
    func setLoginItemEnabled(_ isEnabled: Bool)

}
