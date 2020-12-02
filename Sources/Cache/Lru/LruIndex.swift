// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// The only purpose of this index wrapper type is to make it
// impossible for users of the API to create indices themselves.

public struct LruIndex<RawIndex> {
    @usableFromInline
    internal let value: RawIndex

    @inlinable
    @inline(__always)
    internal init(_ value: RawIndex) {
        self.value = value
    }
}

extension LruIndex: Equatable
where
    RawIndex: Equatable
{
    @inlinable
    @inline(__always)
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
    @inlinable
    @inline(__always)
    public func hash(into hasher: inout Hasher) {
        self.value.hash(into: &hasher)
    }
}

extension LruIndex: CustomStringConvertible {
    @inlinable
    @inline(__always)
    public var description: String {
        String(describing: self.value)
    }
}

extension LruIndex: ExpressibleByIntegerLiteral
where
    RawIndex: BinaryInteger
{
    public typealias IntegerLiteralType = UInt

    @inlinable
    @inline(__always)
    public init(integerLiteral value: IntegerLiteralType) {
        assert(value >= 0)

        self.init(RawIndex(truncatingIfNeeded: value))
    }
}
