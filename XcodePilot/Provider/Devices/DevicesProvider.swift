// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

final class DevicesProvider {

    // MARK: - Properties
    private(set) var simulators: [Simulator] = []
    private(set) var devices: [PhysicalDevice] = []
    private(set) var isRefreshing = false
    private(set) var busySimulators: Set<String> = []
    private let subject = CurrentValueSubject<Void, Never>(())
    private let simulatorService: SimulatorServiceProtocol
    private let deviceService: DeviceServiceProtocol
    private let xcodeAppService: XcodeAppServiceProtocol
    private var refreshTask: Task<Void, Never>?

    // MARK: - Init/Deinit
    init(
        simulatorService: SimulatorServiceProtocol,
        deviceService: DeviceServiceProtocol,
        xcodeAppService: XcodeAppServiceProtocol
    ) {
        self.simulatorService = simulatorService
        self.deviceService = deviceService
        self.xcodeAppService = xcodeAppService
    }

    // MARK: - Private methods
    private func changeState(of simulator: Simulator, operation: @escaping (String) async throws -> Void) {
        busySimulators.insert(simulator.udid)
        subject.send()
        Task { @MainActor [weak self] in
            try? await operation(simulator.udid)
            self?.busySimulators.remove(simulator.udid)
            self?.refresh()
        }
    }

}

// MARK: - DevicesProviderProtocol
extension DevicesProvider: DevicesProviderProtocol {

    var publisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    func refresh() {
        guard refreshTask == nil else {
            return
        }
        isRefreshing = true
        subject.send()
        refreshTask = Task { @MainActor [weak self, simulatorService, deviceService] in
            // Listing devices waits for CoreDevice, simulators come back faster and are shown first
            let simulators = await simulatorService.list()
            self?.simulators = simulators
            self?.subject.send()

            let devices = await deviceService.list()
            self?.devices = devices
            self?.isRefreshing = false
            self?.refreshTask = nil
            self?.subject.send()
        }
    }

    func boot(_ simulator: Simulator) {
        changeState(of: simulator) { [simulatorService] udid in
            try await simulatorService.boot(udid)
        }
    }

    func shutdown(_ simulator: Simulator) {
        changeState(of: simulator) { [simulatorService] udid in
            try await simulatorService.shutdown(udid)
        }
    }

    func showSimulatorApp(udid: String?) {
        Task { [simulatorService, xcodeAppService] in
            await simulatorService.showSimulatorApp(udid: udid, xcode: await xcodeAppService.activeXcode())
        }
    }

}
