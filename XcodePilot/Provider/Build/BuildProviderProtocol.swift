// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

protocol BuildProviderProtocol: AnyObject {

    // MARK: - Properties
    /// Fires whenever the activity or the log change
    var publisher: AnyPublisher<Void, Never> { get }
    /// The running or the last finished action
    var activity: BuildActivity? { get }
    var log: BuildLog { get }
    /// The archive the last successful Archive produced
    var lastArchive: ArchiveInfo? { get }
    var isBusy: Bool { get }

    // MARK: - Methods
    /// Starts an action; Run also launches the product once the build succeeded
    func start(_ action: BuildAction, request: BuildRequest)
    /// Interrupts the running action
    func cancel()
    /// Exports the archive to the export folder, or uploads it to App Store Connect
    func export(_ archive: ArchiveInfo, method: ExportMethod, upload: Bool)
    /// Forgets the finished activity, the menu bar goes back to idle
    func dismissActivity()

}
