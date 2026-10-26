// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import Combine
import Foundation

/// State and actions of the menu bar item: the icon, the text next to it and the right-click menu
@MainActor
final class StatusBarViewModel: ObservableObject {

    // MARK: - Properties
    @Published private(set) var icon: StatusIconState = .idle
    @Published private(set) var title = String.empty
    @Published private(set) var isTitleAlert = false
    @Published private(set) var tooltip = CommonConstants.appName
    private let buildProvider: BuildProviderProtocol
    private let runProvider: RunProviderProtocol
    private let projectProvider: ProjectProviderProtocol
    private let preferencesProvider: PreferencesProviderProtocol
    private let xcodeProvider: XcodeProviderProtocol
    private let hotKeyService: HotKeyServiceProtocol
    private let timerScheduler: TimerSchedulerProtocol
    private let appStateRepository: AppStateRepository
    private var clockTimer: Timer?
    private var badgeTimer: Timer?
    /// The finished activity whose success badge has been shown long enough
    private var expiredActivityId: UUID?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed properties
    var recentProjects: [ProjectRef] {
        projectProvider.recentProjects
    }

    var project: ProjectRef? {
        projectProvider.project
    }

    var schemes: [String] {
        projectProvider.info?.schemes ?? []
    }

    var scheme: String? {
        projectProvider.scheme
    }

    var destinationGroups: [DestinationGroup] {
        DestinationGroup.make(from: projectProvider.destinations, recent: projectProvider.recentDestinations)
    }

    var destination: Destination? {
        projectProvider.destination
    }

    var isBusy: Bool {
        buildProvider.isBusy
    }

    var isAppRunning: Bool {
        runProvider.run?.isActive == true
    }

    var canStart: Bool {
        projectProvider.request != nil && isBusy == false
    }

    var canRun: Bool {
        canStart && projectProvider.destination?.isRunnable == true
    }

    var lastArchive: ArchiveInfo? {
        buildProvider.lastArchive
    }

    // MARK: - Init/Deinit
    init(
        buildProvider: BuildProviderProtocol,
        runProvider: RunProviderProtocol,
        projectProvider: ProjectProviderProtocol,
        preferencesProvider: PreferencesProviderProtocol,
        xcodeProvider: XcodeProviderProtocol,
        hotKeyService: HotKeyServiceProtocol,
        timerScheduler: TimerSchedulerProtocol,
        appStateRepository: AppStateRepository
    ) {
        self.buildProvider = buildProvider
        self.runProvider = runProvider
        self.projectProvider = projectProvider
        self.preferencesProvider = preferencesProvider
        self.xcodeProvider = xcodeProvider
        self.hotKeyService = hotKeyService
        self.timerScheduler = timerScheduler
        self.appStateRepository = appStateRepository

        bindPublishers()
        refresh()
    }

    // MARK: - Internal methods
    func start(_ action: BuildAction) {
        guard let request = projectProvider.request, isBusy == false else {
            return
        }
        buildProvider.start(action, request: request)
    }

    func stop() {
        if isBusy {
            buildProvider.cancel()
        } else {
            Task { [runProvider] in
                await runProvider.stop()
            }
        }
    }

    func select(_ project: ProjectRef) {
        projectProvider.select(project)
    }

    func selectScheme(_ scheme: String) {
        projectProvider.selectScheme(scheme)
    }

    func selectDestination(_ destination: Destination) {
        projectProvider.selectDestination(destination)
    }

    func showPanel() {
        appStateRepository.panelRequests.send(.show)
    }

    func openInXcode() {
        guard let project else {
            return
        }
        xcodeProvider.open(project)
    }

