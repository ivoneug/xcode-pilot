// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Everything xcodebuild needs to know about what to build
struct BuildRequest: Hashable {

    // MARK: - Properties
    let project: ProjectRef
    let scheme: String
    /// `nil` uses the configuration the scheme sets for the action
    let configuration: String?
    let destination: Destination
    var allowProvisioningUpdates = true
    var skipMacroValidation = false

    // MARK: - Computed properties
    /// Key the duration of previous runs is remembered under, to estimate the progress of the next one
    func durationKey(for action: BuildAction) -> String {
        [project.path, scheme, action.rawValue, destination.platform, configuration ?? String.empty]
            .joined(separator: "|")
    }

}
