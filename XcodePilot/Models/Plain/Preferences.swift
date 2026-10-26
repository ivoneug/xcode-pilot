// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// User settings
struct Preferences: Codable, Equatable {

    // MARK: - Properties
    /// `Contents/Developer` of the Xcode builds use, `nil` follows `xcode-select`
    var developerDirectory: String?
    var showsElapsedTime = true
    var showsIssueCount = true
    var notifiesOnFinish = true
    var playsSounds = false
    var bringsSimulatorToFront = true
    var allowsProvisioningUpdates = true
    var skipsMacroValidation = false
    var usesGlobalHotKeys = true
    var showsCompactLog = true
    /// Seconds the "succeeded" badge stays in the menu bar, zero keeps it until the next action
    var successBadgeDuration: TimeInterval = 30
    var editor: EditorChoice = .xcode
    /// Where exported archives go, `nil` is the Desktop
    var exportDirectory: String?

    // MARK: - Init/Deinit
    init() {}

    /// Every field is optional on decoding, so settings saved by an older version survive new ones
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Preferences()
        developerDirectory = try container.decodeIfPresent(String.self, forKey: .developerDirectory)
        showsElapsedTime = try container.decodeIfPresent(Bool.self, forKey: .showsElapsedTime) ?? defaults.showsElapsedTime
        showsIssueCount = try container.decodeIfPresent(Bool.self, forKey: .showsIssueCount) ?? defaults.showsIssueCount
        notifiesOnFinish = try container.decodeIfPresent(Bool.self, forKey: .notifiesOnFinish) ?? defaults.notifiesOnFinish
        playsSounds = try container.decodeIfPresent(Bool.self, forKey: .playsSounds) ?? defaults.playsSounds
        bringsSimulatorToFront = try container.decodeIfPresent(Bool.self, forKey: .bringsSimulatorToFront)
            ?? defaults.bringsSimulatorToFront
        allowsProvisioningUpdates = try container.decodeIfPresent(Bool.self, forKey: .allowsProvisioningUpdates)
            ?? defaults.allowsProvisioningUpdates
        skipsMacroValidation = try container.decodeIfPresent(Bool.self, forKey: .skipsMacroValidation) ?? defaults.skipsMacroValidation
        usesGlobalHotKeys = try container.decodeIfPresent(Bool.self, forKey: .usesGlobalHotKeys) ?? defaults.usesGlobalHotKeys
        showsCompactLog = try container.decodeIfPresent(Bool.self, forKey: .showsCompactLog) ?? defaults.showsCompactLog
        successBadgeDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .successBadgeDuration)
            ?? defaults.successBadgeDuration
        editor = try container.decodeIfPresent(EditorChoice.self, forKey: .editor) ?? defaults.editor
        exportDirectory = try container.decodeIfPresent(String.self, forKey: .exportDirectory)
    }

}