    func show(_ window: XcodeWindow) {
        Task { [xcodeProvider] in
            do {
                try await xcodeProvider.show(window)
            } catch {
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }

    func showLastArchiveInOrganizer() {
        guard let lastArchive else {
            return
        }
        xcodeProvider.showInOrganizer(lastArchive)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Private methods
    private func bindPublishers() {
        Publishers.Merge4(
            buildProvider.publisher,
            runProvider.publisher,
            projectProvider.publisher,
            preferencesProvider.publisher.map { _ in () }
        )
        .throttle(for: Constants.refreshThrottle, scheduler: DispatchQueue.main, latest: true)
        .sink(receiveValue: { [weak self] in
            self?.refresh()
        })
        .store(in: &cancellables)

        preferencesProvider.publisher
            .map(\.usesGlobalHotKeys)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isEnabled in
                self?.registerHotKeys(isEnabled)
            })
            .store(in: &cancellables)
    }

    private func registerHotKeys(_ isEnabled: Bool) {
        hotKeyService.unregisterAll()
        guard isEnabled else {
            return
        }
        hotKeyService.register(.build) { [weak self] in
            self?.start(.build)
        }
        hotKeyService.register(.run) { [weak self] in
            self?.start(.run)
        }
        hotKeyService.register(.stop) { [weak self] in
            self?.stop()
        }
        hotKeyService.register(.togglePanel) { [weak self] in
            self?.appStateRepository.panelRequests.send(.toggle)
        }
    }

    private func refresh() {
        let preferences = preferencesProvider.preferences
        let activity = buildProvider.activity
        let run = runProvider.run

        icon = makeIcon(activity: activity, run: run)
        isTitleAlert = false
        title = String.empty
        if let activity, activity.isRunning {
            title = preferences.showsElapsedTime ? activity.duration.readableDuration : String.empty
        } else if let activity, case .failed = icon, preferences.showsIssueCount, activity.errorCount > .zero {
            title = "\(activity.errorCount)"
            isTitleAlert = true
        }
        tooltip = makeTooltip(activity: activity, run: run)

        updateClock(isTicking: activity?.isRunning == true)
        scheduleBadgeExpiry(for: activity, duration: preferences.successBadgeDuration)
    }

    private func makeIcon(activity: BuildActivity?, run: AppRun?) -> StatusIconState {
        if let activity, activity.isRunning {
            return .working(work(for: activity.action), progress: activity.estimatedProgress)
        }
        if let run, run.isActive {
            return run.isPreparing ? .working(.install, progress: nil) : .running
        }
        if case .failed = run?.state {
            return .failed
        }
        guard let activity else {
            return .idle
        }
        switch activity.status {
        case .failed:
            return .failed
        case .succeeded:
            return expiredActivityId == activity.id ? .idle : .succeeded
        case .running, .cancelled:
            return .idle
        }
    }

    private func work(for action: BuildAction) -> StatusIconState.Work {
        switch action {
        case .build, .run:
            return .build
        case .test:
            return .test
        case .clean:
            return .clean
        case .archive:
            return .archive
        case .export:
            return .export
        }
    }

    private func makeTooltip(activity: BuildActivity?, run: AppRun?) -> String {
        var lines = [CommonConstants.appName]
        if let project = projectProvider.project {
            let selection = [project.name, projectProvider.scheme, projectProvider.destination?.displayName]
            lines.append(selection.compactMap { $0 }.joined(separator: " · "))
        }
        if let activity {
            var line = activity.title
            if let step = activity.step, activity.isRunning {
                line += ": \(step)"
            }
            lines.append(line)
        }
        if let run, run.isActive {
            lines.append(run.stateDescription)
        }
        return lines.joined(separator: String.lineBreak)
    }

    /// Ticks once a second while something runs, for the elapsed time and the estimated progress
    private func updateClock(isTicking: Bool) {
        guard isTicking else {
            clockTimer?.invalidate()
            clockTimer = nil
            return
        }
        guard clockTimer == nil else {
            return
        }
        clockTimer = timerScheduler.makeTimer(timeInterval: Constants.clockInterval, repeats: true) { [weak self] in
            self?.refresh()
        }
    }

    private func scheduleBadgeExpiry(for activity: BuildActivity?, duration: TimeInterval) {
        guard let activity, activity.status == .succeeded, expiredActivityId != activity.id, duration > .zero, badgeTimer == nil else {
            return
        }
        let delay = max(duration - Date().timeIntervalSince(activity.finishedAt ?? Date()), .zero)
        badgeTimer = timerScheduler.makeTimer(timeInterval: delay, repeats: false) { [weak self] in
            self?.badgeTimer = nil
            self?.expiredActivityId = activity.id
            self?.refresh()
        }
    }

}

private enum Constants {
    static let refreshThrottle: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(150)
    static let clockInterval: TimeInterval = 1
}
