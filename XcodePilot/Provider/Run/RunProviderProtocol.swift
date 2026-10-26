// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

protocol RunProviderProtocol: AnyObject {

    // MARK: - Properties
    /// Fires whenever the run state or the console change
    var publisher: AnyPublisher<Void, Never> { get }
    /// The current or the last launched app
    var run: AppRun? { get }
    /// stdout and stderr of the launched app, plus install and launch progress
    var console: BuildLog { get }

    // MARK: - Methods
    /// Installs and launches the product, then stays attached until the app exits
    func launch(_ product: RunnableProduct, on destination: Destination) async
    /// Stops the running app and waits until it is gone
    func stop() async

}
