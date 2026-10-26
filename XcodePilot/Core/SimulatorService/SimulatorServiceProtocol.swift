// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol SimulatorServiceProtocol {
    /**
     Available simulators, newest runtime first
     */
    func list() async -> [Simulator]
    /**
     Boots the simulator if needed and waits until it finished booting
     - Parameter udid: Simulator identifier
     */
    func boot(_ udid: String) async throws
    /**
     Shuts the simulator down
     - Parameter udid: Simulator identifier
     */
    func shutdown(_ udid: String) async throws
    /**
     Installs an app bundle
     - Parameter udid: Simulator identifier
     - Parameter app: Path of the `.app`
     */
    func install(_ udid: String, app: String) async throws
    /**
     Launches the app and stays attached to it, streaming its stdout and stderr until it exits
     - Parameter udid: Simulator identifier
     - Parameter bundleIdentifier: App to launch
     */
    func launch(_ udid: String, bundleIdentifier: String) -> (AsyncStream<ProcessOutput>, ProcessHandle)
    /**
     Terminates the app if it runs
     */
    func terminate(_ udid: String, bundleIdentifier: String) async
    /**
     Shows Simulator.app, focused on the device if one is given
     */
    func showSimulatorApp(udid: String?, xcode: URL?) async
}
