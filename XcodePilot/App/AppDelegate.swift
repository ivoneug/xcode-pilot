// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit

final class AppDelegate: AppDelegateProxy {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

}
