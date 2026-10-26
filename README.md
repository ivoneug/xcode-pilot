# Xcode Pilot

**English** · [Русский](README.ru.md)

A macOS menu bar app for building and running Xcode projects without keeping Xcode open.
Everything goes through `xcodebuild`, `simctl` and `devicectl`, so Xcode.app can stay closed.

## Features

- **Project picker**: `.xcodeproj`, `.xcworkspace` or a Swift package (a folder with `Package.swift`).
  Recent projects are remembered, and projects Xcode has opened recently are picked up from DerivedData.
- **Scheme, run destination and configuration**, just like in Xcode's toolbar. Devices come from
  `xcodebuild -showdestinations`, so the list only shows what the scheme can actually run on.
- **Build / Run / Stop / Test / Clean / Archive**. Run builds, installs and launches the app on a
  simulator (booting it if needed), a connected device or the Mac, and stays attached to it:
  `print` output goes to the Console tab.
- **Errors and warnings right in the panel**: file and line, the code snippet from the compiler,
  an errors/warnings filter. Copy any issue (as `file:line:col: error: …`) or all of them at once,
  or open it at the right line in Xcode, VS Code, Cursor or Zed. After the build the list is
  reconciled with the `.xcresult`, so nothing gets lost or duplicated.
- **Build log**, short (tasks, diagnostics, result) or full, with search (⌘F).
- **Archives** go where Xcode puts them and show up in the Organizer right away. From the panel an
  archive can be opened in the Organizer, exported (App Store Connect, Ad Hoc, Development,
  Enterprise, Developer ID) or uploaded to App Store Connect.
- **Organizer and Devices and Simulators** open from buttons in the panel and in the icon menu.
  For everyday use there is also a Devices tab: simulators (boot, shut down, show) and connected
  devices, any of which can be picked as the run destination.
- **The menu bar icon shows what's going on**: a progress ring while building (estimated from the
  duration of the previous identical build), build time next to the icon, a green badge on success,
  a red badge with the error count on failure, and separate states for installing and for a running
  app. Right-click opens a menu with the main actions and project, scheme and device pickers.
- **Global shortcuts**: ⌃⌥⌘R to run, ⌃⌥⌘B to build, ⌃⌥⌘. to stop, ⌃⌥⌘X to show or hide the panel.
  Inside the panel the usual ⌘R, ⌘B, ⌘., ⌘U and ⇧⌘K work.
- A notification when a build finishes while the panel is closed; sounds; launch at login; Xcode
  version selection when several are installed; the panel can be detached into a separate window.

## Building

You need Xcode 26, [XcodeGen](https://github.com/yonaskolb/XcodeGen), [SwiftGen](https://github.com/SwiftGen/SwiftGen)
and [SwiftLint](https://github.com/realm/SwiftLint) (`brew install xcodegen swiftgen swiftlint`).

```bash
cd Scripts && ./generateProject.sh
```

Then open `XcodePilot.xcodeproj` and run the `XcodePilot` scheme. The development team is set in
`Scripts/project.env` (`DEVELOPMENT_TEAM_ID`).

## Permissions

- **Accessibility**: only for the Organizer and Devices and Simulators buttons. Xcode has no URL
  scheme or AppleScript command for these windows, so the app presses their items in Xcode's
  Window menu.
- **Notifications**: requested with the first build-finished notification.

## Limitations

- While Xcode itself is building the same project, a parallel build from Xcode Pilot will hit the
  DerivedData lock: both share one folder so incremental builds are shared.
- Packages with macros and plugins that were never trusted in Xcode won't build with xcodebuild;
  for those, settings have a "Skip macro and plugin validation" option.
- Running on Mac as "Designed for iPad" isn't supported; such destinations are hidden.
- Build progress is an estimate based on the last successful build of the same scheme: xcodebuild
  doesn't report the total number of tasks.

## Architecture

View → ViewModel → Provider → Core Service layers, DI through locators, a generated project and
SwiftGen resources. Details are in [CLAUDE.md](CLAUDE.md) (in Russian).

## License

Xcode Pilot is released under the [MIT License](LICENSE).
