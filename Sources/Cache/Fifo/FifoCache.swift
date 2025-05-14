// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Cache using a first-in, first-out cache policy.
///
/// See `CustomFifoPolicy<…>` for more info.
public typealias FifoCache<Key, Value> = CustomFifoCache<Key, Value, UInt64>
where
    Key: Hashable

/// Cache using a first-in, first-out cache policy.
///
/// See `CustomFifoPolicy<…>` for more info.
public typealias CustomFifoCache<Key, Value, RawIndex> = CustomCache<Key, Value, CustomFifoPolicy<RawIndex>>
where
    Key: Hashable,
    RawIndex: FixedWidthInteger & UnsignedInteger
