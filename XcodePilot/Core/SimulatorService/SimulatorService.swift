// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

final class SimulatorService {

    // MARK: - Properties
    private let processService: ProcessServiceProtocol

    // MARK: - Init/Deinit
    init(processService: ProcessServiceProtocol) {
        self.processService = processService
    }

}

// MARK: - SimulatorServiceProtocol
extension SimulatorService: SimulatorServiceProtocol {

    func list() async -> [Simulator] {
        let command = Command(Constants.simctl, ["list", "devices", "available", "-j"])
        guard let data = try? await processService.stdout(command),
              let response = try? JSONDecoder().decode(SimulatorListResponseDTO.self, from: data) else {
            return []
        }
        return response.convertToPlain()
    }

    func boot(_ udid: String) async throws {
        try await processService.check(Command(Constants.simctl, ["bootstatus", udid, "-b"]))
    }

    func shutdown(_ udid: String) async throws {
        try await processService.check(Command(Constants.simctl, ["shutdown", udid]))
    }

    func install(_ udid: String, app: String) async throws {
        try await processService.check(Command(Constants.simctl, ["install", udid, app]))
    }

    func launch(_ udid: String, bundleIdentifier: String) -> (AsyncStream<ProcessOutput>, ProcessHandle) {
        // A pseudo terminal keeps the app's stdout line buffered, so print() shows up right away
        processService.stream(Command(Constants.simctl, ["launch", "--console-pty", "--terminate-running-process", udid, bundleIdentifier]))
    }

    func terminate(_ udid: String, bundleIdentifier: String) async {
        _ = await processService.run(Command(Constants.simctl, ["terminate", udid, bundleIdentifier]))
    }

    func showSimulatorApp(udid: String?, xcode: URL?) async {
        var arguments = ["-a", Constants.simulatorAppName]
        if let simulator = xcode?.appendingPathComponent(Constants.simulatorAppPath),
           FileManager.default.fileExists(atPath: simulator.path) {
            arguments = ["-a", simulator.path]
        }
        if let udid {
            arguments += ["--args", "-CurrentDeviceUDID", udid]
        }
        _ = await processService.run(Command(Constants.open, arguments))
    }

}

private enum Constants {
    static let simctl = "simctl"
    static let open = "/usr/bin/open"
    static let simulatorAppName = "Simulator"
    static let simulatorAppPath = "Contents/Developer/Applications/Simulator.app"
}
