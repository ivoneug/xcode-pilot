// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

struct DeviceRowView: View {

    // MARK: - Properties
    let device: PhysicalDevice
    @ObservedObject var viewModel: DevicesViewModel

    // MARK: - Computed properties
    private var isSelected: Bool {
        viewModel.selectedDestinationId == device.udid
    }

    private var details: String {
        var parts = [device.model]
        if let osVersion = device.osVersion {
            parts.append("\(device.platform) \(osVersion)")
        }
        parts.append(device.stateDescription)
        if device.isDeveloperModeEnabled == false {
            parts.append(Localizations.Devices.developerModeOff)
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Layout
    var body: some View {
        HStack(spacing: Margin.x4) {
            Image(systemName: device.symbolName)
                .foregroundStyle(device.isConnected ? Colors.success.color : Colors.textTertiary.color)
                .frame(width: Constants.iconWidth)
            VStack(alignment: .leading, spacing: .zero) {
                Text(device.name)
                    .font(.system(size: Constants.titleSize, weight: isSelected ? .semibold : .regular))
                Text(details)
                    .font(.system(size: Constants.detailSize))
                    .foregroundStyle(Colors.textSecondary.color)
                    .lineLimit(1)
            }
            Spacer(minLength: .zero)
            if viewModel.canUse(device.udid) {
                SymbolButton(
                    symbolName: isSelected ? "checkmark.circle.fill" : "scope",
                    help: Localizations.Devices.use
                ) {
                    viewModel.use(device.udid)
                }
            }
        }
        .opacity(device.isConnected ? 1 : Constants.unavailableOpacity)
    }

}

private enum Constants {
    static let iconWidth: CGFloat = 18
    static let titleSize: CGFloat = 12
    static let detailSize: CGFloat = 10.5
    static let unavailableOpacity = 0.6
}
