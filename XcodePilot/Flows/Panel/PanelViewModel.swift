// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation
import SwiftUI

@MainActor
final class PanelViewModel: IdentifiableObject {

    // MARK: - Nested types
    enum Tab: CaseIterable, Identifiable {
        case issues
        case log
        case console
        case devices

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .issues:
                return Localizations.Panel.Tab.issues
            case .log:
                return Localizations.Panel.Tab.log
            case .console:
                return Localizations.Panel.Tab.console
            case .devices:
                return Localizations.Panel.Tab.devices
            }
        }
    }

    enum IssueFilter: CaseIterable, Identifiable {
        case all
        case errors
        case warnings

        var id: Self {
            self
        }
    }

    // MARK: - Properties
    @Published var selectedTab: Tab = .issues
    @Published var issueFilter: IssueFilter = .all
    @Published var consoleFilter = ConsoleFilter() {
        didSet {
            refreshConsole()
        }
    }
    @Published var alertMessage: String?
    @Published private(set) var project: ProjectRef?
    @Published private(set) var recentProjects: [ProjectRef] = []
    @Published private(set) var xcodeRecentProjects: [ProjectRef] = []
    @Published private(set) var schemes: [String] = []
    @Published private(set) var scheme: String?
    @Published private(set) var configurations: [String] = []
    @Published private(set) var configuration: String?
    @Published private(set) var destinationGroups: [DestinationGroup] = []
    @Published private(set) var destination: Destination?
    @Published private(set) var isLoadingProject = false
    @Published private(set) var isLoadingDestinations = false
    @Published private(set) var projectError: String?
    @Published private(set) var activity: BuildActivity?
    @Published private(set) var run: AppRun?
    @Published private(set) var lastArchive: ArchiveInfo?
    @Published private(set) var logVersion: Int = .zero
    @Published private(set) var consoleVersion: Int = .zero
    @Published private(set) var isCompactLog = true
    @Published private(set) var copiedIssueId: UUID?
    let navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>
    let projectProvider: ProjectProviderProtocol
    let buildProvider: BuildProviderProtocol
    let runProvider: RunProviderProtocol
    let preferencesProvider: PreferencesProviderProtocol
    let xcodeProvider: XcodeProviderProtocol
    private var lastActivityId: UUID?
    private var filteredConsole = FilteredLines()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed properties
    var isBusy: Bool {
        activity?.isRunning == true
    }

    var isAppRunning: Bool {
        run?.isActive == true
    }

    var canStart: Bool {
        projectProvider.request != nil && isBusy == false
    }

    var canRun: Bool {
        canStart && destination?.isRunnable == true
    }

    var allIssues: [BuildIssue] {
        activity?.issues ?? []
    }

    /// Errors before warnings, each in the order the build reported them
    var issues: [BuildIssue] {
        let errors = allIssues.filter { $0.severity == .error }
        let warnings = allIssues.filter { $0.severity == .warning }
        switch issueFilter {
        case .all:
            return errors + warnings
        case .errors:
            return errors
        case .warnings:
            return warnings
        }
    }

    var logLines: [String] {
        buildProvider.log.lines(compact: isCompactLog)
    }

    /// What the console shows: the lines that pass the filter
    var consoleLines: [String] {
        consoleFilter.isActive ? filteredConsole.lines : runProvider.console.fullLines
    }

    /// Every line the app printed, shown or not
    var consoleLineCount: Int {
        runProvider.console.fullLines.count
    }

    var configurationTitle: String {
        configuration ?? Localizations.Toolbar.schemeConfiguration
    }

    // MARK: - Init/Deinit
    init(
        navigation: CurrentValueSubject<RootCoordinator.NavigationEvent?, Never>,
        projectProvider: ProjectProviderProtocol,
        buildProvider: BuildProviderProtocol,
        runProvider: RunProviderProtocol,
        preferencesProvider: PreferencesProviderProtocol,
        xcodeProvider: XcodeProviderProtocol
    ) {
        self.navigation = navigation
        self.projectProvider = projectProvider
        self.buildProvider = buildProvider
        self.runProvider = runProvider
        self.preferencesProvider = preferencesProvider
        self.xcodeProvider = xcodeProvider

        refreshProject()
        refreshActivity()
        refreshRun()
        bindPublishers()
    }

    // MARK: - Internal methods
    func appear() {
        projectProvider.refreshRecentProjects()
    }

    func showCopiedFeedback(for issue: BuildIssue) {
        withAnimation(Constants.animation) {
            copiedIssueId = issue.id
        }
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: Constants.copiedFeedbackDuration)
            guard self?.copiedIssueId == issue.id else {
                return
            }
            withAnimation(Constants.animation) {
                self?.copiedIssueId = nil
            }
        }
    }

    // MARK: - Private methods
    private func bindPublishers() {
        projectProvider.publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.refreshProject()
            })
            .store(in: &cancellables)

        buildProvider.publisher
            .throttle(for: Constants.throttle, scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] in
                self?.refreshActivity()
            })
            .store(in: &cancellables)

        runProvider.publisher
            .throttle(for: Constants.throttle, scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] in
                self?.refreshRun()
            })
            .store(in: &cancellables)

        preferencesProvider.publisher
            .map(\.showsCompactLog)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isCompact in
                self?.isCompactLog = isCompact
            })
            .store(in: &cancellables)
    }

    private func refreshProject() {
        project = projectProvider.project
        recentProjects = projectProvider.recentProjects
        xcodeRecentProjects = projectProvider.xcodeRecentProjects
        schemes = projectProvider.info?.schemes ?? []
        scheme = projectProvider.scheme
        configurations = projectProvider.info?.configurations ?? []
        configuration = projectProvider.configuration
        destinationGroups = DestinationGroup.make(from: projectProvider.destinations, recent: projectProvider.recentDestinations)
        destination = projectProvider.destination
        isLoadingProject = projectProvider.isLoadingInfo
        isLoadingDestinations = projectProvider.isLoadingDestinations
        projectError = projectProvider.errorMessage
    }

    private func refreshActivity() {
        let activity = buildProvider.activity
        // A new build shows its issues as they come in (an export has none, only a log), and a
        // failed one ends on whatever explains the failure
        if let activity, activity.id != lastActivityId {
            lastActivityId = activity.id
            if selectedTab != .log {
                selectedTab = activity.action == .export ? .log : .issues
            }
        }
        if let activity, self.activity?.isRunning == true, activity.status == .failed {
            selectedTab = activity.errorCount > .zero ? .issues : .log
            issueFilter = .all
        }
        self.activity = activity
        lastArchive = buildProvider.lastArchive
        logVersion = buildProvider.log.version
    }

    private func refreshRun() {
        let run = runProvider.run
        if let run, run.isActive, self.run?.id != run.id {
            selectedTab = .console
        }
        self.run = run
        refreshConsole()
    }

    private func refreshConsole() {
        consoleVersion = runProvider.console.version
        if consoleFilter.isActive {
            filteredConsole.update(from: runProvider.console, source: run?.id, filter: consoleFilter)
        } else {
            filteredConsole.reset()
        }
    }

}

private enum Constants {
    static let animation: Animation = .easeInOut(duration: 0.2)
    static let throttle: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(120)
    static let copiedFeedbackDuration: UInt64 = 1_200_000_000
}
