// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import UserNotifications

/// Brings the panel up when a build notification is clicked
final class UserNotificationsAppDelegateProxy: NSObject {

    // MARK: - Property wrappers
    @RepositoryDependency private var appStateRepository: AppStateRepository

}

// MARK: - NSApplicationDelegate
extension UserNotificationsAppDelegateProxy: NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

}

// MARK: - UNUserNotificationCenterDelegate
extension UserNotificationsAppDelegateProxy: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        appStateRepository.panelRequests.send(.show)
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

}
