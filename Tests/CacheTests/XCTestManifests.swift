import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LruCacheTests.allTests),
        testCase(LruPolicyTests.allTests),
        testCase(RrCacheTests.allTests),
        testCase(RrPolicyTests.allTests),
    ]
}
#endif
