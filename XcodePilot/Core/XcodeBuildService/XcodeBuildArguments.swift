// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Pure builders of xcodebuild and xcresulttool command lines
enum XcodeBuildArguments {

    // MARK: - Internal methods
    static func list(_ project: ProjectRef) -> Command {
        Command(Constants.xcodebuild, ["-list", "-json"] + project.xcodebuildArguments, in: project.directory)
    }

    static func destinations(_ project: ProjectRef, scheme: String) -> Command {
        Command(Constants.xcodebuild, ["-showdestinations", "-scheme", scheme] + project.xcodebuildArguments, in: project.directory)
    }

    static func buildSettings(_ request: BuildRequest) -> Command {
        var arguments = ["-showBuildSettings", "-json"] + request.project.xcodebuildArguments + ["-scheme", request.scheme]
        if let configuration = request.configuration {
            arguments += ["-configuration", configuration]
        }
        arguments += ["-destination", request.destination.specifier]
        return Command(Constants.xcodebuild, arguments, in: request.project.directory)
    }

    /// Build, test, clean or archive. Export goes through `exportArchive(_:exportPath:optionsPlist:)`.
    static func action(_ action: BuildAction, _ request: BuildRequest, resultBundle: URL?, archivePath: URL?) -> Command {
        var arguments: [String]
        switch action {
        case .build, .run, .export:
            arguments = ["build"]
        case .test:
            arguments = ["test"]
        case .clean:
            arguments = ["clean"]
        case .archive:
            arguments = ["archive"]
        }
        arguments += request.project.xcodebuildArguments
        arguments += ["-scheme", request.scheme]
        if let configuration = request.configuration {
            arguments += ["-configuration", configuration]
        }
        arguments += ["-destination", action == .archive ? request.destination.archiveSpecifier : request.destination.specifier]
        if let archivePath {
            arguments += ["-archivePath", archivePath.path]
        }
        if let resultBundle {
            arguments += ["-resultBundlePath", resultBundle.path]
        }
        // Signing for a device, the Mac or distribution may need profiles Xcode creates on demand
        let needsSigning = action == .archive || request.destination.isPhysicalDevice || request.destination.isMac
        if request.allowProvisioningUpdates, needsSigning {
            arguments.append("-allowProvisioningUpdates")
        }
        if request.skipMacroValidation {
            arguments += ["-skipMacroValidation", "-skipPackagePluginValidation"]
        }
        return Command(Constants.xcodebuild, arguments, in: request.project.directory)
    }

    static func exportArchive(_ archive: URL, exportPath: URL, optionsPlist: URL) -> Command {
        Command(Constants.xcodebuild, [
            "-exportArchive",
            "-archivePath", archive.path,
            "-exportPath", exportPath.path,
            "-exportOptionsPlist", optionsPlist.path,
            "-allowProvisioningUpdates"
        ])
    }

    static func buildResults(_ resultBundle: URL) -> Command {
        Command(Constants.xcresulttool, ["get", "build-results", "--path", resultBundle.path, "--compact"])
    }

    static func testSummary(_ resultBundle: URL) -> Command {
        Command(Constants.xcresulttool, ["get", "test-results", "summary", "--path", resultBundle.path, "--compact"])
    }

}

private enum Constants {
    static let xcodebuild = "xcodebuild"
    static let xcresulttool = "xcresulttool"
}
