import XCTest

@testable import Cache

final class LRUPolicyTests: XCTestCase {
    typealias Policy = LRUPolicy
    typealias Token = Policy.Token
    typealias Index = Policy.Index

    func policy(
        count: Int = 0
    ) -> Policy {
        var policy = Policy()

        for _ in 0..<count {
            let _ = policy.insert()
        }

        return policy
    }

    func testToken() throws {
        let index: Index = 42
        let token = Token(index: index)

        XCTAssertEqual(token.index, index)
    }

    func testInit() throws {
        let policy = self.policy()

        XCTAssertNil(policy.head)
        XCTAssertNil(policy.tail)
        XCTAssertEqual(policy.nodes, [])
        XCTAssertNil(policy.firstFree)
    }

    func testInsert() throws {
        var policy = self.policy()

        let head = policy.insert()

        XCTAssertEqual(policy.head, head.index)
        XCTAssertEqual(policy.tail, head.index)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: nil, next: nil)),
        ])
        XCTAssertNil(policy.firstFree)

        let newHead = policy.insert()

        XCTAssertEqual(policy.head, newHead.index)
        XCTAssertEqual(policy.tail, head.index)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: nil, next: 0)),
        ])
        XCTAssertNil(policy.firstFree)
    }

    func testUse() throws {
        var policy = self.policy(count: 5)

        XCTAssertEqual(policy.head, 4)
        XCTAssertEqual(policy.tail, 0)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: 3, next: 1)),
            .occupied(.init(previous: 4, next: 2)),
            .occupied(.init(previous: nil, next: 3)),
        ])
        XCTAssertEqual(policy.firstFree, nil)

        let tokenBefore = Token(index: 2)
        let tokenAfter = policy.use(tokenBefore)

        XCTAssertEqual(tokenAfter, tokenBefore)

        XCTAssertEqual(policy.head, 2)
        XCTAssertEqual(policy.tail, 0)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 3, next: 0)),
            .occupied(.init(previous: nil, next: 4)),
            .occupied(.init(previous: 4, next: 1)),
            .occupied(.init(previous: 2, next: 3)),
        ])
        XCTAssertEqual(policy.firstFree, nil)
    }

    func testNext() throws {
        var policy = self.policy(count: 3)

        let token = try XCTUnwrap(policy.next())

        XCTAssertEqual(token.index, policy.tail)
    }

    func testRemove() throws {
        var policy = self.policy(count: 5)

        XCTAssertEqual(policy.head, 4)
        XCTAssertEqual(policy.tail, 0)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: 3, next: 1)),
            .occupied(.init(previous: 4, next: 2)),
            .occupied(.init(previous: nil, next: 3)),
        ])
        XCTAssertEqual(policy.firstFree, nil)

        // depolicy head:
        policy.remove(.init(index: 4))

        XCTAssertEqual(policy.head, 3)
        XCTAssertEqual(policy.tail, 0)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: 3, next: 1)),
            .occupied(.init(previous: nil, next: 2)),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(policy.firstFree, 4)

        // depolicy middle:
        policy.remove(.init(index: 2))

        XCTAssertEqual(policy.head, 3)
        XCTAssertEqual(policy.tail, 0)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 3, next: 0)),
            .free(.init(nextFree: 4)),
            .occupied(.init(previous: nil, next: 1)),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(policy.firstFree, 2)

        // depolicy tail:
        policy.remove(.init(index: 0))

        XCTAssertEqual(policy.head, 3)
        XCTAssertEqual(policy.tail, 1)
        XCTAssertEqual(policy.nodes, [
            .free(.init(nextFree: 2)),
            .occupied(.init(previous: 3, next: nil)),
            .free(.init(nextFree: 4)),
            .occupied(.init(previous: nil, next: 1)),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(policy.firstFree, 0)
    }

    func testRemoveAll() throws {
        var policy = self.policy(count: 3)

        XCTAssertEqual(policy.head, 2)
        XCTAssertEqual(policy.tail, 0)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: nil, next: 1)),
        ])
        XCTAssertEqual(policy.firstFree, nil)

        policy.removeAll()

        XCTAssertEqual(policy.head, nil)
        XCTAssertEqual(policy.tail, nil)
        XCTAssertEqual(policy.nodes, [])
        XCTAssertEqual(policy.firstFree, nil)

        XCTAssertEqual(policy.nodes.capacity, 0)
    }

    func testRemoveAllKeepingCapacity() throws {
        var policy = self.policy(count: 3)

        XCTAssertEqual(policy.head, 2)
        XCTAssertEqual(policy.tail, 0)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: nil, next: 1)),
        ])
        XCTAssertEqual(policy.firstFree, nil)

        let capacity = policy.nodes.capacity

        policy.removeAll(keepingCapacity: true)

        XCTAssertEqual(policy.head, nil)
        XCTAssertEqual(policy.tail, nil)
        XCTAssertEqual(policy.nodes, [])
        XCTAssertEqual(policy.firstFree, nil)

        XCTAssertEqual(policy.nodes.capacity, capacity)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInsert", testInsert),
        ("testUse", testUse),
        ("testNext", testNext),
        ("testRemove", testRemove),
        ("testRemoveAll", testRemoveAll),
        ("testRemoveAllKeepingCapacity", testRemoveAllKeepingCapacity),
    ]
}
