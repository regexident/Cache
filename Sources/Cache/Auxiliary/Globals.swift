import Logging

public var logger = Logger(label: "Cache")

#if DEBUG
internal var shouldValidate: Bool = false
#endif
