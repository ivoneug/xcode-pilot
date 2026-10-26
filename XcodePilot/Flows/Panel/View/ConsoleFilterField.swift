// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit
import SwiftUI

/// Token field of the console filter, like the one in Xcode's console: Return or a comma turns
/// the typed text into a token, Delete removes tokens, a token's menu switches it to hiding lines.
struct ConsoleFilterField: NSViewRepresentable {

    // MARK: - Properties
    let tokens: [ConsoleFilter.Token]
    let draft: String
    let onChange: (_ tokens: [ConsoleFilter.Token], _ draft: String) -> Void

    // MARK: - Internal methods
    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    /// The field sits in a container SwiftUI sizes: the field's own size changes as the user types,
    /// and SwiftUI measuring it would start another layout pass from every pass
    func makeNSView(context: Context) -> NSView {
        let field = NSTokenField()
        field.delegate = context.coordinator
        field.placeholderString = Localizations.Console.Filter.placeholder
        field.toolTip = Localizations.Console.Filter.help
        field.controlSize = .small
        field.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        field.bezelStyle = .roundedBezel
        field.tokenStyle = .rounded
        field.usesSingleLineMode = true
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.objectValue = tokens.map { TokenObject($0) }
        let height = field.fittingSize.height
        field.frame = NSRect(x: .zero, y: .zero, width: Constants.initialWidth, height: height)
        field.autoresizingMask = [.width, .height]

        let container = NSView(frame: field.frame)
        container.addSubview(field)
        context.coordinator.field = field
        context.coordinator.height = height
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onChange = onChange
        guard let field = coordinator.field else {
            return
        }
        // The field reports every edit, so it differs from the state only after a change made
        // elsewhere: the filter was cleared or a repeated token dropped
        let isDraftCleared = draft.isEmpty && coordinator.draft(of: field).isEmpty == false
        guard coordinator.tokens(of: field) != tokens || isDraftCleared else {
            return
        }
        coordinator.show(tokens, in: field)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? Constants.initialWidth, height: context.coordinator.height)
    }

}

extension ConsoleFilterField {

    /// Represented object of a token. Only the ones the user actually added are `isAdded`: reading
    /// the field's value while the user types turns the typed text into a token object as well.
    final class TokenObject: NSObject {

        // MARK: - Properties
        var token: ConsoleFilter.Token
        var isAdded: Bool

        // MARK: - Init/Deinit
        init(_ token: ConsoleFilter.Token) {
            self.token = token
            isAdded = true
        }

        init(typed token: ConsoleFilter.Token) {
            self.token = token
            isAdded = false
        }

    }

    final class Coordinator: NSObject {

        // MARK: - Properties
        var onChange: ([ConsoleFilter.Token], String) -> Void
        weak var field: NSTokenField?
        var height: CGFloat = .zero
        /// The object of the text being typed; the field asks for one on every redraw and would
        /// see a new value each time if it got a new object
        private var typedObject: TokenObject?

        // MARK: - Init/Deinit
        init(onChange: @escaping ([ConsoleFilter.Token], String) -> Void) {
            self.onChange = onChange
        }

        // MARK: - Internal methods
        func tokens(of field: NSTokenField) -> [ConsoleFilter.Token] {
            objects(of: field).filter(\.isAdded).map(\.token)
        }

        /// The typed text that is not a token yet; the field editor keeps tokens as attachments
        func draft(of field: NSTokenField) -> String {
            guard let editor = field.currentEditor() as? NSTextView else {
                return String.empty
            }
            return editor.string.replacingOccurrences(of: Constants.attachmentCharacter, with: String.empty)
        }

        /// Replaces what the field shows; the field keeps the focus, but the typed text is gone
        func show(_ tokens: [ConsoleFilter.Token], in field: NSTokenField) {
            let isEditing = field.currentEditor() != nil
            if isEditing {
                field.abortEditing()
            }
            field.objectValue = tokens.map { TokenObject($0) }
            if isEditing, field.window?.makeFirstResponder(field) == true, let editor = field.currentEditor() {
                editor.selectedRange = NSRange(location: (editor.string as NSString).length, length: .zero)
            }
        }

        // MARK: - Private methods
        private func typedObject(for token: ConsoleFilter.Token) -> TokenObject {
            if let typedObject, typedObject.isAdded == false, typedObject.token == token {
                return typedObject
            }
            let object = TokenObject(typed: token)
            typedObject = object
            return object
        }

        private func objects(of field: NSTokenField) -> [TokenObject] {
            (field.objectValue as? [Any] ?? []).compactMap { $0 as? TokenObject }
        }

        private func report(_ field: NSTokenField) {
            onChange(tokens(of: field), draft(of: field))
        }

        private func menu(for object: TokenObject) -> NSMenu {
            let menu = NSMenu()
            let hide = ClosureMenuItem(title: Localizations.Console.Filter.hideMatching) { [weak self] in
                object.token.isExcluded.toggle()
                self?.refresh()
            }
            hide.state = object.token.isExcluded ? .on : .off
            menu.addItem(hide)
            menu.addItem(ClosureMenuItem(title: Localizations.Console.Filter.remove) { [weak self] in
                self?.remove(object)
            })
            return menu
        }

        /// Shows the changed tokens and reports them
        private func refresh() {
            guard let field else {
                return
            }
            show(tokens(of: field), in: field)
            report(field)
        }

        private func remove(_ object: TokenObject) {
            guard let field else {
                return
            }
            show(objects(of: field).filter { $0.isAdded && $0 !== object }.map(\.token), in: field)
            report(field)
        }

    }

}

// MARK: - NSTokenFieldDelegate
extension ConsoleFilterField.Coordinator: NSTokenFieldDelegate {

    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSTokenField else {
            return
        }
        report(field)
    }

    /// Text left in the field is shown as a token once editing ends, so it becomes one
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let field = notification.object as? NSTokenField else {
            return
        }
        // The field editor is still attached and holds the text, but nothing is a draft any more
        let objects = objects(of: field)
        objects.forEach { $0.isAdded = true }
        onChange(objects.map(\.token), String.empty)
    }

    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any? {
        ConsoleFilter.Token(parsing: editingString).map(typedObject(for:))
    }

    /// Called only when the user adds tokens, not when the field's value is read
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        let objects = tokens.compactMap { $0 as? ConsoleFilterField.TokenObject }
        objects.forEach { $0.isAdded = true }
        return objects
    }

    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        (representedObject as? ConsoleFilterField.TokenObject)?.token.displayString ?? representedObject as? String
    }

    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        (representedObject as? ConsoleFilterField.TokenObject)?.token.editingString ?? representedObject as? String
    }

    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
        (representedObject as? ConsoleFilterField.TokenObject)?.token.isExcluded == true ? .squared : .rounded
    }

    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        representedObject is ConsoleFilterField.TokenObject
    }

    func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
        (representedObject as? ConsoleFilterField.TokenObject).map(menu(for:))
    }

}

private enum Constants {
    static let attachmentCharacter = "\u{FFFC}"
    static let initialWidth: CGFloat = 200
}
