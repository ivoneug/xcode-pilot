// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Metadata of an `.xcarchive`
struct ArchiveInfo: Hashable {

    // MARK: - Properties
    let path: URL
    let name: String
    let bundleIdentifier: String?
    let version: String?
    let build: String?
    let teamId: String?
    let isMac: Bool
    let creationDate: Date?

    // MARK: - Computed properties
    var versionDescription: String {
        switch (version, build) {
        case let (version?, build?):
            return "\(version) (\(build))"
        case let (version?, nil):
            return version
        default:
            return String.empty
        }
    }

}
