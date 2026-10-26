// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// A compiler, linker, build system or test diagnostic
struct BuildIssue: Identifiable, Hashable {

    // MARK: - Nested types
    enum Severity: String, Hashable {
        case error
        case warning
    }

    // MARK: - Properties
    var id = UUID()
    var severity: Severity
    var message: String
    var file: String?
    var line: Int?
    var column: Int?
    /// Source excerpt and notes the compiler prints after the diagnostic
    var context: [String] = []
    var target: String?
    var category: String?

    // MARK: - Computed properties
    var fileName: String? {
        file.map { URL(fileURLWithPath: $0).lastPathComponent }
    }

    var location: String? {
        guard let file else {
            return nil
        }
        guard let line else {
            return file
        }
        guard let column else {
            return "\(file):\(line)"
        }
        return "\(file):\(line):\(column)"
    }

    var shortLocation: String? {
        guard let fileName else {
            return nil
        }
        guard let line else {
            return fileName
        }
        return "\(fileName):\(line)"
    }

    /// Clang-style text that editors and terminals recognise
    var copyText: String {
        var head = location.map { "\($0): " } ?? String.empty
        head += "\(severity.rawValue): \(message)"
        guard context.isEmpty == false else {
            return head
        }
        return ([head] + context).joined(separator: "\n")
    }

    /// Identity used to collapse the duplicates xcodebuild prints for multi-arch or batch builds
    var dedupeKey: String {
        [severity.rawValue, file ?? String.empty, "\(line ?? .zero)", "\(column ?? .zero)", message.lowercased()]
            .joined(separator: "|")
    }

}

extension Array where Element == BuildIssue {

    // MARK: - Computed properties
    var errorCount: Int {
        filter { $0.severity == .error }.count
    }

    var warningCount: Int {
        filter { $0.severity == .warning }.count
    }

    var copyText: String {
        map(\.copyText).joined(separator: "\n\n")
    }

}
