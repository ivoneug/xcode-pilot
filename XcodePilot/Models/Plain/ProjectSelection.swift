// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// What was picked for a project last time, restored when the project is selected again
struct ProjectSelection: Codable, Hashable {

    // MARK: - Properties
    var scheme: String?
    /// `nil` builds with the configuration the scheme sets for the action
    var configuration: String?
    var destinationId: String?
    var destinationVariant: String?

}
