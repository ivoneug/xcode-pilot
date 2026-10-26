// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Outcome of a test run, from the result bundle
struct TestSummary: Hashable {

    // MARK: - Properties
    let passed: Int
    let failed: Int
    let skipped: Int
    let failures: [BuildIssue]

    // MARK: - Computed properties
    var description: String {
        var parts = [Localizations.Test.passed(passed)]
        if failed > .zero {
            parts.append(Localizations.Test.failed(failed))
        }
        if skipped > .zero {
            parts.append(Localizations.Test.skipped(skipped))
        }
        return parts.joined(separator: ", ")
    }

}
