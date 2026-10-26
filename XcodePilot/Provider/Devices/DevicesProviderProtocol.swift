// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

protocol DevicesProviderProtocol: AnyObject {

    // MARK: - Properties
    /// Fires whenever the lists or their loading state change
    var publisher: AnyPublisher<Void, Never> { get }
    var simulators: [Simulator] { get }
    var devices: [PhysicalDevice] { get }
    var isRefreshing: Bool { get }
    /// Simulators currently busy booting or shutting down
    var busySimulators: Set<String> { get }

    // MARK: - Methods
    func refresh()
    func boot(_ simulator: Simulator)
    func shutdown(_ simulator: Simulator)
    func showSimulatorApp(udid: String?)

}
