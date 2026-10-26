// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

@MainActor
final class ExportViewModel: IdentifiableObject {

    // MARK: - Properties
    @Published var method: ExportMethod
    @Published var isUpload = false
    let archive: ArchiveInfo
    let methods: [ExportMethod]
    private let navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>
    private let buildProvider: BuildProviderProtocol
    private let preferencesProvider: PreferencesProviderProtocol

    // MARK: - Computed properties
    var actionTitle: String {
        isUpload && method.canUpload ? Localizations.Export.uploadAction : Localizations.Export.exportAction
    }

    var destinationDescription: String {
        guard isUpload == false || method.canUpload == false else {
            return Localizations.Export.uploadDescription
        }
        let folder = (preferencesProvider.exportDirectory.path as NSString).abbreviatingWithTildeInPath
        return Localizations.Export.folderDescription(folder)
    }

    // MARK: - Init/Deinit
    init(
        archive: ArchiveInfo,
        navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>,
        buildProvider: BuildProviderProtocol,
        preferencesProvider: PreferencesProviderProtocol
    ) {
        self.archive = archive
        self.navigation = navigation
        self.buildProvider = buildProvider
        self.preferencesProvider = preferencesProvider
        methods = ExportMethod.methods(forMac: archive.isMac)
        method = methods.first ?? .appStoreConnect
    }

    // MARK: - Internal methods
    func export() {
        buildProvider.export(archive, method: method, upload: isUpload && method.canUpload)
        navigation.send(.dismissExport)
    }

    func cancel() {
        navigation.send(.dismissExport)
    }

}
