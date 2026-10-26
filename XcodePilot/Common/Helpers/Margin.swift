// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import CoreGraphics

enum Margin {

    /// 2 points
    static let x1: CGFloat = 2
    /// 4 points
    static let x2 = x1 * 2
    /// 6 points
    static let x3 = x1 * 3
    /// 8 points
    static let x4 = x1 * 4
    /// 10 points
    static let x5 = x1 * 5
    /// 12 points
    static let x6 = x1 * 6
    /// 14 points
    static let x7 = x1 * 7
    /// 16 points
    static let x8 = x1 * 8
    /// 18 points
    static let x9 = x1 * 9
    /// 20 points
    static let x10 = x1 * 10
    /// 22 points
    static let x11 = x1 * 11
    /// 24 points
    static let x12 = x1 * 12
    /// 26 points
    static let x13 = x1 * 13
    /// 28 points
    static let x14 = x1 * 14
    /// 30 points
    static let x15 = x1 * 15
    /// 32 points
    static let x16 = x1 * 16
    /// 34 points
    static let x17 = x1 * 17
    /// 36 points
    static let x18 = x1 * 18
    /// 38 points
    static let x19 = x1 * 19
    /// 40 points
    static let x20 = x1 * 20

    static func x(_ value: CGFloat) -> CGFloat {
        x1 * value
    }

}
