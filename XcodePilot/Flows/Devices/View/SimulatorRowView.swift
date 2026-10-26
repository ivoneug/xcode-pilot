// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

struct SimulatorRowView: View {

    // MARK: - Properties
    let simulator: Simulator
    @ObservedObject var viewModel: DevicesViewModel

    // MARK: - Computed properties
    private var isBusy: Bool {
        viewModel.busySimulators.contains(simulator.udid)
    }

    private var isSelected: Bool {
        viewModel.selectedDestinationId == simulator.udid
    }

    // MARK: - Layout
    var body: some View {
        HStack(spacing: Margin.x4) {
            Image(systemName: simulator.symbolName)
                .foregroundStyle(simulator.isBooted ? Colors.success.color : Colors.textSecondary.color)
                .frame(width: Constants.iconWidth)
            VStack(alignment: .leading, spacing: .zero) {
                Text(simulator.name)
                    .font(.system(size: Constants.titleSize, weight: isSelected ? .semibold : .regular))
                Text(simulator.isBooted ? "\(simulator.runtime) · \(Localizations.Devices.State.booted)" : simulator.runtime)
                    .font(.system(size: Constants.detailSize))
                    .foregroundStyle(Colors.textSecondary.color)
            }
            Spacer(minLength: .zero)

            if isBusy {
                ProgressView()
                    .controlSize(.mini)
            } else if simulator.isBooted {
                SymbolButton(symbolName: "macwindow", help: Localizations.Devices.show) {
                    viewModel.showInSimulatorApp(simulator)
                }
                SymbolButton(symbolName: "power", help: Localizations.Devices.shutdown) {
                    viewModel.shutdown(simulator)
                }
            } else {
                SymbolButton(symbolName: "power", help: Localizations.Devices.boot) {
                    viewModel.boot(simulator)
                }
            }
            if viewModel.canUse(simulator.udid) {
                SymbolButton(
                    symbolName: isSelected ? "checkmark.circle.fill" : "scope",
                    help: Localizations.Devices.use
                ) {
                    viewModel.use(simulator.udid)
                }
            }
        }
        .contextMenu {
            if viewModel.canUse(simulator.udid) {
                Button(Localizations.Devices.use) {
                    viewModel.use(simulator.udid)
                }
            }
            Button(simulator.isBooted ? Localizations.Devices.shutdown : Localizations.Devices.boot) {
                simulator.isBooted ? viewModel.shutdown(simulator) : viewModel.boot(simulator)
            }
            Button(Localizations.Devices.show) {
                viewModel.showInSimulatorApp(simulator)
            }
        }
    }

}

private enum Constants {
    static let iconWidth: CGFloat = 18
    static let titleSize: CGFloat = 12
    static let detailSize: CGFloat = 10.5
}
