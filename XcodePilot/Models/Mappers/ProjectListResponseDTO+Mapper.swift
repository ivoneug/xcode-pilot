// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension ProjectListResponseDTO {

    // MARK: - Internal methods
    func convertToPlain() -> ProjectInfo {
        let container = project ?? workspace
        return ProjectInfo(schemes: container?.schemes ?? [], configurations: container?.configurations ?? [])
    }

}
