// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// One element of `xcodebuild -showBuildSettings -json`
struct BuildSettingsResponseDTO: Decodable {

    // MARK: - Properties
    let target: String
    let buildSettings: [String: String]

}
