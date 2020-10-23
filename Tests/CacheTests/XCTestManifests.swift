import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LruCacheTests.allTests),
        testCase(LruPolicyTests.allTests),
    ]
}
#endif
