// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension Encodable {

    var toData: Data? {
        return try? Constants.encoder.encode(self)
    }

}

private enum Constants {
    static let encoder = JSONEncoder()
}
