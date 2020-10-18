// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public typealias CacheCost = Comparable & AdditiveArithmetic & Numeric

public struct Cache<Key, Value, Cost, Policy>
where
    Key: Hashable,
    Policy: CachePolicy,
    Cost: CacheCost
{
    public typealias Element = (key: Key, value: Value)

    internal typealias Token = Policy.Token

    fileprivate struct ElementContainer {
        var cost: Cost
        var element: Element
    }

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

    public var totalCostLimit: Cost? {
        didSet {
            guard let totalCostLimit = self.totalCostLimit else {
                return
            }

            self.removeWhile(
                totalCostAbove: totalCostLimit
            )
        }
    }

    public let defaultCost: Cost

    public private(set) var totalCost: Cost
    
    fileprivate private(set) var tokensByKey: [Key: Token]
    fileprivate private(set) var elementsByToken: [Token: ElementContainer]
    fileprivate private(set) var policy: Policy

    public init(
        minimumCapacity: Int? = nil,
        totalCostLimit: Cost? = nil,
        defaultCost: Cost
    ) {

        let minimumCapacity = minimumCapacity ?? 0

        self.init(
            totalCostLimit: totalCostLimit,
            defaultCost: defaultCost,
            totalCost: .zero,
            tokensByKey: .init(minimumCapacity: minimumCapacity),
            elementsByToken: .init(minimumCapacity: minimumCapacity),
            policy: .init(minimumCapacity: minimumCapacity)
        )
    }

    fileprivate init(
        totalCostLimit: Cost?,
        defaultCost: Cost,
        totalCost: Cost,
        tokensByKey: [Key: Token],
        elementsByToken: [Token: ElementContainer],
        policy: Policy
    ) {
        if let totalCostLimit = totalCostLimit {
            assert(totalCostLimit >= 0)
        }

        self.totalCostLimit = totalCostLimit
        self.defaultCost = defaultCost
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

        guard let container = self.elementsByToken[token] else {
            return nil
        }

        let newToken = self.policy.use(token)

        if newToken != token {
            self.tokensByKey[key] = newToken
            let container = self.elementsByToken.removeValue(
                forKey: token
            )
            self.elementsByToken[newToken] = container
        }

        return container.element.value
    }

    public func peekValue(
        forKey key: Key
    ) -> Value? {
        guard let token = self.tokensByKey[key] else {
            return nil
        }

        guard let container = self.elementsByToken[token] else {
            return nil
        }

        return container.element.value
    }

    public mutating func setValue(
        _ value: Value?,
        forKey key: Key,
        cost: Cost? = nil
    ) {
        guard let value = value else {
            self.removeValue(forKey: key)
            return
        }

        self.updateValue(value, forKey: key, cost: cost)
    }

    @discardableResult
    public mutating func updateValue(
        _ value: Value,
        forKey key: Key,
        cost: Cost? = nil
    ) -> Value? {
        let oldValue = self.removeValue(forKey: key)

        let cost = cost ?? self.defaultCost

        // Evict excessive elements, if necessary:

        if let totalCostLimit = self.totalCostLimit {
            // Remove one more, to make space for new element:

            self.removeWhile(
                totalCostAbove: totalCostLimit - cost
            )
        }

        let token = self.policy.insert()

        self.tokensByKey[key] = token

        self.elementsByToken[token] = .init(
            cost: cost,
            element: (key: key, value: value)
        )

        self.totalCost += cost

        return oldValue
    }

    @discardableResult
    public mutating func removeValue(
        forKey key: Key
    ) -> Value? {
        guard let token = self.tokensByKey.removeValue(forKey: key) else {
            return nil
        }

        guard let element = self.removeValue(forToken: token) else {
            return nil
        }

        return element.value
    }

    @discardableResult
    public mutating func remove() -> Element? {
        guard !self.isEmpty else {
            return nil
        }

        guard let token = self.policy.next() else {
            return nil
        }

        return self.removeValue(forToken: token)
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
    private mutating func removeValue(
        forToken token: Token
    ) -> Element? {
        guard let container = self.elementsByToken.removeValue(forKey: token) else {
            return nil
        }

        self.policy.remove(token)

        self.tokensByKey.removeValue(forKey: container.element.key)

        self.totalCost -= container.cost

        return container.element
    }

    private mutating func removeWhile(totalCostAbove totalCostLimit: Cost) {
        while (self.count > 0) && (self.totalCost > totalCostLimit) {
            let _ = self.remove()
        }
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

            let lhsElement = lhs.elementsByToken[lhsToken]!.element
            let rhsElement = rhs.elementsByToken[rhsToken]!.element

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
            guard let container = self.elementsByToken[token] else {
                continue
            }

            let (key, value) = container.element

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
        let elements = self.elementsByToken.values.lazy.map { container in
            container.element
        }
        return .init(elements.makeIterator())
    }
}
