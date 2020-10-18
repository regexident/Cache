import XCTest

@testable import Cache

extension LRUQueue {
    fileprivate var headNode: LRUQueue.Node? {
        guard let index = self.head else {
            return nil
        }
        return self.nodes[index]
    }

    fileprivate var tailNode: LRUQueue.Node? {
        guard let index = self.tail else {
            return nil
        }
        return self.node(at: index)
    }

    fileprivate func node(at index: LRUQueue.Index) -> LRUQueue.Node {
        return self.nodes[index]
    }
}

final class LRUQueueTests: XCTestCase {
    typealias Queue = LRUQueue
    typealias Index = Queue.Index

    func queue(
        count: Int = 0
    ) -> Queue {
        var queue = Queue()

        for _ in 0..<count {
            let _ = queue.enqueue()
        }

        return queue
    }

    func testInit() throws {
        let queue = self.queue()

        XCTAssertNil(queue.head)
        XCTAssertNil(queue.tail)
        XCTAssertEqual(queue.nodes, [])
        XCTAssertNil(queue.free)
    }

    func testEnqueue() throws {
        var queue = self.queue()

        let head = queue.enqueue()

        XCTAssertEqual(queue.head, head)
        XCTAssertEqual(queue.tail, head)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: nil, next: nil)),
        ])
        XCTAssertNil(queue.free)

        let newHead = queue.enqueue()

        XCTAssertEqual(queue.head, newHead)
        XCTAssertEqual(queue.tail, head)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: nil, next: 0)),
        ])
        XCTAssertNil(queue.free)
    }

    func testNext() throws {
        var queue = self.queue(count: 3)

        let index = queue.next()
        XCTAssertEqual(index, queue.tail)
    }

    func testDequeue() throws {
        var queue = self.queue(count: 5)

        XCTAssertEqual(queue.head, 4)
        XCTAssertEqual(queue.tail, 0)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: 3, next: 1)),
            .occupied(.init(previous: 4, next: 2)),
            .occupied(.init(previous: nil, next: 3)),
        ])
        XCTAssertEqual(queue.free, nil)

        // dequeue head:
        queue.dequeue(4)

        XCTAssertEqual(queue.head, 3)
        XCTAssertEqual(queue.tail, 0)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: 3, next: 1)),
            .occupied(.init(previous: nil, next: 2)),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(queue.free, 4)

        // dequeue middle:
        queue.dequeue(2)

        XCTAssertEqual(queue.head, 3)
        XCTAssertEqual(queue.tail, 0)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 3, next: 0)),
            .free(.init(nextFree: 4)),
            .occupied(.init(previous: nil, next: 1)),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(queue.free, 2)

        // dequeue tail:
        queue.dequeue(0)

        XCTAssertEqual(queue.head, 3)
        XCTAssertEqual(queue.tail, 1)
        XCTAssertEqual(queue.nodes, [
            .free(.init(nextFree: 2)),
            .occupied(.init(previous: 3, next: nil)),
            .free(.init(nextFree: 4)),
            .occupied(.init(previous: nil, next: 1)),
            .free(.init(nextFree: nil)),
        ])
        XCTAssertEqual(queue.free, 0)
    }

    func testDequeueAll() throws {
        var queue = self.queue(count: 3)

        XCTAssertEqual(queue.head, 2)
        XCTAssertEqual(queue.tail, 0)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: nil, next: 1)),
        ])
        XCTAssertEqual(queue.free, nil)

        queue.dequeueAll()

        XCTAssertEqual(queue.head, nil)
        XCTAssertEqual(queue.tail, nil)
        XCTAssertEqual(queue.nodes, [])
        XCTAssertEqual(queue.free, nil)

        XCTAssertEqual(queue.nodes.capacity, 0)
    }

    func testDequeueAllKeepingCapacity() throws {
        var queue = self.queue(count: 3)

        XCTAssertEqual(queue.head, 2)
        XCTAssertEqual(queue.tail, 0)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: nil, next: 1)),
        ])
        XCTAssertEqual(queue.free, nil)

        let capacity = queue.nodes.capacity

        queue.dequeueAll(keepingCapacity: true)

        XCTAssertEqual(queue.head, nil)
        XCTAssertEqual(queue.tail, nil)
        XCTAssertEqual(queue.nodes, [])
        XCTAssertEqual(queue.free, nil)

        XCTAssertEqual(queue.nodes.capacity, capacity)
    }

    func testRequeue() throws {
        var queue = self.queue(count: 5)

        XCTAssertEqual(queue.head, 4)
        XCTAssertEqual(queue.tail, 0)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 2, next: 0)),
            .occupied(.init(previous: 3, next: 1)),
            .occupied(.init(previous: 4, next: 2)),
            .occupied(.init(previous: nil, next: 3)),
        ])
        XCTAssertEqual(queue.free, nil)

        // dequeue head:
        queue.requeue(2)

        XCTAssertEqual(queue.head, 2)
        XCTAssertEqual(queue.tail, 0)
        XCTAssertEqual(queue.nodes, [
            .occupied(.init(previous: 1, next: nil)),
            .occupied(.init(previous: 3, next: 0)),
            .occupied(.init(previous: nil, next: 4)),
            .occupied(.init(previous: 4, next: 1)),
            .occupied(.init(previous: 2, next: 3)),
        ])
        XCTAssertEqual(queue.free, nil)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testEnqueue", testEnqueue),
        ("testNext", testNext),
        ("testDequeue", testDequeue),
        ("testDequeueAll", testDequeueAll),
        ("testDequeueAllKeepingCapacity", testDequeueAllKeepingCapacity),
        ("testRequeue", testRequeue),
    ]
}
