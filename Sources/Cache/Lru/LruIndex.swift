// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public struct LruIndex<RawIndex> {
    internal let value: RawIndex

    internal init(_ value: RawIndex) {
        self.value = value
    }
}

extension LruIndex: Equatable
where
    RawIndex: Equatable
{
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.value == rhs.value
    }
}

extension LruIndex: Hashable
where
    RawIndex: Hashable
{
    public func hash(into hasher: inout Hasher) {
        self.value.hash(into: &hasher)
    }
}

extension LruIndex: CustomStringConvertible {
    public var description: String {
        String(describing: self.value)
    }
}

extension LruIndex: ExpressibleByIntegerLiteral
where
    RawIndex: BinaryInteger
{
    public typealias IntegerLiteralType = UInt

    public init(integerLiteral value: IntegerLiteralType) {
        assert(value >= 0)

        self.init(RawIndex(truncatingIfNeeded: value))
    }
}
