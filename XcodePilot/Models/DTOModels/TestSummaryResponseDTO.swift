// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// `xcrun xcresulttool get test-results summary --path <bundle>`
struct TestSummaryResponseDTO: Decodable {

    // MARK: - Nested types
    struct Failure: Decodable {
        let testName: String
        let targetName: String?
        let failureText: String
    }

    private enum CodingKeys: String, CodingKey {
        case result
        case passedTests
        case failedTests
        case skippedTests
        case testFailures
    }

    // MARK: - Properties
    let result: String
    let passedTests: Int
    let failedTests: Int
    let skippedTests: Int
    let testFailures: [Failure]

    // MARK: - Init/Deinit
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decode(String.self, forKey: .result)
        passedTests = try container.decodeIfPresent(Int.self, forKey: .passedTests) ?? .zero
        failedTests = try container.decodeIfPresent(Int.self, forKey: .failedTests) ?? .zero
        skippedTests = try container.decodeIfPresent(Int.self, forKey: .skippedTests) ?? .zero
        // The schema describes a single object, real bundles carry a list
        if let list = try? container.decodeIfPresent([Failure].self, forKey: .testFailures) {
            testFailures = list
        } else if let single = try? container.decodeIfPresent(Failure.self, forKey: .testFailures) {
            testFailures = [single]
        } else {
            testFailures = []
        }
    }

}
