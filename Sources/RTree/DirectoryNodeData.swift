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
    public var boundingBox: BoundingRectangle<T.Point>?
    public var children: [RTreeNode<T>]?
    private var childrenOffsets = [UInt64]()
    public var depth: Int = 1
    public var options: RTreeOptions = RTreeOptions()
    public var storage: Storage<T>?
    
    public init(storage: Storage<T>) {
        self.storage = storage
        
    }
    
    public init(depth: Int, options: RTreeOptions, storage: Storage<T>?) {
        self.depth = depth
        self.options = options
        self.storage = storage
        
    }
    
    public init(boundingBox: BoundingRectangle<T.Point>?, children: [RTreeNode<T>], depth: Int, options: RTreeOptions, storage: Storage<T>?) {
        self.boundingBox = boundingBox
        self.children = children
        self.depth = depth
        self.options = options
        self.storage = storage
        
    }
    
}

extension DirectoryNodeData {
    public static func newParent(_ children: [RTreeNode<T>], depth: Int, options: RTreeOptions, storage: Storage<T>) -> DirectoryNodeData<T> {
        var result = DirectoryNodeData(
            boundingBox: nil,
            children: children,
            depth: depth,
            options: options,
            storage: storage
        )
        result.updateMBR()
        
        return result
        
    }
    
