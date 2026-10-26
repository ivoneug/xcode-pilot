// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit

final class SoundService {}

// MARK: - SoundServiceProtocol
extension SoundService: SoundServiceProtocol {

    func playFinished(succeeded: Bool) {
        DispatchQueue.main.async {
            NSSound(named: succeeded ? Constants.success : Constants.failure)?.play()
        }
    }

}

private enum Constants {
    static let success = NSSound.Name("Glass")
    static let failure = NSSound.Name("Basso")
}
