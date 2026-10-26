// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import SwiftUI

typealias IdentifiableObject = ObservableObject & Identifiable

@MainActor
final class RootCoordinator: IdentifiableObject {

    // MARK: - ViewModels
    @Published var panelViewModel: PanelViewModel
    @Published var devicesViewModel: DevicesViewModel
    @Published var settingsViewModel: SettingsViewModel?
    @Published var exportViewModel: ExportViewModel?

    // MARK: - Properties
    /// Whether the panel lives in its own window rather than in the menu bar popover
    @Published private(set) var isDetached = false
    private let navigation = CurrentValueSubject<NavigationEvent?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init/Deinit
    init() {
        panelViewModel = PanelViewModelFactory.build(with: navigation)
        devicesViewModel = DevicesViewModelFactory.build(with: navigation)

        bindPublishers()
    }

    // MARK: - Internal methods
    /// Called each time the panel comes on screen
    func panelWillAppear() {
        panelViewModel.appear()
        devicesViewModel.appear()
    }

    /// Called once the detached window was closed by the user
    func windowClosed() {
        isDetached = false
    }

    // MARK: - Private methods
    private func bindPublishers() {
        navigation
            .sink(receiveValue: { [weak self] event in
                guard let self, let event else {
                    return
                }
                switch event {
                case .main:
                    settingsViewModel = nil
                case .settings:
                    settingsViewModel = SettingsViewModelFactory.build(with: navigation)
                case .export(let archive):
                    exportViewModel = ExportViewModelFactory.build(archive: archive, navigation: navigation)
                case .dismissExport:
                    exportViewModel = nil
                case .detach:
                    isDetached = true
                case .attach:
                    isDetached = false
                }
            })
            .store(in: &cancellables)
    }

}

extension RootCoordinator {

    enum NavigationEvent {
        case main
        case settings
        case export(archive: ArchiveInfo)
        case dismissExport
        case detach
        case attach
    }

}
