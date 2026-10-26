// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import SwiftUI

enum NavigationMode {
    case push(onPop: () -> Void = {})
    case modalPresent(onDismiss: (() -> Void)? = nil)
}

extension View {

    // MARK: - Internal methods
    /// Shows the destination while the model is set. Pushing needs a `NavigationStack` up the hierarchy.
    @ViewBuilder func navigation<Model: Identifiable, Destination: View>(
        model: Binding<Model?>,
        mode: NavigationMode = .push(),
        @ViewBuilder destination: @escaping (Model) -> Destination
    ) -> some View {
        switch mode {
        case .push(let onPop):
            let isPresented = Binding(
                get: { model.wrappedValue != nil },
                set: { newValue in
                    guard model.wrappedValue != nil, newValue == false else {
                        return
                    }
                    onPop()
                    model.wrappedValue = nil
                }
            )
            navigationDestination(isPresented: isPresented) {
                if let value = model.wrappedValue {
                    destination(value)
                }
            }
        case .modalPresent(let onDismiss):
            sheet(
                item: model,
                onDismiss: onDismiss,
                content: destination
            )
        }
    }

}
