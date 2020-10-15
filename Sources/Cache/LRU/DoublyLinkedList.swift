import Foundation

internal class DoublyLinkedListNode<Element> {
    internal var element: Element

    fileprivate var next: DoublyLinkedListNode?
    fileprivate weak var previous: DoublyLinkedListNode?

    fileprivate var isHead: Bool {
        self.previous == nil
    }

    fileprivate var isTail: Bool {
        self.next == nil
    }

    internal init(
        element: Element,
        next: DoublyLinkedListNode? = nil,
        previous: DoublyLinkedListNode? = nil
    ) {
        self.element = element
        self.next = next
        self.previous = previous
    }
}

extension DoublyLinkedListNode: Equatable
where
    Element: Equatable
{
    internal static func == (
        lhs: DoublyLinkedListNode,
        rhs: DoublyLinkedListNode
    ) -> Bool {
        lhs.element == rhs.element
    }
}

extension DoublyLinkedListNode: Hashable
where
    Element: Hashable
{
    internal func hash(into hasher: inout Hasher) {
        self.element.hash(into: &hasher)
    }
}

internal class DoublyLinkedList<Element>: ExpressibleByArrayLiteral {
    internal typealias Node = DoublyLinkedListNode<Element>

    private typealias NodeIterator = DoublyLinkedListNodeIterator<Element>

    internal private(set) var head: Node?
    internal private(set) var tail: Node?

    internal var first: Element? {
        guard let head = self.head else {
            return nil
        }

        return head.element
    }

    internal var last: Element? {
        guard let tail = self.tail else {
            return nil
        }

        return tail.element
    }

    /// Complexity: O(`1`).
    internal var isEmpty: Bool {
        (self.head == nil) && (self.tail == nil)
    }

    /// Complexity: O(`n`), where `n` is the length of the linked list.
    internal var count: Int {
        self.nodes.reduce(0) { count, _ in count + 1 }
    }

    private var nodes: IteratorSequence<NodeIterator> {
        .init(NodeIterator(self))
    }

    internal init() {
        self.head = nil
        self.tail = nil
    }

    internal required convenience init(arrayLiteral: Element...) {
        self.init(arrayLiteral)
    }

    internal convenience init<S>(_ elements: S)
    where
        S: Sequence,
        S.Element == Element
    {
        self.init()

        var iterator = elements.makeIterator()

        guard let firstElement = iterator.next() else {
            return
        }

        var currentNode = Node(element: firstElement)

        self.head = currentNode

        while let element = iterator.next() {
            let nextNode = Node(
                element: element,
                previous: currentNode
            )

            currentNode.next = nextNode
            currentNode = nextNode
        }

        self.tail = currentNode
    }

    internal func prepend(_ element: Element) {
        self.prepend(node: .init(element: element))
    }

    internal func append(_ element: Element) {
        self.append(node: .init(element: element))
    }

    internal func firstIndex(
        where predicate: (Element) throws -> Bool
    ) rethrows -> Node? {
        try self.nodes.first { node in
            try predicate(node.element)
        }
    }

    @discardableResult
    internal func removeFirst() -> Element {
        guard let head = self.head else {
            fatalError(
                "Can't remove first element from an empty list"
            )
        }

        return self.remove(node: head)
    }

    @discardableResult
    internal func removeLast() -> Element {
        guard let tail = self.tail else {
            fatalError(
                "Can't remove last element from an empty list"
            )
        }

        return self.remove(node: tail)
    }

    @discardableResult
    internal func remove(at node: Node) -> Element {
        self.remove(node: node)
    }

    internal func removeAll(
        where shouldBeRemoved: (Element) throws -> Bool
    ) rethrows {
        for node in self.nodes {
            guard try shouldBeRemoved(node.element) else {
                continue
            }
            self.remove(node: node)
        }
    }

    internal func removeAll() {
        self.head = nil
        self.tail = nil
    }

    internal func prepend(node: Node) {
        guard !self.isEmpty else {
            self.setFirst(node)

            return
        }

        let currentHead = self.head

        self.head?.previous = node
        self.head = node
        self.head?.next = currentHead
    }

    internal func append(node: Node) {
        guard !self.isEmpty else {
            self.setFirst(node)

            return
        }

        let currentTail = self.tail

        self.tail?.next = node
        self.tail = node
        self.tail?.previous = currentTail
    }

    @discardableResult
    internal func remove(node: Node) -> Element {
        if self.head === node {
            self.head = node.next
        }
        if self.tail === node {
            self.tail = node.previous
        }

        if let previousNode = node.previous {
            previousNode.next = node.next
        }
        if let nextNode = node.next {
            nextNode.previous = node.previous
        }
        node.next = nil
        node.previous = nil

        return node.element
    }

    private func setFirst(_ node: Node) {
        assert(self.isEmpty)

        self.head = node
        self.tail = node
    }
}

extension DoublyLinkedList
where
    Element: Equatable
{
    internal func firstIndex(of element: Element) -> Node? {
        self.firstIndex { $0 == element}
    }
}

extension DoublyLinkedList: Equatable
where
    Element: Equatable
{
    internal static func == (
        lhs: DoublyLinkedList<Element>,
        rhs: DoublyLinkedList<Element>
    ) -> Bool {
        zip(lhs.nodes, rhs.nodes).allSatisfy { lhs, rhs in
            // zip is short-curcuiting, so we need to check for tail
            // position to accomodate for lists of different length:
            guard lhs.isTail == rhs.isTail else {
                return false
            }
            guard lhs.element == rhs.element else {
                return false
            }
            return true
        }
    }
}

extension DoublyLinkedList: CustomStringConvertible {
    internal var description: String {
        var description = ""
        var current = self.head

        while current != nil {
            description += String(describing: current!.element)

            current = current?.next
        }
        return description
    }
}

extension DoublyLinkedList: Sequence {
    internal typealias Iterator = AnyIterator<Element>

    internal func makeIterator() -> Iterator {
        .init(DoublyLinkedListIterator(self))
    }
}

internal struct DoublyLinkedListIterator<Element>: IteratorProtocol {
    fileprivate typealias Base = DoublyLinkedListNodeIterator<Element>

    private var base: Base

    fileprivate init(_ linkedList: DoublyLinkedList<Element>) {
        self.init(Base(linkedList))
    }

    fileprivate init(_ base: Base) {
        self.base = base
    }

    internal mutating func next() -> Element? {
        guard let node = self.base.next() else {
            return nil
        }

        return node.element
    }
}

fileprivate struct DoublyLinkedListNodeIterator<Element>: IteratorProtocol {
    private var node: DoublyLinkedListNode<Element>?

    fileprivate init(_ linkedList: DoublyLinkedList<Element>) {
        self.node = linkedList.head
    }

    fileprivate mutating func next() -> DoublyLinkedListNode<Element>? {
        guard let node = self.node else {
            return nil
        }

        defer {
            self.node = node.next
        }

        return node
    }
}
