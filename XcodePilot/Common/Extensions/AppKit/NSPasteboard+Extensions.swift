// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit

extension NSPasteboard {

    // MARK: - Internal methods
    func copy(_ text: String) {
        clearContents()
        setString(text, forType: .string)
    }

}
