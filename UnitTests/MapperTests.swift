// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

@testable import XcodePilot
import XCTest

final class MapperTests: XCTestCase {

    // MARK: - Tests
    func testBuildResultsUseOneBasedLocations() throws {
        let json = """
        {
          "status" : "failed",
          "errors" : [{
            "issueType" : "Swift Compiler Error",
            "message" : "Cannot find 'undefinedFunction' in scope",
            "sourceURL" : "file:///tmp/My%20App/Broken.swift#EndingColumnNumber=8&StartingColumnNumber=8&StartingLineNumber=5"
          }],
          "warnings" : [{ "issueType" : "Warning", "message" : "Deprecated", "targetName" : "App" }]
        }
        """
        let issues = try JSONDecoder().decode(BuildResultsResponseDTO.self, from: TestData.json(json)).convertToPlain()

        XCTAssertEqual(issues.count, 2)
        XCTAssertEqual(issues[0].file, "/tmp/My App/Broken.swift")
        XCTAssertEqual(issues[0].line, 6)
        XCTAssertEqual(issues[0].column, 9)
        XCTAssertEqual(issues[0].category, "Swift Compiler Error")
        XCTAssertEqual(issues[1].severity, .warning)
        XCTAssertNil(issues[1].file)
        XCTAssertEqual(issues[1].target, "App")
    }

    func testTestSummaryAcceptsListAndSingleFailure() throws {
        let list = """
        { "result": "Failed", "passedTests": 3, "failedTests": 1, "skippedTests": 0,
          "testFailures": [{ "testName": "testFoo()", "targetName": "AppTests", "failureText": "XCTAssertEqual failed" }] }
        """
        let single = """
        { "result": "Failed", "passedTests": 0, "failedTests": 1, "skippedTests": 2,
          "testFailures": { "testName": "testBar()", "failureText": "Boom" } }
        """
        let first = try JSONDecoder().decode(TestSummaryResponseDTO.self, from: TestData.json(list)).convertToPlain()
        let second = try JSONDecoder().decode(TestSummaryResponseDTO.self, from: TestData.json(single)).convertToPlain()

        XCTAssertEqual(first.passed, 3)
        XCTAssertEqual(first.failures.first?.message, "testFoo(): XCTAssertEqual failed")
        XCTAssertEqual(first.failures.first?.target, "AppTests")
        XCTAssertEqual(second.skipped, 2)
        XCTAssertEqual(second.failures.count, 1)
    }

    func testSimulatorList() throws {
        let json = """
        { "devices": {
          "com.apple.CoreSimulator.SimRuntime.iOS-18-5": [
            { "udid": "A", "name": "iPhone 16", "state": "Shutdown", "isAvailable": true,
              "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-16" }
          ],
          "com.apple.CoreSimulator.SimRuntime.iOS-26-5": [
            { "udid": "B", "name": "iPad Air", "state": "Booted", "isAvailable": true,
              "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPad-Air" },
            { "udid": "C", "name": "Broken", "state": "Shutdown", "isAvailable": false }
          ]
        } }
        """
        let simulators = try JSONDecoder().decode(SimulatorListResponseDTO.self, from: TestData.json(json)).convertToPlain()

        XCTAssertEqual(simulators.map(\.udid), ["B", "A"])
        XCTAssertEqual(simulators[0].runtime, "iOS 26.5")
        XCTAssertTrue(simulators[0].isBooted)
        XCTAssertEqual(simulators[0].symbolName, "ipad")
        XCTAssertEqual(SimulatorListResponseDTO.runtimeName("com.apple.CoreSimulator.SimRuntime.watchOS-11-0"), "watchOS 11.0")
    }

    func testDeviceList() throws {
        let json = """
        { "result": { "devices": [
          { "identifier": "1", "hardwareProperties": { "udid": "U1", "platform": "iOS", "marketingName": "iPhone 11" },
            "deviceProperties": { "name": "Old Phone", "osVersionNumber": "18.7", "developerModeStatus": "enabled" },
            "connectionProperties": { "tunnelState": "unavailable", "pairingState": "paired" } },
          { "identifier": "2", "hardwareProperties": { "udid": "U2", "platform": "iOS", "marketingName": "iPhone 17" },
            "deviceProperties": { "name": "New Phone", "osVersionNumber": "27.0" },
            "connectionProperties": { "tunnelState": "connected", "pairingState": "paired", "transportType": "localNetwork" } }
        ] } }
        """
        let devices = try JSONDecoder().decode(DeviceListResponseDTO.self, from: TestData.json(json)).convertToPlain()

        XCTAssertEqual(devices.map(\.identifier), ["2", "1"])
        XCTAssertTrue(devices[0].isConnected)
        XCTAssertEqual(devices[1].isDeveloperModeEnabled, true)
        XCTAssertEqual(devices[1].udid, "U1")
    }

    func testRunnableProductPrefersSchemeTargetApplication() {
        func entry(_ target: String, type: String, name: String) -> BuildSettingsResponseDTO {
            BuildSettingsResponseDTO(target: target, buildSettings: [
                "TARGET_BUILD_DIR": "/tmp/Build/Products/Debug-iphonesimulator",
                "PRODUCT_TYPE": type,
                "FULL_PRODUCT_NAME": name,
                "EXECUTABLE_PATH": name + "/" + target,
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.\(target)"
            ])
        }
        let entries = [
            entry("Core", type: "com.apple.product-type.framework", name: "Core.framework"),
            entry("Watch", type: "com.apple.product-type.application.watchapp2", name: "Watch.app"),
            entry("App", type: "com.apple.product-type.application", name: "App.app")
        ]

        let product = entries.runnableProduct(scheme: "Other", preferredTarget: nil)
        XCTAssertEqual(product?.target, "App")
        XCTAssertEqual(product?.productPath, "/tmp/Build/Products/Debug-iphonesimulator/App.app")
        XCTAssertEqual(product?.bundleIdentifier, "com.example.App")
        XCTAssertEqual(entries.runnableProduct(scheme: "Other", preferredTarget: "Watch")?.target, "Watch")
    }

    func testProjectList() throws {
        let json = "warning: something\n{ \"workspace\": { \"name\": \"App\", \"schemes\": [\"App\", \"AppTests\"] } }"
        let data = TestData.json(json)
        let start = try XCTUnwrap(data.firstIndex(of: UInt8(ascii: "{")))
        let info = try JSONDecoder().decode(ProjectListResponseDTO.self, from: data[start...]).convertToPlain()

        XCTAssertEqual(info.schemes, ["App", "AppTests"])
        XCTAssertTrue(info.configurations.isEmpty)
    }

}
