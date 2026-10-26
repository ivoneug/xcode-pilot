// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Distribution method of `xcodebuild -exportArchive`
enum ExportMethod: String, CaseIterable, Identifiable {
    case appStoreConnect = "app-store-connect"
    case releaseTesting = "release-testing"
    case enterprise
    case debugging
    case developerId = "developer-id"
    case macApplication = "mac-application"

    // MARK: - Computed properties
    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .appStoreConnect:
            return Localizations.Export.Method.appStoreConnect
        case .releaseTesting:
            return Localizations.Export.Method.releaseTesting
        case .enterprise:
            return Localizations.Export.Method.enterprise
        case .debugging:
            return Localizations.Export.Method.debugging
        case .developerId:
            return Localizations.Export.Method.developerId
        case .macApplication:
            return Localizations.Export.Method.macApplication
        }
    }

    var canUpload: Bool {
        self == .appStoreConnect
    }

    // MARK: - Static methods
    static func methods(forMac isMac: Bool) -> [ExportMethod] {
        isMac ? [.appStoreConnect, .developerId, .debugging, .macApplication] : [.appStoreConnect, .releaseTesting, .enterprise, .debugging]
    }

    // MARK: - Internal methods
    /// Contents of the `-exportOptionsPlist` file
    func exportOptions(upload: Bool, teamId: String?) -> [String: Any] {
        var options: [String: Any] = [
            "method": rawValue,
            "signingStyle": "automatic",
            "destination": upload && canUpload ? "upload" : "export"
        ]
        if let teamId, teamId.isEmpty == false {
            options["teamID"] = teamId
        }
        if self == .appStoreConnect {
            options["uploadSymbols"] = true
            options["manageAppVersionAndBuildNumber"] = false
        }
        return options
    }

}
