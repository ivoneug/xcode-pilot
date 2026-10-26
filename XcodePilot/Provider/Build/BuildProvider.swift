// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Combine
import Foundation

final class BuildProvider {

    // MARK: - Properties
    private(set) var activity: BuildActivity?
    private(set) var lastArchive: ArchiveInfo?
    let log = BuildLog()
    private let subject = CurrentValueSubject<Void, Never>(())
    private let xcodeBuildService: XcodeBuildServiceProtocol
    private let userDefaultsService: UserDefaultsServiceProtocol
    private let userNotificationsService: UserNotificationsServiceProtocol
    private let soundService: SoundServiceProtocol
    private let runProvider: RunProviderProtocol
    private let preferencesProvider: PreferencesProviderProtocol
    private let appStateRepository: AppStateRepository
    private var durations: [String: TimeInterval]
    private var handle: ProcessHandle?
    private var task: Task<Void, Never>?

    // MARK: - Init/Deinit
    init(
        xcodeBuildService: XcodeBuildServiceProtocol,
        userDefaultsService: UserDefaultsServiceProtocol,
        userNotificationsService: UserNotificationsServiceProtocol,
        soundService: SoundServiceProtocol,
        runProvider: RunProviderProtocol,
        preferencesProvider: PreferencesProviderProtocol,
        appStateRepository: AppStateRepository
    ) {
        self.xcodeBuildService = xcodeBuildService
        self.userDefaultsService = userDefaultsService
        self.userNotificationsService = userNotificationsService
        self.soundService = soundService
        self.runProvider = runProvider
        self.preferencesProvider = preferencesProvider
        self.appStateRepository = appStateRepository
        durations = userDefaultsService.getModel(with: [String: TimeInterval].self, by: .buildDurations) ?? [:]
    }

    // MARK: - Private methods
    @MainActor
    private func perform(_ action: BuildAction, request: BuildRequest) async {
        if action == .run {
            await runProvider.stop()
        }
        let resultBundle = action.producesResultBundle ? BuildPaths.makeResultBundle() : nil
        let archivePath = action == .archive ? BuildPaths.makeArchive(scheme: request.scheme) : nil

        var activity = BuildActivity(action: action, request: request)
        activity.expectedDuration = durations[request.durationKey(for: action)]
        begin(activity)

        // Build settings are read alongside the build, Run needs them the moment it succeeds
        let productTask = action == .run ? Task { [xcodeBuildService] in try await xcodeBuildService.runnableProduct(request) } : nil

        let (stream, handle) = xcodeBuildService.start(action, request: request, resultBundle: resultBundle, archivePath: archivePath)
        self.handle = handle
        let status = await consume(stream, id: activity.id)
        await finish(activity.id, status: status, handle: handle, resultBundle: resultBundle, archivePath: archivePath)

        guard action == .run, self.activity?.id == activity.id, self.activity?.status == .succeeded, let productTask else {
            productTask?.cancel()
            return
        }
        do {
            let product = try await productTask.value
            await runProvider.launch(product, on: request.destination)
        } catch {
            update(activity.id) { $0.issues.append(BuildIssue(severity: .error, message: error.localizedDescription)) }
            log.append([error.localizedDescription])
        }
    }

    @MainActor
    private func performExport(_ archive: ArchiveInfo, method: ExportMethod, upload: Bool, request: BuildRequest) async {
        var activity = BuildActivity(action: .export, request: request)
        activity.archive = archive
        activity.isUpload = upload && method.canUpload
        begin(activity)

        let exportPath = BuildPaths.makeExportFolder(in: preferencesProvider.exportDirectory, name: archive.name)
        do {
            let (stream, handle) = try xcodeBuildService.exportArchive(
                archive,
                method: method,
                upload: activity.isUpload,
                exportPath: exportPath
            )
            self.handle = handle
            let status = await consume(stream, id: activity.id)
            await finish(activity.id, status: status, handle: handle, resultBundle: nil, archivePath: nil)
            if self.activity?.status == .succeeded, activity.isUpload == false {
                update(activity.id) { $0.exportURL = exportPath }
            }
        } catch {
            log.append([error.localizedDescription])
            update(activity.id) { activity in
                activity.issues.append(BuildIssue(severity: .error, message: error.localizedDescription))
                activity.status = .failed
                activity.finishedAt = Date()
            }
        }
    }

    @MainActor
    private func begin(_ activity: BuildActivity) {
        self.activity = activity
        log.reset()
        subject.send()
    }

    @MainActor
    private func update(_ id: UUID, _ change: (inout BuildActivity) -> Void) {
        guard var activity, activity.id == id else {
            return
        }
        change(&activity)
        self.activity = activity
        subject.send()
    }

