// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import ApplicationServices

final class XcodeAppService {

    // MARK: - Properties
    private let processService: ProcessServiceProtocol

    // MARK: - Init/Deinit
    init(processService: ProcessServiceProtocol) {
        self.processService = processService
    }

    // MARK: - Private methods
    private func xcodeURL() async -> URL? {
        if let active = await activeXcode(), FileManager.default.fileExists(atPath: active.path) {
            return active
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: Constants.xcodeBundleIdentifier)
    }

    private func open(_ urls: [URL], with application: URL) async {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        _ = try? await NSWorkspace.shared.open(urls, withApplicationAt: application, configuration: configuration)
    }

    @MainActor
    private func runningXcode(at url: URL) async throws -> NSRunningApplication {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: Constants.xcodeBundleIdentifier)
        if let application = running.first(where: { $0.bundleURL == url }) ?? running.first {
            application.activate()
            return application
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        return try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    }

    private func menuItem(in application: AXUIElement, menu menuTitle: String, title: String) -> AXUIElement? {
        guard let menuBar: AXUIElement = attribute(application, kAXMenuBarAttribute) else {
            return nil
        }
        let barItems: [AXUIElement] = attribute(menuBar, kAXChildrenAttribute) ?? []
        guard let barItem = barItems.first(where: { (attribute($0, kAXTitleAttribute) as String?) == menuTitle }) else {
            return nil
        }
        let menus: [AXUIElement] = attribute(barItem, kAXChildrenAttribute) ?? []
        for menu in menus {
            let items: [AXUIElement] = attribute(menu, kAXChildrenAttribute) ?? []
            if let item = items.first(where: { (attribute($0, kAXTitleAttribute) as String?) == title }) {
                return item
            }
        }
        return nil
    }

    private func attribute<Value>(_ element: AXUIElement, _ name: String) -> Value? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value as? Value
    }

}

// MARK: - XcodeAppServiceProtocol
extension XcodeAppService: XcodeAppServiceProtocol {

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibility() {
        // `kAXTrustedCheckOptionPrompt` spelled out: the imported global isn't concurrency safe
        let options = [Constants.trustedCheckOptionPrompt: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        if let url = Constants.accessibilitySettingsUrl {
            NSWorkspace.shared.open(url)
        }
    }

    func installedXcodes() -> [URL] {
        let fileManager = FileManager.default
        let roots = [URL(fileURLWithPath: "/Applications"), fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        return roots
            .flatMap { (try? fileManager.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? [] }
            .filter { $0.pathExtension == "app" && $0.lastPathComponent.hasPrefix(Constants.xcodeNamePrefix) }
            .filter { fileManager.fileExists(atPath: $0.appendingPathComponent(Constants.xcodebuildPath).path) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    func activeXcode() async -> URL? {
        var developerDirectory = processService.developerDirectory
        if developerDirectory?.isEmpty != false {
            let result = await processService.run(Command(Constants.xcodeSelect, ["-p"]))
            developerDirectory = result.succeeded ? result.output.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        }
        guard let developerDirectory, developerDirectory.hasSuffix(Constants.developerSuffix) else {
            return nil
        }
        // `/Applications/Xcode.app/Contents/Developer` → `/Applications/Xcode.app`
        return URL(fileURLWithPath: developerDirectory).deletingLastPathComponent().deletingLastPathComponent()
    }

    func recentProjects(limit: Int) -> [ProjectRef] {
        let fileManager = FileManager.default
        let derivedData = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(Constants.derivedDataPath)
        let folders = (try? fileManager.contentsOfDirectory(at: derivedData, includingPropertiesForKeys: nil)) ?? []
        var found: [ProjectRef: Date] = [:]
        for folder in folders {
            guard let data = try? Data(contentsOf: folder.appendingPathComponent("info.plist")),
                  let info = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let path = info[Constants.workspacePathKey] as? String,
                  fileManager.fileExists(atPath: path),
                  let project = ProjectRef.resolve(URL(fileURLWithPath: path)) else {
                continue
            }
            let date = info[Constants.lastAccessedKey] as? Date ?? .distantPast
            found[project] = max(found[project] ?? .distantPast, date)
        }
        return found.sorted { $0.value > $1.value }.prefix(limit).map(\.key)
    }

    func open(_ project: ProjectRef) async {
        guard let xcode = await xcodeURL() else {
            return
        }
        await open([project.url], with: xcode)
    }

    func showInOrganizer(_ archive: URL) async {
        guard let xcode = await xcodeURL() else {
            return
        }
        await open([archive], with: xcode)
    }

    func show(_ window: XcodeWindow) async throws {
        guard isAccessibilityTrusted else {
            requestAccessibility()
            throw PilotError.accessibilityRequired
        }
        guard let xcode = await xcodeURL() else {
            throw PilotError.xcodeNotFound
        }

        // Xcode has neither a URL scheme nor an AppleScript command for these windows
        let application = try await runningXcode(at: xcode)
        let element = AXUIElementCreateApplication(application.processIdentifier)
        // A freshly launched Xcode needs a while to build its menu bar
        for _ in .zero..<Constants.menuLookupAttempts {
            if let item = menuItem(in: element, menu: Constants.windowMenu, title: window.menuItemTitle) {
                AXUIElementPerformAction(item, kAXPressAction as CFString)
                await MainActor.run {
                    _ = application.activate()
                }
                return
            }
            try await Task.sleep(nanoseconds: Constants.menuLookupInterval)
        }
        throw PilotError.menuItemNotFound(window.menuItemTitle)
    }

    func open(file: String, line: Int?, column: Int?, editor: EditorChoice) {
        if editor == .xcode {
            var arguments = ["xed"]
            if let line {
                arguments += ["--line", String(line)]
            }
            arguments.append(file)
            Task { [processService] in
                _ = await processService.run(Command(Constants.xcrun, arguments))
            }
            return
        }

        guard let scheme = editor.urlScheme else {
            NSWorkspace.shared.open(URL(fileURLWithPath: file))
            return
        }
        var location = file
        if let line {
            location += ":\(line)"
            if let column {
                location += ":\(column)"
            }
        }
        let encoded = location.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? location
        if let url = URL(string: "\(scheme)://file\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }

    func reveal(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    func activate(processIdentifier: Int32) {
        DispatchQueue.main.async {
            _ = NSRunningApplication(processIdentifier: processIdentifier)?.activate()
        }
    }

}

private enum Constants {
    static let xcodeBundleIdentifier = "com.apple.dt.Xcode"
    static let xcodeNamePrefix = "Xcode"
    static let xcodebuildPath = "Contents/Developer/usr/bin/xcodebuild"
    static let developerSuffix = "/Contents/Developer"
    static let xcodeSelect = "/usr/bin/xcode-select"
    static let xcrun = "/usr/bin/xcrun"
    static let derivedDataPath = "Library/Developer/Xcode/DerivedData"
    static let workspacePathKey = "WorkspacePath"
    static let lastAccessedKey = "LastAccessedDate"
    static let windowMenu = "Window"
    static let menuLookupAttempts = 60
    static let menuLookupInterval: UInt64 = 500_000_000
    static let trustedCheckOptionPrompt = "AXTrustedCheckOptionPrompt"
    static let accessibilitySettingsUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
}
