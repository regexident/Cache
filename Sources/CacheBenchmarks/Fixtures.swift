import Foundation

import ArgumentParser

import Foundation

import Cache

typealias Key = Int
typealias Value = Int
typealias Cost = Int

internal enum KeyOrder: String, ExpressibleByArgument, CustomStringConvertible {
    case sequential
    case semiSequential
    case randomUniform
    case randomNormal

    var description: String {
        switch self {
        case .sequential: return "sequential"
        case .semiSequential: return "semiSequential"
        case .randomUniform: return "randomUniform"
        case .randomNormal: return "randomNormal"
        }
    }
}

internal enum CachePolicyKind: String, ExpressibleByArgument, CustomStringConvertible {
    case lru
    case rr
    case clock

    var description: String {
        switch self {
        case .lru: return "LRU"
        case .rr: return "RR"
        case .clock: return "CLOCK"
        }
    }
}

func makePrng(seed: Int = 0) -> SplitMix64 {
    .init(state: .init(seed))
}

func makeKeys(count: Int) -> Range<Int> {
    0..<count
}

func makeSequentialKeys(
    keyCount: Int,
    accessCount: Int
) -> [Int] {
    let keys = makeKeys(count: keyCount)
    return (0..<accessCount).map { i in
        let index = i % keyCount
        return keys[index]
    }
}

func makeSemiSequentialKeys(
    keyCount: Int,
    accessCount: Int
) -> [Int] {
    let keys = makeKeys(count: keyCount)
    var prng = makePrng()
    return (0..<accessCount).map { i in
        let index: Int
        if Bool.random(using: &prng) {
            index = Int.random(in: 0..<keyCount, using: &prng)
        } else {
            index = i % keyCount
        }
        return keys[index]
    }
}

func makeUniformRandomizedKeys(
    keyCount: Int,
    accessCount: Int
) -> [Int] {
    let keys = makeKeys(count: keyCount)
    var prng = makePrng()
    return (0..<accessCount).map { _ in
        let index = Int.random(in: 0..<keyCount, using: &prng)
        return keys[index]
    }
}

func makeNormalRandomizedKeys(
    keyCount: Int,
    accessCount: Int
) -> [Int] {
    let keys = makeKeys(count: keyCount)
    var prng = makePrng()
    return (0..<accessCount).map { _ in
        let sampleCount: Int = 3
        let index = (0..<sampleCount).map { _ in
            Int.random(in: 0..<keyCount, using: &prng)
        }.reduce(0, +) / sampleCount
        return keys[index]
    }
}

func makeKeysFor(
    keys: Int,
    accesses: Int,
    ordered order: KeyOrder
) -> [Int] {
    switch order {
    case .sequential:
        return makeSequentialKeys(
            keyCount: keys,
            accessCount: accesses
        )
    case .semiSequential:
        return makeSemiSequentialKeys(
            keyCount: keys,
            accessCount: accesses
        )
    case .randomUniform:
        return makeUniformRandomizedKeys(
            keyCount: keys,
            accessCount: accesses
        )
    case .randomNormal:
        return makeNormalRandomizedKeys(
            keyCount: keys,
            accessCount: accesses
        )
    }
}

@discardableResult
func runWith<P>(policy: P.Type, capacity: Int, keys: [Key]) -> Int
where
    P: CachePolicy
{
    return cacheMissesUsing(
        policy: P.self,
        capacity: capacity,
        keys: keys
    )
}

func measureTime(
    of closure: () throws -> ()
) rethrows -> Double {
    let start = Date()
    try closure()
    let end = Date()
    return end.timeIntervalSince(start)
}

@discardableResult
func cacheMissesUsing<P>(
    policy: P.Type,
    capacity: Int,
    keys: [Key]
) -> Int
where
    P: CachePolicy
{
    typealias Cache = CustomCache<Key, Value, Cost, P>

    var cache = Cache(totalCostLimit: capacity)

    var misses: Int = 0

    for key in keys {
        var didMiss: Bool = false
        let _ = cache.cachedValue(forKey: key, didMiss: &didMiss) {
            key
        }

        if didMiss {
            misses += 1
        }
    }

    return misses
}

func frequencies(keys: [Int]) -> [(key: Int, frequency: Int)] {
    var keyFrequencies: [Int: Int] = [:]

    for key in keys {
        keyFrequencies[key, default: 0] += 1
    }

    let sortedKeyFrequencies = keyFrequencies.sorted { lhs, rhs in
        lhs.value > rhs.value
    }.map {
        key, frequency in (key: key, frequency: frequency)
    }

    return sortedKeyFrequencies
}
