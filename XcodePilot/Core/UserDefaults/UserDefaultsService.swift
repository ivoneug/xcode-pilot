// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

final class UserDefaultsService {

    // MARK: - Properties
    private let decoder = JSONDecoder()
    private let userDefaults: UserDefaults

    // MARK: - Init/Deinit
    init(with userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

}

// MARK: - UserDefaultsServiceProtocol
extension UserDefaultsService: UserDefaultsServiceProtocol {

    func getModel<Model: Decodable>(with type: Model.Type, by key: UserDefaultsKey) -> Model? {
        let data = userDefaults.data(forKey: key.rawValue)
        return data.flatMap { try? decoder.decode(type, from: $0) }
    }

    func saveModel(_ model: Encodable?, by key: UserDefaultsKey) {
        if let model = model?.toData {
            userDefaults.set(model, forKey: key.rawValue)
        } else {
            userDefaults.removeObject(forKey: key.rawValue)
        }
    }

    func removeKeys(_ keys: [UserDefaultsKey]) {
        UserDefaultsKey
            .allCases
            .filter { keys.contains($0) }
            .forEach { saveModel(nil, by: $0) }
    }

    func removeAll() {
        UserDefaultsKey.allCases.forEach {
            saveModel(nil, by: $0)
        }
    }

}
