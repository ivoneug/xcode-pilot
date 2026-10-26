// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

struct RootCoordinatorView: View {

    // MARK: - Properties
    @ObservedObject var coordinator: RootCoordinator

    // MARK: - Layout
    var body: some View {
        NavigationStack {
            PanelView(viewModel: coordinator.panelViewModel, devicesViewModel: coordinator.devicesViewModel)
                .navigation(model: $coordinator.settingsViewModel, mode: .push()) {
                    SettingsView(viewModel: $0)
                }
        }
        .navigation(model: $coordinator.exportViewModel, mode: .modalPresent()) {
            ExportView(viewModel: $0)
        }
        .frame(
            minWidth: CommonConstants.panelWidth,
            maxWidth: .infinity,
            minHeight: CommonConstants.panelHeight,
            maxHeight: .infinity
        )
    }

}
