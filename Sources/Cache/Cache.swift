// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct Cache<Key, Value, Policy>
where
    Key: Hashable,
    Policy: CachePolicy
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

    fileprivate private(set) var totalCostLimit: Int?
    fileprivate private(set) var totalCost: Int
    fileprivate private(set) var tokensByKey: [Key: Token]
    fileprivate private(set) var elementsByToken: [Token: Element]
    fileprivate private(set) var policy: Policy

    fileprivate init(
        totalCostLimit: Int
    ) {
        assert(totalCostLimit >= 0)

        let totalCostLimit = Self.totalCostLimitFor(
            totalCostLimit: totalCostLimit
        )

        self.init(
            totalCostLimit: totalCostLimit,
            totalCost: .init(),
            tokensByKey: .init(),
            elementsByToken: .init(),
            policy: .init()
        )
    }

    fileprivate init(
        totalCostLimit: Int?,
        totalCost: Int,
        tokensByKey: [Key: Token],
        elementsByToken: [Token: Element],
        policy: Policy
    ) {
        self.totalCostLimit = totalCostLimit
        self.totalCost = totalCost
        self.tokensByKey = tokensByKey
        self.elementsByToken = elementsByToken
        self.policy = policy
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
        forKey key: Key,
        cost: Int = 1
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
        forKey key: Key,
        cost: Int = 1
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

        if let totalCostLimit = self.totalCostLimit, self.totalCost >= totalCostLimit {
            // Remove one more, to make space for new element:
            self.removeLeastRecentlyUsed(
                Swift.max(0, self.count - (totalCostLimit - 1))
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

        let token = self.policy.remove()!

        let element = self.elementsByToken.removeValue(forKey: token)!

        self.tokensByKey.removeValue(forKey: element.key)

        return element
    }

    private static func totalCostLimitFor(
        totalCostLimit: Int
    ) -> Int {
        assert(totalCostLimit >= 0)

        return totalCostLimit
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

extension Cache: CustomStringConvertible {
    public var description: String {
        let typeName = String(describing: type(of: self))
        let totalCostLimit = self.totalCostLimit.map { "\($0)" } ?? "nil"
        let elements = self.lazy.map { key, value in
            return "\(key): \(value)"
        }.joined(separator: ", ")
        return "\(typeName)(totalCostLimit: \(totalCostLimit), elements: [\(elements)])"
    }
}

extension Cache: Sequence {
    public typealias Iterator = AnyIterator<Element>

    public func makeIterator() -> Iterator {
        .init(self.elementsByToken.values.makeIterator())
    }
}
