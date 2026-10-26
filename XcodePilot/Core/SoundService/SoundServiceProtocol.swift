// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol SoundServiceProtocol {
    /**
     Plays the system sound for a finished action
     - Parameter succeeded: Whether the action succeeded
     */
    func playFinished(succeeded: Bool)
}
