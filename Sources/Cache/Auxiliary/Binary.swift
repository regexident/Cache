import Foundation

extension String.StringInterpolation {
    /// Represents a single numeric radix
    internal enum Radix: Int {
        case binary = 2
        case octal = 8
        case decimal = 10
        case hex = 16

        private static let prefixesByRadix: [Self: String] = [
            .binary: "0b",
            .octal: "0o",
            .hex: "0x"
        ]

        fileprivate var prefix: String {
            Self.prefixesByRadix[self, default: ""]
        }
    }

    /// Return padded version of the value using a specified radix
    internal mutating func appendInterpolation<T>(
        _ value: T,
        radix: Radix,
        prefix: Bool = false,
        toWidth width: Int = 0
    )
    where
        T: BinaryInteger
    {
        var string = String(value, radix: radix.rawValue).uppercased()
        if string.count < width {
            string = String(repeating: "0", count: max(0, width - string.count)) + string
        }
        if prefix {
            string = radix.prefix + string
        }
        self.appendInterpolation(string)
    }
}
