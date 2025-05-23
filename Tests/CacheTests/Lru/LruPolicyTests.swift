import XCTest

@testable import Cache

final class LruPolicyTests: XCTestCase {
    typealias Policy = CustomLruPolicy<UInt>
    typealias Index = Policy.Index

    func testInit() throws {
        let policy = Policy()

        XCTAssertNil(policy.deque.head)
        XCTAssertNil(policy.deque.tail)
        XCTAssertEqual(policy.deque.nodes, [])
        XCTAssertNil(policy.deque.firstFree)
    }

    func testHasCapacity() throws {
        let policy = Policy()

        XCTAssertTrue(policy.hasCapacity(forMetadata: nil))
        XCTAssertTrue(policy.hasCapacity(forMetadata: .default))
    }

    func testStateOf() throws {
        var policy = Policy()

        let index = policy.insert(metadata: .default)

        XCTAssertEqual(policy.state(of: index), .alive)
    }

    func testInsert() throws {
        var policy = Policy()

        let head = policy.insert(metadata: .default)

        XCTAssertFalse(policy.isEmpty)
        XCTAssertEqual(policy.count, 1)

        XCTAssertEqual(policy.deque.head, head.rawValue)
        XCTAssertEqual(policy.deque.tail, head.rawValue)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: nil,
                next: nil
            )),
        ])
        XCTAssertNil(policy.deque.firstFree)

        let newHead = policy.insert(metadata: .default)

        XCTAssertFalse(policy.isEmpty)
        XCTAssertEqual(policy.count, 2)

        XCTAssertEqual(policy.deque.head, newHead.rawValue)
        XCTAssertEqual(policy.deque.tail, head.rawValue)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: 1,
                next: nil
            )),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 0
            )),
        ])
        XCTAssertNil(policy.deque.firstFree)
    }

    func testUse() throws {
        var policy = Policy()

        for _ in 0..<5 {
            let _ = policy.insert(metadata: .default)
        }

        XCTAssertEqual(policy.deque.head, 4)
        XCTAssertEqual(policy.deque.tail, 0)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: 1,
                next: nil
            )),
            .occupied(.init(
                element: .default,
                previous: 2,
                next: 0
            )),
            .occupied(.init(
                element: .default,
                previous: 3,
                next: 1
            )),
            .occupied(.init(
                element: .default,
                previous: 4,
                next: 2
            )),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 3
            )),
        ])
        XCTAssertEqual(policy.deque.firstFree, nil)

        let index: Index = .init(2)
        let newIndex = policy.use(index, metadata: .default)

        XCTAssertEqual(index, newIndex)

        XCTAssertEqual(policy.deque.head, 2)
        XCTAssertEqual(policy.deque.tail, 0)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: 1,
                next: nil
            )),
            .occupied(.init(
                element: .default,
                previous: 3,
                next: 0
            )),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 4
            )),
            .occupied(.init(
                element: .default,
                previous: 4,
                next: 1
            )),
            .occupied(.init(
                element: .default,
                previous: 2,
                next: 3
            )),
        ])
        XCTAssertEqual(policy.deque.firstFree, nil)
    }

    func testRemove() throws {
        var policy = Policy()

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index, .init(0))
    }

    func testRemoveIndex() throws {
        var policy = Policy()

        for _ in 0..<5 {
            let _ = policy.insert(metadata: .default)
        }

        XCTAssertEqual(policy.deque.head, 4)
        XCTAssertEqual(policy.deque.tail, 0)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: 1,
                next: nil
            )),
            .occupied(.init(
                element: .default,
                previous: 2,
                next: 0
            )),
            .occupied(.init(
                element: .default,
                previous: 3,
                next: 1
            )),
            .occupied(.init(
                element: .default,
                previous: 4,
                next: 2
            )),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 3
            )),
        ])
        XCTAssertEqual(policy.deque.firstFree, nil)

        // Remove head:
        let _ = policy.remove(.init(4))

        XCTAssertEqual(policy.deque.head, 3)
        XCTAssertEqual(policy.deque.tail, 0)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: 1,
                next: nil
            )),
            .occupied(.init(
                element: .default,
                previous: 2,
                next: 0
            )),
            .occupied(.init(
                element: .default,
                previous: 3,
                next: 1
            )),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 2
            )),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(policy.deque.firstFree, 4)

        // Remove middle:
        let _ = policy.remove(.init(2))

        XCTAssertEqual(policy.deque.head, 3)
        XCTAssertEqual(policy.deque.tail, 0)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: 1,
                next: nil
            )),
            .occupied(.init(
                element: .default,
                previous: 3,
                next: 0
            )),
            .free(.init(nextFree: 4)),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 1
            )),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(policy.deque.firstFree, 2)

        // Remove tail:
        let _ = policy.remove(.init(0))

        XCTAssertEqual(policy.deque.head, 3)
        XCTAssertEqual(policy.deque.tail, 1)
        XCTAssertEqual(policy.deque.nodes, [
            .free(.init(nextFree: 2)),
            .occupied(.init(
                element: .default,
                previous: 3,
                next: nil
            )),
            .free(.init(nextFree: 4)),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 1
            )),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(policy.deque.firstFree, 0)
    }

    func testRemoveExpired() throws {
        var policy = Policy()

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

        policy.removeExpired { index in
            XCTFail("Indices should not expire")
        }

        XCTAssertEqual(policy.count, 3)
    }

    func testRemoveAll() throws {
        var policy = Policy()

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

        XCTAssertEqual(policy.deque.head, 2)
        XCTAssertEqual(policy.deque.tail, 0)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: 1,
                next: nil
            )),
            .occupied(.init(
                element: .default,
                previous: 2,
                next: 0
            )),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 1
            )),
        ])
        XCTAssertEqual(policy.deque.firstFree, nil)

        policy.removeAll()

        XCTAssertEqual(policy.deque.head, nil)
        XCTAssertEqual(policy.deque.tail, nil)
        XCTAssertEqual(policy.deque.nodes, [])
        XCTAssertEqual(policy.deque.firstFree, nil)

        XCTAssertEqual(policy.deque.nodes.capacity, 0)
    }

    func testRemoveAllKeepingCapacity() throws {
        var policy = Policy()

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

        XCTAssertEqual(policy.deque.head, 2)
        XCTAssertEqual(policy.deque.tail, 0)
        XCTAssertEqual(policy.deque.nodes, [
            .occupied(.init(
                element: .default,
                previous: 1,
                next: nil
            )),
            .occupied(.init(
                element: .default,
                previous: 2,
                next: 0
            )),
            .occupied(.init(
                element: .default,
                previous: nil,
                next: 1
            )),
        ])
        XCTAssertEqual(policy.deque.firstFree, nil)

        let capacity = policy.deque.nodes.capacity

        policy.removeAll(keepingCapacity: true)

        XCTAssertEqual(policy.deque.head, nil)
        XCTAssertEqual(policy.deque.tail, nil)
        XCTAssertEqual(policy.deque.nodes, [])
        XCTAssertEqual(policy.deque.firstFree, nil)

        XCTAssertEqual(policy.deque.nodes.capacity, capacity)
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
