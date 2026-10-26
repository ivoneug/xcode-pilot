// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Reads the runnable target out of a `.xcscheme` file
enum SchemeFileParser {

    // MARK: - Internal methods
    /// Shared schemes first, then the per user ones Xcode creates on its own
    static func schemeFile(named scheme: String, in project: ProjectRef) -> URL? {
        let fileManager = FileManager.default
        for container in containers(of: project) {
            let shared = container.appendingPathComponent("xcshareddata/xcschemes/\(scheme).xcscheme")
            if fileManager.fileExists(atPath: shared.path) {
                return shared
            }
            let userData = container.appendingPathComponent("xcuserdata")
            let users = (try? fileManager.contentsOfDirectory(at: userData, includingPropertiesForKeys: nil)) ?? []
            for user in users {
                let file = user.appendingPathComponent("xcschemes/\(scheme).xcscheme")
                if fileManager.fileExists(atPath: file.path) {
                    return file
                }
            }
        }
        return nil
    }

    /// `BlueprintName` of the `BuildableProductRunnable` in the scheme's LaunchAction
    static func runnableTarget(in xml: String) -> String? {
        guard let launch = xml.range(of: "<LaunchAction"), let end = xml[launch.lowerBound...].range(of: "</LaunchAction>") else {
            return nil
        }
        let section = xml[launch.lowerBound..<end.upperBound]
        guard let runnable = section.range(of: "<BuildableProductRunnable"),
              let match = section[runnable.lowerBound...].firstMatch(of: Constants.blueprintName) else {
            return nil
        }
        return String(match.1)
    }

    // MARK: - Private methods
    private static func containers(of project: ProjectRef) -> [URL] {
        switch project.kind {
        case .project:
            return [project.url]
        case .workspace:
            // The schemes of a workspace usually live in its projects
            let siblings = (try? FileManager.default.contentsOfDirectory(at: project.directory, includingPropertiesForKeys: nil)) ?? []
            return [project.url] + siblings.filter { $0.pathExtension == "xcodeproj" }
        case .package:
            return [project.url.appendingPathComponent(".swiftpm/xcode/package.xcworkspace")]
        }
    }

}

private enum Constants {
    static let blueprintName = #/BlueprintName = "([^"]*)"/#
}
