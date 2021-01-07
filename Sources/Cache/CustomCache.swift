// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public struct CustomCache<Key, Value, Policy>
where
    Key: Hashable,
    Policy: CachePolicy
{
    public typealias Element = (key: Key, value: Value)
    public typealias Metadata = Policy.Metadata

    internal typealias Index = Policy.Index
    internal typealias Storage = CustomCacheStorage<Key, Value, Policy>

    /// Complexity: O(`1`).
    public var isEmpty: Bool {
        self.storage.isEmpty
    }

    /// Complexity: O(`1`).
    public var count: Int {
        self.storage.count
    }

    public var capacity: Int {
        self.storage.capacity
    }

    internal fileprivate(set) var storage: Storage
    internal let defaultMetadata: Metadata

    /// Creates an empty cache with preallocated space
    /// for at least the specified number of values
    /// and a `defaultMetadata` of `Metadata.default`.
    ///
    /// - Note:
    ///   For performance reasons, the size of the newly allocated
    ///   storage might be greater than the requested capacity.
    ///   Use the policy's `capacity` property to determine the size
    ///   of the new storage.
    ///
    /// - Parameters:
    ///   - minimumCapacity:
    ///     The minimum number of elements to provide initial capacity for.
    ///   - policy:
    ///     The cache's desired policy for a given `minimumCapacity`.
    public init(
        minimumCapacity: Int = 0,
        policy policyProvider: (Int) -> Policy
    )
    where
        Metadata: DefaultCacheMetadata
    {
        self.init(
            minimumCapacity: minimumCapacity,
            defaultMetadata: .default,
            policy: policyProvider
        )
    }

    /// Creates an empty cache with preallocated space
    /// for at least the specified number of values.
    ///
    /// - Note:
    ///   For performance reasons, the size of the newly allocated
    ///   storage might be greater than the requested capacity.
    ///   Use the policy's `capacity` property to determine the size
    ///   of the new storage.
    ///
    /// - Parameters:
    ///   - minimumCapacity:
    ///     The minimum number of elements to provide initial capacity for.
    ///   - defaultMetadata:
    ///     The default metadata to use when not explicitly provided.
    ///   - policy:
    ///     The cache's desired policy for a given `minimumCapacity`.
    public init(
        minimumCapacity: Int = 0,
        defaultMetadata: Metadata,
        policy policyProvider: (Int) -> Policy
    ) {
        self.storage = .init(
            indicesByKey: .init(minimumCapacity: minimumCapacity),
            elementsByIndex: .init(minimumCapacity: minimumCapacity),
            policy: policyProvider(minimumCapacity)
        )
        self.defaultMetadata = defaultMetadata
    }

    public mutating func cachedValue(
        forKey key: Key,
        metadata: Metadata? = nil,
        didMiss: UnsafeMutablePointer<Bool>? = nil,
        by closure: () throws -> Value
    ) rethrows -> Value {
        let metadata = metadata ?? self.defaultMetadata

        return try self.modifyStorage { storage in
            try storage.cachedValue(
                forKey: key,
                metadata: metadata,
                didMiss: didMiss,
                by: closure
            )
        }
    }

    public mutating func value(
        forKey key: Key,
        metadata: Metadata? = nil
    ) -> Value? {
        let metadata = metadata ?? self.defaultMetadata

        return self.modifyStorage { storage in
            storage.value(
                forKey: key,
                metadata: metadata
            )
        }
    }

    public func peekValue(
        forKey key: Key
    ) -> Value? {
        self.storage.peekValue(forKey: key)
    }

    public mutating func setValue(
        _ value: Value?,
        forKey key: Key,
        metadata: Metadata? = nil
    ) {
        let metadata = metadata ?? self.defaultMetadata

        return self.modifyStorage { storage in
            storage.setValue(
                value,
                forKey: key,
                metadata: metadata
            )
        }
    }

    @discardableResult
    public mutating func updateValue(
        _ value: Value,
        forKey key: Key,
        metadata: Metadata? = nil
    ) -> Value? {
        let metadata = metadata ?? self.defaultMetadata

        return self.modifyStorage { storage in
            storage.updateValue(
                value,
                forKey: key,
                metadata: metadata
            )
        }
    }

    @discardableResult
    public mutating func removeValue(
        forKey key: Key
    ) -> Value? {
        self.modifyStorage { storage in
            storage.removeValue(
                forKey: key
            )
        }
    }

    @discardableResult
    public mutating func remove() -> Element? {
        self.modifyStorage { storage in
            storage.remove()
        }
    }

    public mutating func removeExpired() {
        self.modifyStorage { storage in
            storage.removeExpired()
        }
    }

    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.modifyStorage { storage in
            storage.removeAll(
                keepingCapacity: keepCapacity
            )
        }
    }

    // Since `self.storage` has reference semantics we need to guard
    // mutating access to it with `.isKnownUniquelyReferenced()`
    // to ensure conforming to value semantics:
    @discardableResult
    private mutating func modifyStorage<T>(
        closure: (inout Storage) throws -> T
    ) rethrows -> T {
        if !Swift.isKnownUniquelyReferenced(&self.storage) {
            self.storage = Storage(self.storage)
        }

        return try closure(&self.storage)
    }
}

extension CustomCache: Equatable
where
    Value: Equatable
{
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }
}

extension CustomCache: Hashable
where
    Value: Hashable
{
    public func hash(into hasher: inout Hasher) {
        self.storage.hash(into: &hasher)
    }
}

extension CustomCache: CustomStringConvertible {
    public var description: String {
        let typeName = String(describing: type(of: self))
        let elements = self.lazy.map { key, value in
            return "\(key): \(value)"
        }.joined(separator: ", ")
        return "\(typeName)(elements: [\(elements)])"
    }
}

extension CustomCache: Sequence {
    public typealias Iterator = AnyIterator<Element>

    public func makeIterator() -> Iterator {
        self.storage.makeIterator()
    }
}
