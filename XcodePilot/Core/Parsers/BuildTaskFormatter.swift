// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Turns build system task lines into short human readable steps
enum BuildTaskFormatter {

    // MARK: - Internal methods
    static func task(from line: String) -> BuildTask? {
        guard line.hasSuffix("')"), line.contains(" (in target '"), let match = line.wholeMatch(of: Constants.taskLine) else {
            return nil
        }
        let tokens = tokenize(String(match.1))
        guard let kind = tokens.first else {
            return nil
        }
        return BuildTask(
            kind: kind,
            title: title(kind: kind, arguments: Array(tokens.dropFirst())),
            target: String(match.2),
            project: String(match.3)
        )
    }

    /// Splits on spaces, honouring the backslash escaped spaces xcodebuild prints in paths and titles
    static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = String.empty
        var isEscaping = false
        for character in text {
            if isEscaping {
                current.append(character)
                isEscaping = false
            } else if character == "\\" {
                isEscaping = true
            } else if character == " " {
                if current.isEmpty == false {
                    tokens.append(current)
                }
                current = String.empty
            } else {
                current.append(character)
            }
        }
        if current.isEmpty == false {
            tokens.append(current)
        }
        return tokens
    }

    static func title(kind: String, arguments: [String]) -> String {
        let source = arguments.first { argument in
            argument.hasPrefix("/") && Constants.sourceExtensions.contains(URL(fileURLWithPath: argument).pathExtension.lowercased())
        }
        let described = arguments.first { $0.contains(" ") }
        let firstPath = arguments.first { $0.hasPrefix("/") }

        switch kind {
        // The batch and the per-file lines of one compile read the same, so the parser shows one
        case "SwiftCompile", "CompileSwift", "CompileC", "CompileMetalFile", "CompileStoryboard", "CompileXIB":
            return Localizations.Task.compiling(fileName(source ?? firstPath))
        case "CompileSwiftSources":
            return Localizations.Task.compilingSwiftSources
        case "SwiftEmitModule", "EmitSwiftModule":
            return Localizations.Task.emittingModule
        case "SwiftExplicitDependencyGeneratePcm",
             "SwiftExplicitDependencyCompileModuleFromInterface",
             "ScanDependencies",
             "PrecompileModule":
            let module = fileName(firstPath).components(separatedBy: "-").first ?? String.empty
            return module.isEmpty ? Localizations.Task.buildingModules : Localizations.Task.buildingModule(module)
        case "Ld", "Libtool", "CreateUniversalBinary":
            return Localizations.Task.linking(fileName(firstPath))
        case "CodeSign":
            return Localizations.Task.signing(fileName(firstPath))
        case "CompileAssetCatalog", "CompileAssetCatalogVariant":
            return Localizations.Task.compilingAssets
        case "PhaseScriptExecution":
            return Localizations.Task.runningScript(arguments.first ?? String.empty)
        case "ProcessInfoPlistFile":
            return Localizations.Task.processing(fileName(arguments.last))
        case "CopySwiftLibs":
            return Localizations.Task.copyingSwiftLibraries
        case "CpResource", "Copy", "CpHeader", "CopyPlistFile", "CopyStringsFile", "Ditto":
            return Localizations.Task.copying(fileName(firstPath))
        case "GenerateDSYMFile":
            return Localizations.Task.generatingDsym
        case "ExtractAppIntentsMetadata", "AppIntentsSSUTraining":
            return Localizations.Task.processingAppIntents
        case "Validate", "ValidateEmbeddedBinary":
            return Localizations.Task.validating(fileName(firstPath))
        default:
            if kind.hasPrefix("SwiftDriver") {
                return Localizations.Task.planningSwiftBuild
            }
            return described ?? splitCamelCase(kind)
        }
    }

    /// Housekeeping tasks every target runs; they count as steps but clutter the condensed log
    static func isBookkeeping(_ kind: String) -> Bool {
        Constants.bookkeepingKinds.contains(kind)
    }

    /// Lines that are only interesting in the full log
    static func isNoise(_ line: String) -> Bool {
        if Constants.noisePrefixes.contains(where: line.hasPrefix) {
            return true
        }
        // Internal logging: "2026-10-26 13:01:25.073 xcodebuild[33991:1892634] ..."
        return line.first?.isNumber == true && line.contains(" xcodebuild[")
    }

    /// Top level steps that come before or around the target tasks
    static func phaseTitle(for line: String) -> String? {
        if let phase = Constants.phases[line] {
            return phase
        }
        if Constants.packagePrefixes.contains(where: line.hasPrefix) {
            return Localizations.Phase.resolvingPackages
        }
        return nil
    }

    // MARK: - Private methods
    private static func fileName(_ path: String?) -> String {
        path.map { URL(fileURLWithPath: $0).lastPathComponent } ?? String.empty
    }

    /// `ConstructStubExecutorLinkFileList` → `Construct stub executor link file list`, acronyms stay whole
    private static func splitCamelCase(_ text: String) -> String {
        let characters = Array(text)
        var words: [String] = []
        var current = String.empty
        for (index, character) in characters.enumerated() {
            let previous = index > .zero ? characters[index - 1] : nil
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            let startsWord = character.isUppercase
                && (previous?.isLowercase == true || (previous?.isUppercase == true && next?.isLowercase == true))
            if startsWord, current.isEmpty == false {
                words.append(current)
                current = String.empty
            }
            current.append(character)
        }
        words.append(current)
        let sentence = words.enumerated().map { index, word in
            index > .zero && word.count > 1 && word.dropFirst().allSatisfy(\.isLowercase) ? word.lowercased() : word
        }
        return sentence.joined(separator: String.space)
    }

}

private enum Constants {
    static let taskLine = #/(\S.*?) \(in target '(.*)' from project '(.*)'\)/#
    static let sourceExtensions: Set<String> = ["swift", "m", "mm", "c", "cc", "cpp", "cxx", "metal", "s", "storyboard", "xib"]
    static let noisePrefixes = [
        "Command line invocation:", "Build description signature:", "Build description path:",
        "Writing result bundle at path:", "Result bundle written to path:", "User defaults from command line:",
        "Build settings from command line:", "ExecuteExternalTool ", "ClangStatCache ", "Ignoring --"
    ]
    static let bookkeepingKinds: Set<String> = [
        "WriteAuxiliaryFile", "MkDir", "CreateBuildDirectory", "SymLink", "Touch", "RegisterExecutionPolicyException",
        "ConstructStubExecutorLinkFileList", "ProcessProductPackaging", "ProcessProductPackagingDER", "SwiftMergeGeneratedHeaders",
        "SwiftDriverJobDiscovery", "RegisterWithLaunchServices"
    ]
    static let packagePrefixes = ["Fetching from ", "Cloning ", "Checking out ", "Resolved source packages", "Fetching "]
    static let phases: [String: String] = [
        "Resolve Package Graph": Localizations.Phase.resolvingPackages,
        "Prepare packages": Localizations.Phase.preparingPackages,
        "ComputeTargetDependencyGraph": Localizations.Phase.computingDependencies,
        "ComputePackagePrebuildTargetDependencyGraph": Localizations.Phase.computingDependencies,
        "CreateBuildDescription": Localizations.Phase.creatingBuildDescription,
        "GatherProvisioningInputs": Localizations.Phase.gatheringProvisioningInputs,
        "CreateBuildRequest": Localizations.Phase.preparingBuild,
        "SendProjectDescription": Localizations.Phase.preparingBuild,
        "CreateBuildOperation": Localizations.Phase.preparingBuild
    ]
}
