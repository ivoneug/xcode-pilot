// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

enum UserDefaultsKey: String, CaseIterable {
    case preferences = "xp.preferences"
    case recentProjects = "xp.recentProjects"
    case currentProject = "xp.currentProject"
    case projectSelections = "xp.projectSelections"
    case cachedProjectInfo = "xp.cachedProjectInfo"
    case cachedDestinations = "xp.cachedDestinations"
    case buildDurations = "xp.buildDurations"
    case recentDestinations = "xp.recentDestinations"
}
