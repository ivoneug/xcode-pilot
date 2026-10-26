// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

protocol ProjectProviderProtocol: AnyObject {

    // MARK: - Properties
    /// Fires whenever the selection or the loading state changes
    var publisher: AnyPublisher<Void, Never> { get }
    /// Projects opened in this app, most recent first
    var recentProjects: [ProjectRef] { get }
    /// Projects Xcode opened recently that aren't among `recentProjects`
    var xcodeRecentProjects: [ProjectRef] { get }
    var project: ProjectRef? { get }
    var info: ProjectInfo? { get }
    var scheme: String? { get }
    /// `nil` builds with the configuration the scheme sets for the action
    var configuration: String? { get }
    var destinations: [Destination] { get }
    var destination: Destination? { get }
    /// The selected destination and the ones picked before it that the scheme still offers, newest first
    var recentDestinations: [Destination] { get }
    var isLoadingInfo: Bool { get }
    var isLoadingDestinations: Bool { get }
    var errorMessage: String? { get }
    /// What the toolbar is set to build, `nil` while something is missing
    var request: BuildRequest? { get }

    // MARK: - Methods
    func refreshRecentProjects()
    func select(_ project: ProjectRef)
    func remove(_ project: ProjectRef)
    func selectScheme(_ scheme: String)
    func selectConfiguration(_ configuration: String?)
    func selectDestination(_ destination: Destination)
    /// Reads schemes and configurations again, then the destinations
    func reload()
    func reloadDestinations()

}
