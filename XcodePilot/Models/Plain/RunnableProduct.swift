// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// The product Run launches: where the built bundle is and how to start it
struct RunnableProduct: Hashable {

    // MARK: - Properties
    let target: String
    let productPath: String
    let bundleIdentifier: String?
    /// Absolute path of the executable, for macOS apps and command line tools
    let executablePath: String?
    let isApplication: Bool

    // MARK: - Computed properties
    var name: String {
        URL(fileURLWithPath: productPath).deletingPathExtension().lastPathComponent
    }

}
