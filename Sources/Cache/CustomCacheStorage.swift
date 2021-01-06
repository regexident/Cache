// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

internal final class CustomCacheStorage<Key, Value, Policy>
where
    Key: Hashable,
    Policy: CachePolicy
{
    internal typealias Element = (key: Key, value: Value)
    internal typealias Payload = Policy.Payload
    internal typealias Index = Policy.Index

    /// Complexity: O(`1`).
    internal var isEmpty: Bool {
        self.indicesByKey.isEmpty
    }

    /// Complexity: O(`1`).
    internal var count: Int {
        self.indicesByKey.count
    }

    internal var capacity: Int {
        self.indicesByKey.capacity
    }

    internal fileprivate(set) var indicesByKey: [Key: Index]
    internal fileprivate(set) var elementsByIndex: [Index: Element]
    internal fileprivate(set) var policy: Policy

    internal convenience init(
        _ other: CustomCacheStorage
    ) {
        self.init(
            indicesByKey: other.indicesByKey,
            elementsByIndex: other.elementsByIndex,
            policy: other.policy
        )
    }

    internal init(
        indicesByKey: [Key: Index],
        elementsByIndex: [Index: Element],
        policy: Policy
    ) {

        self.indicesByKey = indicesByKey
        self.elementsByIndex = elementsByIndex
        self.policy = policy
    }

    internal func cachedValue(
        forKey key: Key,
        payload: Payload,
        didMiss: UnsafeMutablePointer<Bool>? = nil,
        by closure: () throws -> Value
    ) rethrows -> Value {
        if let index = self.indicesByKey[key] {
            didMiss?.pointee = false
            return self.value(forIndex: index)
        }

        let value = try closure()

        self.setValue(
            value,
            forKey: key,
            payload: payload
        )

        didMiss?.pointee = true

        return value
    }

    internal func value(
        forKey key: Key
    ) -> Value? {
        guard let index = self.indicesByKey[key] else {
            return nil
        }

        return self.value(forIndex: index)
    }

    internal func peekValue(
        forKey key: Key
    ) -> Value? {
        guard let index = self.indicesByKey[key] else {
            return nil
        }

        guard let element = self.elementsByIndex[index] else {
            fatalError("Expected element, found nil")
        }

        return element.value
    }

    internal func setValue(
        _ value: Value?,
        forKey key: Key,
        payload: Payload
    ) {
        guard let value = value else {
            self.removeValue(forKey: key)
            return
        }

        self.updateValue(value, forKey: key, payload: payload)
    }

    @discardableResult
    internal func updateValue(
        _ value: Value,
        forKey key: Key,
        payload: Payload
    ) -> Value? {
        if let index = self.indicesByKey[key] {
            return self.replaceValue(
                value,
                forKey: key,
                index: index,
                payload: payload
            )
        } else {
            self.insertValue(
                value,
                forKey: key,
                payload: payload
            )
            return nil
        }
    }

    @discardableResult
    internal func removeValue(
        forKey key: Key
    ) -> Value? {
        guard let index = self.indicesByKey[key] else {
            return nil
        }

        let _ = self.policy.remove(index)

        let element = self.removeValue(forIndex: index)

        return element.value
    }

    @discardableResult
    internal func remove() -> Element? {
        guard !self.isEmpty else {
            return nil
        }

        guard let (index, _) = self.policy.remove() else {
            fatalError("Expected index, found nil")
        }

        let removed = self.removeValue(forIndex: index)
        return removed
    }

    internal func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    internal func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.indicesByKey.removeAll(keepingCapacity: keepCapacity)
        self.elementsByIndex.removeAll(keepingCapacity: keepCapacity)
        self.policy.removeAll(keepingCapacity: keepCapacity)
    }

    private func value(
        forIndex index: Index
    ) -> Value {
        guard let element = self.elementsByIndex[index] else {
            fatalError("Expected element, found nil")
        }

        self.policy.use(index)

        #if DEBUG
        assert(self.isValid() != false)
        #endif

        return element.value
    }

    private func insertValue(
        _ value: Value,
        forKey key: Key,
        payload: Payload
    ) {
        self.policy.evictIfNeeded(
            for: .alloc(payload: payload)
        ) { index in
            let _ = self.removeValue(
                forIndex: index,
                validate: false
            )
        }

        let index = self.policy.insert(payload: payload)

        self.indicesByKey[key] = index
        self.elementsByIndex[index] = (key: key, value: value)

        #if DEBUG
        assert(self.isValid() != false)
        #endif
    }

    private func replaceValue(
        _ value: Value,
        forKey key: Key,
        index: Index,
        payload: Payload
    ) -> Value? {
        let container = (key: key, value: value)

        self.policy.use(index)

        guard let oldValue = self.elementsByIndex.updateValue(
            container,
            forKey: index
        ) else {
            return nil
        }

        return oldValue.value
    }

    @discardableResult
    private func removeValue(
        forIndex index: Index,
        validate: Bool = true
    ) -> Element {
        guard let element = self.elementsByIndex.removeValue(
            forKey: index
        ) else {
            fatalError("Expected element, found nil")
        }

        let key = element.key

        guard let _ = self.indicesByKey.removeValue(
            forKey: key
        ) else {
            fatalError("Expected index, found nil")
        }

        #if DEBUG
        if validate {
            assert(self.isValid() != false)
        }
        #endif

        return element
    }

    #if DEBUG
    internal func isValid() -> Bool? {
        guard shouldValidate else {
            return nil
        }

        let uniqueCounts: Set<Int> = [
            self.indicesByKey.count,
            self.elementsByIndex.count,
//            self.policy.count,
        ]

        guard uniqueCounts.count == 1 else {
            return false
        }

        return true
    }
    #endif
}

extension CustomCacheStorage: Equatable
where
    Value: Equatable
{
    internal static func == (lhs: CustomCacheStorage, rhs: CustomCacheStorage) -> Bool {
        guard lhs.indicesByKey.count == rhs.indicesByKey.count else {
            return false
        }

        for (key, lhsIndex) in lhs.indicesByKey {
            guard let rhsIndex = rhs.indicesByKey[key] else {
                return false
            }

            let lhsElement = lhs.elementsByIndex[lhsIndex]!
            let rhsElement = rhs.elementsByIndex[rhsIndex]!

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

extension CustomCacheStorage: Hashable
where
    Value: Hashable
{
    internal func hash(into hasher: inout Hasher) {
        var commutativeHash = 0
        for index in self.indicesByKey.values {
            guard let (key, value) = self.elementsByIndex[index] else {
                continue
            }

            var elementHasher = hasher
            key.hash(into: &elementHasher)
            value.hash(into: &elementHasher)

            commutativeHash ^= elementHasher.finalize()
        }
        hasher.combine(commutativeHash)
    }
}

extension CustomCacheStorage: Sequence {
    internal typealias Iterator = AnyIterator<Element>

    internal func makeIterator() -> Iterator {
        let elements = self.elementsByIndex.values
        return .init(elements.makeIterator())
    }
}
