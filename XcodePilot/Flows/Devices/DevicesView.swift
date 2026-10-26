// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// Simulators and devices, managed without Xcode's Devices and Simulators window
struct DevicesView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: DevicesViewModel

    // MARK: - Layout
    var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: Margin.x4) {
                Button(Localizations.Devices.openSimulator) {
                    viewModel.showInSimulatorApp(nil)
                }
                Button(Localizations.Xcode.devicesAndSimulators, action: viewModel.openDevicesWindow)
                Spacer(minLength: .zero)
                if viewModel.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }
                SymbolButton(symbolName: "arrow.clockwise", help: Localizations.Devices.refresh, action: viewModel.refresh)
            }
            .controlSize(.small)
            .padding(.horizontal, Margin.x6)
            .padding(.vertical, Margin.x3)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: Constants.fontSize))
                    .foregroundStyle(Colors.failure.color)
                    .padding(.horizontal, Margin.x6)
            }

            Divider()

            List {
                if viewModel.devices.isEmpty == false {
                    Section(Localizations.Devices.devices) {
                        ForEach(viewModel.devices) { device in
                            DeviceRowView(device: device, viewModel: viewModel)
                        }
                    }
                }
                if viewModel.bootedSimulators.isEmpty == false {
                    Section(Localizations.Devices.booted) {
                        ForEach(viewModel.bootedSimulators) { simulator in
                            SimulatorRowView(simulator: simulator, viewModel: viewModel)
                        }
                    }
                }
                ForEach(viewModel.simulatorGroups) { group in
                    Section(group.runtime) {
                        ForEach(group.simulators) { simulator in
                            SimulatorRowView(simulator: simulator, viewModel: viewModel)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
        }
    }

}

private enum Constants {
    static let fontSize: CGFloat = 11
}
