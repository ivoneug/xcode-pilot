// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

enum AppInfo {

    // MARK: - Static properties
    static var version: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? String.empty
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? String.empty
        return "\(version) (\(build))"
    }

    /// Whether the process is the host of the unit tests, which must not set up the menu bar item
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

}
