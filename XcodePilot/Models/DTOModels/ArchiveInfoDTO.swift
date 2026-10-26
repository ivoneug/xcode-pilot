// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// `Info.plist` at the root of an `.xcarchive`
struct ArchiveInfoDTO: Decodable {

    // MARK: - Nested types
    struct ApplicationProperties: Decodable {
        let applicationPath: String?
        let bundleIdentifier: String?
        let shortVersion: String?
        let version: String?
        let team: String?

        private enum CodingKeys: String, CodingKey {
            case applicationPath = "ApplicationPath"
            case bundleIdentifier = "CFBundleIdentifier"
            case shortVersion = "CFBundleShortVersionString"
            case version = "CFBundleVersion"
            case team = "Team"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case creationDate = "CreationDate"
        case applicationProperties = "ApplicationProperties"
    }

    // MARK: - Properties
    let name: String?
    let creationDate: Date?
    let applicationProperties: ApplicationProperties?

}
