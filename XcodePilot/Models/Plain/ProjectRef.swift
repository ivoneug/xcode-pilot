// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// A buildable container on disk: an `.xcodeproj`, an `.xcworkspace` or a Swift package directory
struct ProjectRef: Codable, Hashable, Identifiable {

    // MARK: - Nested types
    enum Kind: String, Codable {
        case project
        case workspace
        case package
    }

    // MARK: - Properties
    /// Path to the `.xcodeproj` / `.xcworkspace` bundle, or to the package directory
    let path: String
    let kind: Kind

    // MARK: - Computed properties
    var id: String {
        path
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }

    var name: String {
        switch kind {
        case .package:
            return url.lastPathComponent
        case .project, .workspace:
            return url.deletingPathExtension().lastPathComponent
        }
    }

    /// Directory xcodebuild runs in
    var directory: URL {
        switch kind {
        case .package:
            return url
        case .project, .workspace:
            return url.deletingLastPathComponent()
        }
    }

    /// Arguments that select this container for xcodebuild. A package is picked up from the directory.
    var xcodebuildArguments: [String] {
        switch kind {
        case .project:
            return ["-project", path]
        case .workspace:
            return ["-workspace", path]
        case .package:
            return []
        }
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    var displayPath: String {
        (path as NSString).abbreviatingWithTildeInPath
    }

    var symbolName: String {
        switch kind {
        case .project:
            return "hammer"
        case .workspace:
            return "square.stack.3d.up"
        case .package:
            return "shippingbox"
        }
    }

}

extension ProjectRef {

    // MARK: - Static methods
    /// Resolves whatever the user picked (a bundle, `Package.swift`, or a folder) into a project.
    /// A folder prefers a workspace, then a project, then a package manifest.
    static func resolve(_ url: URL) -> ProjectRef? {
        let url = url.standardizedFileURL
        switch url.pathExtension {
        case Constants.workspaceExtension:
            // `Foo.xcodeproj/project.xcworkspace` is an implementation detail of the project
            if url.deletingLastPathComponent().pathExtension == Constants.projectExtension {
                return ProjectRef(path: url.deletingLastPathComponent().path, kind: .project)
            }
            return ProjectRef(path: url.path, kind: .workspace)
        case Constants.projectExtension:
            return ProjectRef(path: url.path, kind: .project)
        default:
            break
        }

        if url.lastPathComponent == Constants.packageManifest {
            return ProjectRef(path: url.deletingLastPathComponent().path, kind: .package)
        }
        return resolveDirectory(url)
    }

    // MARK: - Private methods
    private static func resolveDirectory(_ url: URL) -> ProjectRef? {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return nil
        }

        let children = (try? fileManager.contentsOfDirectory(atPath: url.path))?.sorted() ?? []
        if let workspace = children.first(where: { $0.hasSuffix(".\(Constants.workspaceExtension)") }) {
            return ProjectRef(path: url.appendingPathComponent(workspace).path, kind: .workspace)
        }
        if let project = children.first(where: { $0.hasSuffix(".\(Constants.projectExtension)") }) {
            return ProjectRef(path: url.appendingPathComponent(project).path, kind: .project)
        }
        if children.contains(Constants.packageManifest) {
            return ProjectRef(path: url.path, kind: .package)
        }
        return nil
    }

}

private enum Constants {
    static let workspaceExtension = "xcworkspace"
    static let projectExtension = "xcodeproj"
    static let packageManifest = "Package.swift"
}
