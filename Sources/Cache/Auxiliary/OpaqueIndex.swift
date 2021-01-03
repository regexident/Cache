// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// The only purpose of this index wrapper type is to make it
// impossible for users of the API to create indices themselves.
public struct OpaqueIndex<RawValue> {
    @usableFromInline
    internal let rawValue: RawValue

    @inlinable
    @inline(__always)
    internal init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension OpaqueIndex: Equatable
where
    RawValue: Equatable
{
    @inlinable
    @inline(__always)
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

extension OpaqueIndex: Hashable
where
    RawValue: Hashable
{
    @inlinable
    @inline(__always)
    public func hash(into hasher: inout Hasher) {
        self.rawValue.hash(into: &hasher)
    }
}

extension OpaqueIndex: CustomStringConvertible {
    @inlinable
    @inline(__always)
    public var description: String {
        String(describing: self.rawValue)
    }
}
