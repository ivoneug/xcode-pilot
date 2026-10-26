// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import Combine
import SwiftUI

/// The menu bar item: draws the icon, opens the panel as a popover or as a window, shows the menu
@MainActor
final class StatusBarController: NSObject {

    // MARK: - Properties
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let viewModel: StatusBarViewModel
    private let coordinator: RootCoordinator
    private let menuBuilder: StatusMenuBuilder
    private let appStateRepository: AppStateRepository
    private let timerScheduler: TimerSchedulerProtocol
    private var window: NSWindow?
    private var animationTimer: Timer?
    private var animationPhase: Double = .zero
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed properties
    private var isPanelVisible: Bool {
        popover.isShown || window?.isVisible == true
    }

    // MARK: - Init/Deinit
    init(
        viewModel: StatusBarViewModel,
        coordinator: RootCoordinator,
        appStateRepository: AppStateRepository,
        timerScheduler: TimerSchedulerProtocol
    ) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        self.appStateRepository = appStateRepository
        self.timerScheduler = timerScheduler
        menuBuilder = StatusMenuBuilder(viewModel: viewModel)
        super.init()

        configureStatusItem()
        configurePopover()
        bindPublishers()
    }

    // MARK: - Private methods
    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }
        button.target = self
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
        render()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: CommonConstants.panelWidth, height: CommonConstants.panelHeight)
        popover.contentViewController = NSHostingController(rootView: RootCoordinatorView(coordinator: coordinator))
    }

    private func bindPublishers() {
        Publishers.CombineLatest4(viewModel.$icon, viewModel.$title, viewModel.$isTitleAlert, viewModel.$tooltip)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.render()
            })
            .store(in: &cancellables)

        appStateRepository.panelRequests
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] request in
                switch request {
                case .show:
                    self?.showPanel()
                case .toggle:
                    self?.togglePanel()
                }
            })
            .store(in: &cancellables)

        coordinator.$isDetached
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isDetached in
                if isDetached {
                    self?.detach()
                } else {
                    self?.window?.close()
                }
            })
            .store(in: &cancellables)
    }

    @objc private func handleClick() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            togglePanel()
        }
    }

    private func showMenu() {
        popover.performClose(nil)
        // Attached for the duration of one click only, a permanent menu would swallow left clicks too
        statusItem.menu = menuBuilder.makeMenu()
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func togglePanel() {
        if isPanelVisible, window?.isKeyWindow != false {
            popover.performClose(nil)
            window?.close()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        NSApp.activate(ignoringOtherApps: true)
        if let window, coordinator.isDetached {
            coordinator.panelWillAppear()
            window.makeKeyAndOrderFront(nil)
            return
        }
        guard popover.isShown == false, let button = statusItem.button else {
            return
        }
        coordinator.panelWillAppear()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func detach() {
        popover.performClose(nil)
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        appStateRepository.isPanelVisible.send(true)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: RootCoordinatorView(coordinator: coordinator)))
        window.title = CommonConstants.appName
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: CommonConstants.panelWidth, height: CommonConstants.panelHeight))
        window.setFrameAutosaveName(Constants.windowAutosaveName)
        window.delegate = self
        return window
    }

    private func render() {
        guard let button = statusItem.button else {
            return
        }
        button.image = StatusIconRenderer.image(for: viewModel.icon, phase: animationPhase)
        button.toolTip = viewModel.tooltip

        if viewModel.title.isEmpty {
            button.title = String.empty
            button.attributedTitle = NSAttributedString()
        } else {
            var attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: Constants.titleFontSize, weight: .medium),
                .baselineOffset: Constants.titleBaselineOffset
            ]
            if viewModel.isTitleAlert {
                attributes[.foregroundColor] = Colors.failure.nsColor
            }
            button.attributedTitle = NSAttributedString(string: String.space + viewModel.title, attributes: attributes)
        }
        updateAnimation(isAnimated: viewModel.icon.isAnimated)
    }

    private func updateAnimation(isAnimated: Bool) {
        guard isAnimated else {
            animationTimer?.invalidate()
            animationTimer = nil
            return
        }
        guard animationTimer == nil else {
            return
        }
        animationTimer = timerScheduler.makeTimer(timeInterval: Constants.frameInterval, repeats: true) { [weak self] in
            guard let self else {
                return
            }
            animationPhase = (animationPhase + Constants.phaseStep).truncatingRemainder(dividingBy: 1)
            statusItem.button?.image = StatusIconRenderer.image(for: viewModel.icon, phase: animationPhase)
        }
    }

}

// MARK: - NSPopoverDelegate
extension StatusBarController: NSPopoverDelegate {

    func popoverDidShow(_ notification: Notification) {
        appStateRepository.isPanelVisible.send(true)
    }

    func popoverDidClose(_ notification: Notification) {
        appStateRepository.isPanelVisible.send(window?.isVisible == true)
    }

}

// MARK: - NSWindowDelegate
extension StatusBarController: NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        appStateRepository.isPanelVisible.send(popover.isShown)
        coordinator.windowClosed()
    }

}

private enum Constants {
    static let frameInterval: TimeInterval = 1.0 / 15
    static let phaseStep = 1.0 / 18
    static let titleFontSize: CGFloat = 11
    static let titleBaselineOffset: CGFloat = 0.5
    static let windowAutosaveName = "PanelWindow"
}
