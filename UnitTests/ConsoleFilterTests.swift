// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

final class ConsoleFilterTests: XCTestCase {

    // MARK: - Properties
    private let lines = [
        "[Network] GET /feed 200",
        "[Auth] token refreshed",
        "[Network] POST /login 401",
        "[UI] feed appeared",
        "heartbeat"
    ]

    // MARK: - Tests
    func testParsingTokens() {
        XCTAssertEqual(ConsoleFilter.Token(parsing: "  [Network] "), ConsoleFilter.Token(text: "[Network]"))
        XCTAssertEqual(ConsoleFilter.Token(parsing: "-heartbeat"), ConsoleFilter.Token(text: "heartbeat", isExcluded: true))
        XCTAssertEqual(ConsoleFilter.Token(parsing: "− heartbeat"), ConsoleFilter.Token(text: "heartbeat", isExcluded: true))
        XCTAssertNil(ConsoleFilter.Token(parsing: "   "))
        XCTAssertNil(ConsoleFilter.Token(parsing: "-"))
        XCTAssertEqual(ConsoleFilter.Token(text: "heartbeat", isExcluded: true).editingString, "-heartbeat")
    }

    func testEmptyFilterShowsEverything() {
        let filter = ConsoleFilter()

        XCTAssertFalse(filter.isActive)
        XCTAssertEqual(filter.apply(to: lines), lines)
    }

    func testAnyModeShowsLinesWithOneOfTheTokens() {
        let filter = ConsoleFilter(tokens: [ConsoleFilter.Token(text: "[network]"), ConsoleFilter.Token(text: "[AUTH]")])

        XCTAssertEqual(filter.apply(to: lines), [lines[0], lines[1], lines[2]])
    }

    func testAllModeShowsLinesWithEveryToken() {
        let filter = ConsoleFilter(tokens: [ConsoleFilter.Token(text: "[Network]"), ConsoleFilter.Token(text: "40")], mode: .all)

        XCTAssertEqual(filter.apply(to: lines), [lines[2]])
    }

    func testExcludedTokensHideLinesInEitherMode() {
        let hidden = [ConsoleFilter.Token(text: "heartbeat", isExcluded: true), ConsoleFilter.Token(text: "POST", isExcluded: true)]

        XCTAssertEqual(ConsoleFilter(tokens: hidden).apply(to: lines), [lines[0], lines[1], lines[3]])
        let filter = ConsoleFilter(tokens: hidden + [ConsoleFilter.Token(text: "feed")], mode: .all)
        XCTAssertEqual(filter.apply(to: lines), [lines[0], lines[3]])
        XCTAssertEqual(filter.highlights, ["feed"])
    }

    func testDraftFiltersLikeAToken() {
        var filter = ConsoleFilter(tokens: [ConsoleFilter.Token(text: "[UI]")], draft: "-")
        XCTAssertEqual(filter.apply(to: lines), [lines[3]])

        filter.draft = "[Auth"
        XCTAssertEqual(filter.apply(to: lines), [lines[1], lines[3]])
        XCTAssertEqual(filter.highlights, ["[UI]", "[Auth"])
    }

    func testRepeatedTokenReplacesTheEarlierOne() {
        let tokens = ConsoleFilter.unique([
            ConsoleFilter.Token(text: "feed"),
            ConsoleFilter.Token(text: "[UI]"),
            ConsoleFilter.Token(text: "FEED", isExcluded: true)
        ])

        XCTAssertEqual(tokens, [ConsoleFilter.Token(text: "[UI]"), ConsoleFilter.Token(text: "FEED", isExcluded: true)])
    }

    func testFilteredLinesFollowTheLog() {
        let log = BuildLog()
        let filter = ConsoleFilter(tokens: [ConsoleFilter.Token(text: "[Network]")])
        var filtered = FilteredLines()

        log.append(Array(lines[0...1]))
        filtered.update(from: log, source: "run", filter: filter)
        XCTAssertEqual(filtered.lines, [lines[0]])

        log.append(Array(lines[2...]))
        filtered.update(from: log, source: "run", filter: filter)
        XCTAssertEqual(filtered.lines, [lines[0], lines[2]])

        filtered.update(from: log, source: "run", filter: ConsoleFilter(tokens: [ConsoleFilter.Token(text: "feed")]))
        XCTAssertEqual(filtered.lines, [lines[0], lines[3]])
    }

    func testFilteredLinesStartOverForANewRun() {
        let log = BuildLog()
        let filter = ConsoleFilter(tokens: [ConsoleFilter.Token(text: "[Network]")])
        var filtered = FilteredLines()
        log.append(lines)
        filtered.update(from: log, source: "first", filter: filter)

        log.reset()
        log.append([lines[2]])
        filtered.update(from: log, source: "second", filter: filter)

        XCTAssertEqual(filtered.lines, [lines[2]])
    }

}
