// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension SimulatorListResponseDTO {

    // MARK: - Internal methods
    func convertToPlain() -> [Simulator] {
        devices
            .flatMap { runtime, devices in
                devices
                    .filter { $0.isAvailable != false }
                    .map { device in
                        Simulator(
                            udid: device.udid,
                            name: device.name,
                            state: device.state,
                            runtime: Self.runtimeName(runtime),
                            deviceType: device.deviceTypeIdentifier ?? String.empty
                        )
                    }
            }
            .sorted { lhs, rhs in
                guard lhs.runtime == rhs.runtime else {
                    return lhs.runtime.compare(rhs.runtime, options: .numeric) == .orderedDescending
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    // MARK: - Static methods
    /// `com.apple.CoreSimulator.SimRuntime.iOS-18-5` → `iOS 18.5`
    static func runtimeName(_ identifier: String) -> String {
        guard let last = identifier.split(separator: ".").last else {
            return identifier
        }
        var parts = last.split(separator: "-").map(String.init)
        guard parts.isEmpty == false else {
            return identifier
        }
        let platform = parts.removeFirst()
        return parts.isEmpty ? platform : "\(platform) \(parts.joined(separator: String.dot))"
    }

}
