import Foundation

internal enum LruNode<RawIndex>: Equatable
where
    RawIndex: BinaryInteger
{
    internal struct Free: Equatable {
        var nextFree: RawIndex?
    }

    internal struct Occupied: Equatable {
        var previous: RawIndex?
        var next: RawIndex?
    }

    case free(Free)
    case occupied(Occupied)
}
