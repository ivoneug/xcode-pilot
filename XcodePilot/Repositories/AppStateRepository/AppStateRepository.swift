// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

/// State of the app shell that features need to know about
final class AppStateRepository {

    // MARK: - Nested types
    enum PanelRequest {
        case show
        case toggle
    }

    // MARK: - Static properties
    static let shared = AppStateRepository()

    // MARK: - Properties
    /// Whether the panel is on screen, either as the popover or as the detached window
    let isPanelVisible = CurrentValueSubject<Bool, Never>(false)
    /// Something outside the panel (a notification, a shortcut) asks to bring it up
    let panelRequests = PassthroughSubject<PanelRequest, Never>()

}
