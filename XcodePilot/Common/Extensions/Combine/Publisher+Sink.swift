// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine

extension Publisher {

    // MARK: - Public methods
    func sink(
        receiveFailure: @escaping ((Self.Failure) -> Void) = { _ in },
        receiveValue: @escaping ((Self.Output) -> Void) = { _ in }
    ) -> AnyCancellable {
        return sink(receiveCompletion: { completion in
            guard case let .failure(error) = completion else {
                return
            }
            receiveFailure(error)
        }, receiveValue: { receiveValue($0) })
    }

}
