// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Which console lines are shown. Like Xcode's console filter it is a set of tokens matched
/// case insensitively against each line; a token that starts with a minus hides the lines instead.
struct ConsoleFilter: Hashable {

    // MARK: - Nested types
    struct Token: Hashable {

        // MARK: - Properties
        let text: String
        /// Hides the lines that contain the text instead of showing only them
        var isExcluded: Bool

        // MARK: - Computed properties
        /// What the user types to get this token back
        var editingString: String {
            isExcluded ? Constants.exclusionPrefix + text : text
        }

        var displayString: String {
            isExcluded ? Constants.exclusionSign + text : text
        }

        // MARK: - Init/Deinit
        init(text: String, isExcluded: Bool = false) {
            self.text = text
            self.isExcluded = isExcluded
        }

        /// `-text` hides the lines with the text, anything else shows only them; blank text is no token
        init?(parsing string: String) {
            var text = string.trimmingCharacters(in: .whitespacesAndNewlines)
            let isExcluded = text.hasPrefix(Constants.exclusionPrefix) || text.hasPrefix(Constants.exclusionSign)
            if isExcluded {
                text = text.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard text.isEmpty == false else {
                return nil
            }
            self.init(text: text, isExcluded: isExcluded)
        }

    }

    /// How the tokens that show lines combine; hiding tokens always hide
    enum Mode: CaseIterable, Identifiable {
        case any
        case all

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .any:
                return Localizations.Console.Filter.matchAny
            case .all:
                return Localizations.Console.Filter.matchAll
            }
        }
    }

    // MARK: - Properties
    var tokens: [Token] = []
    /// Text typed into the field that is not a token yet; it filters as one meanwhile
    var draft = String.empty
    var mode: Mode = .any

    // MARK: - Computed properties
    /// Tokens plus the draft
    var terms: [Token] {
        tokens + (Token(parsing: draft).map { [$0] } ?? [])
    }

    var isActive: Bool {
        terms.isEmpty == false
    }

    var isEmpty: Bool {
        tokens.isEmpty && draft.isEmpty
    }

    /// Text worth marking in the shown lines
    var highlights: [String] {
        terms.filter { $0.isExcluded == false }.map(\.text)
    }

    // MARK: - Internal methods
    func matches(_ line: String) -> Bool {
        Matcher(self).matches(line)
    }

    func apply<Lines: Sequence>(to lines: Lines) -> [String] where Lines.Element == String {
        let matcher = Matcher(self)
        return lines.filter(matcher.matches)
    }

    /// Drops repeated tokens, the later one wins: typing `-text` after `text` turns it into a hiding one
    static func unique(_ tokens: [Token]) -> [Token] {
        var result: [Token] = []
        for token in tokens {
            result.removeAll { $0.text.caseInsensitiveCompare(token.text) == .orderedSame }
            result.append(token)
        }
        return result
    }

}

private extension ConsoleFilter {

    /// The filter split once into what it looks for, so long consoles are not split again per line
    struct Matcher {

        // MARK: - Properties
        let included: [String]
        let excluded: [String]
        let mode: Mode

        // MARK: - Init/Deinit
        init(_ filter: ConsoleFilter) {
            let terms = filter.terms
            included = terms.filter { $0.isExcluded == false }.map(\.text)
            excluded = terms.filter(\.isExcluded).map(\.text)
            mode = filter.mode
        }

        // MARK: - Internal methods
        func matches(_ line: String) -> Bool {
            guard excluded.contains(where: { line.range(of: $0, options: .caseInsensitive) != nil }) == false else {
                return false
            }
            guard included.isEmpty == false else {
                return true
            }
            switch mode {
            case .any:
                return included.contains { line.range(of: $0, options: .caseInsensitive) != nil }
            case .all:
                return included.allSatisfy { line.range(of: $0, options: .caseInsensitive) != nil }
            }
        }

    }

}

private enum Constants {
    static let exclusionPrefix = "-"
    static let exclusionSign = "−"
}
