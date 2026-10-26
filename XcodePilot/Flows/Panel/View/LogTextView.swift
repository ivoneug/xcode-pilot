// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import SwiftUI

/// Large, append only, selectable text: SwiftUI's Text can't keep up with a build log.
/// New lines are appended to the text storage, and the view follows the end while it is there.
struct LogTextView: NSViewRepresentable {

    // MARK: - Properties
    let lines: [String]
    /// Changes whenever `lines` does, cheaper to compare than the lines themselves
    let version: Int
    /// Identity of the log shown; a new one replaces the text instead of appending to it
    let source: AnyHashable
    /// Text marked wherever it appears, matched case insensitively. Part of `source` when it changes.
    var highlights: [String] = []

    // MARK: - Internal methods
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        if let textView = scrollView.documentView as? NSTextView {
            textView.isEditable = false
            textView.isSelectable = true
            textView.drawsBackground = false
            textView.usesFindBar = true
            textView.isIncrementalSearchingEnabled = true
            textView.textContainerInset = NSSize(width: Margin.x4, height: Margin.x4)
            textView.font = Constants.font
            textView.textColor = Colors.textPrimary.nsColor
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView, let storage = textView.textStorage else {
            return
        }
        let coordinator = context.coordinator
        let isNewSource = coordinator.source != source
        guard isNewSource || coordinator.version != version || coordinator.lineCount != lines.count else {
            return
        }

        let isAtBottom = scrollView.contentView.bounds.maxY >= textView.bounds.maxY - Constants.followThreshold
        if isNewSource || lines.count < coordinator.lineCount || coordinator.lineCount == .zero {
            // Another log, a reset one or a switch between the full and the condensed one
            storage.setAttributedString(attributed(lines.joined(separator: String.lineBreak)))
        } else if lines.count > coordinator.lineCount {
            storage.append(attributed(String.lineBreak + lines[coordinator.lineCount...].joined(separator: String.lineBreak)))
        }
        coordinator.lineCount = lines.count
        coordinator.version = version
        coordinator.source = source

        if isAtBottom {
            textView.scrollToEndOfDocument(nil)
        }
    }

    // MARK: - Private methods
    private func attributed(_ text: String) -> NSAttributedString {
        let string = NSMutableAttributedString(
            string: text,
            attributes: [.font: Constants.font, .foregroundColor: Colors.textPrimary.nsColor]
        )
        let nsText = text as NSString
        for highlight in highlights {
            var searchRange = NSRange(location: .zero, length: nsText.length)
            while searchRange.length > .zero {
                let found = nsText.range(of: highlight, options: .caseInsensitive, range: searchRange)
                guard found.location != NSNotFound else {
                    break
                }
                string.addAttribute(.backgroundColor, value: Colors.highlight.nsColor, range: found)
                searchRange = NSRange(location: NSMaxRange(found), length: nsText.length - NSMaxRange(found))
            }
        }
        return string
    }

}

extension LogTextView {

    final class Coordinator {

        // MARK: - Properties
        var lineCount: Int = .zero
        var version: Int = -1
        var source: AnyHashable?

    }

}

private enum Constants {
    static let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    static let followThreshold: CGFloat = 40
}
