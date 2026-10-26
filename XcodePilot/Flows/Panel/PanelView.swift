// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

struct PanelView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: PanelViewModel
    @ObservedObject var devicesViewModel: DevicesViewModel

    // MARK: - Computed properties
    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    viewModel.alertMessage = nil
                }
            }
        )
    }

    // MARK: - Layout
    var body: some View {
        VStack(spacing: .zero) {
            PanelHeaderView(viewModel: viewModel)
            ToolbarView(viewModel: viewModel)
            ActivityCardView(viewModel: viewModel)

            Picker(String.empty, selection: $viewModel.selectedTab) {
                ForEach(PanelViewModel.Tab.allCases) { tab in
                    Text(tab.title)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, Margin.x6)
            .padding(.top, Margin.x5)
            .padding(.bottom, Margin.x2)

            Group {
                switch viewModel.selectedTab {
                case .issues:
                    IssuesListView(viewModel: viewModel)
                case .log:
                    LogPaneView(viewModel: viewModel)
                case .console:
                    ConsolePaneView(viewModel: viewModel)
                case .devices:
                    DevicesView(viewModel: devicesViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            PanelFooterView(viewModel: viewModel)
        }
        .toolbar(.hidden)
        .alert(viewModel.alertMessage ?? String.empty, isPresented: isAlertPresented) {
            Button(Localizations.Common.ok, role: .cancel) {}
            if viewModel.alertMessage == PilotError.accessibilityRequired.errorDescription {
                Button(Localizations.Common.openSettings, action: viewModel.openAccessibilitySettings)
            }
        }
    }

}
