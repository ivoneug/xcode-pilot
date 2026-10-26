// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation
import UserNotifications

final class UserNotificationsService {

    // MARK: - Properties
    @Protected private(set) var isGranted = false

    // MARK: - Init/Deinit
    init() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let status = settings.authorizationStatus
            self?.isGranted = status == .authorized || status == .provisional
        }
    }

}

// MARK: - UserNotificationsServiceProtocol
extension UserNotificationsService: UserNotificationsServiceProtocol {

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            self?.isGranted = granted
            completion(granted)
        }
    }

    func post(title: String, body: String, playsSound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if playsSound {
            content.sound = .default
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()

        // Asked for on the first notification rather than at launch, when it means something
        center.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self?.requestPermissions { isGranted in
                    if isGranted {
                        center.add(request)
                    }
                }
            case .authorized, .provisional:
                center.add(request)
            default:
                break
            }
        }
    }

}
