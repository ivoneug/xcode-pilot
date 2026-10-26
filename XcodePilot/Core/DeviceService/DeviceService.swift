// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

final class DeviceService {

    // MARK: - Properties
    private let processService: ProcessServiceProtocol

    // MARK: - Init/Deinit
    init(processService: ProcessServiceProtocol) {
        self.processService = processService
    }

}

// MARK: - DeviceServiceProtocol
extension DeviceService: DeviceServiceProtocol {

    func list() async -> [PhysicalDevice] {
        // devicectl only writes JSON to a file
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("devices-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: output)
        }
        let result = await processService.run(Command(Constants.devicectl, ["list", "devices", "--quiet", "--json-output", output.path]))
        guard result.succeeded,
              let data = try? Data(contentsOf: output),
              let response = try? JSONDecoder().decode(DeviceListResponseDTO.self, from: data) else {
            return []
        }
        return response.convertToPlain()
    }

    func install(_ device: String, app: String) -> (AsyncStream<ProcessOutput>, ProcessHandle) {
        processService.stream(Command(Constants.devicectl, ["device", "install", "app", "--device", device, app]))
    }

    func launch(_ device: String, bundleIdentifier: String) -> (AsyncStream<ProcessOutput>, ProcessHandle) {
        processService.stream(Command(Constants.devicectl, [
            "device", "process", "launch", "--device", device, "--terminate-existing", "--console", bundleIdentifier
        ]))
    }

}

private enum Constants {
    static let devicectl = "devicectl"
}
