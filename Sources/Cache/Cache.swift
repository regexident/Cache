// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct Cache<Key, Value, Policy>: CacheProtocol, EvictableCacheProtocol
where
    Key: Hashable,
    Policy: CachePolicyProtocol
{
    public typealias Element = (key: Key, value: Value)

    internal typealias Token = Policy.Token

    /// Complexity: O(`1`).
    public var isEmpty: Bool {
        self.tokensByKey.isEmpty
    }

    /// Complexity: O(`1`).
    public var count: Int {
        self.tokensByKey.count
    }

    public var capacity: Int {
        self.tokensByKey.capacity
    }

    public private(set) var maximumCount: Int {
        didSet {
            assert(self.maximumCount >= 0)

            self.removeLeastRecentlyUsed(
                Swift.max(0, self.count - self.maximumCount)
            )
        }
    }

    fileprivate private(set) var tokensByKey: [Key: Token]
    fileprivate private(set) var elementsByToken: [Token: Element]
    fileprivate private(set) var policy: Policy

    public init(
        maximumCount: Int
    ) {
        assert(maximumCount >= 0)

        let maximumCount = Self.maximumCountFor(
            maximumCount: maximumCount
        )

        self.maximumCount = maximumCount
        self.tokensByKey = [:]
        self.elementsByToken = [:]
        self.policy = .init(maximumCount: maximumCount)
    }

    @inlinable
    @inline(__always)
    public init<S>(
        uniqueKeysWithValues keysAndValues: S
    )
    where
        S: Sequence,
        S.Element == (Key, Value)
    {
        self.init(
            maximumCount: .max,
            uniqueKeysWithValues: keysAndValues
        )
    }

    public init<S>(
        maximumCount: Int,
        uniqueKeysWithValues keysAndValues: S
    )
    where
        S: Sequence,
        S.Element == (Key, Value)
    {
        self.init(maximumCount: maximumCount)
        for (key, value) in keysAndValues {
            self.setValue(value, forKey: key)
        }
    }

    public mutating func resizeTo(
        maximumCount: Int
    ) {
        let maximumCount = Self.maximumCountFor(
            maximumCount: maximumCount
        )
        self.maximumCount = maximumCount
    }

    public mutating func value(
        forKey key: Key
    ) -> Value? {
        guard let token = self.tokensByKey[key] else {
            return nil
        }

        let element = self.element(forToken: token)

        self.policy.use(token)

        return element.value
    }

    public func peekValue(
        forKey key: Key
    ) -> Value? {
        guard let token = self.tokensByKey[key] else {
            return nil
        }

        let element = self.element(forToken: token)

        return element.value
    }

    public mutating func setValue(
        _ value: Value?,
        forKey key: Key
    ) {
        guard let value = value else {
            self.removeValue(forKey: key)
            return
        }

        self.updateValue(value, forKey: key)
    }

    @discardableResult
    public mutating func updateValue(
        _ value: Value,
        forKey key: Key
    ) -> Value? {
        // If value present by that key, update it:

        let updatedValue = self.updateValueIfPresent(
            value,
            forKey: key
        )

        if updatedValue != nil {
            return updatedValue
        }

        // No value present by that key, so:

        // 1. Evict excessive elements, if necessary:

        if self.count >= self.maximumCount {
            // Remove one more, to make space for new element:
            self.removeLeastRecentlyUsed(
                Swift.max(0, self.count - (self.maximumCount - 1))
            )
        }

        // 2. Add the new value:

        self.addValueIfNotPresent(
            value,
            forKey: key
        )

        return nil
    }

    @discardableResult
    public mutating func removeValue(
        forKey key: Key
    ) -> Value? {
        guard let token = self.tokensByKey.removeValue(
            forKey: key
        ) else {
            return nil
        }

        let element = self.elementsByToken.removeValue(
            forKey: token)!

        self.policy.remove(token)

        return element.value
    }

    private func element(forToken token: Token) -> Element {
        let element = self.elementsByToken[token]!

        return element
    }

    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.tokensByKey.removeAll(keepingCapacity: keepCapacity)
        self.elementsByToken.removeAll(keepingCapacity: keepCapacity)
        self.policy.removeAll(keepingCapacity: keepCapacity)
    }

    @discardableResult
    private mutating func updateValueIfPresent(
        _ value: Value,
        forKey key: Key
    ) -> Value? {
        guard let token = self.tokensByKey[key] else {
            return nil
        }

        self.policy.use(token)

        let oldValue: Value? = self.elementsByToken.modifyValue(
            forKey: token
        ) { element in
            defer {
                element?.value = value
            }

            return element?.value
        }

        return oldValue
    }

    private mutating func addValueIfNotPresent(
        _ value: Value,
        forKey key: Key
    ) {
        guard self.tokensByKey[key] == nil else {
            return
        }

        let token = self.policy.insert()

        self.tokensByKey[key] = token

        let element = (key: key, value: value)
        self.elementsByToken[token] = element
    }

    private mutating func removeLeastRecentlyUsed(_ k: Int) {
        for _ in 0..<k {
            self.removeLeastRecentlyUsed()
        }
    }

    @discardableResult
    private mutating func removeLeastRecentlyUsed() -> Element? {
        guard !self.isEmpty else {
            return nil
        }

        let token = self.policy.removeLeastRecentlyUsed()!

        let element = self.elementsByToken.removeValue(forKey: token)!

        self.tokensByKey.removeValue(forKey: element.key)

        return element
    }

    private static func maximumCountFor(
        maximumCount: Int
    ) -> Int {
        assert(maximumCount >= 0)

        return maximumCount
    }
}

extension Cache: Equatable
where
    Value: Equatable
{
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.tokensByKey.count == rhs.tokensByKey.count else {
            return false
        }

        for (key, lhsToken) in lhs.tokensByKey {
            guard let rhsToken = rhs.tokensByKey[key] else {
                return false
            }

            let lhsElement = lhs.elementsByToken[lhsToken]!
            let rhsElement = rhs.elementsByToken[rhsToken]!

            guard lhsElement.key == rhsElement.key else {
                return false
            }
            guard lhsElement.value == rhsElement.value else {
                return false
            }
        }

        return true
    }
}

extension Cache: Hashable
where
    Value: Hashable
{
    public func hash(into hasher: inout Hasher) {
        var commutativeHash = 0
        for token in self.tokensByKey.values {
            let (key, value) = self.elementsByToken[token]!

            var elementHasher = hasher
            key.hash(into: &elementHasher)
            value.hash(into: &elementHasher)

            commutativeHash ^= elementHasher.finalize()
        }
        hasher.combine(commutativeHash)
    }
}

extension Cache: ExpressibleByDictionaryLiteral {
    @inlinable
    @inline(__always)
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
}

extension Cache: CustomStringConvertible {
    public var description: String {
        let typeName = String(describing: type(of: self))
        let elements = self.lazy.map { key, value in
            return "\(key): \(value)"
        }.joined(separator: ", ")
        return "\(typeName)(maximumCount: \(self.maximumCount), elements: [\(elements)])"
    }
}

extension Cache: Sequence {
    public typealias Iterator = AnyIterator<Element>

    public func makeIterator() -> Iterator {
        .init(self.elementsByToken.values.makeIterator())
    }
}
