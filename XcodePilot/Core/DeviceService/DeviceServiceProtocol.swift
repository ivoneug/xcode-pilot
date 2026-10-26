// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

protocol DeviceServiceProtocol {
    /**
     Devices CoreDevice knows about, connected ones first
     */
    func list() async -> [PhysicalDevice]
    /**
     Installs an app bundle, streaming devicectl's progress
     - Parameter device: Device identifier, UDID or name
     - Parameter app: Path of the `.app`
     */
    func install(_ device: String, app: String) -> (AsyncStream<ProcessOutput>, ProcessHandle)
    /**
     Launches the app with the console attached; devicectl forwards signals to it and waits for it to exit
     - Parameter device: Device identifier, UDID or name
     - Parameter bundleIdentifier: App to launch
     */
    func launch(_ device: String, bundleIdentifier: String) -> (AsyncStream<ProcessOutput>, ProcessHandle)
}
