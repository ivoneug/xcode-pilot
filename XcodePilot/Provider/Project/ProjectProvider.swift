// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

final class ProjectProvider {

    // MARK: - Properties
    private(set) var recentProjects: [ProjectRef]
    private(set) var xcodeRecentProjects: [ProjectRef] = []
    private(set) var project: ProjectRef?
    private(set) var info: ProjectInfo?
    private(set) var scheme: String?
    private(set) var configuration: String?
    private(set) var destinations: [Destination] = []
    private(set) var destination: Destination?
    private(set) var isLoadingInfo = false
    private(set) var isLoadingDestinations = false
    private(set) var errorMessage: String?
    private let subject = CurrentValueSubject<Void, Never>(())
    private let xcodeBuildService: XcodeBuildServiceProtocol
    private let xcodeAppService: XcodeAppServiceProtocol
    private let userDefaultsService: UserDefaultsServiceProtocol
    private let preferencesProvider: PreferencesProviderProtocol
    private var selections: [String: ProjectSelection]
    private var cachedInfo: [String: ProjectInfo]
    private var cachedDestinations: [String: [Destination]]
    /// Destinations picked by hand, newest first and shared by all projects: the same simulators and
    /// devices are used across them, and a list filtered by what the scheme offers fits any project
    private var pickedDestinations: [Destination]
    private var infoTask: Task<Void, Never>?
    private var destinationsTask: Task<Void, Never>?

    // MARK: - Init/Deinit
    init(
        xcodeBuildService: XcodeBuildServiceProtocol,
        xcodeAppService: XcodeAppServiceProtocol,
        userDefaultsService: UserDefaultsServiceProtocol,
        preferencesProvider: PreferencesProviderProtocol
    ) {
        self.xcodeBuildService = xcodeBuildService
        self.xcodeAppService = xcodeAppService
        self.userDefaultsService = userDefaultsService
        self.preferencesProvider = preferencesProvider
        recentProjects = (userDefaultsService.getModel(with: [ProjectRef].self, by: .recentProjects) ?? []).filter(\.exists)
        selections = userDefaultsService.getModel(with: [String: ProjectSelection].self, by: .projectSelections) ?? [:]
        cachedInfo = userDefaultsService.getModel(with: [String: ProjectInfo].self, by: .cachedProjectInfo) ?? [:]
        cachedDestinations = userDefaultsService.getModel(with: [String: [Destination]].self, by: .cachedDestinations) ?? [:]
        pickedDestinations = userDefaultsService.getModel(with: [Destination].self, by: .recentDestinations) ?? []

        if let current = userDefaultsService.getModel(with: ProjectRef.self, by: .currentProject), current.exists {
            select(current)
        }
        refreshRecentProjects()
    }

    // MARK: - Private methods
    private func loadInfo() {
        guard let project else {
            return
        }
        infoTask?.cancel()
        isLoadingInfo = true
        subject.send()

        infoTask = Task { @MainActor [weak self, xcodeBuildService] in
            do {
                let info = try await xcodeBuildService.projectInfo(project)
                guard let self, self.project == project else {
                    return
                }
                apply(info)
            } catch {
                guard let self, self.project == project, Task.isCancelled == false else {
                    return
                }
                isLoadingInfo = false
                errorMessage = error.localizedDescription
                subject.send()
            }
        }
    }

    private func apply(_ info: ProjectInfo) {
        guard let project else {
            return
        }
        self.info = info
        cachedInfo[project.path] = info
        userDefaultsService.saveModel(cachedInfo, by: .cachedProjectInfo)
        isLoadingInfo = false
        errorMessage = nil

        if scheme.map(info.schemes.contains) != true {
            // Xcode names the main scheme after the project; anything else is a guess anyway
            scheme = info.schemes.first { $0 == project.name } ?? info.schemes.first
            destinations = scheme.flatMap { cachedDestinations[destinationsKey(project, scheme: $0)] } ?? []
            destination = pickDestination(from: destinations)
        }
        if let configuration, info.configurations.contains(configuration) == false {
            self.configuration = nil
        }
        saveSelection()
        subject.send()
        reloadDestinations()
    }

    private func apply(_ destinations: [Destination], project: ProjectRef, scheme: String) {
        self.destinations = destinations
        cachedDestinations[destinationsKey(project, scheme: scheme)] = destinations
        userDefaultsService.saveModel(cachedDestinations, by: .cachedDestinations)
        destination = pickDestination(from: destinations)
        isLoadingDestinations = false
        errorMessage = nil
        saveSelection()
        subject.send()
    }

    /// Keeps the current destination if the list still has it, then the saved one, otherwise
    /// picks the newest iPhone simulator like Xcode does for a fresh scheme
    private func pickDestination(from destinations: [Destination]) -> Destination? {
        if let destination, let match = destinations.first(where: { $0.matches(destination) }) {
            return match
        }
        let saved = project.flatMap { selections[$0.path] }
        let savedMatch = destinations.first { $0.id == saved?.destinationId && $0.variant == saved?.destinationVariant }
        if let savedMatch {
            return savedMatch
        }
        let iPhoneSimulator = destinations.first { destination in
            destination.isSimulator && destination.basePlatform == Constants.iOS && destination.name.contains(Constants.iPhone)
        }
        return iPhoneSimulator ?? destinations.first(where: \.isRunnable) ?? destinations.first
    }

