// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

extension ArchiveInfoDTO {

    // MARK: - Internal methods
    func convertToPlain(path: URL, isMac: Bool) -> ArchiveInfo {
        ArchiveInfo(
            path: path,
            name: name ?? path.deletingPathExtension().lastPathComponent,
            bundleIdentifier: applicationProperties?.bundleIdentifier,
            version: applicationProperties?.shortVersion,
            build: applicationProperties?.version,
            teamId: applicationProperties?.team,
            isMac: isMac,
            creationDate: creationDate
        )
    }

}
