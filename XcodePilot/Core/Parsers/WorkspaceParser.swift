// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Reads `contents.xcworkspacedata`
enum WorkspaceParser {

    // MARK: - Internal methods
    /// Projects a workspace references, CocoaPods' own project excluded
    static func projects(in workspace: ProjectRef) -> [ProjectRef] {
        let contents = workspace.url.appendingPathComponent("contents.xcworkspacedata")
        guard let xml = try? String(contentsOf: contents, encoding: .utf8) else {
            return []
        }
        return xml.matches(of: Constants.location).compactMap { match in
            let kind = String(match.1)
            let location = String(match.2)
            guard location.hasSuffix(".xcodeproj") else {
                return nil
            }
            let url = kind == "absolute" ? URL(fileURLWithPath: location) : workspace.directory.appendingPathComponent(location)
            guard url.lastPathComponent.hasPrefix(Constants.podsPrefix) == false else {
                return nil
            }
            return ProjectRef(path: url.standardizedFileURL.path, kind: .project)
        }
    }

}

private enum Constants {
    static let location = #/location = "(\w+):([^"]*)"/#
    static let podsPrefix = "Pods"
}
