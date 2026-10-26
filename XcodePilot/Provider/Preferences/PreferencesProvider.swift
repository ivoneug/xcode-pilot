// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

final class PreferencesProvider {

    // MARK: - Properties
    private let subject: CurrentValueSubject<Preferences, Never>
    private let userDefaultsService: UserDefaultsServiceProtocol
    private let processService: ProcessServiceProtocol
    private let loginItemService: LoginItemServiceProtocol

    // MARK: - Init/Deinit
    init(
        userDefaultsService: UserDefaultsServiceProtocol,
        processService: ProcessServiceProtocol,
        loginItemService: LoginItemServiceProtocol
    ) {
        self.userDefaultsService = userDefaultsService
        self.processService = processService
        self.loginItemService = loginItemService

        let preferences = userDefaultsService.getModel(with: Preferences.self, by: .preferences) ?? Preferences()
        subject = CurrentValueSubject(preferences)
        processService.developerDirectory = preferences.developerDirectory
    }

}

// MARK: - PreferencesProviderProtocol
extension PreferencesProvider: PreferencesProviderProtocol {

    var preferences: Preferences {
        subject.value
    }

    var publisher: AnyPublisher<Preferences, Never> {
        subject.eraseToAnyPublisher()
    }

    var isLoginItemEnabled: Bool {
        loginItemService.isEnabled
    }

    var exportDirectory: URL {
        preferences.exportDirectory.map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(Constants.defaultExportFolder)
    }

    func update(_ change: (inout Preferences) -> Void) {
        var preferences = subject.value
        change(&preferences)
        guard preferences != subject.value else {
            return
        }
        processService.developerDirectory = preferences.developerDirectory
        userDefaultsService.saveModel(preferences, by: .preferences)
        subject.send(preferences)
    }

    func setLoginItemEnabled(_ isEnabled: Bool) {
        try? loginItemService.setEnabled(isEnabled)
        // Observers re-read the login item state along with the settings
        subject.send(subject.value)
    }

}

private enum Constants {
    static let defaultExportFolder = "Desktop"
}
