import Cache
import PseudoRandom

extension SplitMix64: InitializableRandomNumberGenerator {
    public init() {
        self.init(seed: 0)
    }
}
