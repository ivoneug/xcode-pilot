// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Carbon.HIToolbox
import Foundation

/// System wide shortcuts through Carbon's `RegisterEventHotKey`, which needs no Accessibility permission
final class HotKeyService {

    // MARK: - Properties
    /// The Carbon callback is a C function and can't capture, it finds the service through this
    fileprivate static weak var current: HotKeyService?
    private var actions: [UInt32: () -> Void] = [:]
    private var references: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private var nextIdentifier: UInt32 = 1

    // MARK: - Init/Deinit
    init() {
        Self.current = self
    }

    // MARK: - Private methods
    fileprivate func fire(_ identifier: UInt32) {
        actions[identifier]?()
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else {
            return
        }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotKeyHandler, 1, &eventType, nil, &eventHandler)
    }

}

// MARK: - HotKeyServiceProtocol
extension HotKeyService: HotKeyServiceProtocol {

    func register(_ hotKey: HotKey, action: @escaping () -> Void) {
        installHandlerIfNeeded()
        let identifier = nextIdentifier
        nextIdentifier += 1

        var reference: EventHotKeyRef?
        let hotKeyId = EventHotKeyID(signature: Constants.signature, id: identifier)
        let modifiers = hotKey.modifiers.reduce(UInt32.zero) { $0 | $1.carbonFlag }
        let status = RegisterEventHotKey(hotKey.keyCode, modifiers, hotKeyId, GetApplicationEventTarget(), .zero, &reference)
        guard status == noErr, let reference else {
            return
        }
        references.append(reference)
        actions[identifier] = action
    }

    func unregisterAll() {
        references.forEach { UnregisterEventHotKey($0) }
        references.removeAll()
        actions.removeAll()
    }

}

private extension HotKey.Modifier {

    var carbonFlag: UInt32 {
        switch self {
        case .command:
            return UInt32(cmdKey)
        case .option:
            return UInt32(optionKey)
        case .control:
            return UInt32(controlKey)
        case .shift:
            return UInt32(shiftKey)
        }
    }

}

private func hotKeyHandler(_ handler: EventHandlerCallRef?, _ event: EventRef?, _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    var hotKeyId = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyId
    )
    let identifier = hotKeyId.id
    DispatchQueue.main.async {
        HotKeyService.current?.fire(identifier)
    }
    return noErr
}

private enum Constants {
    /// "XPLT"
    static let signature: OSType = 0x5850_4C54
}
