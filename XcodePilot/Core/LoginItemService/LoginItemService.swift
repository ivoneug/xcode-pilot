// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation
import ServiceManagement

final class LoginItemService {}

// MARK: - LoginItemServiceProtocol
extension LoginItemService: LoginItemServiceProtocol {

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

}
