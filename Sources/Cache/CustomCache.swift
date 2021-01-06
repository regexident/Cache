// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public struct CustomCache<Key, Value, Policy>
where
    Key: Hashable,
    Policy: CachePolicy
{
    public typealias Element = (key: Key, value: Value)
    public typealias Payload = Policy.Payload

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
    internal let defaultPayload: Payload

    /// Creates an empty cache with preallocated space
    /// for at least the specified number of values
    /// and a `defaultPayload` of `Payload.default`.
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
        Payload: DefaultCachePayload
    {
        self.init(
            minimumCapacity: minimumCapacity,
            defaultPayload: .default,
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
    ///   - defaultPayload:
    ///     The default payload to use when not explicitly provided.
    ///   - policy:
    ///     The cache's desired policy for a given `minimumCapacity`.
    public init(
        minimumCapacity: Int = 0,
        defaultPayload: Payload,
        policy policyProvider: (Int) -> Policy
    ) {
        self.storage = .init(
            indicesByKey: .init(minimumCapacity: minimumCapacity),
            elementsByIndex: .init(minimumCapacity: minimumCapacity),
            policy: policyProvider(minimumCapacity)
        )
        self.defaultPayload = defaultPayload
    }

    public mutating func cachedValue(
        forKey key: Key,
        payload: Payload? = nil,
        didMiss: UnsafeMutablePointer<Bool>? = nil,
        by closure: () throws -> Value
    ) rethrows -> Value {
        let payload = payload ?? self.defaultPayload

        return try self.modifyStorage { storage in
            try storage.cachedValue(
                forKey: key,
                payload: payload,
                didMiss: didMiss,
                by: closure
            )
        }
    }

    public mutating func value(
        forKey key: Key,
        payload: Payload? = nil
    ) -> Value? {
        let payload = payload ?? self.defaultPayload

        return self.modifyStorage { storage in
            storage.value(
                forKey: key,
                payload: payload
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
        payload: Payload? = nil
    ) {
        let payload = payload ?? self.defaultPayload

        return self.modifyStorage { storage in
            storage.setValue(
                value,
                forKey: key,
                payload: payload
            )
        }
    }

    @discardableResult
    public mutating func updateValue(
        _ value: Value,
        forKey key: Key,
        payload: Payload? = nil
    ) -> Value? {
        let payload = payload ?? self.defaultPayload

        return self.modifyStorage { storage in
            storage.updateValue(
                value,
                forKey: key,
                payload: payload
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
