# Cache

Useful caching data structures in Swift.

## `FifoCache<Key: Hashable, Value>`

Cache using a **first-in, first-out** cache policy.

A simple cache eviction strategy where the oldest cache entry
(i.e., the one added earliest) is evicted when the cache is full.

This policy operates on the assumption that the order of insertion
reflects relevance over time, making it straightforward and predictable,
though it may not always align with actual access patterns.

```swift
public typealias FifoCache<Key: Hashable, Value> = CustomCache<Key, Value, CustomFifoPolicy<UInt64>>
```

## `LruCache<Key: Hashable, Value>`

Cache using a **least recently used** cache policy.

A simple cache eviction strategy
where the least recently accessed cache entry is evicted when the cache is full.

This policy assumes that data accessed in the past is less likely to be needed in the near future.

```swift
public typealias LruCache<Key: Hashable, Value> = CustomCache<Key, Value, CustomLruPolicy<UInt64>>
```

## `RrCache<Key: Hashable, Value>`

A cache using a **random replacement** cache policy.

A simple cache eviction strategy
where a random cache entry is evicted when the cache is full.

This method is particularly useful in scenarios where access patterns are unpredictable,
as it offers equal opportunities for all entries to remain in the cache.

It's a lightweight approach with minimal computational overhead, making it suitable for environments where resource optimization is crucial.

```swift
public typealias RrCache<Key: Hashable, Value> = CustomRrCache<Key, Value, UInt64, SystemRandomNumberGenerator>
```

## License

This project is licensed under the [**MPL-2.0**](https://www.tldrlegal.com/l/mpl-2.0) – see the [LICENSE.md](LICENSE.md) file for details.
