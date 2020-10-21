// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public struct LRUIndex {
    internal let value: Int

    internal init(_ value: Int) {
        self.value = value
    }
}

extension LRUIndex: Equatable {
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.value == rhs.value
    }
}

extension LRUIndex: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.value.hash(into: &hasher)
    }
}

extension LRUIndex: CustomStringConvertible {
    public var description: String {
        String(describing: self.value)
    }
}

extension LRUIndex: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt

    public init(integerLiteral value: IntegerLiteralType) {
        assert(value >= 0)

        self.init(Int(bitPattern: value))
    }
}
