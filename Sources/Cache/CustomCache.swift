// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public typealias CacheCost = Comparable & AdditiveArithmetic & Numeric

public struct CustomCache<Key, Value, Cost, Policy>
where
    Key: Hashable,
    Policy: CachePolicy,
    Cost: CacheCost
{
    public typealias Element = (key: Key, value: Value)

    internal typealias Index = Policy.Index

    internal struct ElementContainer {
        var cost: Cost
        var element: Element
    }

    /// Complexity: O(`1`).
    public var isEmpty: Bool {
        self.indicesByKey.isEmpty
    }

    /// Complexity: O(`1`).
    public var count: Int {
        self.indicesByKey.count
    }

    public var capacity: Int {
        self.indicesByKey.capacity
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
    
    internal fileprivate(set) var indicesByKey: [Key: Index]
    internal fileprivate(set) var elementsByIndex: [Index: ElementContainer]
    internal fileprivate(set) var policy: Policy

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
    ///     The requested number of elements to store.
    ///   - totalCostLimit:
    ///     The maximum total cost that the cache can
    ///     hold before it starts evicting objects.
    ///   - defaultCost:
    ///     The default cost associated with all stored value,
    ///     for which no individual cost was specified.
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
            indicesByKey: .init(minimumCapacity: minimumCapacity),
            elementsByIndex: .init(minimumCapacity: minimumCapacity),
            policy: .init(minimumCapacity: minimumCapacity)
        )
    }

    fileprivate init(
        totalCostLimit: Cost?,
        defaultCost: Cost,
        totalCost: Cost,
        indicesByKey: [Key: Index],
        elementsByIndex: [Index: ElementContainer],
        policy: Policy
    ) {
        if let totalCostLimit = totalCostLimit {
            assert(totalCostLimit >= 0)
        }

        self.totalCostLimit = totalCostLimit
        self.defaultCost = defaultCost
        self.totalCost = totalCost
        self.indicesByKey = indicesByKey
        self.elementsByIndex = elementsByIndex
        self.policy = policy
    }

    public mutating func value(
        forKey key: Key
    ) -> Value? {
        guard let index = self.indicesByKey[key] else {
            return nil
        }

        guard let container = self.elementsByIndex[index] else {
            fatalError("Expected element, found nil")
        }

        self.policy.use(index)

        assert(self.isValid())

        return container.element.value
    }

    public func peekValue(
        forKey key: Key
    ) -> Value? {
        guard let index = self.indicesByKey[key] else {
            return nil
        }

        guard let container = self.elementsByIndex[index] else {
            fatalError("Expected element, found nil")
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
        let cost = cost ?? self.defaultCost

        if let index = self.indicesByKey[key] {
            return self.replaceValue(
                value,
                forKey: key,
                index: index,
                cost: cost
            )
        } else {
            self.insertValue(
                value,
                forKey: key,
                cost: cost
            )
            return nil
        }
    }

    @discardableResult
    public mutating func removeValue(
        forKey key: Key
    ) -> Value? {
        guard let index = self.indicesByKey[key] else {
            return nil
        }

        self.policy.remove(index)

        let element = self.removeValue(forIndex: index)

        return element.value
    }

    @discardableResult
    public mutating func remove() -> Element? {
        guard !self.isEmpty else {
            return nil
        }

        guard let index = self.policy.remove() else {
            fatalError("Expected index, found nil")
        }

        let removed = self.removeValue(forIndex: index)
        return removed
    }

    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.indicesByKey.removeAll(keepingCapacity: keepCapacity)
        self.elementsByIndex.removeAll(keepingCapacity: keepCapacity)
        self.policy.removeAll(keepingCapacity: keepCapacity)
    }

    private mutating func insertValue(
        _ value: Value,
        forKey key: Key,
        cost: Cost
    ) {
        // Evict excessive elements, if necessary:

        if
            let totalCostLimit = self.totalCostLimit,
            (self.totalCost + cost) > totalCostLimit
        {
            // Remove one more, to make space for new element:

            self.removeWhile(
                totalCostAbove: totalCostLimit - cost
            )
        }

        let index = self.policy.insert()

        self.indicesByKey[key] = index

        self.elementsByIndex[index] = .init(
            cost: cost,
            element: (key: key, value: value)
        )

        self.totalCost += cost

        assert(self.isValid())
    }

    private mutating func replaceValue(
        _ value: Value,
        forKey key: Key,
        index: Index,
        cost: Cost
    ) -> Value? {
        let container = ElementContainer(
            cost: cost,
            element: (key: key, value: value)
        )

        self.policy.use(index)

        guard let oldValue = self.elementsByIndex.updateValue(
            container,
            forKey: index
        ) else {
            return nil
        }

        return oldValue.element.value
    }

    @discardableResult
    private mutating func removeValue(
        forIndex index: Index
    ) -> Element {
        guard let container = self.elementsByIndex.removeValue(
            forKey: index
        ) else {
            fatalError("Expected element, found nil")
        }

        let key = container.element.key

        guard let _ = self.indicesByKey.removeValue(
            forKey: key
        ) else {
            fatalError("Expected index, found nil")
        }

        self.totalCost -= container.cost

        assert(self.isValid())

        return container.element
    }

    private mutating func removeWhile(totalCostAbove totalCostLimit: Cost) {
        while (self.count > 0) && (self.totalCost > totalCostLimit) {
            guard let _ = self.remove() else {
                break
            }
        }
    }

    internal func isValid() -> Bool {
        let indexCount = self.indicesByKey.count
        let elementCount = self.elementsByIndex.count
        let policyIndexCount = self.policy.count

        guard indexCount == policyIndexCount else {
            return false
        }

        guard elementCount == policyIndexCount else {
            return false
        }

        return true
    }
}

extension CustomCache: Equatable
where
    Value: Equatable
{
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.indicesByKey.count == rhs.indicesByKey.count else {
            return false
        }

        for (key, lhsIndex) in lhs.indicesByKey {
            guard let rhsIndex = rhs.indicesByKey[key] else {
                return false
            }

            let lhsElement = lhs.elementsByIndex[lhsIndex]!.element
            let rhsElement = rhs.elementsByIndex[rhsIndex]!.element

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

extension CustomCache: Hashable
where
    Value: Hashable
{
    public func hash(into hasher: inout Hasher) {
        var commutativeHash = 0
        for index in self.indicesByKey.values {
            guard let container = self.elementsByIndex[index] else {
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

extension CustomCache: CustomStringConvertible {
    public var description: String {
        let typeName = String(describing: type(of: self))
        let totalCostLimit = self.totalCostLimit.map { "\($0)" } ?? "nil"
        let elements = self.lazy.map { key, value in
            return "\(key): \(value)"
        }.joined(separator: ", ")
        return "\(typeName)(totalCostLimit: \(totalCostLimit), elements: [\(elements)])"
    }
}

extension CustomCache: Sequence {
    public typealias Iterator = AnyIterator<Element>

    public func makeIterator() -> Iterator {
        let elements = self.elementsByIndex.values.lazy.map { container in
            container.element
        }
        return .init(elements.makeIterator())
    }
}
