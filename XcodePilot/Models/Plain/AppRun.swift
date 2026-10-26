// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// The app launched after a successful Run
struct AppRun: Identifiable {

    // MARK: - Nested types
    enum State: Equatable {
        case booting
        case installing
        case launching
        case running
        case exited(code: Int32)
        case failed(message: String)
    }

    // MARK: - Properties
    let id = UUID()
    let product: RunnableProduct
    let destination: Destination
    let startedAt = Date()
    var state: State = .launching
    var stopRequested = false

    // MARK: - Computed properties
    var isActive: Bool {
        switch state {
        case .booting, .installing, .launching, .running:
            return true
        case .exited, .failed:
            return false
        }
    }

    var isPreparing: Bool {
        switch state {
        case .booting, .installing, .launching:
            return true
        case .running, .exited, .failed:
            return false
        }
    }

    var stateDescription: String {
        switch state {
        case .booting:
            return Localizations.Run.booting(destination.name)
        case .installing:
            return Localizations.Run.installing(destination.name)
        case .launching:
            return Localizations.Run.launching(product.name)
        case .running:
            return Localizations.Run.running(destination.name)
        case .exited(let code):
            return code == .zero || stopRequested ? Localizations.Run.stopped : Localizations.Run.exited(Int(code))
        case .failed(let message):
            return message
        }
    }

}
