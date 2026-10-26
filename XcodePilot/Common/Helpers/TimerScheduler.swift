// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

final class TimerScheduler: TimerSchedulerProtocol {

    func makeTimer(fireDate: Date, repeats: Bool, handler: @escaping () -> Void) -> Timer {
        let callback = TimerCallback(block: handler)
        let timer = Timer(
            fireAt: fireDate,
            interval: 0,
            target: callback,
            selector: #selector(TimerCallback.fire(with:)),
            userInfo: nil,
            repeats: repeats
        )
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    func makeTimer(timeInterval: TimeInterval, repeats: Bool, handler: @escaping () -> Void) -> Timer {
        let callback = TimerCallback(block: handler)
        let timer = Timer(
            timeInterval: timeInterval,
            target: callback,
            selector: #selector(TimerCallback.fire(with:)),
            userInfo: nil,
            repeats: repeats
        )
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

}

private final class TimerCallback {

    // MARK: - Properties
    private let block: () -> Void

    // MARK: - Init/Deinit
    init(block: @escaping () -> Void) {
        self.block = block
    }

    // MARK: - Internal methods
    @objc func fire(with _: Timer) {
        block()
    }

}
