// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

@main
struct MainApp: App {

    // MARK: - Properties
    @NSApplicationDelegateAdaptor var delegate: AppDelegate

    // MARK: - Layout
    var body: some Scene {
        // The panel lives in the menu bar item (see StatusBarAppDelegateProxy); SwiftUI still needs
        // a scene, and this one never shows. The hidden main menu it brings is what makes the key
        // equivalents work in the panel: copy, paste and select all, and find in the logs.
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {}
            CommandGroup(replacing: .newItem) {}
            TextEditingCommands()
        }
    }

}
