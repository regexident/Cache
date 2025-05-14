// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Cache using a random replacement cache policy.
///
/// See `CustomRrPolicy<…>` for more info.
public typealias RrCache<Key, Value> = CustomRrCache<Key, Value, UInt64, SystemRandomNumberGenerator>
where
    Key: Hashable

/// Cache using a customized random replacement cache policy.
///
/// See `CustomRrPolicy<…>` for more info.
public typealias CustomRrCache<Key, Value, Bits, Generator> = CustomCache<Key, Value, CustomRrPolicy<Bits, Generator>>
where
    Key: Hashable,
    Bits: FixedWidthInteger & UnsignedInteger,
    Generator: RandomNumberGenerator
