// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// `xcrun xcresulttool get build-results --path <bundle>`
struct BuildResultsResponseDTO: Decodable {

    // MARK: - Nested types
    struct Issue: Decodable {
        let issueType: String?
        let message: String
        let targetName: String?
        /// `file:///path/File.swift#EndingColumnNumber=21&EndingLineNumber=4&StartingColumnNumber=21&StartingLineNumber=4`
        let sourceURL: String?
    }

    // MARK: - Properties
    let status: String?
    let errors: [Issue]?
    let warnings: [Issue]?
    let analyzerWarnings: [Issue]?

}
