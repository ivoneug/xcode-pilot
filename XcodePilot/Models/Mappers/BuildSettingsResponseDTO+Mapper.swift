// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension BuildSettingsResponseDTO {

    // MARK: - Computed properties
    var productType: String {
        buildSettings[Constants.productType] ?? String.empty
    }

    var isApplication: Bool {
        productType.hasPrefix(Constants.applicationType)
    }

    var isWatchApplication: Bool {
        productType.contains(Constants.watchMarker)
    }

    // MARK: - Internal methods
    /// The launchable product of the target: an application or a command line tool
    func convertToPlain() -> RunnableProduct? {
        guard let directory = buildSettings[Constants.targetBuildDir] else {
            return nil
        }

        if isApplication {
            guard let name = buildSettings[Constants.fullProductName] ?? buildSettings[Constants.wrapperName] else {
                return nil
            }
            return RunnableProduct(
                target: target,
                productPath: directory + "/" + name,
                bundleIdentifier: buildSettings[Constants.bundleIdentifier],
                executablePath: buildSettings[Constants.executablePath].map { directory + "/" + $0 },
                isApplication: true
            )
        }

        guard productType == Constants.toolType,
              let executable = buildSettings[Constants.executablePath] ?? buildSettings[Constants.fullProductName] else {
            return nil
        }
        return RunnableProduct(
            target: target,
            productPath: directory + "/" + executable,
            bundleIdentifier: buildSettings[Constants.bundleIdentifier],
            executablePath: directory + "/" + executable,
            isApplication: false
        )
    }

}

extension Array where Element == BuildSettingsResponseDTO {

    // MARK: - Internal methods
    /// Picks the product the scheme runs: its runnable target if known, otherwise an application
    /// (named like the scheme, or the container of an embedded watch app), otherwise a tool
    func runnableProduct(scheme: String, preferredTarget: String?) -> RunnableProduct? {
        let candidates = compactMap { entry in entry.convertToPlain().map { (entry, $0) } }
        if let preferredTarget, let match = candidates.first(where: { $0.0.target == preferredTarget }) {
            return match.1
        }

        let applications = candidates.filter { $0.0.isApplication }
        if let named = applications.first(where: { $0.0.target == scheme }) {
            return named.1
        }
        if let container = applications.first(where: { $0.0.isWatchApplication == false }) {
            return container.1
        }
        if let application = applications.first {
            return application.1
        }
        if let tool = candidates.first(where: { $0.0.target == scheme }) {
            return tool.1
        }
        return candidates.first?.1
    }

}

private enum Constants {
    static let productType = "PRODUCT_TYPE"
    static let targetBuildDir = "TARGET_BUILD_DIR"
    static let fullProductName = "FULL_PRODUCT_NAME"
    static let wrapperName = "WRAPPER_NAME"
    static let executablePath = "EXECUTABLE_PATH"
    static let bundleIdentifier = "PRODUCT_BUNDLE_IDENTIFIER"
    static let applicationType = "com.apple.product-type.application"
    static let toolType = "com.apple.product-type.tool"
    static let watchMarker = "watch"
}
