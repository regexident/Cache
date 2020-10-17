import XCTest

@testable import Cache

final class LRUQueueTests: XCTestCase {
    typealias Queue = LRUQueue
    typealias Node = Queue.Node

    func testInit() throws {
        let queue = Queue()

        XCTAssertNil(queue.head)
        XCTAssertNil(queue.tail)
    }

    func testEnqueue() throws {
        let queue = Queue()

        let head = queue.enqueue()

        XCTAssertEqual(queue.head, head)
        XCTAssertEqual(queue.tail, head)

        let newHead = queue.enqueue()

        XCTAssertEqual(queue.head, newHead)
        XCTAssertEqual(queue.tail, head)
        XCTAssertEqual(head.previous, newHead)
        XCTAssertEqual(newHead.next, head)
    }

    func testEnqueueNode() throws {
        let queue = Queue()

        let head = Node()
        queue.enqueue(head)

        XCTAssertEqual(queue.head, head)
        XCTAssertEqual(queue.tail, head)

        XCTAssertNil(head.previous)
        XCTAssertNil(head.next)

        let newHead = Node()
        queue.enqueue(newHead)

        XCTAssertNil(newHead.previous)
        XCTAssertEqual(newHead.next, head)

        XCTAssertEqual(queue.head, newHead)
        XCTAssertEqual(queue.tail, head)
        XCTAssertEqual(head.previous, newHead)
        XCTAssertEqual(newHead.next, head)
    }

    func testDequeueNode() throws {
        let queue = Queue()

        let tail = queue.enqueue()
        let _ = queue.enqueue()
        let mid = queue.enqueue()
        let _ = queue.enqueue()
        let head = queue.enqueue()

        queue.dequeue(tail)

        XCTAssertNil(queue.tail?.next)

        XCTAssertNil(tail.previous)
        XCTAssertNil(tail.next)

        queue.dequeue(head)

        XCTAssertNil(queue.head?.previous)

        XCTAssertNil(head.previous)
        XCTAssertNil(head.next)

        queue.dequeue(mid)

        XCTAssertEqual(queue.head?.next, queue.tail)
        XCTAssertEqual(queue.tail?.previous, queue.head)

        XCTAssertNil(mid.previous)
        XCTAssertNil(mid.next)
    }

//    func testRemoveFirst() throws {
//        let queue = Queue([0, 1, 2])
//
//        queue.removeFirst()
//        XCTAssertEqual(Array(queue), [1, 2])
//
//        queue.removeFirst()
//        XCTAssertEqual(Array(queue), [2])
//
//        queue.removeFirst()
//        XCTAssertEqual(Array(queue), [])
//    }
//
//    func testRemoveLast() throws {
//        let queue = Queue([0, 1, 2])
//
//        queue.removeLast()
//        XCTAssertEqual(Array(queue), [0, 1])
//
//        queue.removeLast()
//        XCTAssertEqual(Array(queue), [0])
//
//        queue.removeLast()
//        XCTAssertEqual(Array(queue), [])
//    }
//
//    func testRemoveAt() throws {
//        let queue = Queue([0, 1, 2, 3, 4])
//
//        let indexOrNil = queue.firstIndex(of: 2)
//        let index = try XCTUnwrap(indexOrNil)
//        queue.remove(at: index)
//
//        XCTAssertEqual(Array(queue), [0, 1, 3, 4])
//    }
//
//    func testRemoveAllWhere() throws {
//        let queue = Queue([0, 1, 2, 3, 4])
//
//        // Remove none:
//        queue.removeAll { _ in false }
//        XCTAssertEqual(Array(queue), [0, 1, 2, 3, 4])
//
//        // Remove prefix (i.e. head):
//        queue.removeAll { $0 == 0 }
//        XCTAssertEqual(Array(queue), [1, 2, 3, 4])
//
//        // Remove suffix (i.e. tail):
//        queue.removeAll { $0 == 4 }
//        XCTAssertEqual(Array(queue), [1, 2, 3])
//
//        // Remove infix:
//        queue.removeAll { $0 == 2 }
//        XCTAssertEqual(Array(queue), [1, 3])
//
//        // Remove all:
//        queue.removeAll { _ in true }
//        XCTAssertEqual(Array(queue), [])
//    }
//
//    func testRemoveAll() throws {
//        let queue = Queue([0, 1, 2, 3, 4])
//
//        queue.removeAll()
//        XCTAssertEqual(Array(queue), [])
//    }
//
//    func testDoesNotLeak() throws {
//        class Dummy {
//            let closure: () -> ()
//
//            init(closure: @escaping () -> ()) {
//                self.closure = closure
//            }
//
//            deinit {
//                self.closure()
//            }
//        }
//
//        let expectation = self.expectation(
//            description: "Expected element to be deinit'ed"
//        )
//
//        let closure = {
//            expectation.fulfill()
//        }
//
//        var queue: DoublyLinkedQueue! = [
//            Dummy(closure: closure),
//            Dummy(closure: closure),
//            Dummy(closure: closure),
//            Dummy(closure: closure),
//            Dummy(closure: closure),
//        ]
//
//        expectation.expectedFulfillmentCount = queue.count
//
//        queue = nil
//
//        self.waitForExpectations(timeout: 0.0)
//    }

    static var allTests = [
        ("testInit", testInit),
//        ("testInitElements", testInitElements),
//        ("testFirst", testFirst),
//        ("testLast", testLast),
//        ("testIsEmpty", testIsEmpty),
//        ("testCount", testCount),
//        ("testPrepend", testPrepend),
//        ("testAppend", testAppend),
//        ("testFirstIndexOf", testFirstIndexOf),
//        ("testFirstIndexWhere", testFirstIndexWhere),
//        ("testRemoveFirst", testRemoveFirst),
//        ("testRemoveLast", testRemoveLast),
//        ("testRemoveAt", testRemoveAt),
//        ("testRemoveAllWhere", testRemoveAllWhere),
//        ("testRemoveAll", testRemoveAll),
//        ("testDoesNotLeak", testDoesNotLeak),
    ]
}
