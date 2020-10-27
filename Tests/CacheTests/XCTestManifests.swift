import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LruCacheTests.allTests),
        testCase(LruPolicyTests.allTests),
        testCase(RrCacheTests.allTests),
        testCase(RrPolicyTests.allTests),
        testCase(ClockCacheTests.allTests),
        testCase(ClockPolicyTests.allTests),
    ]
}
#endif
