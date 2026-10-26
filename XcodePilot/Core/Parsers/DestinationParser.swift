// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Reads the text `xcodebuild -showdestinations` prints: it has no JSON mode
enum DestinationParser {

    // MARK: - Internal methods
    /// Parses the "Available destinations" section
    static func parse(_ output: String) -> [Destination] {
        var result: [Destination] = []
        var isInAvailable = false
        for rawLine in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix(Constants.availableHeader) {
                isInAvailable = true
                continue
            }
            if line.hasPrefix(Constants.ineligibleHeader) {
                isInAvailable = false
                continue
            }
            guard isInAvailable, line.hasPrefix("{"), line.hasSuffix("}") else {
                continue
            }

            let fields = parseFields(line.dropFirst().dropLast().trimmingCharacters(in: .whitespaces))
            guard let id = fields["id"], let platform = fields["platform"], let name = fields["name"] else {
                continue
            }
            // "Designed for iPad/iPhone" on Mac would need a launch path of its own
            if let variant = fields["variant"], variant.hasPrefix(Constants.designedForPrefix) {
                continue
            }

            let destination = Destination(
                id: id,
                platform: platform,
                name: name,
                arch: fields["arch"],
                variant: fields["variant"],
                os: fields["OS"]
            )
            if result.contains(where: { $0.matches(destination) }) == false {
                result.append(destination)
            }
        }
        return sorted(result)
    }

    /// Splits `platform:iOS Simulator, id:ABC, OS:18.0, name:iPhone 16` into fields.
    /// Values may contain commas, so the text is only split in front of a known key.
    static func parseFields(_ body: String) -> [String: String] {
        let matches = body.matches(of: Constants.fieldKey)
        var fields: [String: String] = [:]
        for (index, match) in matches.enumerated() {
            let valueEnd = index + 1 < matches.count ? matches[index + 1].range.lowerBound : body.endIndex
            fields[String(match.1)] = body[match.range.upperBound..<valueEnd].trimmingCharacters(in: .whitespaces)
        }
        return fields
    }

    /// Orders destinations like Xcode's menu: this Mac, devices, then simulators with the newest OS first
    static func sorted(_ destinations: [Destination]) -> [Destination] {
        destinations.sorted { lhs, rhs in
            guard rank(lhs) == rank(rhs) else {
                return rank(lhs) < rank(rhs)
            }
            guard lhs.platform == rhs.platform else {
                return lhs.platform < rhs.platform
            }
            guard lhs.os == rhs.os else {
                return (lhs.os ?? String.empty).compare(rhs.os ?? String.empty, options: .numeric) == .orderedDescending
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    // MARK: - Private methods
    private static func rank(_ destination: Destination) -> Int {
        if destination.isMac {
            return 0
        }
        if destination.isPhysicalDevice {
            return 1
        }
        return destination.isSimulator ? 2 : 3
    }

}

private enum Constants {
    static let availableHeader = "Available destinations"
    static let ineligibleHeader = "Ineligible destinations"
    static let designedForPrefix = "Designed for"
    static let fieldKey = #/(?:^|,\s*)(platform|arch|variant|id|OS|name|error):/#
}
