// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit

/// Menu item that runs a closure instead of sending an action through the responder chain
final class ClosureMenuItem: NSMenuItem {

    // MARK: - Properties
    private let handler: () -> Void

    // MARK: - Init/Deinit
    init(title: String, symbolName: String? = nil, keyEquivalent: String = String.empty, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(performHandler), keyEquivalent: keyEquivalent)

        target = self
        if let symbolName {
            image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods
    @objc private func performHandler() {
        handler()
    }

}
