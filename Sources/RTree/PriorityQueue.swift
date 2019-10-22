//
//  PriorityQueue.swift
//  Swift-PriorityQueue
//
//  Created by Bouke Haarsma on 12-02-15.
//  Copyright (c) 2015 Bouke Haarsma. All rights reserved.
//

import Foundation

public class PriorityQueue<T> {

    private final var _heap: [T]
    private let compare: (T, T) -> Bool

    public init(_ compare: @escaping (T, T) -> Bool) {
        _heap = []
        self.compare = compare
    }

    public func push(newElement: T) {
        _heap.append(newElement)
        siftUp(index: _heap.endIndex - 1)
    }

    public func pop() -> T? {
        if _heap.count == 0 {
            return nil
        }
        if _heap.count == 1 {
            return _heap.removeLast()
        }
        _heap.swapAt(0, _heap.endIndex - 1)
        let pop = _heap.removeLast()
        siftDown(index: 0)
        return pop
    }

    @discardableResult
    private func siftDown(index: Int) -> Bool {
        let left = index * 2 + 1
        let right = index * 2 + 2
        var smallest = index

        if left < _heap.count && compare(_heap[left], _heap[smallest]) {
            smallest = left
        }
        if right < _heap.count && compare(_heap[right], _heap[smallest]) {
            smallest = right
        }
        if smallest != index {
            _heap.swapAt(index, smallest)
            siftDown(index: smallest)
            return true
        }
        return false
    }

    @discardableResult
    private func siftUp(index: Int) -> Bool {
        if index == 0 {
            return false
        }
        let parent = (index - 1) >> 1
        if compare(_heap[index], _heap[parent]) {
            _heap.swapAt(index, parent)
            siftUp(index: parent)
            return true
        }
        return false
    }
}

extension PriorityQueue {
    public var count: Int {
        return _heap.count
    }

    public var isEmpty: Bool {
        return _heap.isEmpty
    }

    public func update<T2: Equatable>(element: T2) -> T? {
        assert(element is T)  // How to enforce this with type constraints?
        for (index, item) in _heap.enumerated() {
            if (item as! T2) == element {
                _heap[index] = element as! T
                if siftDown(index: index) || siftUp(index: index) {
                    return item
                }
            }
        }
        return nil
    }

    public func remove<T2: Equatable>(element: T2) -> T? {
        assert(element is T)  // How to enforce this with type constraints?
        for (index, item) in _heap.enumerated() {
            if (item as! T2) == element {
                _heap.swapAt(index, _heap.endIndex - 1)
                _heap.removeLast()
                siftDown(index: index)
                return item
            }
        }
        return nil
    }

    public var heap: [T] {
        return _heap
    }

    public func removeAll() {
        _heap.removeAll()
    }
}

extension PriorityQueue: IteratorProtocol {
    public typealias Element = T
    public func next() -> Element? {
        return pop()
    }
}

extension PriorityQueue: Sequence {
    public typealias Generator = PriorityQueue
    public func generate() -> Generator {
        return self
    }
}
