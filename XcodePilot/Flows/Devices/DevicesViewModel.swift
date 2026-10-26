// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

@MainActor
final class DevicesViewModel: IdentifiableObject {

    // MARK: - Nested types
    struct SimulatorGroup: Identifiable {
        let runtime: String
        let simulators: [Simulator]

        var id: String {
            runtime
        }
    }

    // MARK: - Properties
    @Published private(set) var bootedSimulators: [Simulator] = []
    @Published private(set) var simulatorGroups: [SimulatorGroup] = []
    @Published private(set) var devices: [PhysicalDevice] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var busySimulators: Set<String> = []
    @Published private(set) var destinationIds: Set<String> = []
    @Published private(set) var selectedDestinationId: String?
    @Published var errorMessage: String?
    private let navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>
    private let devicesProvider: DevicesProviderProtocol
    private let projectProvider: ProjectProviderProtocol
    private let xcodeProvider: XcodeProviderProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init/Deinit
    init(
        navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>,
        devicesProvider: DevicesProviderProtocol,
        projectProvider: ProjectProviderProtocol,
        xcodeProvider: XcodeProviderProtocol
    ) {
        self.navigation = navigation
        self.devicesProvider = devicesProvider
        self.projectProvider = projectProvider
        self.xcodeProvider = xcodeProvider

        bindPublishers()
    }

    // MARK: - Internal methods
    func appear() {
        devicesProvider.refresh()
    }

    func refresh() {
        devicesProvider.refresh()
    }

    func boot(_ simulator: Simulator) {
        devicesProvider.boot(simulator)
    }

    func shutdown(_ simulator: Simulator) {
        devicesProvider.shutdown(simulator)
    }

    func showInSimulatorApp(_ simulator: Simulator?) {
        devicesProvider.showSimulatorApp(udid: simulator?.udid)
    }

    /// Whether the current scheme can run on the simulator or device with this identifier
    func canUse(_ identifier: String?) -> Bool {
        identifier.map(destinationIds.contains) == true
    }

    func use(_ identifier: String?) {
        guard let identifier, let destination = projectProvider.destinations.first(where: { $0.id == identifier }) else {
            return
        }
        projectProvider.selectDestination(destination)
    }

    func openDevicesWindow() {
        Task { @MainActor [weak self, xcodeProvider] in
            do {
                try await xcodeProvider.show(.devicesAndSimulators)
            } catch {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Private methods
    private func bindPublishers() {
        devicesProvider.publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.refreshDevices()
            })
            .store(in: &cancellables)

        projectProvider.publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                guard let self else {
                    return
                }
                destinationIds = Set(projectProvider.destinations.map(\.id))
                selectedDestinationId = projectProvider.destination?.id
            })
            .store(in: &cancellables)
    }

    private func refreshDevices() {
        let simulators = devicesProvider.simulators
        bootedSimulators = simulators.filter(\.isBooted)
        // Runtimes keep the provider's order: newest first
        var groups: [SimulatorGroup] = []
        for simulator in simulators where simulator.isBooted == false {
            if let index = groups.firstIndex(where: { $0.runtime == simulator.runtime }) {
                groups[index] = SimulatorGroup(runtime: simulator.runtime, simulators: groups[index].simulators + [simulator])
            } else {
                groups.append(SimulatorGroup(runtime: simulator.runtime, simulators: [simulator]))
            }
        }
        simulatorGroups = groups
        devices = devicesProvider.devices
        isRefreshing = devicesProvider.isRefreshing
        busySimulators = devicesProvider.busySimulators
    }

}
