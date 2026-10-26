// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

/// Serializes every read and write of a single value shared between threads.
///
/// Needed wherever a background worker publishes state the UI reads on the main thread. Swift
/// values are not atomic: a plain `Array` property written on one thread while another copies it
/// races on the buffer reference count, which over-releases the buffer and corrupts the heap long
/// before anything visibly goes wrong. The lock also gives the memory ordering flags like
/// `interrupted` rely on, which a bare `Bool` read in a loop does not have.
@propertyWrapper
final class Protected<Value> {

    // MARK: - Properties
    private let lock = NSLock()
    private var value: Value

    // MARK: - Computed properties
    var wrappedValue: Value {
        get {
            lock.withLock({ value })
        }
        set {
            lock.withLock({ value = newValue })
        }
    }

    // MARK: - Init/Deinit
    init(wrappedValue: Value) {
        value = wrappedValue
    }

}
