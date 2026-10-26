// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension DeviceListResponseDTO {

    // MARK: - Internal methods
    func convertToPlain() -> [PhysicalDevice] {
        result.devices
            .map { $0.convertToPlain() }
            .sorted { lhs, rhs in
                guard lhs.isConnected == rhs.isConnected else {
                    return lhs.isConnected
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

}

extension DeviceListResponseDTO.Device {

    // MARK: - Internal methods
    func convertToPlain() -> PhysicalDevice {
        PhysicalDevice(
            identifier: identifier,
            udid: hardwareProperties?.udid,
            name: deviceProperties?.name ?? hardwareProperties?.marketingName ?? identifier,
            platform: hardwareProperties?.platform ?? String.empty,
            model: hardwareProperties?.marketingName ?? hardwareProperties?.productType ?? String.empty,
            osVersion: deviceProperties?.osVersionNumber,
            tunnelState: connectionProperties?.tunnelState,
            pairingState: connectionProperties?.pairingState,
            transport: connectionProperties?.transportType,
            isDeveloperModeEnabled: deviceProperties?.developerModeStatus.map { $0 == Constants.enabled }
        )
    }

}

private enum Constants {
    static let enabled = "enabled"
}