    /// Parses the output off the main thread and applies it in batches
    private func consume(_ stream: AsyncStream<ProcessOutput>, id: UUID) async -> Int32 {
        await Task.detached(priority: .userInitiated) { [weak self] in
            let parser = BuildOutputParser()
            var status = Constants.unknownStatus
            for await output in stream {
                switch output {
                case .lines(let lines):
                    var events: [BuildOutputEvent] = []
                    var compact: [String] = []
                    for line in lines {
                        let parsed = parser.parse(line)
                        events.append(contentsOf: parsed.events)
                        if let text = parsed.compact {
                            compact.append(text)
                        }
                    }
                    await self?.apply(events, full: lines, compact: compact, id: id)
                case .exit(let code):
                    status = code
                }
            }
            return status
        }.value
    }

    @MainActor
    private func apply(_ events: [BuildOutputEvent], full: [String], compact: [String], id: UUID) {
        guard activity?.id == id else {
            return
        }
        log.append(full: full, compact: compact)
        update(id) { $0.apply(events) }
    }

    @MainActor
    private func finish(_ id: UUID, status: Int32, handle: ProcessHandle, resultBundle: URL?, archivePath: URL?) async {
        self.handle = nil
        guard let current = activity, current.id == id else {
            return
        }

        var finished = current
        finished.finishedAt = Date()
        if handle.isCancelled {
            finished.status = .cancelled
        } else {
            finished.status = status == .zero ? .succeeded : .failed
        }

        if let resultBundle, finished.status != .cancelled {
            if let bundleIssues = await xcodeBuildService.buildIssues(resultBundle: resultBundle) {
                finished.issues = IssueMerger.merge(live: finished.issues, bundle: bundleIssues)
            }
            if finished.action == .test, let summary = await xcodeBuildService.testSummary(resultBundle: resultBundle) {
                finished.testSummary = summary
                finished.issues += summary.failures
            }
            BuildPaths.removeOldResultBundles(keeping: resultBundle)
        }
        if finished.status == .failed, finished.errorCount == .zero {
            finished.issues.insert(fallbackIssue(for: finished, status: status), at: .zero)
        }
        if finished.status == .succeeded, let archivePath {
            finished.archive = xcodeBuildService.archiveInfo(at: archivePath)
            lastArchive = finished.archive
        }
        if finished.status == .succeeded {
            durations[finished.request.durationKey(for: finished.action)] = finished.duration
            userDefaultsService.saveModel(durations, by: .buildDurations)
        }

        activity = finished
        subject.send()
        announce(finished)
    }

    /// Something to show when xcodebuild failed without a diagnostic the parser recognised
    private func fallbackIssue(for activity: BuildActivity, status: Int32) -> BuildIssue {
        let failed = activity.failedCommands.filter { $0.hasPrefix(Constants.buildingProjectPrefix) == false }
        guard failed.isEmpty else {
            return BuildIssue(severity: .error, message: Localizations.Issues.commandsFailed, context: failed)
        }
        return BuildIssue(
            severity: .error,
            message: Localizations.Issues.exitedWithCode(Int(status)),
            context: Array(log.fullLines.suffix(Constants.fallbackContextLines))
        )
    }

    private func announce(_ activity: BuildActivity) {
        guard activity.status == .succeeded || activity.status == .failed else {
            return
        }
        let preferences = preferencesProvider.preferences
        if preferences.playsSounds {
            soundService.playFinished(succeeded: activity.status == .succeeded)
        }
        // Run is announced by the app showing up, a notification would only cover it
        let isAnnouncedByApp = activity.action == .run && activity.status == .succeeded
        guard preferences.notifiesOnFinish, appStateRepository.isPanelVisible.value == false, isAnnouncedByApp == false else {
            return
        }
        var body = "\(activity.request.scheme) · \(activity.duration.readableDuration)"
        if let error = activity.issues.first(where: { $0.severity == .error }) {
            body += "\n" + error.message
        } else if let summary = activity.testSummary {
            body += "\n" + summary.description
        }
        userNotificationsService.post(title: activity.title, body: body, playsSound: preferences.playsSounds == false)
    }

}

// MARK: - BuildProviderProtocol
extension BuildProvider: BuildProviderProtocol {

    var publisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    var isBusy: Bool {
        activity?.isRunning == true
    }

    func start(_ action: BuildAction, request: BuildRequest) {
        guard isBusy == false else {
            return
        }
        task = Task { @MainActor [weak self] in
            await self?.perform(action, request: request)
        }
    }

    func cancel() {
        handle?.cancel()
    }

    func export(_ archive: ArchiveInfo, method: ExportMethod, upload: Bool) {
        guard isBusy == false, let request = activity?.request else {
            return
        }
        task = Task { @MainActor [weak self] in
            await self?.performExport(archive, method: method, upload: upload, request: request)
        }
    }

    func dismissActivity() {
        guard isBusy == false else {
            return
        }
        activity = nil
        subject.send()
    }

}

private enum Constants {
    static let unknownStatus: Int32 = -1
    static let fallbackContextLines = 15
    /// The last entry of the failed commands list just names the scheme
    static let buildingProjectPrefix = "Building "
}
