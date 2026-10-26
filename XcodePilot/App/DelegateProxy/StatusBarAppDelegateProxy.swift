// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit

/// Puts the app into the menu bar
final class StatusBarAppDelegateProxy: NSObject {

    // MARK: - Property wrappers
    @RepositoryDependency private var appStateRepository: AppStateRepository
    @Dependency private var timerScheduler: TimerSchedulerProtocol
    @Dependency private var buildProvider: BuildProviderProtocol
    @Dependency private var runProvider: RunProviderProtocol

    // MARK: - Properties
    private var controller: StatusBarController?

}

// MARK: - NSApplicationDelegate
extension StatusBarAppDelegateProxy: NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests are hosted by the app, they get no menu bar item, shortcuts or providers
        guard AppInfo.isRunningTests == false else {
            return
        }
        controller = StatusBarController(
            viewModel: StatusBarViewModelFactory.build(),
            coordinator: RootCoordinator(),
            appStateRepository: appStateRepository,
            timerScheduler: timerScheduler
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard AppInfo.isRunningTests == false else {
            return
        }
        // Child processes outlive the app otherwise: xcodebuild keeps building, simctl stays attached
        buildProvider.cancel()
        Task { [runProvider] in
            await runProvider.stop()
        }
    }

}
