// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

extension Publisher {

    func withUnretained<Object: AnyObject, Output>(
        _ object: Object,
        resultSelector: @escaping ((Object, Self.Output) -> Output)
    ) -> AnyPublisher<Output, Failure> {
        return flatMap { [weak object] element -> AnyPublisher<Output, Failure> in
            guard let object = object else {
                return Empty().eraseToAnyPublisher()
            }
            return Just(resultSelector(object, element))
                .setFailureType(to: Failure.self)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    func withUnretained<Object: AnyObject>(_ object: Object) -> AnyPublisher<(Object, Output), Failure> {
        return withUnretained(object) { ($0, $1) }
    }

}
