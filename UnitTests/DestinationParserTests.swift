// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

final class DestinationParserTests: XCTestCase {

    // MARK: - Properties
    private let output = """
    Command line invocation:
        /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -showdestinations -scheme App

    \tAvailable destinations for the "App" scheme:
    \t\t{ platform:macOS, arch:arm64, variant:Designed for [iPad,iPhone], id:00006030-000870923CD0001C, name:My Mac }
    \t\t{ platform:macOS, arch:arm64, variant:Mac Catalyst, id:00006030-000870923CD0001C, name:My Mac }
    \t\t{ platform:iOS, arch:arm64, id:00008150-001D79381EF8401C, name:Ivan’s iPhone, Pro }
    \t\t{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
    \t\t{ platform:iOS Simulator, arch:arm64, id:B75A3EA1-E19A-4A91-843F-2B53A651B741, OS:17.5, name:iPad (10th generation) }
    \t\t{ platform:iOS Simulator, arch:arm64, id:8E1492DC-A05C-4D48-B31A-097101291DEB, OS:26.5, name:iPhone 17 }

    \tIneligible destinations for the "App" scheme:
    \t\t{ platform:visionOS, id:dvtdevice-xros:placeholder, name:Any visionOS Device, error:visionOS 26.5 is not installed. }
    """

    // MARK: - Tests
    func testParsesAvailableDestinationsOnly() {
        let destinations = DestinationParser.parse(output)

        XCTAssertEqual(destinations.count, 5)
        XCTAssertFalse(destinations.contains { $0.platform == "visionOS" })
        XCTAssertFalse(destinations.contains { $0.variant?.hasPrefix("Designed for") == true })
    }

    func testOrderAndValuesWithCommas() {
        let destinations = DestinationParser.parse(output)

        XCTAssertEqual(destinations.first?.variant, "Mac Catalyst")
        XCTAssertEqual(destinations[1].name, "Ivan’s iPhone, Pro")
        XCTAssertTrue(destinations[1].isPhysicalDevice)
        // Simulators come newest OS first
        XCTAssertEqual(destinations[2].os, "26.5")
        XCTAssertEqual(destinations.last?.isPlaceholder, true)
    }

    func testSpecifiers() {
        let destinations = DestinationParser.parse(output)
        let catalyst = destinations[0]
        let device = destinations[1]
        let placeholder = destinations[4]

        XCTAssertEqual(catalyst.specifier, "platform=macOS,arch=arm64,variant=Mac Catalyst")
        XCTAssertEqual(catalyst.archiveSpecifier, "generic/platform=macOS,variant=Mac Catalyst")
        XCTAssertEqual(device.specifier, "id=00008150-001D79381EF8401C")
        XCTAssertEqual(device.archiveSpecifier, "generic/platform=iOS")
        XCTAssertEqual(placeholder.specifier, "generic/platform=iOS")
        XCTAssertEqual(TestData.simulator.archiveSpecifier, "generic/platform=iOS")
    }

    func testRecentGroupComesFirstAndKeepsTheOtherGroups() {
        let destinations = DestinationParser.parse(output)
        let recent = [destinations[2], destinations[1]]

        let groups = DestinationGroup.make(from: destinations, recent: recent)

        XCTAssertEqual(groups.first?.title, Localizations.Destination.recent)
        XCTAssertEqual(groups.first?.destinations, recent)
        XCTAssertTrue(groups.dropFirst().contains { $0.destinations.contains(destinations[2]) })
        XCTAssertEqual(DestinationGroup.make(from: destinations).first?.title, Localizations.Destination.devices)
    }

}
