//
//  DirectoryNodeData.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

public struct DirectoryNodeData<T>
where
    T: SpatialObject
{
    var boundingBox: BoundingRectangle<T.Point>?
    var children = [RTreeNode<T>]()
    var depth: UInt
    var options: RTreeOptions
    
    public static func newParent(_ children: [RTreeNode<T>], depth: UInt, options: RTreeOptions) -> DirectoryNodeData<T> {
        var result = DirectoryNodeData(boundingBox: nil, children: children, depth: depth, options: options)
        result.updateMBR()
        
        return result
        
    }
    
    public mutating func updateMBR() {
        guard let first = self.children.first else {
            self.boundingBox = nil
            return
            
        }
        
        var newMBR: BoundingRectangle<T.Point> = first.minimumBoundingRectangle()
        
        for child in self.children[1...] {
            newMBR.add(child.minimumBoundingRectangle())
            
        }
        
        self.boundingBox = newMBR
        
    }
    
    mutating func updateMBRWithElement(_ elementBoundingBox: BoundingRectangle<T.Point>) {
        if let _ = self.boundingBox {
            self.boundingBox!.add(elementBoundingBox)
            
        } else {
            self.boundingBox = elementBoundingBox
            
        }
        
    }
    
    mutating func insert(_ t: RTreeNode<T>, state: inout InsertionState) -> InsertionResult<T>
    {
        
        let tMBR: BoundingRectangle<T.Point> = t.minimumBoundingRectangle()
        
        self.updateMBRWithElement(tMBR)
        
        if t.depth() + 1 == self.depth {
            var newChildren = [t]
            self.addChildren(&newChildren)
            return self.resolveOverflow(&state)
            
        }
        
        var follow = self.chooseSubtree(t)
        let expand = follow.insert(t, state: &state)
        
        switch expand {
        case .split(let child):
            var children = [child]
            self.addChildren(&children)
            return self.resolveOverflow(&state)
        case .reinsert:
            self.updateMBR()
            return expand
        case .complete:
            return .complete
        }
        
    }
    
    mutating func resolveOverflow(_ state: inout InsertionState) -> InsertionResult<T> {
        if self.children.count > self.options.maxSize {
            let offsplit = self.split()
            return .split(offsplit)
            
        }
        
    }
    
    mutating func split() -> RTreeNode<T> {
        let axis = self.getSplitAxis()
        
        assert(self.children.count > 1, "Cannot split tree with less than 2 children")
        
        self.children.sort { (l, r) -> Bool in
            l.minimumBoundingRectangle()
                .lower.nth(index: axis).value < r.minimumBoundingRectangle().lower.nth(index: axis).value
        }
        
        var best: (T.Point.Scalar, T.Point.Scalar) = (0, 0)
        var bestIndex = self.options.minSize
        
        for k in self.options.minSize...(UInt(self.children.count) - self.options.minSize) {
            var firstMBR = self.children[Int(k - 1)].minimumBoundingRectangle()
            var secondMBR = self.children[Int(k)].minimumBoundingRectangle()
            let l = self.children[...Int(k)]
            let r = self.children[Int(k + 1)...]
            
            for child in l {
                firstMBR.add(child.minimumBoundingRectangle())
            }
            
            for child in r {
                secondMBR.add(child.minimumBoundingRectangle())
            }
            
            let overlapValue = firstMBR.intersect(secondMBR).area()
            let areaValue = firstMBR.area() + secondMBR.area()
            let newBest = (overlapValue, areaValue)
            
            if newBest < best || k == self.options.minSize {
                best = newBest
                bestIndex = k
            }
            
        }
        
        let offsplit = self.children[Int(bestIndex)...]
        let result = RTreeNode.directoryNode(
            DirectoryNodeData.newParent(
                offsplit,
                depth: self.depth,
                options: self.options
            )
        )
        
        self.updateMBR()
        
        return result
        
    }
    
    mutating func reinsert() -> [RTreeNode<T>] {
        let center = self.boundingBox!.center()
        
        self.children.sort { (l, r) -> Bool in
            let lCenter = l.minimumBoundingRectangle().center()
            let rCenter = r.minimumBoundingRectangle().center()
            
        return lCenter.subtract(center).lengthSquared() < rCenter.subtract(center).lengthSquared()
            
        }
        
    }
    
    mutating func getSplitAxis() -> UInt {
        var bestGoodness: T.Point.Scalar = 0 // What
        var bestAxis = 0
        
        for axis in 0..<self.boundingBox!.lower.dimensions() {
            self.children.sort { (l, r) -> Bool in
                l.minimumBoundingRectangle().lower.nth(index: axis).value < r.minimumBoundingRectangle().lower.nth(index: axis).value
                
            }
            
            for k in (Int(self.options.minSize)...(self.children.count - Int(self.options.minSize))) {
                var firstMBR = self.children[k - 1].minimumBoundingRectangle()
                var secondMBR = self.children[k].minimumBoundingRectangle()
                
                let l = self.children[..<k]
                let r = self.children[k...]
                
                for child in l {
                    firstMBR.add(child.minimumBoundingRectangle())
                    
                }
                
                for child in r {
                    secondMBR.add(child.minimumBoundingRectangle())
                    
                }
                
                let marginValue = firstMBR.halfMargin() + secondMBR.halfMargin()
                
                if bestGoodness > marginValue || axis == 0 {
                    bestAxis = Int(axis)
                    bestGoodness = marginValue
                }
                
            }
            
        }
        
        return UInt(bestAxis)
        
    }
    
    mutating func chooseSubtree(_ node: RTreeNode<T>) -> DirectoryNodeData<T> {
        assert(self.depth > 1, "Cannot choose subtree when depth is 1")
        let insertionMBR = node.minimumBoundingRectangle()
        var inclusionCount = 0
        var minArea: T.Point.Scalar = 0
        var minIndex = 0
        var first = true
        
        for (index, child) in self.children.enumerated() {
            let MBR = child.minimumBoundingRectangle()
            
            if MBR.contains(rectangle: insertionMBR) {
                inclusionCount += 1
                let area = MBR.area()
                if area < minArea || first {
                    minArea = area
                    minIndex = index
                    first = false
                    
                }
                
            }
            
        }
        
        if inclusionCount == 0 {
            let allLeaves = self.depth < 1
            var min: (T.Point.Scalar, T.Point.Scalar, T.Point.Scalar) = (0, 0, 0)
            
            for (index, child1) in self.children.enumerated() {
                let MBR = child1.minimumBoundingRectangle()
                var newMBR = MBR
                
                newMBR.add(insertionMBR)
                
                var overlapIncrease: T.Point.Scalar = 0
                
                if allLeaves {
                    var overlap: T.Point.Scalar = 0
                    var newOverlap: T.Point.Scalar = 0
                    
                    for child2 in self.children {
                        if !(child1 == child2) {
                            let childMBR = child2.minimumBoundingRectangle()
                            overlap += MBR.intersect(childMBR).area()
                            newOverlap += newMBR.intersect(childMBR).area()
                        }
                        
                    }
                    
                    overlapIncrease = newOverlap - overlap
                    
                } else {
                    overlapIncrease = 0
                    
                }
                
                let area = newMBR.area()
                let areaIncrease = area + MBR.area()
                let newMin = (overlapIncrease, areaIncrease, area)
                
                if newMin < min || index == 0 {
                    min = newMin
                    minIndex = index
                    
                }
                
            }
            
        }
        
        switch self.children[minIndex] {
        case .directoryNode(let data):
            return data
        default:
            fatalError("No leaves at this depth")
        }
        
    }
    
    public mutating func addChildren(_ children: inout [RTreeNode<T>]) {
        if let _ = self.boundingBox {
            for child in children {
                self.boundingBox!.add(child.minimumBoundingRectangle())
                
            }
            
            self.children.append(contentsOf: children)
            return
            
        }
        
        if let first = children.first {
            var boundingBox = first.minimumBoundingRectangle()
            for child in children[1...] {
                boundingBox.add(child.minimumBoundingRectangle())
                
            }
            
            self.boundingBox = boundingBox
            
        }
        
        self.children.append(contentsOf: children)
        
    }
    
    public func closeNeighbor(_ point: T.Point) -> T? {
        if self.children.isEmpty {
            return nil
            
        }
        
        var follow = self
        
        while true {
            var minMinDistance: T.Point.Scalar = 0
            var newFollow = follow.children.first!
            var first = true
            
            for child in follow.children {
                let minDistance = child.minimumBoundingRectangle().minDistanceSquared(point)
                
                if minDistance < minMinDistance || first {
                    newFollow = child
                    minMinDistance = minDistance
                    first = false
                    
                }
                
            }
            
            switch newFollow {
            case .directoryNode(let data):
                follow = data
            case .leaf(let t):
                return t
                
            }
            
        }
        
    }
    
    func extendHeap(heap: inout PriorityQueue<RTreeNodeDistanceWrapper<T>>, children: [RTreeNode<T>], queryPoint: T.Point, pruneDistanceOption: inout T.Point.Scalar?) {
        for child in children {
            var distance: T.Point.Scalar = 0
            
            switch child {
            case .directoryNode(let data):
                distance = data.boundingBox!.minDistanceSquared(queryPoint)
            case .leaf(let t):
                distance = t.distanceSquared(point: queryPoint)
            }
            
            var doPrune = false
            if let pruneDistance = pruneDistanceOption {
                if distance > pruneDistance {
                    doPrune = true
                } else {
                    let newPruneDistance = child.minimumBoundingRectangle().minMaxDistanceSquared(queryPoint)
                    pruneDistanceOption = minInline(pruneDistance, newPruneDistance)
                    doPrune = false
                    
                }
                
            } else {
                pruneDistanceOption = child.minimumBoundingRectangle().minMaxDistanceSquared(queryPoint)
                doPrune = false
                
            }
            
            if !doPrune {
                heap.push(newElement: RTreeNodeDistanceWrapper(node: child, distance: distance))
                
            }
            
        }
        
    }
    
    func nearestNeighbor(_ point: T.Point) -> T? {
        var smallestMinMax: T.Point.Scalar? = nil
        var heap = PriorityQueue<RTreeNodeDistanceWrapper<T>>(<)
        
        self.extendHeap(heap: &heap, children: self.children, queryPoint: point, pruneDistanceOption: &smallestMinMax)
        
        while let current = heap.pop() {
            switch current.node {
            case .directoryNode(let data):
                self.extendHeap(heap: &heap, children: data.children, queryPoint: point, pruneDistanceOption: &smallestMinMax)
            case .leaf(let t):
                return t
                
            }
            
        }
        
        return nil
        
    }
    
    func nearestNeighbors(_ point: T.Point, nearestDistance: inout T.Point.Scalar?, result: inout [T]) -> T.Point.Scalar? {
        var smallestMinMax: T.Point.Scalar = 0
        var first = true
        
        for child in self.children {
            let newMin = child.minimumBoundingRectangle().minMaxDistanceSquared(point)
            
            if first {
                first = false
                smallestMinMax = newMin
                
            } else {
                smallestMinMax = minInline(smallestMinMax, newMin)
                
            }
            
        }
        
        let sorted = self.children.sorted { (l, r) -> Bool in
            l.minimumBoundingRectangle().minDistanceSquared(point) < r.minimumBoundingRectangle().minDistanceSquared(point)
            
        }
        
        for child in sorted {
            let minDist = child.minimumBoundingRectangle() .minDistanceSquared(point)
            if minDist > smallestMinMax {
                continue
            }
            
            if let nearestDistance = nearestDistance, minDist > nearestDistance {
                continue
            }
            
            if let nearest = child.nearestNeighbors(point, nearestDistance: &nearestDistance, result: &result) {
                nearestDistance = nearest
            }
            
        }
        
        return nearestDistance
        
    }
    
    func lookup(_ point: T.Point) -> T? {
        var todoList = [Self]()
        
        while let next = todoList.popLast() {
            if next.boundingBox?.contains(point: point) ?? false {
                for child in next.children {
                    switch child {
                    case .directoryNode(let data):
                        todoList.append(data)
                    case .leaf(let obj):
                        if obj.contains(point: point) {
                            return obj
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        return nil
        
    }

}
