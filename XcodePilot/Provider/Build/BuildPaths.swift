// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Where result bundles, archives and exports are written
enum BuildPaths {

    // MARK: - Internal methods
    /// A fresh path: xcodebuild refuses to write a result bundle over an existing one
    static func makeResultBundle() -> URL {
        resultBundlesFolder.appendingPathComponent("\(UUID().uuidString).xcresult")
    }

    /// Xcode's own Archives folder, so the Organizer lists the archive like one made by Xcode
    static func makeArchive(scheme: String) -> URL {
        let now = Date()
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(Constants.archivesPath)
            .appendingPathComponent(Constants.dayFormatter.string(from: now))
            .appendingPathComponent("\(scheme) \(Constants.timeFormatter.string(from: now)).xcarchive")
    }

    static func makeExportFolder(in directory: URL, name: String) -> URL {
        directory.appendingPathComponent("\(name) \(Constants.timeFormatter.string(from: Date()))")
    }

    /// Keeps the cache from growing: only the newest bundles are worth reopening
    static func removeOldResultBundles(keeping current: URL) {
        let fileManager = FileManager.default
        let bundles = (try? fileManager.contentsOfDirectory(
            at: resultBundlesFolder,
            includingPropertiesForKeys: [.creationDateKey]
        )) ?? []
        let sorted = bundles.sorted { creationDate(of: $0) > creationDate(of: $1) }
        for bundle in sorted.dropFirst(Constants.keptResultBundles) where bundle != current {
            try? fileManager.removeItem(at: bundle)
        }
    }

    // MARK: - Private methods
    private static var resultBundlesFolder: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let folder = caches
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? Constants.fallbackBundleIdentifier)
            .appendingPathComponent(Constants.resultBundlesFolder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func creationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
    }

}

private enum Constants {
    static let archivesPath = "Library/Developer/Xcode/Archives"
    static let resultBundlesFolder = "ResultBundles"
    static let fallbackBundleIdentifier = "dev.ivon.XcodePilot"
    static let keptResultBundles = 5
    static let dayFormatter = makeFormatter("yyyy-MM-dd")
    static let timeFormatter = makeFormatter("yyyy-MM-dd, HH.mm.ss")

    static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}
