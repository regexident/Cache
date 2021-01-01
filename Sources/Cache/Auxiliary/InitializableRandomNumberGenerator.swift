import Foundation

public protocol InitializableRandomNumberGenerator: RandomNumberGenerator {
    init()
}

extension SystemRandomNumberGenerator: InitializableRandomNumberGenerator {

}
