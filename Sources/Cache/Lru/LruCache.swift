// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Cache using a least recently used cache policy.
///
/// See `CustomLruPolicy<…>` for more info.
public typealias LruCache<Key, Value> = CustomLruCache<Key, Value, UInt64>
where
    Key: Hashable

/// Cache using a least recently used cache policy.
///
/// See `CustomLruPolicy<…>` for more info.
public typealias CustomLruCache<Key, Value, RawIndex> = CustomCache<Key, Value, CustomLruPolicy<RawIndex>>
where
    Key: Hashable,
    RawIndex: FixedWidthInteger & UnsignedInteger
