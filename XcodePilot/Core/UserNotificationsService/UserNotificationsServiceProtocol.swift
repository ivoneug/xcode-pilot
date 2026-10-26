// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol UserNotificationsServiceProtocol {
    /**
     Whether the user allowed notifications
     */
    var isGranted: Bool { get }
    /**
     Asks for the permission to show notifications
     - Parameter completion: Called with whether the user allowed them
     */
    func requestPermissions(completion: @escaping (Bool) -> Void)
    /**
     Shows a notification right away
     - Parameter title: Title
     - Parameter body: Body
     - Parameter playsSound: Whether the default sound plays
     */
    func post(title: String, body: String, playsSound: Bool)
}
