// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/**
 Creates timers scheduled on the main run loop
 */
protocol TimerSchedulerProtocol: AnyObject {

    /**
     Creates a timer that fires at a date
     - Parameter fireDate: When the timer fires
     - Parameter repeats: Whether the timer repeats
     - Parameter handler: Callback
     - Returns: The scheduled timer
     */
    func makeTimer(fireDate: Date, repeats: Bool, handler: @escaping () -> Void) -> Timer

    /**
     Creates a timer that fires after an interval
     - Parameter timeInterval: Interval after which the timer fires
     - Parameter repeats: Whether the timer repeats
     - Parameter handler: Callback
     - Returns: The scheduled timer
     */
    func makeTimer(timeInterval: TimeInterval, repeats: Bool, handler: @escaping () -> Void) -> Timer

}