    private func saveSelection() {
        guard let project else {
            return
        }
        selections[project.path] = ProjectSelection(
            scheme: scheme,
            configuration: configuration,
            destinationId: destination?.id,
            destinationVariant: destination?.variant
        )
        userDefaultsService.saveModel(selections, by: .projectSelections)
    }

    private func destinationsKey(_ project: ProjectRef, scheme: String) -> String {
        "\(project.path)|\(scheme)"
    }

}

// MARK: - ProjectProviderProtocol
extension ProjectProvider: ProjectProviderProtocol {

    var publisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    var recentDestinations: [Destination] {
        let candidates = (destination.map { [$0] } ?? []) + pickedDestinations
        var result: [Destination] = []
        for candidate in candidates {
            guard let available = destinations.first(where: { $0.matches(candidate) }),
                  result.contains(where: { $0.matches(available) }) == false else {
                continue
            }
            result.append(available)
            if result.count == Constants.recentDestinationsShown {
                break
            }
        }
        return result
    }

    var request: BuildRequest? {
        guard let project, let scheme, let destination else {
            return nil
        }
        let preferences = preferencesProvider.preferences
        return BuildRequest(
            project: project,
            scheme: scheme,
            configuration: configuration,
            destination: destination,
            allowProvisioningUpdates: preferences.allowsProvisioningUpdates,
            skipMacroValidation: preferences.skipsMacroValidation
        )
    }

    func refreshRecentProjects() {
        Task { @MainActor [weak self, xcodeAppService] in
            let found = await Task.detached { xcodeAppService.recentProjects(limit: Constants.xcodeRecentsLimit) }.value
            guard let self else {
                return
            }
            xcodeRecentProjects = found.filter { self.recentProjects.contains($0) == false }
            subject.send()
        }
    }

    func select(_ project: ProjectRef) {
        infoTask?.cancel()
        destinationsTask?.cancel()

        self.project = project
        recentProjects = Array(([project] + recentProjects.filter { $0 != project }).prefix(Constants.recentsLimit))
        xcodeRecentProjects.removeAll { $0 == project }
        userDefaultsService.saveModel(recentProjects, by: .recentProjects)
        userDefaultsService.saveModel(project, by: .currentProject)

        // Whatever was seen last time shows right away, the fresh lists replace it once loaded
        let selection = selections[project.path] ?? ProjectSelection()
        info = cachedInfo[project.path]
        scheme = selection.scheme
        configuration = selection.configuration
        destination = nil
        destinations = scheme.flatMap { cachedDestinations[destinationsKey(project, scheme: $0)] } ?? []
        destination = pickDestination(from: destinations)
        isLoadingDestinations = false
        errorMessage = nil
        subject.send()

        loadInfo()
    }

    func remove(_ project: ProjectRef) {
        recentProjects.removeAll { $0 == project }
        userDefaultsService.saveModel(recentProjects, by: .recentProjects)
        subject.send()
    }

    func selectScheme(_ scheme: String) {
        guard let project, scheme != self.scheme else {
            return
        }
        self.scheme = scheme
        destinations = cachedDestinations[destinationsKey(project, scheme: scheme)] ?? destinations
        destination = pickDestination(from: destinations)
        saveSelection()
        subject.send()
        reloadDestinations()
    }

    func selectConfiguration(_ configuration: String?) {
        self.configuration = configuration
        saveSelection()
        subject.send()
    }

    func selectDestination(_ destination: Destination) {
        self.destination = destination
        pickedDestinations = Array(
            ([destination] + pickedDestinations.filter { $0.matches(destination) == false }).prefix(Constants.recentDestinationsKept)
        )
        userDefaultsService.saveModel(pickedDestinations, by: .recentDestinations)
        saveSelection()
        subject.send()
    }

    func reload() {
        loadInfo()
    }

    func reloadDestinations() {
        guard let project, let scheme else {
            return
        }
        destinationsTask?.cancel()
        isLoadingDestinations = true
        subject.send()

        destinationsTask = Task { @MainActor [weak self, xcodeBuildService] in
            do {
                let destinations = try await xcodeBuildService.destinations(project, scheme: scheme)
                guard let self, self.project == project, self.scheme == scheme else {
                    return
                }
                apply(destinations, project: project, scheme: scheme)
            } catch {
                guard let self, self.project == project, Task.isCancelled == false else {
                    return
                }
                isLoadingDestinations = false
                errorMessage = error.localizedDescription
                subject.send()
            }
        }
    }

}

private enum Constants {
    static let recentsLimit = 10
    static let xcodeRecentsLimit = 15
    static let recentDestinationsShown = 3
    /// More than shown, so the list still fills up when a project can't use some of them
    static let recentDestinationsKept = 10
    static let iOS = "iOS"
    static let iPhone = "iPhone"
}
