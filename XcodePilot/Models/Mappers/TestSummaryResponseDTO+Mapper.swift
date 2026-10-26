// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension TestSummaryResponseDTO {

    // MARK: - Internal methods
    func convertToPlain() -> TestSummary {
        TestSummary(
            passed: passedTests,
            failed: failedTests,
            skipped: skippedTests,
            failures: testFailures.map { failure in
                BuildIssue(
                    severity: .error,
                    message: "\(failure.testName): \(failure.failureText)",
                    target: failure.targetName,
                    category: Localizations.Test.failureCategory
                )
            }
        )
    }

}
