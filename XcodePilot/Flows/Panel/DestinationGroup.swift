// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// A section of the destination menu
struct DestinationGroup: Identifiable, Hashable {

    // MARK: - Properties
    let title: String
    let destinations: [Destination]

    // MARK: - Computed properties
    var id: String {
        title
    }

    // MARK: - Static methods
    /// The recently used ones on top, then this Mac and the connected devices, simulators by platform
    /// and the generic ones. A recent destination also stays in its own group, like in Xcode.
    static func make(from destinations: [Destination], recent: [Destination] = []) -> [DestinationGroup] {
        let devices = destinations.filter { $0.isMac || $0.isPhysicalDevice }
        let simulators = Dictionary(grouping: destinations.filter(\.isSimulator), by: \.platform)
        let generic = destinations.filter(\.isPlaceholder)

        var groups: [DestinationGroup] = []
        if recent.isEmpty == false {
            groups.append(DestinationGroup(title: Localizations.Destination.recent, destinations: recent))
        }
        if devices.isEmpty == false {
            groups.append(DestinationGroup(title: Localizations.Destination.devices, destinations: devices))
        }
        for platform in simulators.keys.sorted() {
            groups.append(DestinationGroup(title: platform, destinations: simulators[platform] ?? []))
        }
        if generic.isEmpty == false {
            groups.append(DestinationGroup(title: Localizations.Destination.generic, destinations: generic))
        }
        return groups
    }

}
