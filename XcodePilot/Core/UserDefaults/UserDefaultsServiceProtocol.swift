// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

// MARK: - UserDefaultsServiceProtocol
protocol UserDefaultsServiceProtocol {
    /**
     Reads a model from UserDefaults
     - Parameter type: Type of the model
     - Parameter key: Key of the model
     - Returns: The model, `nil` if it is missing or can't be decoded
     */
    func getModel<Model: Decodable>(with type: Model.Type, by key: UserDefaultsKey) -> Model?
    /**
     Writes a model to UserDefaults
     - Parameter model: The model, `nil` removes the key
     - Parameter key: Key of the model
     */
    func saveModel(_ model: Encodable?, by key: UserDefaultsKey)
    /**
     Removes the given keys
     - Parameter keys: Keys to remove
     */
    func removeKeys(_ keys: [UserDefaultsKey])
    /**
     Removes every key of the app
     */
    func removeAll()
}
