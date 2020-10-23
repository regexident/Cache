import XCTest

@testable import Cache

final class LruPolicyTests: XCTestCase {
    typealias Policy = CustomLruPolicy
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

        XCTAssertEqual(policy.head, head)
        XCTAssertEqual(policy.tail, head)
        XCTAssertEqual(policy.nodes, [
            .occupied(.init(previous: nil, next: nil)),
        ])
        XCTAssertNil(policy.firstFree)

        let newHead = policy.insert()

        XCTAssertEqual(policy.head, newHead)
        XCTAssertEqual(policy.tail, head)
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

        let index: Index = 2
        policy.use(index)

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

    func testRemove() throws {
        var policy = self.policy(count: 3)

        let index = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index, 0)
    }

    func testRemoveIndex() throws {
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
        policy.remove(4)

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
        policy.remove(2)

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
        policy.remove(0)

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
        ("testRemove", testRemove),
        ("testRemoveIndex", testRemoveIndex),
        ("testRemoveAll", testRemoveAll),
        ("testRemoveAllKeepingCapacity", testRemoveAllKeepingCapacity),
    ]
}
