// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit

class AppDelegateProxy: NSObject {

    // MARK: - Properties
    var services: [NSApplicationDelegate] = [
        UserNotificationsAppDelegateProxy(),
        StatusBarAppDelegateProxy()
    ]

}

// MARK: - NSApplicationDelegate
extension AppDelegateProxy: NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        services.forEach { $0.applicationDidFinishLaunching?(notification) }
    }

    func applicationWillTerminate(_ notification: Notification) {
        services.forEach { $0.applicationWillTerminate?(notification) }
    }

}
