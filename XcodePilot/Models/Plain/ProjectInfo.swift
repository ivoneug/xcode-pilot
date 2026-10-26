// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Schemes and build configurations reported by `xcodebuild -list`
struct ProjectInfo: Codable, Hashable {

    // MARK: - Properties
    let schemes: [String]
    let configurations: [String]

}
