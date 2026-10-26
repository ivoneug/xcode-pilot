// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// What can be done with a fresh archive or export
struct ArchiveResultView: View {

    // MARK: - Properties
    let activity: BuildActivity
    let archive: ArchiveInfo
    @ObservedObject var viewModel: PanelViewModel

    // MARK: - Layout
    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x3) {
            HStack(spacing: Margin.x2) {
                Image(systemName: "archivebox")
                Text(archive.name)
                    .fontWeight(.medium)
                if archive.versionDescription.isEmpty == false {
                    Text(archive.versionDescription)
                        .foregroundStyle(Colors.textSecondary.color)
                }
            }
            .font(.system(size: Constants.fontSize))

            HStack(spacing: Margin.x3) {
                switch activity.action {
                case .export:
                    if activity.isUpload {
                        Label(Localizations.Archive.uploaded, systemImage: "icloud.and.arrow.up")
                            .font(.system(size: Constants.fontSize))
                    } else {
                        Button(Localizations.Archive.showExport, action: viewModel.revealExport)
                    }
                default:
                    Button(Localizations.Archive.showInOrganizer) {
                        viewModel.showInOrganizer(archive)
                    }
                    Button(Localizations.Archive.export) {
                        viewModel.export(archive)
                    }
                    .buttonStyle(.borderedProminent)
                    Button(Localizations.Archive.reveal) {
                        viewModel.reveal(archive)
                    }
                }
            }
            .controlSize(.small)
        }
    }

}

private enum Constants {
    static let fontSize: CGFloat = 11
}
