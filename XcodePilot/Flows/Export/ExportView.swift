// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

struct ExportView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: ExportViewModel

    // MARK: - Layout
    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x8) {
            VStack(alignment: .leading, spacing: Margin.x2) {
                Text(Localizations.Export.title)
                    .font(.system(size: Constants.titleSize, weight: .semibold))
                Text([viewModel.archive.name, viewModel.archive.versionDescription].filter { $0.isEmpty == false }.joined(separator: " "))
                    .foregroundStyle(Colors.textSecondary.color)
            }

            Picker(Localizations.Export.method, selection: $viewModel.method) {
                ForEach(viewModel.methods) { method in
                    Text(method.title)
                        .tag(method)
                }
            }
            .pickerStyle(.radioGroup)

            if viewModel.method.canUpload {
                Toggle(Localizations.Export.upload, isOn: $viewModel.isUpload)
            }

            Text(viewModel.destinationDescription)
                .font(.system(size: Constants.detailSize))
                .foregroundStyle(Colors.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button(Localizations.Common.cancel, action: viewModel.cancel)
                    .keyboardShortcut(.cancelAction)
                Button(viewModel.actionTitle, action: viewModel.export)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Margin.x12)
        .frame(width: Constants.width)
    }

}

private enum Constants {
    static let titleSize: CGFloat = 15
    static let detailSize: CGFloat = 11
    static let width: CGFloat = 380
}
