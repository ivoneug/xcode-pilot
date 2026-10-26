// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

/// State of the app launched by Run
struct RunStatusView: View {

    // MARK: - Properties
    let run: AppRun
    let onStop: () -> Void

    // MARK: - Layout
    var body: some View {
        HStack(spacing: Margin.x3) {
            Image(systemName: symbolName)
                .foregroundStyle(color)
            Text(run.stateDescription)
                .font(.system(size: Constants.fontSize))
                .lineLimit(Constants.lineLimit)
                .textSelection(.enabled)
            Spacer(minLength: .zero)
            if run.isPreparing {
                ProgressView()
                    .controlSize(.mini)
            }
            if run.isActive {
                Button(Localizations.Action.stop, action: onStop)
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Computed properties
    private var symbolName: String {
        switch run.state {
        case .running:
            return "play.circle.fill"
        case .failed:
            return "exclamationmark.octagon.fill"
        case .booting, .installing, .launching:
            return "arrow.down.app"
        case .exited:
            return "stop.circle"
        }
    }

    private var color: Color {
        switch run.state {
        case .running:
            return Colors.success.color
        case .failed:
            return Colors.failure.color
        case .booting, .installing, .launching, .exited:
            return Colors.textSecondary.color
        }
    }

}

private enum Constants {
    static let fontSize: CGFloat = 11
    static let lineLimit = 3
}