    public mutating func updateMBR() {
        if self.children == nil {
            try! self.load()
            
        }
        
        let children = self.children!
        
        guard let first = children.first else {
            self.boundingBox = nil
            return
            
        }
        
        var newMBR = first.minimumBoundingRectangle()
        
        for child in children[1...] {
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
        self.updateMBRWithElement(t.minimumBoundingRectangle())
        
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
        if self.children == nil {
            try! self.load()
            
        }
        
        if self.children!.count > self.options.maxSize {
            if state.didReinsert(depth: self.depth) {
                
                // We did already reinsert on that level - split this node
                let offsplit = self.split()
                
                let result = InsertionResult.split(offsplit)
                
                return result
                
            } else {
                // We didn't attempt to reinsert yet - give it a try
                state.markReinsertion(depth: self.depth)
                
                let reinsertionNodes = self.reinsert()
                
                let result = InsertionResult.reinsert(reinsertionNodes)
                
                return result
                
            }
            
        }
        
        return .complete
        
    }
    
    mutating func split() -> RTreeNode<T> {
        if self.children == nil {
            try! self.load()
            
        }
        
        let axis = self.getSplitAxis()
        
        assert(self.children!.count > 1, "Cannot split tree with less than 2 children")
        
        self.children!.sort { (l, r) -> Bool in
            l.minimumBoundingRectangle()
                .lower[axis] < r.minimumBoundingRectangle().lower[axis]
        }
        
        var best: (T.Point.Scalar, T.Point.Scalar) = (0, 0)
        var bestIndex = self.options.minSize
        
        for k in self.options.minSize...(self.children!.count - self.options.minSize) {
            var firstMBR = self.children![k - 1].minimumBoundingRectangle()
            var secondMBR = self.children![k].minimumBoundingRectangle()
            
            let (l, r) = self.children!.splitAt(k)
            
            for child in l {
                firstMBR.add(child.minimumBoundingRectangle())
                
            }
            
            for child in r {
                secondMBR.add(child.minimumBoundingRectangle())
                
            }
            
            let overlapValue = firstMBR.intersect(secondMBR).area()
            let areaValue = firstMBR.area() + secondMBR.area()
            let newBest = (overlapValue, areaValue)
            
            if (newBest < best) || (k == self.options.minSize) {
                best = newBest
                bestIndex = k
                
            }
            
        }
        
        let offsplit = self.children!.splitOff(at: bestIndex)
        
        let result = RTreeNode.directoryNode(
            DirectoryNodeData.newParent(
                Array(offsplit),
                depth: self.depth,
                options: self.options,
                storage: self.storage!
            )
        )
        
        self.updateMBR()
        
        return result
        
    }
    
    mutating func reinsert() -> [RTreeNode<T>] {
        if self.children == nil {
            try! self.load()
            
        }
        
        let center = self.boundingBox!.center()
        
        self.children!.sort { (l, r) -> Bool in
            let lCenter = l.minimumBoundingRectangle().center()
            let rCenter = r.minimumBoundingRectangle().center()
            
            let result = lCenter.subtract(center).lengthSquared() < rCenter.subtract(center).lengthSquared()
            
            
            return result
            
        }
        
        let numChildren = self.children!.count
        
        let result = self.children!.splitOff(at: numChildren - self.options.reinsertionCount)
        
        self.updateMBR()
        
        return result
        
    }
    
    mutating func getSplitAxis() -> Int {
        if self.children == nil {
            try! self.load()
            
        }
        
        var bestGoodness: T.Point.Scalar = 0 // What
        var bestAxis = 0
        
        for axis in 0..<self.boundingBox!.lower.dimensions() {
            self.children!.sort { (l, r) -> Bool in
                l.minimumBoundingRectangle().lower[axis] < r.minimumBoundingRectangle().lower[axis]
                
            }
            
            for k in (self.options.minSize...(self.children!.count - self.options.minSize)) {
                var firstMBR = self.children![k - 1].minimumBoundingRectangle()
                var secondMBR = self.children![k].minimumBoundingRectangle()
                
                let (l, r) = self.children!.splitAt(k)
                
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
        
        return bestAxis
        
    }
    
    mutating func chooseSubtree(_ node: RTreeNode<T>) -> DirectoryNodeData<T> {
        assert(self.depth > 1, "Cannot choose subtree when depth is 1")
        let insertionMBR = node.minimumBoundingRectangle()
        var inclusionCount = 0
        var minArea: T.Point.Scalar = 0
        var minIndex = 0
        var first = true
        
        if self.children == nil {
            try! self.load()
            
        }
        
        let children = self.children!
        
        for (index, child) in children.enumerated() {
            let MBR = child.minimumBoundingRectangle()
            
            if MBR.contains(rectangle: insertionMBR) {
                inclusionCount += 1
                let area = MBR.area()
                if (area < minArea) || first {
                    minArea = area
                    minIndex = index
                    first = false
                    
                }
                
            }
            
        }
        
        if inclusionCount == 0 {
            let allLeaves = self.depth <= 2
            var min: (T.Point.Scalar, T.Point.Scalar, T.Point.Scalar) = (0, 0, 0)
            
            for (index, child1) in children.enumerated() {
                let MBR = child1.minimumBoundingRectangle()
                var newMBR = MBR
                
                newMBR.add(insertionMBR)
                
                var overlapIncrease: T.Point.Scalar = 0
                
                if allLeaves {
                    var overlap: T.Point.Scalar = 0
                    var newOverlap: T.Point.Scalar = 0
                    
                    for child2 in self.children! {
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
                let areaIncrease = area - MBR.area()
                let newMin = (overlapIncrease, areaIncrease, area)
                
                if (newMin < min) || (index == 0) {
                    min = newMin
                    minIndex = index
                    
                }
                
            }
            
        }
        
        switch children[minIndex] {
        case .directoryNode(let data):
            return data
            
        case .leaf:
            fatalError("No leaves at this depth")
            
        }
        
    }
    
    public mutating func addChildren(_ newChildren: inout [RTreeNode<T>]) {
        if self.children == nil {
            try! self.load()
            
        }
        
        if let _ = self.boundingBox {
            for child in newChildren {
                self.boundingBox!.add(child.minimumBoundingRectangle())
                
            }
            
            self.children!.mutatingAppend(&newChildren)
            return
            
        }
        
        if let first = newChildren.first {
            var boundingBox = first.minimumBoundingRectangle()
            
            for child in newChildren[1...] {
                boundingBox.add(child.minimumBoundingRectangle())
                
            }
            
            self.boundingBox = boundingBox
            
        }
        
        self.children!.mutatingAppend(&newChildren)
        
    }
    
    func extend(_ heap: inout Heap<RTreeNodeDistanceWrapper<T>>, children: [RTreeNode<T>], queryPoint: T.Point, pruneDistanceOption: inout T.Point.Scalar?) {
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
                heap.insert(RTreeNodeDistanceWrapper(node: child, distance: distance))
                
            }
            
        }
        
    }
    
    mutating func nearestNeighbor(_ point: T.Point) -> T? {
        if self.children == nil {
            try! self.load()
            
        }
        
        var smallestMinMax: T.Point.Scalar? = nil
        var heap = Heap<RTreeNodeDistanceWrapper<T>>(sort: <)
        
        self.extend(&heap, children: self.children!, queryPoint: point, pruneDistanceOption: &smallestMinMax)
        
        while let current = heap.remove() {
            switch current.node {
            case .directoryNode(var data):
                if data.children == nil {
                    try! data.load()
                    
                }
                
                self.extend(&heap, children: data.children!, queryPoint: point, pruneDistanceOption: &smallestMinMax)
                
            case .leaf(let t):
                return t
                
            }
            
        }
        
        return nil
        
    }

}

extension DirectoryNodeData {
    public mutating func load() throws {
        guard let storage = self.storage else {
            throw RTreeError.nodeHasNoStorage
            
        }
        
        self.children = try self.childrenOffsets.map { (offset) -> RTreeNode<T> in
            try storage.loadRTreeNode(withOffset: offset)
            
        }
        
    }
    
    public mutating func save() throws -> UInt64 {
        guard let storage = self.storage else {
            throw RTreeError.nodeHasNoStorage
            
        }
        
        if self.children == nil {
            try self.load()
            
        }
        
        self.childrenOffsets = try self.children!.map { (node) -> UInt64 in
            return try storage.save(node)
            
        }
        
        return try storage.save(self)
        
    }
    
}

extension DirectoryNodeData: Codable {
    enum CodingKeys: CodingKey {
        case boundingBox
        case children
        case depth
        case options
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.boundingBox, forKey: .boundingBox)
        try container.encode(self.childrenOffsets.map({ (offset) -> String in
            offset.toPaddedString()
        }), forKey: .children)
        try container.encode(self.depth, forKey: .depth)
        try container.encode(self.options, forKey: .options)
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.boundingBox = try container.decode(BoundingRectangle<T.Point>.self, forKey: .boundingBox)
        self.depth = try container.decode(Int.self, forKey: .depth)
        self.options = try container.decode(RTreeOptions.self, forKey: .options)
        
        let childrenOffsetStrings = try container.decode([String].self, forKey: .children)
        self.childrenOffsets = try childrenOffsetStrings.map({ (offsetString) -> UInt64 in
            guard let offset = UInt64(offsetString) else {
                throw RTreeError.invalidRecord
                
            }
            
            return offset
            
        })
        
    }
    
}
