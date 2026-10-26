// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

enum TestData {

    // MARK: - Static properties
    static let project = ProjectRef(path: "/tmp/App/App.xcodeproj", kind: .project)

    static let simulator = Destination(
        id: "8E1492DC-A05C-4D48-B31A-097101291DEB",
        platform: "iOS Simulator",
        name: "iPad (A16)",
        arch: "arm64",
        variant: nil,
        os: "26.5"
    )

    static let request = BuildRequest(project: project, scheme: "App", configuration: nil, destination: simulator)

    // MARK: - Static methods
    static func json(_ text: String) -> Data {
        Data(text.utf8)
    }

}
