// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// `xcodebuild -list -json`
struct ProjectListResponseDTO: Decodable {

    // MARK: - Nested types
    struct Container: Decodable {
        let schemes: [String]?
        let configurations: [String]?
    }

    // MARK: - Properties
    let project: Container?
    let workspace: Container?

}
