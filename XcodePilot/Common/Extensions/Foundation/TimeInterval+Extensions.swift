// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension TimeInterval {

    // MARK: - Computed properties
    /// Duration in positional format: `0:07`, `2:35`, `1:04:09`
    var readableDuration: String {
        let total = Int(max(self, .zero).rounded(.down))
        let hours = total / Constants.secondsInHour
        let minutes = total % Constants.secondsInHour / Constants.secondsInMinute
        let seconds = total % Constants.secondsInMinute
        guard hours > .zero else {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

}

private enum Constants {
    static let secondsInHour = 3600
    static let secondsInMinute = 60
}
