// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

final class RunProvider {

    // MARK: - Properties
    private(set) var run: AppRun?
    let console = BuildLog()
    private let subject = CurrentValueSubject<Void, Never>(())
    private let processService: ProcessServiceProtocol
    private let simulatorService: SimulatorServiceProtocol
    private let deviceService: DeviceServiceProtocol
    private let xcodeAppService: XcodeAppServiceProtocol
    private let preferencesProvider: PreferencesProviderProtocol
    private var handle: ProcessHandle?

    // MARK: - Init/Deinit
    init(
        processService: ProcessServiceProtocol,
        simulatorService: SimulatorServiceProtocol,
        deviceService: DeviceServiceProtocol,
        xcodeAppService: XcodeAppServiceProtocol,
        preferencesProvider: PreferencesProviderProtocol
    ) {
        self.processService = processService
        self.simulatorService = simulatorService
        self.deviceService = deviceService
        self.xcodeAppService = xcodeAppService
        self.preferencesProvider = preferencesProvider
    }

    // MARK: - Private methods
    @MainActor
    private func update(_ id: UUID, _ change: (inout AppRun) -> Void) {
        guard var run, run.id == id else {
            return
        }
        change(&run)
        self.run = run
        subject.send()
    }

    @MainActor
    private func setState(_ state: AppRun.State, for id: UUID) {
        update(id) { $0.state = state }
    }

    @MainActor
    private func isCurrent(_ id: UUID) -> Bool {
        run?.id == id && run?.stopRequested == false
    }

    @MainActor
    private func launchOnSimulator(_ product: RunnableProduct, destination: Destination, id: UUID) async throws {
        guard let bundleIdentifier = product.bundleIdentifier else {
            throw PilotError.missingBundleIdentifier(product: product.name)
        }
        setState(.booting, for: id)
        try await simulatorService.boot(destination.id)
        if preferencesProvider.preferences.bringsSimulatorToFront {
            await simulatorService.showSimulatorApp(udid: destination.id, xcode: await xcodeAppService.activeXcode())
        }
        guard isCurrent(id) else {
            return
        }

        setState(.installing, for: id)
        try await simulatorService.install(destination.id, app: product.productPath)
        guard isCurrent(id) else {
            return
        }

        setState(.launching, for: id)
        let (stream, handle) = simulatorService.launch(destination.id, bundleIdentifier: bundleIdentifier)
        await attach(stream, handle: handle, id: id)
    }

    @MainActor
    private func launchOnDevice(_ product: RunnableProduct, destination: Destination, id: UUID) async throws {
        guard let bundleIdentifier = product.bundleIdentifier else {
            throw PilotError.missingBundleIdentifier(product: product.name)
        }
        setState(.installing, for: id)
        let (installStream, installHandle) = deviceService.install(destination.id, app: product.productPath)
        handle = installHandle
        let status = await consume(installStream, id: id)
        guard isCurrent(id) else {
            return
        }
        guard status == .zero else {
            throw PilotError.launchFailed(Localizations.Run.installFailed(destination.name))
        }

        setState(.launching, for: id)
        let (stream, handle) = deviceService.launch(destination.id, bundleIdentifier: bundleIdentifier)
        await attach(stream, handle: handle, id: id)
    }

    @MainActor
    private func launchOnMac(_ product: RunnableProduct, id: UUID) async {
        let executable = product.executablePath ?? product.productPath
        // Started directly rather than through `open`, so its stdout lands in the console
        let (stream, handle) = processService.stream(Command(executable, []))
        if product.isApplication {
            xcodeAppService.activate(processIdentifier: handle.processIdentifier)
        }
        await attach(stream, handle: handle, id: id)
    }

    /// Streams the app's output into the console until the process attached to it exits
    @MainActor
    private func attach(_ stream: AsyncStream<ProcessOutput>, handle: ProcessHandle, id: UUID) async {
        self.handle = handle
        setState(.running, for: id)
        let status = await consume(stream, id: id)
        self.handle = nil
        setState(.exited(code: status), for: id)
    }

    @MainActor
    private func consume(_ stream: AsyncStream<ProcessOutput>, id: UUID) async -> Int32 {
        var status = Constants.unknownStatus
        for await output in stream {
            switch output {
            case .lines(let lines):
                guard run?.id == id else {
                    continue
                }
                console.append(lines)
                subject.send()
            case .exit(let code):
                status = code
            }
        }
        return status
    }

}

// MARK: - RunProviderProtocol
extension RunProvider: RunProviderProtocol {

    var publisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    @MainActor
    func launch(_ product: RunnableProduct, on destination: Destination) async {
        await stop()

        let run = AppRun(product: product, destination: destination)
        self.run = run
        console.reset()
        subject.send()

        do {
            if destination.isSimulator {
                try await launchOnSimulator(product, destination: destination, id: run.id)
            } else if destination.isPhysicalDevice {
                try await launchOnDevice(product, destination: destination, id: run.id)
            } else {
                await launchOnMac(product, id: run.id)
            }
        } catch {
            guard self.run?.id == run.id else {
                return
            }
            console.append([error.localizedDescription])
            setState(.failed(message: error.localizedDescription), for: run.id)
        }
    }

    @MainActor
    func stop() async {
        guard let current = run, current.isActive else {
            return
        }
        update(current.id) { $0.stopRequested = true }
        if current.destination.isSimulator, let bundleIdentifier = current.product.bundleIdentifier {
            await simulatorService.terminate(current.destination.id, bundleIdentifier: bundleIdentifier)
        }
        handle?.cancel(gracePeriod: Constants.stopGracePeriod)
        handle = nil
        if run?.id == current.id, run?.isActive == true {
            setState(.exited(code: .zero), for: current.id)
        }
    }

}

private enum Constants {
    static let unknownStatus: Int32 = -1
    static let stopGracePeriod: TimeInterval = 2
}
